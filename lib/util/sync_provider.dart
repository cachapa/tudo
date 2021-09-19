import 'package:crdt/crdt.dart';
import 'package:flutter/foundation.dart';
import 'package:tudo_client/extensions.dart';

import '../list_manager/list_provider.dart';
import 'sync_client.dart';

class SyncProvider with ChangeNotifier {
  late ListProvider _listProvider;
  final _clientMap = <String, SyncClient>{};

  Hlc? _lastSync;

  set listProvider(ListProvider listProvider) {
    _listProvider = listProvider;

    _listProvider.lists.map((e) => e.id).forEach((id) {
      if (!_clientMap.containsKey(id)) {
        _clientMap[id] = SyncClient(id)
          ..connectionState.listen((connected) {
            // print(
            //     '${id.substring(0, 4)}… ${connected ? 'Connected' : 'Disconnected'}');
            notifyListeners();
          })
          ..messages.listen((message) {
            // print('<= $message');
            final list = _listProvider.get(id);
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

  bool get connected => _clientMap.isEmpty
      ? true
      : _clientMap.values
          .map((e) => e.isConnected)
          .reduce((value, element) => value && element);

  void connect() {
    if (connected) return;
    for (var client in _clientMap.values) {
      client.connect();
    }
    sync();
  }

  void disconnect() {
    for (var client in _clientMap.values) {
      client.disconnect();
    }
  }

  void sync() {
    for (var list in _listProvider.lists) {
      final changeset = list.toJson(_lastSync);
      '=> ${list.name}: $changeset'.log;
      _clientMap[list.id]!.send(changeset);
    }
  }
}
