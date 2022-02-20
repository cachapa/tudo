import 'package:tudo_app/crdt/tudo_crdt.dart';

class ContactProvider {
  final String userId;
  final TudoCrdt _crdt;

  Future<bool> get isNameSet async =>
      (await _crdt.getField('users', userId, 'name')) != null;

  Stream<String> get name =>
      _crdt.query('SELECT name FROM users WHERE id = ?', [userId]).map(
          (list) => list.isEmpty ? '' : list.first['name']);

  ContactProvider(this.userId, this._crdt);

  Future<void> setName(String value) =>
      _crdt.setField('users', [userId], 'name', value);

  Stream<List<User>> getListParticipants(String listId) => _crdt.query(
        '''
          SELECT user_id, name FROM user_lists
            LEFT JOIN users ON user_id = id
          WHERE list_id = ?1
            AND user_lists.is_deleted = 0 AND coalesce(users.is_deleted, 0) = 0
        ''',
        [listId],
      ).map((l) => l.map((e) => User.fromMap(userId, e)).toList());
}

class User {
  final String id;
  final String name;
  final bool isCurrentUser;

  User(String userId, this.id, this.name) : isCurrentUser = userId == id;

  User.fromMap(String userId, Map<String, dynamic> map)
      : this(userId, map['user_id'], map['name'] ?? '');

  @override
  String toString() => 'User: $name';
}
