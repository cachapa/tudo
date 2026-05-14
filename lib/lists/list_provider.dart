import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sqlite_crdt/sqlite_crdt.dart';

import '../auth/auth_provider.dart';
import '../common/lists.dart';
import '../contacts/contact_provider.dart';
import '../extensions.dart';
import '../registry.dart';
import '../util/store_provider.dart';
import '../util/uuid.dart';

const listIdsKey = 'list_id_keys';

class ListProvider {
  final String userId;
  final SqliteCrdt _crdt;

  final _undoItems = <String, Queue<Iterable<ToDo>>>{};

  late final lists = BehaviorSubject<List<ToDoList>>()
    ..addStream(_queryLists().map((l) => l.map(ToDoList.fromMap).toList()));

  ListProvider(
    AuthProvider authProvider,
    StoreProvider storeProvider,
    this._crdt,
  ) : userId = authProvider.userId;

  Future<void> createList(String name, Color color) async {
    final listId = uuid();

    await _crdt.transaction((txn) async {
      final createdAt = DateTime.now().toUtcString;
      // Create list
      await txn.execute(
        '''
          INSERT INTO lists (id, name, color, creator_id, created_at)
          VALUES (?1, ?2, ?3, ?4, ?5)
        ''',
        [listId, name.trim(), color.hexValue, userId, createdAt],
      );
      // Get max position
      final maxPosition =
          (await txn.query(
                'SELECT max(position) as max_position FROM user_lists WHERE user_id = ?1',
                [userId],
              )).first['max_position']
              as int? ??
          -1;
      // Associate list to user
      await txn.execute(
        '''
          INSERT INTO user_lists (user_id, list_id, created_at, position)
          VALUES (?1, ?2, ?3, ?4)
        ''',
        [userId, listId, createdAt, maxPosition + 1],
      );
    });
  }

  bool hasList(String listId) => lists.value.map((e) => e.id).contains(listId);

  Stream<List<Map<String, dynamic>>> _queryLists() => _crdt.watch(
    '''
        SELECT id, name, color, creator_id, lists.created_at, position, item_count, done_count, member_count FROM user_lists
        JOIN lists
          ON user_lists.user_id = ?1
          AND user_lists.list_id = id
        LEFT JOIN (
          SELECT list_id, count(*) AS item_count, sum(done) AS done_count
          FROM todos GROUP BY list_id
        ) items ON items.list_id = id
        JOIN (
          SELECT list_id, count(*) AS member_count
          FROM user_lists GROUP BY list_id
        ) members ON members.list_id = id
        ORDER BY position
      ''',
    [userId],
  );

  Stream<ToDoListWithItems> getList(String listId) => lists
      .map((e) => e.firstWhere((e) => e.id == listId))
      .asyncMap(
        (list) async =>
            ToDoListWithItems.fromList(list, await _getToDos(listId)),
      );

  /// Removes the list from the user's references
  /// Does not actually delete the list, since it could be used by others
  Future<void> removeList(String listId) => removeUser(userId, listId);

  Future<void> removeUser(String userId, String listId) async {
    await _crdt.execute(
      'DELETE FROM user_lists WHERE user_id = ?1 AND list_id = ?2',
      [userId, listId],
    );
  }

  Future<void> deleteItems(Iterable<ToDo> todos) async {
    // Ensure all items belong to the same list
    assert(todos.map((e) => e.listId).toSet().length == 1);
    final placeholders = List.generate(
      todos.length,
      (i) => '?${i + 1}',
    ).join(', ');
    await _crdt.execute(
      'DELETE FROM todos WHERE id IN ($placeholders)',
      todos.map((e) => e.id).toList(),
    );
    (_undoItems[todos.first.listId] ??= Queue()).addLast(todos);
  }

  bool hasUndoItems(String listId) => _undoItems[listId]?.isNotEmpty ?? false;

  Future<void> undoDelete(String listId) async {
    if (!hasUndoItems(listId)) return;
    final items = _undoItems[listId]!.removeLast();
    await _createItems(items);
  }

  Future<void> setDone(String itemId, bool isDone) => _crdt.execute(
    '''
      UPDATE todos SET
        done = ?1,
        done_at = ?2,
        done_by = ?3
      WHERE id = ?4
    ''',
    [
      isDone.toInt,
      isDone ? DateTime.now().toUtcString : null,
      isDone ? userId : null,
      itemId,
    ],
  );

  Future<void> setItemName(String itemId, String name) => _crdt.execute(
    '''
      UPDATE todos SET name = ?1
      WHERE id = ?2
    ''',
    [name.trim(), itemId],
  );

  void setName(String listId, String name) => _crdt.execute(
    '''
      UPDATE lists SET name = ?1
      WHERE id = ?2
    ''',
    [name.trim(), listId],
  );

  void setColor(String listId, Color color) => _crdt.execute(
    '''
      UPDATE lists SET color = ?1
      WHERE id = ?2
    ''',
    [color.hexValue, listId],
  );

  Future<String> createItem(String listId, String name) async {
    final id = uuid();
    final maxPosition =
        (await _crdt.query(
              'SELECT max(position) AS max_position FROM todos WHERE list_id = ?1',
              [listId],
            )).first['max_position']
            as int? ??
        -1;
    await _createItems([
      ToDo(
        id,
        listId,
        name.trim(),
        false,
        // null,
        // null,
        // null,
        maxPosition + 1,
        userId,
        null,
        DateTime.now(),
      ),
    ]);
    return id;
  }

  Future<void> _createItems(Iterable<ToDo> items) async {
    await _crdt.transaction((txn) async {
      for (final item in items) {
        await txn.execute(
          '''
            INSERT INTO todos (id, list_id, name, done, done_at, done_by, position, creator_id, created_at)
            VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9)
          ''',
          [
            item.id,
            item.listId,
            item.name,
            item.done ? 1 : 0,
            // item.doneAt?.toUtcString,
            // item.doneBy,
            item.position,
            item.creatorId,
            item.createdAt?.toUtcString,
          ],
        );
      }
    });
  }

  Future<void> setListOrder(List<ToDoList> lists) async {
    await _crdt.transaction((txn) async {
      for (int i = 0; i < lists.length; i++) {
        final list = lists[i];
        if (list.position != i) {
          await txn.execute(
            '''
              UPDATE user_lists SET position = ?1
              WHERE user_id = ?2 AND list_id = ?3
            ''',
            [i, userId, list.id],
          );
        }
      }
    });
  }

  Future<void> setItemOrder(List<ToDo> items) async {
    await _crdt.transaction((txn) async {
      for (int i = 0; i < items.length; i++) {
        final item = items[i];
        if (item.position != i) {
          await txn.execute(
            '''
              UPDATE todos SET position = ?1
              WHERE id = ?2
            ''',
            [i, item.id],
          );
        }
      }
    });
  }

  Stream<List<Member>> getMembers(String listId) => _crdt
      .watch(
        '''
        SELECT user_id AS id, name, user_lists.created_at AS joined_at FROM user_lists
          LEFT JOIN users ON user_id = id
        WHERE list_id = ?1
      ''',
        [listId],
      )
      .map((l) => l.map((m) => Member.fromMap(userId, m)).toList());

  Future<List<ToDo>> _getToDos(String listId) => _crdt
      .query(
        '''
    SELECT
      todos.id,
      todos.list_id,
      todos.name,
      todos.done,
      todos.done_at,
      todos.done_by,
      done_users.name AS done_name,
      todos.position,
      todos.creator_id,
      created_users.name AS creator_name,
      todos.created_at
    FROM
      todos
    LEFT JOIN
      users AS done_users ON done_by = done_users.id
    LEFT JOIN
      users AS created_users ON creator_id = created_users.id
    WHERE
      list_id = ?1
    ORDER BY
      position
  ''',
        [listId],
      )
      .then((l) => l.map(ToDo.fromMap).toList());
}

class ToDoListWithItems extends ToDoList {
  final List<ToDo> items;

  ToDoListWithItems.fromList(ToDoList list, this.items)
    : super(
        list.id,
        list.name,
        list.color,
        list.creatorId,
        list.createdAt,
        list.position,
        list.itemCount,
        list.doneCount,
        list.memberCount,
      );

  ToDoListWithItems.fromMap(super.map, this.items) : super.fromMap();
}

class ToDoList extends IdObject {
  final String name;
  final Color color;
  final String? creatorId;
  final DateTime? createdAt;
  final int position;
  final int itemCount;
  final int doneCount;
  final int memberCount;

  bool get isShared => memberCount > 1;

  bool get isEmpty => itemCount == 0;

  /// Convenience method to get list members
  Stream<List<Member>> get members => Registry.listProvider.getMembers(id);

  const ToDoList(
    super.id,
    this.name,
    this.color,
    this.creatorId,
    this.createdAt,
    this.position,
    this.itemCount,
    this.doneCount,
    this.memberCount,
  );

  ToDoList.fromMap(Map<String, dynamic> map)
    : this(
        map['id'],
        map['name'],
        (map['color'] as String).asColor,
        map['creator_id'],
        tryParseDateTime(map['created_at']),
        map['position'],
        map['item_count'] ?? 0,
        map['done_count'] ?? 0,
        map['member_count'] ?? 0,
      );

  @override
  String toString() => '$name [$doneCount/$itemCount]';
}

class ToDo extends IdObject {
  final String listId;
  final String name;
  final bool done;
  // final DateTime? doneAt;
  // final String? doneBy;
  // final String? doneName;
  final int position;
  final String? creatorId;
  final String? creatorName;
  final DateTime? createdAt;

  ToDo(
    super.id,
    this.listId,
    this.name,
    this.done,
    // this.doneAt,
    // this.doneBy,
    // this.doneName,
    this.position,
    this.creatorId,
    this.creatorName,
    this.createdAt,
  );
  // : assert(
  //   (doneAt == null) == (doneBy == null),
  //   '$id doneAt $doneAt doneBy $doneBy',
  // ),
  // assert((doneAt != null) == done),
  // assert((doneBy != null) == done);

  factory ToDo.fromMap(Map<String, dynamic> map) => ToDo(
    map['id'],
    map['list_id'],
    map['name'],
    map['done'] == 1,
    // tryParseDateTime(map['done_at']),
    // map['done_by'],
    // map['done_name'],
    map['position'] is int ? map['position'] : 0,
    map['creator_id'],
    map['creator_name'],
    tryParseDateTime(map['created_at']),
  );

  @override
  bool operator ==(Object other) =>
      other is ToDo &&
      other.id == id &&
      other.name == name &&
      other.done == done;

  @override
  int get hashCode => Object.hash(id, name, done);

  @override
  String toString() => '$name ${done ? '🗹' : '☐'}';
}

class Member extends User {
  final DateTime? joinedAt;

  Member.fromMap(super.userId, super.map)
    : joinedAt = tryParseDateTime(map['joined_at']),
      super.fromMap();
}

extension MembersX on List<Member> {
  String toNames(BuildContext context) =>
      map((e) => e.nameOr(context)).join(' • ');
}

DateTime? tryParseDateTime(Object value) {
  print('--- $value ${value.runtimeType} ---');
  print('--- ${value is String} ---');
  print('--- ${DateTime.tryParse(value as String)} ---');
  return value is String ? DateTime.tryParse(value)?.toLocal() : null;
}
