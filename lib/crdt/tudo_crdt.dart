import 'dart:async';

import 'package:sqlite_crdt/sqlite_crdt.dart';

import '../extensions.dart';

/// Convenience class to handle database creation and upgrades
class TudoCrdt {
  TudoCrdt._();

  static Future<SqliteCrdt> open(String path) => SqliteCrdt.open(
    path,
    collections: ['users', 'user_lists', 'lists', 'todos'],
    version: 6,
    onCreate: _onCreate,
    onUpgrade: _onUpgrade,
  );

  static Future<void> _onCreate(Database db, int version) async {
    'Creating database…'.log;
    await db.execute('''
      CREATE TABLE users (
        id TEXT NOT NULL,
        name TEXT,
        PRIMARY KEY (id)
      )
    ''');
    await db.execute('''
      CREATE TABLE user_lists (
        user_id TEXT NOT NULL,
        list_id TEXT NOT NULL,
        position INTEGER,
        created_at TEXT NOT NULL,
        PRIMARY KEY (user_id, list_id)
      )
    ''');
    await db.execute('''
      CREATE TABLE lists (
        id TEXT NOT NULL,
        name TEXT NOT NULL,
        color TEXT NOT NULL,
        creator_id TEXT NOT NULL,
        created_at TEXT NOT NULL,
        PRIMARY KEY (id)
      )
    ''');
    await db.execute('''
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

  static Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    'Upgrading database from $oldVersion to $newVersion…'.log;

    if (oldVersion <= 4) {
      // There's no upgrade path - nuke it from orbit and allow the system to re-sync
      for (final table in ['lists', 'todos', 'user_lists', 'users']) {
        await db.execute('DELETE FROM $table');
      }
    }

    if (oldVersion == 5) {
      // Create CRDT metadata tables
      await db.execute('''
          CREATE TABLE crdt_config (
            key VARCHAR(255) NOT NULL,
            value VARCHAR(255),
            PRIMARY KEY (key)
          )
        ''');
      await db.execute('''
          CREATE TABLE crdt (
            collection VARCHAR(255) NOT NULL,
            id VARCHAR(255) NOT NULL,
            hlc VARCHAR(255) NOT NULL,
            node_id VARCHAR(255) GENERATED ALWAYS AS (SUBSTR(hlc, INSTR(hlc, 'Z-') + 7)) STORED,
            modified INTEGER NOT NULL,
            PRIMARY KEY (collection, id)
          )
        ''');
      await (db.execute('CREATE INDEX "node_id_idx" ON "crdt" ("node_id")'));
      await (db.execute('CREATE INDEX "modified_idx" ON "crdt" ("modified")'));

      // Get node id
      final nodeQuery = [
        'lists',
        'todos',
        'user_lists',
        'users',
      ].map((t) => 'SELECT modified FROM $t').join(' UNION \n');
      final nodeIdResult = await db.rawQuery('$nodeQuery LIMIT 1');
      final modified = nodeIdResult.firstOrNull?['modified'] as String?;
      await db.execute('INSERT INTO crdt_config (key, value) VALUES (?1, ?2)', [
        'node_id',
        modified != null ? Hlc.parse(modified).nodeId : generateNodeId(),
      ]);

      // Import data
      for (final table in ['lists', 'todos', 'user_lists', 'users']) {
        final result = await db.rawQuery('SELECT * FROM $table');
        for (final row in result) {
          // Copy CRDT metadata over to dedicated table
          final id =
              switch (table) {
                    'auth' => row['token'],
                    'user_lists' => '${row['user_id']}::${row['list_id']}',
                    _ => row['id'],
                  }
                  as String;
          // Convert to HLC to ensure millisecond precision
          final hlc = Hlc.parse(row['hlc'] as String);
          final modified = Hlc.parse(row['modified'] as String).logicalTime;
          await db.execute(
            '''
              INSERT INTO crdt (collection, id, hlc, modified)
              VALUES (?1, ?2, ?3, ?4)
            ''',
            [table, id, hlc.toString(), modified],
          );
        }
        // Purge soft-deleted rows
        await db.execute('DELETE FROM $table WHERE is_deleted = 1');
        // Drop CRDT columns
        await db.execute('ALTER TABLE $table DROP COLUMN is_deleted');
        await db.execute('ALTER TABLE $table DROP COLUMN hlc');
        await db.execute('ALTER TABLE $table DROP COLUMN node_id');
        await db.execute('ALTER TABLE $table DROP COLUMN modified');
      }
    }
  }
}
