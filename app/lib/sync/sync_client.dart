import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:tudo_app/config.dart';
import 'package:tudo_app/crdt/hlc.dart';
import 'package:tudo_app/extensions.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class SyncClient {
  final String userId;
  WebSocketChannel? channel;
  StreamSubscription? subscription;

  final connectionState = BehaviorSubject.seeded(false);

  final messages = PublishSubject<String>();

  SyncClient(this.userId);

  bool get isConnected => connectionState.value;

  void connect(Hlc? lastReceive) {
    if (isConnected) return;

    const endpoint = '$serverAddress/ws';
    channel = IOWebSocketChannel.connect(Uri.parse(endpoint), headers: {
      'api_secret': apiSecret,
      'user_id': userId,
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
