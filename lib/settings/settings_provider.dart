import 'package:flutter/material.dart';
import 'package:tudo_client/util/store.dart';

class SettingsProvider with ChangeNotifier {
  final Store _store;

  ThemeMode get theme => ThemeMode.values[_store.get('theme', defaultValue: 0)];

  set theme(ThemeMode value) => _store.put('theme', value.index);

  SettingsProvider(StoreProvider storeProvider)
      : _store = storeProvider.getStore('settings') {
    _store.watch().listen((_) => notifyListeners());
  }
}
