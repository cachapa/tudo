import 'dart:async';

import 'package:tudo_client/config.dart';
import 'package:tudo_client/extensions.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class SyncClient {
  final String id;

  WebSocketChannel? channel;
  StreamSubscription? subscription;

  final _connectionStateController = StreamController<bool>();

  SyncClient(this.id);

  Stream<bool> get connectionState => _connectionStateController.stream;

  final _messageController = StreamController<String>();

  bool get isConnected => subscription != null;

  Stream<String> get messages => _messageController.stream;

  void connect() {
    if (isConnected) return;

    final endpoint = '$serverAddress/$id/ws';
    channel = IOWebSocketChannel.connect(Uri.parse(endpoint), headers: {
      'api_secret': apiSecret,
    });

    subscription = channel!.stream.listen(
      (message) {
        'connected'.log;
        _connectionStateController.sink.add(true);
        _messageController.add(message);
      },
      onDone: () => disconnect(),
      onError: (e) => disconnect(),
    );
  }

  void send(String message) => channel!.sink.add(message);

  void disconnect() {
    'disconnected'.log;
    _connectionStateController.sink.add(false);
    subscription?.cancel();
    subscription = null;
  }

  void destroy() {
    _connectionStateController.close();
  }
}
