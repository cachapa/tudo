import 'package:flutter/cupertino.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sqlite_crdt/sqlite_crdt.dart';

import '../extensions.dart';

class ContactProvider {
  final String userId;
  final SqlCrdt _crdt;

  final _contacts = BehaviorSubject<Map<String, User>>();

  Stream<bool> get isNameSet => currentUser.map((e) => e.name.isNotEmpty);

  Stream<User> get currentUser => getUser(userId);

  ContactProvider(this.userId, this._crdt) {
    _contacts.addStream(_crdt
        .watch('''
          SELECT * FROM users
          WHERE is_deleted = 0
        ''')
        .map((l) => l.map((m) => User.fromMap(userId, m)))
        .map((l) => {for (final u in l) u.id: u}));
  }

  Future<void> setName(String name) async {
    final userExists = (await _contacts.first).containsKey(userId);
    if (!userExists) {
      await _crdt.execute('''
        INSERT INTO users (id, name)
        VALUES (?1, ?2)
      ''', [userId, name]);
    } else {
      await _crdt.execute('''
        UPDATE users SET name = ?2
        WHERE id = ?1
      ''', [userId, name]);
    }
  }

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
      : this(userId, map['id'], map['name']);

  String nameOr(BuildContext context) =>
      name.isEmpty ? context.t.anonymous : name;

  @override
  String toString() => 'User: $name';
}
