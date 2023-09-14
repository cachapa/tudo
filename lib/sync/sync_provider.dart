import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crdt_sync/crdt_sync.dart';
import 'package:http/http.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sqlite_crdt/sqlite_crdt.dart';

import '../auth/auth_provider.dart';
import '../config.dart';
import '../extensions.dart';
import '../util/build_info.dart';
import '../util/durations.dart';
import '../util/store.dart';
import 'api_client.dart';

class SyncProvider {
  final String _userId;
  final SqlCrdt _crdt;
  final Store _store;

  late final ApiClient _apiClient;
  late final CrdtSyncClient _syncClient;
  late final connectionState = BehaviorSubject.seeded(false)
    ..addStream(_syncClient.watchState.map((e) {
      // '$e'.log;
      return e == SocketState.connected;
    }));

  Timer? _fullSyncTimer;

  SyncProvider(
      AuthProvider authProvider, StoreProvider storeProvider, this._crdt)
      : _userId = authProvider.userId,
        _store = storeProvider.getStore('sync') {
    _apiClient = ApiClient(authProvider.token);
    _syncClient = CrdtSyncClient(
      _crdt,
      serverUri.replace(
          scheme: serverUri.scheme.replaceFirst('http', 'ws'),
          path: 'ws/${authProvider.userId}',
          queryParameters: {
            'token': authProvider.token,
          }),
      validateRecord: (table, record) {
        // Perform full sync whenever user_lists is changed remotely.
        // Makes sure this node gets all relevant records even if they were
        // created before joining a new list (lists, todos, user info).
        if (table == 'user_lists' && record['is_deleted'] == 0) {
          _store.put('need_full_sync', true);
          // Avoid triggering full syncs on every user_lists record
          _fullSyncTimer?.cancel();
          _fullSyncTimer = Timer(longDuration, () => _fullSync());
        }
        return true;
      },
      onConnect: (peerId, customData) {
        // TODO Default to false
        if (_store.get('need_full_sync', defaultValue: true)) {
          _fullSync();
        }
      },
      onChangesetReceived: (nodeId, recordCounts) =>
          '⬇️ ${recordCounts.entries.map((e) => '${e.key}: ${e.value}').join(', ')}'
              .log,
      onChangesetSent: (nodeId, recordCounts) =>
          '⬆️ ${recordCounts.entries.map((e) => '${e.key}: ${e.value}').join(', ')}'
              .log,
      // verbose: true,
    );
  }

  void connect() => _syncClient.connect();

  void disconnect() => _syncClient.disconnect();

  Future<void> joinList(String listId) async {
    'Joining list $listId…'.log;
    await _apiClient.post(serverUri.apply('lists/$_userId/$listId'));
  }

  Future<bool> isUpdateRequired() async {
    try {
      final result = await head(
        serverUri.apply('check_version'),
        headers: {HttpHeaders.userAgentHeader: BuildInfo.userAgent},
      );
      return result.statusCode == HttpStatus.upgradeRequired;
    } catch (_) {
      return false;
    }
  }

  Future<void> _fullSync() async {
    'Performing full sync…'.log;
    final start = DateTime.now().millisecondsSinceEpoch;
    final result = await _apiClient
        .get(serverUri.apply('changeset/$_userId/${_crdt.nodeId}'));
    final changeset = parseCrdtChangeset(jsonDecode(result.body));
    await _crdt.merge(changeset);
    _store.put('need_full_sync', false);
    'Full sync done in ${DateTime.now().millisecondsSinceEpoch - start}ms'.log;
  }
}
