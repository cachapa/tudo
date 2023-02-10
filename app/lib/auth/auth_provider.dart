import '../util/store.dart';
import '../util/token_generator.dart';
import '../util/uuid.dart';

class AuthProvider {
  final Store _store;

  String get token => _store.get('token');

  String get userId => _store.get('user_id');

  AuthProvider(StoreProvider storeProvider)
      : _store = storeProvider.getStore('auth') {
    if (!_store.contains('token')) {
      _store.put('token', generateToken());
    }
    if (!_store.contains('user_id')) {
      _store.put('user_id', uuid());
    }
  }
}
