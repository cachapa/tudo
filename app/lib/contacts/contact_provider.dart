import 'package:flutter/cupertino.dart';
import 'package:rxdart/rxdart.dart';
import 'package:tudo_app/crdt/tudo_crdt.dart';
import 'package:tudo_app/extensions.dart';

class ContactProvider {
  final String userId;
  final TudoCrdt _crdt;

  final _contacts = BehaviorSubject<Map<String, User>>();

  Stream<bool> get isNameSet => currentUser.asyncMap(
      (_) async => (await _crdt.getField('users', userId, 'name')) != null);

  Stream<User> get currentUser => getUser(userId);

  ContactProvider(this.userId, this._crdt) {
    _contacts.addStream(_crdt
        .query('''
          SELECT user_id, name FROM user_lists
            LEFT JOIN users ON user_id = id
          WHERE coalesce(users.is_deleted, 0) = 0
        ''')
        .map((l) => l.map((m) => User.fromMap(userId, m)))
        .map((l) => {for (final u in l) u.id: u}));
  }

  Future<void> setName(String value) =>
      _crdt.setField('users', [userId], 'name', value);

  Stream<User> getUser(String id) =>
      _contacts.map((m) => m[id] ?? User(userId, id, null));
}

class User {
  final String id;
  final String name;
  final bool isCurrentUser;

  User(String userId, this.id, String? name)
      : name = name ?? '',
        isCurrentUser = userId == id;

  User.fromMap(String userId, Map<String, dynamic> map)
      : this(userId, map['user_id'], map['name']);

  String nameOr(BuildContext context) =>
      name.isEmpty ? context.t.anonymous : name;

  @override
  String toString() => 'User: $name';
}
