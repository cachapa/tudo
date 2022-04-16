import 'package:sqflite_common/sqlite_api.dart';

import 'sqflite_crdt.dart';

class TudoCrdt extends SqfliteCrdt {
  @override
  final version = 4;
  @override
  final tableSchemas = <String, Schema>{
    'auth': Schema(
      keys: {'user_id'},
      columns: {
        'token': CrdtType.text,
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
        'done_by': CrdtType.text,
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
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE todos ADD done_at TEXT');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE todos ADD done_by TEXT');
    }
    if (oldVersion < 4) {
      // Change auth primary key from token to user_id
      // Get all user_id|token tuples
      final users = await db.rawQuery('SELECT user_id, token FROM auth');

      final batch = db.batch();
      // Drop the current auth table - it will be recreated automatically from crdt
      batch.execute('DROP TABLE auth');

      // Swap the user_id and token in the CRDT records
      for (final user in users) {
        final userId = user['user_id']!;
        final token = user['token']!;

        // Replace user_id field with token
        batch.execute('''
          UPDATE crdt SET field = 'token', value = ?1
          WHERE collection = 'auth' AND field = 'user_id' AND id = ?1
        ''', [token]);
        // Replace all tokens with user_ids
        batch.execute('''
          UPDATE crdt SET id = ?1
          WHERE collection = 'auth' AND id = ?2
        ''', [userId, token]);
      }

      // Fingers crossed 🤞
      await batch.commit();
    }
  }

  @override
  Future<T?> getField<T>(String collection, String id, String field) {
    // Make sure that 'created_at' is always retrieved as DateTime
    assert(field != 'created_at' || T is DateTime);
    return super.getField<T>(collection, id, field);
  }
}
