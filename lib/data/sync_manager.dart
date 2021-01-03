import 'package:crdt/crdt.dart';
import 'package:flutter/foundation.dart';

import 'list_manager.dart';
import 'sync_client.dart';

class SyncManager with ChangeNotifier {
  final _clientMap = <String, SyncClient>{};

  Hlc _lastSync;
  ListManager _listManager;

  bool get connected => _clientMap.isEmpty
      ? false
      : _clientMap.values
          .map((e) => e.isConnected)
          .reduce((value, element) => value && element);

  set listManager(ListManager lm) {
    _listManager = lm;

    lm.lists.map((e) => e.id).forEach((id) {
      if (!_clientMap.containsKey(id)) {
        _clientMap[id] ??= SyncClient(id);
        _clientMap[id].connectionState.listen((connected) {
          // print(
          //     '${id.substring(0, 4)}… ${connected ? 'Connected' : 'Disconnected'}');
          notifyListeners();
        });
        _clientMap[id].messages.listen((message) {
          // print('<= $message');
          final list = _listManager.get(id);
          list.mergeJson(message);
          _lastSync = list.canonicalTime;
          // print('lastSync: ${_lastSync.logicalTime}');
        });
      }
    });

    // Make sure all sockets are connected
    connect();

    sync();
  }

  void connect() {
    if (connected) return;
    _clientMap.values.forEach((client) => client.connect());
    sync();
  }

  void disconnect() => _clientMap.values.forEach((client) {
        client.disconnect();
      });

  void sync() {
    _listManager.lists.forEach((list) {
      final changeset = list.toJson(_lastSync);
      // print('=> ${list.name}: $changeset');
      _clientMap[list.id].send(changeset);
    });
  }
}
