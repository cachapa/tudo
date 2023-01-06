import 'package:flutter/material.dart';
import 'package:tudo_app/config.dart';
import 'package:tudo_app/contacts/contact_provider.dart';
import 'package:tudo_app/crdt/hlc.dart';
import 'package:tudo_app/crdt/sqflite_crdt.dart';
import 'package:tudo_app/crdt/tudo_crdt.dart';
import 'package:tudo_app/extensions.dart';
import 'package:tudo_app/util/store.dart';
import 'package:tudo_app/util/uuid.dart';

const listIdsKey = 'list_id_keys';

class ListProvider {
  final String userId;
  final TudoCrdt _crdt;

  Stream get allChanges => _crdt.allChanges;

  Stream<List<ToDoList>> get lists =>
      _queryLists().asyncMap((l) => Future.wait(l.map(
          (map) async => ToDoList.fromMap(map, await _getMembers(map['id'])))));

  ListProvider(this.userId, this._crdt, StoreProvider storeProvider);

  Future<void> createList(String name, Color color) async {
    final listId = uuid();

    final batch = _crdt.newBatch();
    batch.setFields('lists', [
      listId
    ], {
      'name': name,
      'color': color.hexValue,
      'creator_id': userId,
      'created_at': DateTime.now(),
    });
    await _setListReference(batch, listId);
    await _crdt.commit(batch);
  }

  Future<void> import(String listId) async {
    final exists = await _crdt.queryAsync('''
      SELECT EXISTS (
        SELECT * FROM user_lists WHERE user_id = ? AND list_id = ? AND is_deleted = 0
      ) AS e
    ''', [userId, listId]);
    if (exists.first['e'] == 1) {
      'Import: already have $listId'.log;
      return;
    }

    'Importing $listId'.log;
    final batch = _crdt.newBatch();
    await _setListReference(batch, listId);
    await _crdt.commit(batch);
  }

  Future<void> _setListReference(CrdtBatch batch, String listId) async {
    final maxPosition = (await _crdt.queryAsync('''
        SELECT max(position) as max_position FROM user_lists
        WHERE is_deleted = 0
      ''')).first['max_position'] ?? -1;
    batch
      ..setField('user_lists', [userId, listId], 'created_at', DateTime.now())
      ..setDeleted('user_lists', [userId, listId], false)
      ..setField('user_lists', [userId, listId], 'position', maxPosition + 1);
  }

  Stream<List<Map<String, dynamic>>> _queryLists([String? listId]) =>
      _crdt.query('''
        SELECT id, name, color, creator_id, lists.created_at, position, item_count, done_count FROM user_lists
        LEFT JOIN lists ON user_lists.user_id = ? AND user_lists.list_id = id
        LEFT JOIN (
          SELECT list_id as item_count_list_id, count(*) as item_count, sum(done) as done_count
          FROM todos WHERE is_deleted = 0 GROUP BY list_id
        ) ON item_count_list_id = id
        WHERE id IS NOT NULL AND user_lists.is_deleted = 0 ${listId != null ? 'AND id = ?' : ''}
        ORDER BY position
      ''', [userId, if (listId != null) listId]);

  Stream<ToDoListWithItems> getList(String listId) => _queryLists(listId)
      .map((e) => e.first)
      .asyncMap((map) async => ToDoListWithItems.fromMap(
            map,
            await _getMembers(listId),
            await _getToDos(listId),
          ));

  /// Removes the list from the user's references
  /// Does not actually delete the list, since it could be used by others
  Future<void> removeList(String listId) => removeUser(userId, listId);

  Future<void> removeUser(String userId, String listId) =>
      _crdt.setDeleted('user_lists', [userId, listId]);

  Future<void> undoRemoveList(String listId) => undoRemoveUser(userId, listId);

  Future<void> undoRemoveUser(String userId, String listId) =>
      _crdt.setDeleted('user_lists', [userId, listId], false);

  Future<void> deleteItem(String id) => _crdt.setDeleted('todos', [id]);

  Future<void> undeleteItem(String id) =>
      _crdt.setDeleted('todos', [id], false);

  Future<void> setDone(String itemId, bool isDone) => _crdt.setFields('todos', [
        itemId
      ], {
        'done': isDone,
        'done_at': isDone ? DateTime.now() : null,
        'done_by': isDone ? userId : null,
      });

  Future<void> setItemName(String itemId, String name) =>
      _crdt.setField('todos', [itemId], 'name', name);

  Future<Hlc> merge(List<Map<String, dynamic>> changeset) =>
      _crdt.merge(changeset);

  Future<CrdtChangeset> changeset(Hlc? lastSync) =>
      _crdt.getChangeset(modifiedSince: lastSync, onlyModifiedHere: true);

  void setName(String listId, String name) =>
      _crdt.setField('lists', [listId], 'name', name);

  void setColor(String listId, Color color) =>
      _crdt.setField('lists', [listId], 'color', color.hexValue);

  Future<String> createItem(String listId, String name) async {
    final id = uuid();
    final maxPosition = (await _crdt.queryAsync('''
        SELECT max(position) AS max_position FROM todos
        WHERE list_id = ? AND is_deleted = 0
      ''', [listId])).first['max_position'] ?? -1;
    await _crdt.setFields('todos', [
      id
    ], {
      'list_id': listId,
      'name': name,
      'done': false,
      'position': maxPosition + 1,
      'creator_id': userId,
      'created_at': DateTime.now(),
    });
    return id;
  }

  Future<void> setListOrder(List<ToDoList> lists) async {
    final batch = _crdt.newBatch();
    for (int i = 0; i < lists.length; i++) {
      final list = lists[i];
      if (list.position != i) {
        batch.setField('user_lists', [userId, list.id], 'position', i);
      }
    }
    await _crdt.commit(batch);
  }

  Future<void> setItemOrder(List<ToDo> items) async {
    final batch = _crdt.newBatch();
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      if (item.position != i) {
        batch.setField('todos', [item.id], 'position', i);
      }
    }
    await _crdt.commit(batch);
  }

  Future<List<Member>> _getMembers(String listId) => _crdt.queryAsync(
        '''
          SELECT user_id, name, user_lists.created_at AS joined_at FROM user_lists
            LEFT JOIN users ON user_id = id
          WHERE list_id = ?1
            AND user_lists.is_deleted = 0 AND coalesce(users.is_deleted, 0) = 0
        ''',
        [listId],
      ).then((l) => l.map((m) => Member.fromMap(userId, m)).toList());

  Future<List<ToDo>> _getToDos(String listId) => _crdt.queryAsync('''
    SELECT
      todos.id,
      todos.name,
      todos.done,
      todos.done_at,
      users.name AS done_by,
      todos.position,
      todos.creator_id,
      todos.created_at
    FROM
      todos
    LEFT JOIN
      users ON done_by = users.id
    WHERE
      list_id = ?
      AND todos.is_deleted = 0
    ORDER BY
      position
  ''', [listId]).then((l) => l.map(ToDo.fromMap).toList());
}

class ToDoListWithItems extends ToDoList {
  final List<ToDo> items;

  ToDoListWithItems.fromList(ToDoList list, this.items)
      : super(list.id, list.name, list.color, list.creatorId, list.createdAt,
            list.position, list.itemCount, list.doneCount, list.members);

  ToDoListWithItems.fromMap(
      Map<String, dynamic> map, List<Member> members, this.items)
      : super.fromMap(map, members);
}

class ToDoList {
  final String id;
  final String name;
  final Color color;
  final String? creatorId;
  final DateTime? createdAt;
  final int position;
  final int itemCount;
  final int doneCount;
  final List<Member> members;

  int get shareCount => members.length;

  bool get isShared => ignoreShares.contains(id) ? false : shareCount > 1;

  bool get isEmpty => itemCount == 0;

  const ToDoList(this.id, this.name, this.color, this.creatorId, this.createdAt,
      this.position, this.itemCount, this.doneCount, this.members);

  ToDoList.fromMap(Map<String, dynamic> map, List<Member> members)
      : this(
          map['id'],
          map['name'],
          (map['color'] as String).asColor,
          map['creator_id'],
          (map['created_at'] as String?)?.asDateTime,
          map['position'],
          map['item_count'] ?? 0,
          map['done_count'] ?? 0,
          members,
        );

  String memberNames(BuildContext context) =>
      members.map((e) => e.nameOr(context)).join(' • ');

  @override
  String toString() => '$name [$doneCount/$itemCount]';
}

class ToDo {
  final String id;
  final String name;
  final bool done;
  final DateTime? doneAt;
  final String? doneBy;
  final int position;
  final String? creatorId;
  final DateTime? createdAt;

  ToDo(this.id, this.name, this.done, this.doneAt, this.doneBy, this.position,
      this.creatorId, this.createdAt);

  factory ToDo.fromMap(Map<String, dynamic> map) => ToDo(
        map['id'],
        map['name'],
        map['done'] == 1,
        (map['done_at'] as String?)?.asDateTime.toLocal(),
        map['done_by'],
        map['position'],
        map['creator_id'],
        (map['created_at'] as String?)?.asDateTime.toLocal(),
      );

  @override
  bool operator ==(Object other) =>
      other is ToDo &&
      other.id == id &&
      other.name == name &&
      other.done == done;

  @override
  int get hashCode => hashValues(id, name, done);

  @override
  String toString() => '$name ${done ? '🗹' : '☐'}';
}

class Member extends User {
  final DateTime? joinedAt;

  Member.fromMap(String userId, Map<String, dynamic> map)
      : joinedAt = (map['joined_at'] as String?)?.asDateTime.toLocal(),
        super.fromMap(userId, map);
}
