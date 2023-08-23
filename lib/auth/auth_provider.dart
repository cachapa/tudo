import 'dart:convert';

import '../config.dart';
import '../extensions.dart';
import '../sync/api_client.dart';
import '../util/store.dart';
import '../util/uuid.dart';

class AuthProvider {
  final Store _store;

  bool get isAuthComplete => _store.contains('token');

  String get token => _store.get('token');

  String get userId => _store.get('user_id');

  AuthProvider(StoreProvider storeProvider)
      : _store = storeProvider.getStore('auth');

  void create() {
    final token = uuid().replaceAll('-', '');
    final userId = uuid();
    _storeCredentials(token, userId);
  }

  Future<void> login(String token) async {
    final result = await ApiClient(token).post(serverUri.apply('auth/login'));
    final userId = jsonDecode(result.body)['user_id'] as String;
    _storeCredentials(token, userId);
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
