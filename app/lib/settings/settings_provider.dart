import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:tudo_app/util/store.dart';

class SettingsProvider {
  final Store _store;

  late final theme =
      (BehaviorSubject.seeded(_store.get('theme', defaultValue: 0))
            ..addStream(_store.watch(key: 'theme').map((e) => e.value)))
          .map((e) => ThemeMode.values[e]);

  void setTheme(ThemeMode value) => _store.put('theme', value.index);

  SettingsProvider(StoreProvider storeProvider)
      : _store = storeProvider.getStore('settings');
}
