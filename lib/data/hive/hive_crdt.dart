import 'dart:async';

import 'package:crdt/crdt.dart';
import 'package:hive/hive.dart';

class HiveCrdt<K, V> extends Crdt<K, V> {
  @override
  final String nodeId;
  final Box<ModRecord> _box;

  HiveCrdt._internal(this._box, this.nodeId);

  static Future<HiveCrdt<K, V>> open<K, V>(String name, String nodeId,
      {String path}) async {
    final box = await Hive.openBox<ModRecord>(name, path: path);
    return HiveCrdt<K, V>._internal(box, nodeId);
  }

  @override
  bool containsKey(K key) => _box.containsKey(_encode(key));

  @override
  Record<V> getRecord(K key) => _box.get(_encode(key))?.record;

  @override
  void putRecord(K key, Record<V> record) =>
      _box.put(_encode(key), ModRecord(record, canonicalTime));

  @override
  void putRecords(Map<K, Record<V>> recordMap) =>
      _box.putAll(recordMap.map((key, record) =>
          MapEntry(_encode(key), ModRecord(record, canonicalTime))));

  @override
  Map<K, Record<V>> recordMap({Hlc modifiedSince}) => (_box.toMap()
        ..removeWhere((key, value) =>
            value.modified.logicalTime < (modifiedSince?.logicalTime ?? 0)))
      .map<K, Record<V>>((key, value) => MapEntry<K, Record<V>>(
          _decode(key),
          Record<V>(
              value.record.hlc, value.record.value, value.record.modified)));

  Stream<MapEntry<K, V>> watch({K key}) => _box
      .watch(key: key)
      .map((event) => MapEntry<K, V>(event.key, event.value.record.value));

  Future<void> close() => _box.close();

  /// Permanently deletes the store from disk. Useful for testing.
  Future<void> deleteStore() => _box.deleteFromDisk();

  dynamic _encode(K key) =>
      key is DateTime ? key?.toUtc()?.toIso8601String() : key;

  K _decode(dynamic key) => K == DateTime ? DateTime.parse(key) : key;
}

class ModRecord<T> {
  final Record<T> record;
  final Hlc modified;

  ModRecord(this.record, this.modified);

  bool operator <=(other) =>
      other == null ? false : other is Hlc && modified <= other;

  bool operator >=(other) =>
      other == null ? false : other is Hlc && modified >= other;
}
