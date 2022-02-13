import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:rxdart/rxdart.dart';
import 'package:sqflite_common/sqlite_api.dart';
// ignore: implementation_imports
import 'package:sqflite_common/src/open_options.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tudo_server/extensions.dart';
import 'package:tudo_server/uuid.dart';

import 'crdt_batch.dart';
import 'hlc.dart';

export 'crdt_batch.dart';

enum CrdtType { integer, real, text, blob, bool, datetime }

extension on CrdtType {
  String get sqlType {
    switch (this) {
      case CrdtType.bool:
      case CrdtType.integer:
        return 'INTEGER';
      case CrdtType.real:
        return 'REAL';
      case CrdtType.blob:
        return 'BLOB';
      case CrdtType.text:
      case CrdtType.datetime:
        return 'TEXT';
    }
  }
}

abstract class SqfliteCrdt {
  static const _shadow = 'crdt';
  static const deletedField = 'is_deleted';

  late final Database _db;

  int get version;

  Map<String, Schema> get tableSchemas;

  final _watches = <StreamController<List<Map<String, dynamic>>>, _Query>{};
  final allChanges = PublishSubject<void>();

  Future<Hlc> _canonicalTime(Transaction txn) async {
    // Select highest modified hlc in the database
    final result = await txn
        .rawQuery('SELECT MAX(modified) as canonical_time FROM $_shadow');
    // Generate a new node id if we don't have one yet
    return (result.first['canonical_time'] as String?)?.asHlc ??
        Hlc.zero(uuid());
  }

  Future<void> onCreate(Database db) async {}

  Future<void> onUpgrade(Database db, int oldVersion, int newVersion) async {}

  Future<void> init(String basePath, String name) async {
    var created = false;
    var upgraded = false;
    databaseFactoryFfi.setDatabasesPath('.');
    _db = await databaseFactoryFfi.openDatabase(
      '$basePath/$name.db',
      options: SqfliteOpenDatabaseOptions(
        version: version,
        onCreate: (db, version) => created = true,
        onUpgrade: (db, oldVersion, newVersion) async {
          await onUpgrade(db, oldVersion, newVersion);
          upgraded = true;
        },
      ),
    );

    // Create shadow table
    await _db.transaction((txn) async {
      final existingTables = (await txn
              .rawQuery("SELECT name FROM sqlite_master WHERE type = 'table'"))
          .map((e) => e['name'] as String)
          .toSet();

      if (!existingTables.contains(_shadow)) {
        final batch = txn.batch();
        batch.rawQuery('''
          CREATE TABLE $_shadow (
            collection TEXT NOT NULL,
            id TEXT NOT NULL,
            field TEXT NOT NULL,
            value BLOB,
            hlc TEXT NOT NULL,
            modified TEXT NOT NULL,
            PRIMARY KEY (collection, id, field)
          )
        ''');
        batch.rawQuery(
            'CREATE INDEX ${_shadow}_modified_idx ON $_shadow (modified)');
        await batch.commit();
      }

      final newTables = tableSchemas.keys.toSet().difference(existingTables);
      for (final table in newTables) {
        await _createTable(txn, table, tableSchemas[table]!);
      }
    });

    if (created) await onCreate(_db);
    if (upgraded) {
      await _db.transaction((txn) => _updateTables(txn));
    }
  }

  Future<void> _createTable(Transaction txn, String name, Schema schema) async {
    assert(name != _shadow, 'Table name "$_shadow" is reserved');

    final keyStatements = schema.keys.map((e) => '$e TEXT,').join('\n        ');
    final columnStatements = schema.columns.entries
        // The deleted field is handled differently
        .where((e) => e.key != deletedField)
        .map((e) => "'${e.key}' ${e.value.sqlType},")
        .join('\n        ');

    // Create tables if they don't exist
    await txn.execute('''
      CREATE TABLE $name (
        $keyStatements
        $columnStatements
        is_deleted INTEGER DEFAULT 0,
        PRIMARY KEY (${schema.keys.join(', ')})
      )
    ''');

    // Create indexes
    for (final index in schema.indexes) {
      await txn
          .execute("CREATE INDEX ${name}_${index}_idx ON $name ('$index')");
    }

    // Import preexisting data in the shadow table
    await _updateTables(txn, table: name);
  }

  Future<T?> getField<T>(String collection, String id, String field) async {
    final result = await queryAsync(
      'SELECT $field FROM $collection WHERE id = ?',
      [id],
    );
    return result.isEmpty
        ? null
        : _decode(result.first[field], tableSchemas[collection]?.columns[field])
            as T;
  }

  Future<List<Map<String, dynamic>>> queryAsync(String sql,
          [List<dynamic>? args]) =>
      _db.rawQuery(sql, args);

  Stream<Map<String, dynamic>> querySingle(String sql, [List<dynamic>? args]) =>
      query(sql, args).where((e) => e.isNotEmpty).map((e) => e.first);

  Stream<List<Map<String, dynamic>>> query(String sql, [List<dynamic>? args]) {
    // Disallow changing the database
    assert(sql.trimLeft().toUpperCase().startsWith('SELECT'));

    // TODO Identify tables being selected and watch only those
    late final StreamController<List<Map<String, dynamic>>> controller;
    controller = StreamController<List<Map<String, dynamic>>>(
      onListen: () {
        final query = _Query(sql, args);
        _watches[controller] = query;
        _emitQuery(controller, query);
      },
      onCancel: () {
        _watches.remove(controller);
        controller.close();
      },
    );

    return controller.stream;
  }

  CrdtBatch newBatch() => CrdtBatch();

  /// Helper function equivalent to immediately creating and applying a [CrdtBatch]
  Future<void> setField(
          String collection, List<String> ids, String field, dynamic value) =>
      commit(newBatch()..setField(collection, ids, field, value));

  /// Helper function equivalent to immediately creating and applying a [CrdtBatch]
  Future<void> setFields(
          String collection, List<String> ids, Map<String, dynamic> fields) =>
      commit(newBatch()..setFields(collection, ids, fields));

  /// Helper function equivalent to immediately creating and applying a [CrdtBatch]
  Future<void> setDeleted(String collection, List<String> ids,
          [bool isDeleted = true]) =>
      commit(newBatch()..setDeleted(collection, ids, isDeleted));

  Future<Hlc> merge(Iterable<Map<String, dynamic>> changeset) async {
    assert(changeset.isNotEmpty);

    late final Hlc canonicalTime;
    await _db.transaction((txn) async {
      // Update our canonical time based on all hlc timestamps in the remote
      // changeset and use it as modified timestamp.
      // The current local canonical time is retrieved from the database.
      canonicalTime = changeset.fold<Hlc>(
          await _canonicalTime(txn),
          (canonicalTime, map) =>
              Hlc.recv(canonicalTime, Hlc.parse(map['hlc'])));

      final batch = txn.batch();
      for (final map in changeset) {
        final collection = map['collection'];
        final field = map['field'];
        final id = map['id'];
        final value = _encode(map['value']);
        final hlc = map['hlc'];

        // Insert or replace crdt records according to HLC comparison
        batch.execute('''
          INSERT INTO $_shadow
          (collection, id, field, value, hlc, modified)
          VALUES (?1, ?2, ?3, ?4, ?5, ?6)
          ON CONFLICT (collection, id, field) DO UPDATE
          SET value = excluded.value, hlc = excluded.hlc, modified = excluded.modified
          WHERE excluded.hlc > $_shadow.hlc
        ''', [collection, id, field, value, hlc, canonicalTime.toString()]);
      }
      await batch.commit();

      // Materialize updated records into value tables
      await _updateTables(txn, since: canonicalTime);
    });

    _onDbChanged();
    return canonicalTime;
  }

  Future<void> _updateTables(Transaction txn,
      {Hlc? since, String? table}) async {
    final tableCondition = table != null ? "AND collection = '$table'" : '';
    final records = await txn.rawQuery(
        'SELECT * FROM $_shadow WHERE modified >= ? $tableCondition',
        [since?.toString() ?? '']);
    if (records.isEmpty) return;

    final batch = txn.batch();
    for (final map in records) {
      final collection = map['collection'] as String;

      if (!tableSchemas.containsKey(collection)) {
        continue;
      }

      final field = map['field'] as String;
      final columns = tableSchemas[collection]!.columns;
      if (!columns.containsKey(field)) {
        'SqfliteCrdt.merge: Skipping unknown field: $collection.$field'.log;
        continue;
      }

      final ids = (map['id'] as String).split(':');
      final value = map['value'];

      _setValueField(batch, BatchEntry(collection, ids, field, value));
    }
    await batch.commit();
  }

  Future<CrdtChangeset> getChangeset(
      {Hlc? modifiedSince, bool onlyModifiedHere = false}) async {
    late final CrdtChangeset changeset;

    await _db.transaction((txn) async {
      final canonicalTime = await _canonicalTime(txn);

      final conditions = [
        if (modifiedSince != null) "modified > '$modifiedSince'",
        if (onlyModifiedHere) "hlc LIKE '%${canonicalTime.nodeId}'",
      ];
      final conditionClause =
          conditions.isEmpty ? '' : 'WHERE ${conditions.join(' AND ')}';

      var records =
          await txn.rawQuery('SELECT * FROM $_shadow $conditionClause');

      // Convert is_deleted to bool
      records = records.map((e) {
        if (e['field'] == deletedField) {
          e = Map.of(e);
          e['value'] = e['value'] == 1;
        }
        return e;
      }).toList();

      changeset = CrdtChangeset(canonicalTime, records);
    });

    return changeset;
  }

  Future<void> commit(CrdtBatch crdtBatch) async {
    if (crdtBatch.isEmpty) {
      return;
    }

    await _db.transaction((txn) async {
      final hlc = Hlc.send(await _canonicalTime(txn));

      final batch = txn.batch();
      for (final entry in crdtBatch.entries) {
        _setCrdtField(batch, entry, hlc, hlc);
        _setValueField(batch, entry);
      }
      await batch.commit();
    });
    _onDbChanged();
  }

  Future<void> purge() async {
    await _db.close();
    await File(_db.path).delete();
  }

  Future<void> _onDbChanged() async {
    allChanges.add(null);
    for (final entry in _watches.entries) {
      _emitQuery(entry.key, entry.value);
    }
  }

  Future<void> _emitQuery(
      StreamController<List<Map<String, dynamic>>> controller,
      _Query query) async {
    final result = await _db.rawQuery(query.sql, query.args);
    if (!controller.isClosed) {
      controller.add(result);
    }
  }

  void _setCrdtField(Batch batch, BatchEntry entry, Hlc hlc, Hlc modified) =>
      batch.execute('''
        INSERT OR REPLACE INTO $_shadow
        VALUES (?, ?, ?, ?, ?, ?)
      ''', [
        entry.collection,
        entry.ids.join(':'),
        entry.field,
        _encode(entry.value),
        hlc.toString(),
        modified.toString(),
      ]);

  void _setValueField(Batch batch, BatchEntry entry) {
    if (!tableSchemas.containsKey(entry.collection)) return;

    final keys = tableSchemas[entry.collection]!.keys.toList();
    batch.execute('''
        INSERT INTO ${entry.collection} (${entry.field}, ${keys.join(', ')})
        VALUES (${List.generate(keys.length + 1, (i) => '?${i + 1}').join(', ')})
        ON CONFLICT(${keys.join(', ')}) DO UPDATE
        SET '${entry.field}' = ?1
      ''', [_encode(entry.value), ...entry.ids]);
  }
}

class _Query {
  final String sql;
  final List<dynamic>? args;

  _Query(this.sql, this.args);
}

dynamic _encode(dynamic value) {
  if (value == null) return null;
  if (value is Map) return jsonEncode(value);

  switch (value.runtimeType) {
    case String:
    case int:
    case double:
      return value;
    case bool:
      return value ? 1 : 0;
    case DateTime:
      return value.toUtc().toIso8601String();
    case Hlc:
      return value.toString();
    default:
      throw 'Unsupported type: ${value.runtimeType}';
  }
}

dynamic _decode(dynamic value, CrdtType? crdtType) {
  if (value == null || crdtType == null) return null;

  switch (crdtType) {
    case CrdtType.bool:
      return (value as int) == 1;
    case CrdtType.datetime:
      return (value as String).asDateTime;
    default:
      return value;
  }
}

class Schema {
  final Set<String> keys;
  final Map<String, CrdtType> columns;
  final Set<String> indexes;

  Schema(
      {Set<String>? keys, Map<String, CrdtType>? columns, Set<String>? indexes})
      : keys = keys ?? {'id'},
        columns = columns ?? {},
        indexes = indexes ?? {} {
    // Ensure deleted field is set
    this.columns[SqfliteCrdt.deletedField] = CrdtType.bool;
    this.indexes.add(SqfliteCrdt.deletedField);
  }
}

// TODO Replace with tuples as soon as Dart supports them
class CrdtChangeset {
  final Hlc canonicalTime;
  final List<Map<String, dynamic>> records;

  CrdtChangeset(this.canonicalTime, this.records);

  CrdtChangeset copyWith(List<Map<String, dynamic>> records) =>
      CrdtChangeset(canonicalTime, records);

  List<Map<String, dynamic>> toJson() => records;
}
