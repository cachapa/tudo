import 'dart:async';
import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:tudo_server/crdt/tudo_crdt.dart';
import 'package:tudo_server/extensions.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'config.dart';

class TudoServer {
  late final TudoCrdt _crdt;

  Future<void> serve(int port) async {
    _crdt = TudoCrdt();
    await _crdt.init('store', 'tudo');

    var router = Router()
      ..get('/ws', _wsHandler)
      // Return 404 for everything else
      ..all('/<ignored|.*>', _notFoundHandler);

    var handler = const Pipeline()
        .addMiddleware(logRequests())
        .addMiddleware(_validateSecret)
        .addHandler(router);

    var server = await io.serve(handler, '0.0.0.0', port);
    print('Serving at http://${server.address.host}:${server.port}');
  }

  Future<Response> _wsHandler(Request request) async {
    if (!request.headers.containsKey('user_id')) {
      return Response.forbidden('Invalid user id');
    }

    final userId = request.headers['user_id']!;
    var lastSend = request.headers['last_receive'];

    print('Client connected: $userId');
    var handler = webSocketHandler((WebSocketChannel webSocket) async {
      StreamSubscription? changesSubscription;
      String? nodeId;

      // Send changeset on connect
      _sendChangeset(webSocket, userId, lastSend, nodeId);

      // Monitor remote changesets
      webSocket.stream.listen((message) async {
        final map = jsonDecode(message) as Map;
        final type = map['type'] ?? '';

        switch (type) {
          case 'hlc':
            lastSend = map['hlc'];
            break;
          case 'changeset':
            // Read node id
            nodeId ??= (map['hlc'] as String).asHlc.nodeId;

            // Merge remote changeset
            final changeset =
                (map['data'] as List).cast<Map<String, dynamic>>();
            print('RECV ${changeset.length} records');

            await _crdt.merge(changeset);

            // HACK Recognize if the user added a new list and re-create the record to trigger
            // the entire list to be sent.
            // This gets around the problem where the changeset wouldn't contain list data older than lastSend
            for (final map in changeset) {
              if (map['collection'] == 'user_lists' &&
                  map['field'] == 'created_at') {
                final listId = (map['id'] as String).split(':')[1];
                await _crdt.setField(
                    'user_lists', [userId, listId], map['field'], map['value']);
                print('hacked new list');
              }
            }

            // Notify client
            webSocket.sink.add(jsonEncode({
              'type': 'hlc',
              'hlc': map['hlc'],
            }));
            break;
        }
      }, onDone: () {
        changesSubscription?.cancel();
        print('Client disconnected from ${request.url.path}');
      }, onError: (e) {
        print(e);
      });

      // Monitor local database
      changesSubscription = _crdt.allChanges
          .listen((_) => _sendChangeset(webSocket, userId, lastSend, nodeId));
    });

    return await handler(request);
  }

  Future<void> _sendChangeset(WebSocketChannel webSocket, String userId,
      String? lastSend, String? nodeId) async {
    var changeset = await _crdt.queryAsync('''
          SELECT collection, id, field, value, hlc, modified FROM user_lists
            JOIN crdt
              ON (collection = 'user_lists' AND id LIKE '%' || list_id)
              OR (collection = 'lists' AND id = list_id)
            WHERE user_id = ?1 AND modified > ?2 AND hlc NOT LIKE '%' || ?3
          UNION ALL
          SELECT collection, crdt.id, field, value, hlc, modified FROM user_lists
            JOIN todos ON user_lists.list_id = todos.list_id
            JOIN crdt ON todos.id = crdt.id
            WHERE user_id = ?1 AND modified > ?2 AND hlc NOT LIKE '%' || ?3
          ''', [userId, lastSend ?? '', nodeId ?? '---']);
    if (changeset.isEmpty) return;

    // Detect if this user joined a new list and send all its data.
    for (final map in changeset) {
      if (map['collection'] == 'user_lists' && map['field'] == 'created_at') {
        final listId = (map['id'] as String).split(':')[1];
        final listChangeset = await _listChangeset(listId);
        changeset = [...changeset, ...listChangeset];
      }
    }

    'SEND ${changeset.length} records'.log;
    webSocket.sink.add(jsonEncode({
      'type': 'changeset',
      'data': changeset,
      'hlc': changeset.first['modified'],
    }));
  }

  Response _notFoundHandler(Request request) => Response.notFound('Not found');

  Handler _validateSecret(Handler innerHandler) => (request) async {
        if (request.headers['api_secret'] == apiSecret) {
          return innerHandler(request);
        } else {
          print('Invalid secret: ${request.headers['api_secret']}');
          return Response.forbidden('Invalid secret');
        }
      };

  Future<List<Map<String, dynamic>>> _listChangeset(String listId) =>
      _crdt.queryAsync('''
        SELECT collection, id, field, value, hlc, modified FROM crdt
          WHERE collection = 'user_lists' AND id LIKE '%:' || ?1
        UNION ALL
        SELECT collection, id, field, value, hlc, modified FROM crdt
          WHERE collection = 'lists' AND id = ?1
        UNION ALL
        SELECT collection, crdt.id, field, value, hlc, modified FROM todos
          JOIN crdt ON todos.id = crdt.id
          WHERE list_id = ?1
        ORDER BY value
      ''', [listId]);
}

class CrdtStream {
  final _controller = StreamController<String>.broadcast();

  Stream<String> get stream => _controller.stream;

  void add(String event) => _controller.add(event);

  void close() => _controller.close();
}
