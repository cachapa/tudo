import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart';
import 'package:platform_info/platform_info.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sqlite_crdt/sqlite_crdt.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../config.dart';
import '../extensions.dart';
import '../util/build_info.dart';

class SyncClient {
  final String token;
  final String userId;
  final String nodeId;
  WebSocketChannel? channel;
  StreamSubscription? subscription;

  final connectionState = BehaviorSubject.seeded(false);

  final messages = PublishSubject<String>();

  SyncClient(this.token, this.userId, this.nodeId);

  bool get isConnected => connectionState.value;

  Future<Hlc?> getRemoteLastModified() async {
    try {
      final result = await get(
          serverUri.apply(
            'last_modified/$userId',
            queryParameters: {
              'api_secret': apiSecret,
              'token': token,
              'node_id': nodeId,
            },
          ),
          headers: {
            HttpHeaders.userAgentHeader: BuildInfo.userAgent,
          });
      if (result.statusCode ~/ 100 != 2) {
        throw '${result.statusCode}: ${result.reasonPhrase}\n${result.body}';
      }
      return (jsonDecode(result.body)['last_modified'] as String?)?.toHlc;
    } catch (_) {
      return null;
    }
  }

  void connect(Hlc? lastReceive) {
    if (isConnected) return;

    // Dart's WebSocket uses a global static client, so the user agent needs to be set like so:
    if (platform.isIO) WebSocket.userAgent = BuildInfo.userAgent;

    final uri = serverUri.apply('ws/$userId',
        scheme: serverUri.scheme.replaceFirst('http', 'ws'),
        queryParameters: {
          'api_secret': apiSecret,
          'token': token,
          'node_id': nodeId,
          if (lastReceive != null) 'last_receive': lastReceive.toString(),
        });
    channel = WebSocketChannel.connect(uri);
    'connected'.log;
    connectionState.add(true);

    subscription = channel!.stream.listen(
      (message) {
        messages.add(message);
      },
      onDone: () => _disconnect(),
      onError: (e) {
        e.toString().log;
        _disconnect();
      },
    );
  }

  void send(dynamic message) => channel?.sink.add(message);

  void disconnect() {
    _disconnect();
  }

  void _disconnect() {
    'disconnected'.log;
    connectionState.add(false);
    subscription?.cancel();
    subscription = null;
    channel?.sink.close();
    channel = null;
  }

  void destroy() {
    connectionState.close();
    messages.close();
  }
}
