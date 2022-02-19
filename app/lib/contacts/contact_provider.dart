import 'package:tudo_app/crdt/tudo_crdt.dart';

class ContactProvider {
  final String userId;
  final TudoCrdt _crdt;

  Stream<String> get name =>
      _crdt.query('SELECT name FROM users WHERE id = ?', [userId]).map(
          (list) => list.isEmpty ? '' : list.first['name']);

  ContactProvider(this.userId, this._crdt);

  Future<void> setName(String value) =>
      _crdt.setField('users', [userId], 'name', value);

  Stream<List<User>> getListParticipants(String listId) => _crdt.query(
        '''
          SELECT name FROM user_lists
            JOIN users ON user_id = id
          WHERE list_id = ?1
            AND user_id <> ?2
            AND user_lists.is_deleted = 0 AND users.is_deleted = 0
        ''',
        [listId, userId],
      ).map((l) => l.map(User.fromMap).toList());
}

class User {
  final String id;
  final String name;

  User(this.id, this.name);

  User.fromMap(Map<String, dynamic> map) : this(map['id'], map['name']);

  @override
  String toString() => 'User: $name';
}
