import 'sqflite_crdt.dart';

class TudoCrdt extends SqfliteCrdt {
  @override
  final version = 1;
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
        'created_at': CrdtType.datetime,
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
  Future<T?> getField<T>(String collection, String id, String field) {
    // Make sure that 'created_at' is always retrieved as DateTime
    assert(field != 'created_at' || T is DateTime);
    return super.getField<T>(collection, id, field);
  }
}
