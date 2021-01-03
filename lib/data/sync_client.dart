import 'dart:async';

import 'package:tudo_client/config.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

enum ConnectionState { disconnected, connecting, connected }

class SyncClient {
  final String id;

  WebSocketChannel channel;
  StreamSubscription subscription;

  final _connectionStateController = StreamController<bool>();

  SyncClient(this.id);

  Stream<bool> get connectionState => _connectionStateController.stream;

  final _messageController = StreamController<String>();

  bool get isConnected => subscription != null;

  Stream<String> get messages => _messageController.stream;

  void connect() {
    if (isConnected) return;

    final endpoint = '$serverAddress/$id/ws';
    channel = WebSocketChannel.connect(Uri.parse(endpoint));

    _connectionStateController.sink.add(true);

    subscription = channel.stream.listen(
      (message) => _messageController.add(message),
      onDone: () => disconnect(),
    );

    // print('connected');
  }

  void send(String message) => channel.sink.add(message);

  void disconnect() {
    // print('disconnected');
    _connectionStateController.sink.add(false);
    subscription?.cancel();
    subscription = null;
  }

  void destroy() {
    _connectionStateController.close();
  }
}
