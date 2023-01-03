import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart';
import 'package:tudo_app/auth/auth_provider.dart';
import 'package:tudo_app/crdt/hlc.dart';
import 'package:tudo_app/extensions.dart';
import 'package:tudo_app/lists/list_provider.dart';
import 'package:tudo_app/util/build_info.dart';
import 'package:tudo_app/util/store.dart';

import '../config.dart';
import 'sync_client.dart';

class SyncProvider {
  final ListProvider _listProvider;
  final Store _store;
  late final SyncClient _client;

  var _online = false;
  Timer? _reconnectTimer;

  set _lastReceive(Hlc? value) => _store.put('last_recv', value);

  Hlc? get _lastReceive => _store.get('last_recv');

  set _lastSend(Hlc? value) => _store.put('last_send', value);

  Hlc? get _lastSend => _store.get('last_send');

  Stream<bool> get connectionState => _client.connectionState;

  SyncProvider(AuthProvider authProvider, StoreProvider storeProvider,
      this._listProvider)
      : _store = storeProvider.getStore('sync') {
    _client = SyncClient(authProvider.token, authProvider.userId)
      ..messages.listen((message) async {
        final map = jsonDecode(message) as Map;
        final type = map['type'];

        switch (type) {
          case 'hlc':
            _lastSend = (map['hlc'] as String).asHlc;
            break;
          case 'changeset':
            // Merge remote changeset
            final changeset =
                (map['data'] as List).cast<Map<String, dynamic>>();
            'RECV ${changeset.length} records'.log;

            // Store last receive time
            final canonicalTime = await _listProvider.merge(changeset);
            _lastReceive = canonicalTime;

            // Notify remote
            _client.send(jsonEncode({
              'type': 'hlc',
              'hlc': map['hlc'],
            }));
            break;
        }
      });

    _client.connectionState.listen((isConnected) {
      if (isConnected) {
        // Sync whenever connection is established
        _sync();
      } else {
        // Trigger reconnect
        if (_online) {
          _reconnectTimer = Timer(const Duration(seconds: 10), () => connect());
        }
      }
    });

    // Sync on changes
    _listProvider.allChanges.listen((_) => _sync());

    // Make sure all sockets are connected
    connect();
  }

  void connect() {
    _reconnectTimer?.cancel();
    _online = true;
    _client.connect(_lastReceive);
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _online = false;

    _client.disconnect();
  }

  Future<void> _sync() async {
    if (!_client.isConnected) return;

    final changeset = await _listProvider.changeset(_lastSend);
    if (changeset.records.isEmpty) return;

    'SEND ${changeset.records.length} records'.log;
    _client.send(jsonEncode({
      'type': 'changeset',
      'data': changeset.records,
      'hlc': changeset.canonicalTime,
    }));
  }

  Future<bool> isUpdateRequired() async {
    final result = await head(
      Uri.parse('$serverAddress/check_version'),
      headers: {HttpHeaders.userAgentHeader: BuildInfo.userAgent},
    );
    // There's actually a status code for this:
    // https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/426
    return result.statusCode == 426;
  }
}
