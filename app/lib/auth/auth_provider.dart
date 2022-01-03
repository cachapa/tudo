import 'package:tudo_app/util/store.dart';
import 'package:tudo_app/util/uuid.dart';

class AuthProvider {
  final Store _store;

  String get userId => _store.get('user_id');

  AuthProvider(StoreProvider storeProvider)
      : _store = storeProvider.getStore('auth') {
    if (!_store.contains('user_id')) {
      _store.put('user_id', uuid());
    }
  }
}
