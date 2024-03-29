import 'dart:convert';

import 'package:rxdart/rxdart.dart';
import 'package:sqlite_crdt/sqlite_crdt.dart';

import '../extensions.dart';
import '../settings/settings_provider.dart';
import '../sync/api_client.dart';
import '../util/store_provider.dart';
import '../util/uuid.dart';

class AuthProvider {
  final SqlCrdt _crdt;
  final SettingsProvider _settingsProvider;
  final Store _store;

  bool get isAuthComplete => _store.contains('token');

  Stream<bool> get isAuthCompleteSteam => BehaviorSubject.seeded(isAuthComplete)
    ..addStream(_store.watch(key: 'token').map((e) => e.value != null));

  String get token => _store.get('token');

  String get userId => _store.get('user_id');

  AuthProvider(this._settingsProvider, StoreProvider storeProvider, this._crdt)
      : _store = storeProvider.getStore('auth');

  void create() {
    final token = uuid().replaceAll('-', '');
    final userId = uuid();
    _storeCredentials(token, userId);
  }

  Future<void> login(String token) async {
    final serverUri = _settingsProvider.serverUri;
    final result = await ApiClient(token).post(serverUri.apply('auth/login'));
    final body = jsonDecode(result.body);

    final userId = body['user_id'] as String;
    final changeset = parseCrdtChangeset(body['changeset']);

    await _crdt.merge(changeset);
    _storeCredentials(token, userId);
  }

  Future<void> deleteData() async {
    final serverUri = _settingsProvider.serverUri;
    await ApiClient(token).delete(serverUri.apply('user/$userId'));
  }

  void _storeCredentials(String token, String userId) {
    assert(!_store.contains('token'));
    assert(!_store.contains('user_id'));
    assert(token.isNotEmpty);
    assert(userId.isNotEmpty);

    _store.put('token', token);
    _store.put('user_id', userId);
  }
}
