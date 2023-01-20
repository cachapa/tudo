import 'dart:async';

import 'package:sqlite_crdt/sqlite_crdt.dart';

final _version = 5;

/// Convenience class to handle database creation and upgrades
class TudoCrdt {
  TudoCrdt._();

  static Future<SqliteCrdt> open(String path) => SqliteCrdt.open(
        path,
        version: _version,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );

  static FutureOr<void> _onCreate(BaseCrdt crdt, int version) async {
    await crdt.execute('''
      CREATE TABLE auth (
        token TEXT NOT NULL,
        user_id TEXT NOT NULL,
        created_at TEXT NOT NULL,
        PRIMARY KEY (token)
      )
    ''');
    await crdt.execute('''
      CREATE TABLE users (
        id TEXT NOT NULL,
        name TEXT,
        PRIMARY KEY (id)
      )
    ''');
    await crdt.execute('''
      CREATE TABLE user_lists (
        user_id TEXT NOT NULL,
        list_id TEXT NOT NULL,
        position INTEGER,
        created_at TEXT NOT NULL,
        PRIMARY KEY (user_id, list_id)
      )
    ''');
    await crdt.execute('''
      CREATE TABLE lists (
        id TEXT NOT NULL,
        name TEXT NOT NULL,
        color TEXT NOT NULL,
        creator_id TEXT NOT NULL,
        created_at TEXT NOT NULL,
        PRIMARY KEY (id)
      )
    ''');
    await crdt.execute('''
      CREATE TABLE todos (
        id TEXT NOT NULL,
        list_id TEXT NOT NULL,
        name TEXT NOT NULL,
        done INTEGER DEFAULT 0,
        done_at TEXT,
        done_by TEXT,
        position INTEGER,
        creator_id TEXT NOT NULL,
        created_at TEXT NOT NULL,
        PRIMARY KEY (id)
      )
    ''');
  }

  static FutureOr<void> _onUpgrade(
      BaseCrdt crdt, int oldVersion, int newVersion) async {
    'Upgrading database from $oldVersion to $newVersion…';
    if (oldVersion < 5) {
      await _upgradeFromCrdt(crdt, 'auth', ['user_id']);
      await _upgradeFromCrdt(crdt, 'login', ['login_token']);
      await _upgradeFromCrdt(crdt, 'tokens', ['token']);

      // Recreate auth table with token as primary key
      // Sqlite doesn't allow changing table structures on the fly, so we have
      // to recreate it and copy the data over
      await crdt.execute('''
        CREATE TABLE auth2 (
          token TEXT NOT NULL,
          user_id TEXT NOT NULL,
          created_at TEXT NOT NULL,
          PRIMARY KEY (token)
        )
      ''');
      await crdt.execute('''
        INSERT INTO auth2 (token, user_id, created_at, is_deleted, hlc, modified)
        SELECT token, user_id, created_at, is_deleted, hlc, modified FROM auth
          WHERE token IS NOT null
      ''');
      await crdt.execute('DROP TABLE auth');
      await crdt.execute('ALTER TABLE auth2 RENAME TO auth');

      await _upgradeFromCrdt(crdt, 'users', ['id']);
      await _upgradeFromCrdt(crdt, 'user_lists', ['user_id', 'list_id']);
      await _upgradeFromCrdt(crdt, 'lists', ['id']);
      await _upgradeFromCrdt(crdt, 'todos', ['id']);

      await crdt.execute('DROP TABLE crdt');
    }
  }

  static Future<void> _upgradeFromCrdt(
      BaseCrdt crdt, String table, List<String> ids) async {
    await crdt.execute('ALTER TABLE $table ADD COLUMN hlc TEXT');
    await crdt.execute('ALTER TABLE $table ADD COLUMN modified TEXT');
    await crdt.execute('''        
        UPDATE $table SET
          hlc = c.hlc,
          modified = c.modified
        FROM
          (SELECT id, max(hlc) AS hlc, max(modified) AS modified FROM crdt
            WHERE collection = '$table'
            GROUP BY id) AS c
        WHERE ${ids.map((e) => '$table.$e').join(" || ':' || ")} = c.id;
      ''');
  }
}
