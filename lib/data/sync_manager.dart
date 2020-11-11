import 'package:flutter/foundation.dart';

import 'list_manager.dart';
import 'sync_client.dart';

class SyncManager with ChangeNotifier {
  final _clientMap = <String, SyncClient>{};

  ListManager _listManager;

  bool get connected => _clientMap.isEmpty
      ? false
      : _clientMap.values
          .map((e) => e.isConnected)
          .reduce((value, element) => value && element);

  set listManager(ListManager lm) {
    _listManager = lm;


    print(lm.lists);

    lm.lists.map((e) => e.id).forEach((id) {
      if (!_clientMap.containsKey(id)) {
        _clientMap[id] ??= SyncClient(id);
        _clientMap[id].connectionState.listen((connected) {
          print(
              '${id.substring(0, 4)}… ${connected ? 'Connected' : 'Disconnected'}');
          notifyListeners();
        });
        _clientMap[id].messages.listen((message) {
          // print('<= $message');
          _listManager.get(id).mergeJson(message);
        });
      }
    });

    // Make sure all sockets are connected
    connect();

    sync();
  }

  void connect() => _clientMap.values.forEach((client) {
    client.connect();
  });

  void sync() {
    _listManager.lists.forEach((list) {
      _clientMap[list.id].send(list.toJson());
    });
  }
}
