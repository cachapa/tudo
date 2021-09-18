import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:tudo_client/util/uuid.dart';

class SettingsProvider with ChangeNotifier {
  final Box _box;

  String get nodeId {
    const key = 'node_id';
    if (!_box.containsKey(key)) {
      _box.put(key, uuid());
    }
    return _box.get(key);
  }

  ThemeMode get theme => ThemeMode.values[
    _box.get('theme', defaultValue: 0)
  ];

  set theme(ThemeMode value) => _box.put('theme', value.index);

  SettingsProvider._(this._box) {
    _box.watch().listen((_) => notifyListeners());
  }

  static Future<SettingsProvider> open() async =>
      SettingsProvider._(await Hive.openBox('settings'));
}
