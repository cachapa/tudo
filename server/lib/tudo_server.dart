import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:postgres_crdt/postgres_crdt.dart';
import 'package:rxdart/transformers.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:version/version.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'config.dart';
import 'extensions.dart';

class TudoServer {
  late final SqlCrdt _crdt;

  var userCount = 0;

  Future<void> serve(int port) async {
    _crdt = await PostgresCrdt.open('tudo', username: 'cachapa');

    final router = Router()
      ..head('/check_version', (_) => Response(200))
      ..get('/auth/<userId>', _auth)
      ..get('/last_modified/<userId>', _lastModified)
      ..get('/ws/<userId>', _wsHandler)
      // TODO Compat request without user id in request path
      ..get('/auth', _auth)
      ..get('/last_modified', _lastModifiedCompat)
      ..get('/ws', _wsHandlerCompat);

    final handler = Pipeline()
        .addMiddleware(logRequests())
        .addMiddleware(_validateVersion)
        .addMiddleware(_validateSecret)
        .addMiddleware(_validateCredentials)
        .addHandler(router);

    var server = await io.serve(handler, '0.0.0.0', port);
    print('Serving at http://${server.address.host}:${server.port}');
  }

  /// By the time we arrive here, both the secret and credentials have been validated
  Response _auth(Request request) => Response.ok('👍');

  Future<Response> _lastModifiedCompat(Request request) =>
      _lastModified(request, request.headers['user_id'] ?? '');

  Future<Response> _lastModified(Request request, String userId) async {
    final nodeId = request.compatParams('node_id')!;
    final latest = await _crdt.lastModified(onlyNodeId: nodeId);
    return Response.ok(jsonEncode({'last_modified': latest}));
  }

  Future<Response> _wsHandlerCompat(Request request) =>
      _wsHandler(request, request.headers['user_id'] ?? '');

  Future<Response> _wsHandler(Request request, String userId) async {
    final nodeId = request.compatParams('node_id')!;
    var lastSend =
        request.compatParams('last_receive')?.toHlc.apply(nodeId: _crdt.nodeId);

    final slug = '${userId.short} (${nodeId.short})';
    print('$slug: connect [${++userCount}]');

    var handler = webSocketHandler((WebSocketChannel webSocket) async {
      StreamSubscription? changesSubscription;

      // Monitor remote changesets
      webSocket.stream.listen((message) async {
        final changeset = (jsonDecode(message) as Map<String, dynamic>)
            .map((key, value) => MapEntry(
                  key,
                  (value as List).cast<Map<String, dynamic>>(),
                ));

        // print(JsonEncoder.withIndent('  ').convert(changeset));

        final count = changeset.recordCount;
        print('RECV $count records');

        // Merge remote changeset
        await _crdt.merge(changeset);
      }, onDone: () {
        changesSubscription?.cancel();
        print('$slug: leave [${--userCount}] ');
      }, onError: (e) {
        print(e);
      });

      // Monitor local database
      changesSubscription = _crdt.watch('''
        SELECT hlc FROM users UNION ALL
        SELECT hlc FROM user_lists UNION ALL
        SELECT hlc FROM lists UNION ALL
        SELECT hlc FROM todos
        LIMIT 1
      ''').debounceTime(Duration(milliseconds: 200)).listen(
            (_) async {
              await _sendChangeset(webSocket, userId, nodeId, lastSend);
              lastSend = _crdt.canonicalTime;
            },
          );
    });

    return await handler(request);
  }

  Future<void> _sendChangeset(WebSocketChannel webSocket, String userId,
      String nodeId, Hlc? modifiedSince) async {
    modifiedSince ??= Hlc.zero(_crdt.nodeId);
    final changeset = <String, Iterable<Map<String, Object?>>>{
      'users': await _crdt.query('''
        SELECT users.id, users.name, users.is_deleted, users.hlc FROM
          (SELECT user_id, max(created_at) AS created_at FROM
            (SELECT list_id FROM user_lists WHERE user_id = ?1 AND is_deleted = 0) AS list_ids
            JOIN user_lists ON user_lists.list_id = list_ids.list_id
            GROUP BY user_lists.user_id
          ) AS user_ids
        JOIN users ON users.id = user_ids.user_id
        WHERE node_id != ?2
          AND modified > CASE WHEN user_ids.created_at >= ?3 THEN '' ELSE ?3 END
      ''', [userId, nodeId, modifiedSince]),
      'user_lists': await _crdt.query('''
        SELECT user_lists.list_id, user_id, position, created_at, is_deleted, hlc FROM
          (SELECT list_id FROM user_lists WHERE user_id = ?1) AS list_ids
        JOIN user_lists ON list_ids.list_id = user_lists.list_id
        WHERE node_id != ?2
          AND modified > CASE WHEN user_lists.created_at >= ?3 THEN '' ELSE ?3 END
      ''', [userId, nodeId, modifiedSince]),
      'lists': await _crdt.query('''
        SELECT lists.id, lists.name, lists.color, lists.creator_id,
          lists.created_at, lists.is_deleted, lists.hlc FROM user_lists
        JOIN lists ON list_id = lists.id AND user_id = ?1 AND user_lists.is_deleted = 0
        WHERE lists.node_id != ?2
          AND lists.modified > CASE WHEN user_lists.created_at >= ?3 THEN '' ELSE ?3 END
      ''', [userId, nodeId, modifiedSince]),
      'todos': await _crdt.query('''
        SELECT todos.id, todos.list_id, todos.name, todos.done, todos.position,
          todos.creator_id, todos.created_at, todos.done_at, todos.done_by,
          todos.is_deleted, todos.hlc FROM user_lists
        JOIN todos ON user_lists.list_id = todos.list_id AND user_id = ?1 AND user_lists.is_deleted = 0
        WHERE todos.node_id != ?2
          AND todos.modified > CASE WHEN user_lists.created_at >= ?3 THEN '' ELSE ?3 END
      ''', [userId, nodeId, modifiedSince]),
    }..removeWhere((_, value) => value.isEmpty);

    if (changeset.recordCount == 0) return;

    print('SEND ${changeset.recordCount} records');
    print(JsonEncoder.withIndent('  ').convert(changeset));
    webSocket.sink.add(jsonEncode(changeset));
  }

  Handler _validateVersion(Handler innerHandler) => (request) async {
        final userAgent = request.headers[HttpHeaders.userAgentHeader]!;
        final version = Version.parse(userAgent.substring(
            userAgent.indexOf('/') + 1, userAgent.indexOf(' ')));
        final needsUpgrade = version < Version(2, 0, 0);
        return needsUpgrade ? Response(426) : innerHandler(request);
      };

  Handler _validateSecret(Handler innerHandler) => (request) async {
        // Do not validate for public paths
        if (['check_version'].contains(request.url.path)) {
          return innerHandler(request);
        }

        final suppliedSecret = request.compatParams('api_secret') ?? '';
        // TODO Compat secret length was reduced to 14
        if (suppliedSecret.startsWith(apiSecret)) {
          return innerHandler(request);
        } else {
          return Response.forbidden('Invalid API secret: $suppliedSecret');
        }
      };

  Handler _validateCredentials(Handler innerHandler) => (request) async {
        // Do not validate for public paths
        if (['check_version'].contains(request.url.path)) {
          return innerHandler(request);
        }

        final userId =
            request.headers['user_id'] ?? request.url.pathSegments.last;
        final token = request.compatParams('token');

        // Validate user id length
        if (userId.length != 36) {
          return Response.forbidden('Invalid user id: $userId');
        }

        // Validate token length
        // print(token!.length);
        if (token == null || token.length < 32 || token.length > 128) {
          return Response.forbidden('Invalid token: $token');
        }

        // Associate token with user id, if it doesn't exist yet
        String? knownToken;
        await _crdt.transaction((txn) async {
          // Check if there's a token in the db
          // This is done in a transaction to make sure the check and creation
          // happen atomically
          final result = await txn
              .query('SELECT token FROM auth WHERE user_id = ?1', [userId]);
          knownToken = result.isEmpty ? null : result.first['token'] as String?;

          // Associate new token with user id
          if (knownToken == null) {
            await txn.execute('''
              INSERT INTO auth (user_id, token, created_at)
              VALUES (?1, ?2, ?3)
            ''', [userId, token, DateTime.now()]);
            knownToken = token;
          }
        });

        // Verify that user id and token match
        return token == knownToken
            ? innerHandler(request)
            : Response.forbidden(
                'Invalid token for supplied user id: $userId\n$token');
      };
}

class CrdtStream {
  final _controller = StreamController<String>.broadcast();

  Stream<String> get stream => _controller.stream;

  void add(String event) => _controller.add(event);

  void close() => _controller.close();
}

// TODO Compat fall back to header parameters
extension on Request {
  String? compatParams(String key) =>
      requestedUri.queryParameters[key] ?? headers[key];
}
