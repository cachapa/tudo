import 'package:crdt/crdt.dart';
import 'package:flutter/foundation.dart';

import '../list_manager/list_provider.dart';
import 'sync_client.dart';

class SyncManager with ChangeNotifier {
  final _clientMap = <String, SyncClient>{};

  late ListProvider _listManager;
  Hlc? _lastSync;

  bool get connected => _clientMap.isEmpty
      ? true
      : _clientMap.values
          .map((e) => e.isConnected)
          .reduce((value, element) => value && element);

  set listManager(ListProvider lm) {
    _listManager = lm;

    lm.lists.map((e) => e.id).forEach((id) {
      if (!_clientMap.containsKey(id)) {
        _clientMap[id] ??= SyncClient(id)
          ..connectionState.listen((connected) {
            // print(
            //     '${id.substring(0, 4)}… ${connected ? 'Connected' : 'Disconnected'}');
            notifyListeners();
          })
          ..messages.listen((message) {
            // print('<= $message');
            final list = _listManager.get(id);
            _lastSync = list!.canonicalTime;
            list.mergeJson(message);
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
      _clientMap[list.id]!.send(changeset);
    });
  }
}
