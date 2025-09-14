import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

import '../config.dart';
import '../util/build_info.dart';
import '../util/store_provider.dart';

class SettingsProvider {
  final Store _store;

  late final String? _prevVersion;

  bool get isFirstRun => _prevVersion == null;

  bool get isUpdate => !isFirstRun && _prevVersion != BuildInfo.version;

  Uri get serverUri =>
      Uri.tryParse(_store.get('server_uri', defaultValue: '$defaultUri')) ??
      defaultUri;

  void setServerUri(String uri) => _store.put('server_uri', uri);

  late final theme =
      (BehaviorSubject.seeded(_store.get('theme', defaultValue: 0))
            ..addStream(_store.watch(key: 'theme').map((e) => e.value)))
          .map((e) => ThemeMode.values[e]);

  void setTheme(ThemeMode value) => _store.put('theme', value.index);

  SettingsProvider(StoreProvider storeProvider)
    : _store = storeProvider.getStore('settings') {
    _prevVersion = _store.get('version');
    _store.put('version', BuildInfo.version);
  }
}
