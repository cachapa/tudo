import 'package:hive/hive.dart';

class StoreProvider {
  final Box _box;

  StoreProvider._(this._box);

  // TODO Remove when tudo v2 has been out for a while
  List<String>? get legacyListIds => _box.get('list_id_keys');

  static Future<StoreProvider> open() async =>
      StoreProvider._(await Hive.openBox('store'));

  Store getStore(String namespace) => Store(_box, namespace);

  // TODO Remove when tudo v2 has been out for a while
  void purgeLegacyListIds() => _box.delete('list_id_keys');
}

class Store {
  final Box _box;
  final String namespace;

  Store(this._box, this.namespace);

  bool contains(String key) => _box.containsKey(_key(key));

  T get<T>(String key, {T? defaultValue}) =>
      _box.get(_key(key), defaultValue: defaultValue);

  void put<T>(String key, T value) => _box.put(_key(key), value);

  Stream<BoxEvent> watch({String? key}) => _box
      .watch(key: key != null ? _key(key) : null)
      .where((event) => (event.key as String).startsWith('$namespace::'));

  String _key(key) => '$namespace::$key';
}
