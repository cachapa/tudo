import 'package:sqflite_common/sqlite_api.dart';

import 'sqflite_crdt.dart';

class TudoCrdt extends SqfliteCrdt {
  @override
  final version = 2;
  @override
  final tableSchemas = <String, Schema>{
    'auth': Schema(
      keys: {'token'},
      columns: {
        'user_id': CrdtType.text,
        'created_at': CrdtType.datetime,
      },
    ),
    'users': Schema(
      columns: {
        'name': CrdtType.text,
      },
    ),
    'user_lists': Schema(
      keys: {'user_id', 'list_id'},
      columns: {
        'position': CrdtType.integer,
        'created_at': CrdtType.datetime,
      },
    ),
    'lists': Schema(
      columns: {
        'name': CrdtType.text,
        'color': CrdtType.text,
        'creator_id': CrdtType.text,
        'created_at': CrdtType.datetime,
      },
    ),
    'todos': Schema(
      columns: {
        'list_id': CrdtType.text,
        'name': CrdtType.text,
        'done': CrdtType.bool,
        'done_at': CrdtType.datetime,
        'position': CrdtType.integer,
        'creator_id': CrdtType.text,
        'created_at': CrdtType.datetime,
      },
      indexes: {
        'list_id',
      },
    ),
  };

  @override
  Future<void> onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion == 1) {
      await db.execute("ALTER TABLE todos ADD done_at TEXT");
    }
  }

  @override
  Future<T?> getField<T>(String collection, String id, String field) {
    // Make sure that 'created_at' is always retrieved as DateTime
    assert(field != 'created_at' || T is DateTime);
    return super.getField<T>(collection, id, field);
  }
}
