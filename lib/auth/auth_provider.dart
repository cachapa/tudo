import 'package:tudo_client/util/store.dart';

class AuthProvider {
  final Store _store;

  String get userId => _store.get('user_id');

  AuthProvider(StoreProvider storeProvider)
      : _store = storeProvider.getStore('auth') {
    if (!_store.contains('user_id')) {
      // _store.put('user_id', uuid());
      _store.put('user_id', '41ec6412-05e5-4bab-8129-856ab9e57cf7');
    }
  }
}
