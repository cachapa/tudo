import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sqlite_crdt/sqlite_crdt.dart';
import 'package:tudo_app/config.dart';
import 'package:tudo_app/extensions.dart';
import 'package:tudo_app/util/build_info.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

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
    final result =
        await get(Uri.parse('$serverAddress/last_modified'), headers: {
      HttpHeaders.userAgentHeader: BuildInfo.userAgent,
      'api_secret': apiSecret,
      'token': token,
      'user_id': userId,
      'node_id': nodeId,
    });
    if (result.statusCode ~/ 100 != 2) {
      throw '${result.statusCode}: ${result.reasonPhrase}\n${result.body}';
    }
    return (jsonDecode(result.body)['last_modified'] as String?)?.toHlc;
  }

  void connect(Hlc? lastReceive) {
    if (isConnected) return;

    // Dart's WebSocket uses a global static client, so the user agent needs to be set like so:
    WebSocket.userAgent = BuildInfo.userAgent;

    final endpoint = '${serverAddress.replaceFirst('http', 'ws')}/ws';
    channel = IOWebSocketChannel.connect(Uri.parse(endpoint), headers: {
      'api_secret': apiSecret,
      'token': token,
      'user_id': userId,
      'node_id': nodeId,
      if (lastReceive != null) 'last_receive': lastReceive,
    });
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

  void send(dynamic message) => channel!.sink.add(message);

  void disconnect() {
    _disconnect();
  }

  void _disconnect() {
    'disconnected'.log;
    connectionState.add(false);
    subscription?.cancel();
    subscription = null;
  }

  void destroy() {
    connectionState.close();
    messages.close();
  }
}
