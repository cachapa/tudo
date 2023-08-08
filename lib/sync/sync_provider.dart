import 'dart:async';
import 'dart:io';

import 'package:crdt_sync/crdt_sync.dart';
import 'package:http/http.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sqlite_crdt/sqlite_crdt.dart';

import '../auth/auth_provider.dart';
import '../config.dart';
import '../extensions.dart';
import '../util/build_info.dart';

class SyncProvider {
  late final CrdtSyncClient _client;
  late final connectionState = BehaviorSubject.seeded(false)
    ..addStream(_client.watchState.map((e) => e == SocketState.connected));

  SyncProvider(AuthProvider authProvider, SqlCrdt crdt) {
    _client = CrdtSyncClient(
      crdt,
      serverUri.replace(
          scheme: serverUri.scheme.replaceFirst('http', 'ws'),
          path: 'ws/${authProvider.userId}',
          queryParameters: {
            'api_secret': apiSecret,
            'token': authProvider.token,
          }),
      onConnect: (_, __) => 'Connected'.log,
      onDisconnect: (_, __, ___) => 'Disconnected'.log,
      onChangesetReceived: (recordCounts) =>
          '⬇️ ${recordCounts.entries.map((e) => '${e.key}: ${e.value}').join(', ')}'
              .log,
      onChangesetSent: (recordCounts) =>
          '⬆️ ${recordCounts.entries.map((e) => '${e.key}: ${e.value}').join(', ')}'
              .log,
    )..connect();
  }

  void connect() => _client.connect();

  void disconnect() => _client.disconnect();

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
}
