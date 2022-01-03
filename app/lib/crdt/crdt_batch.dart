import 'sqflite_crdt.dart';

class CrdtBatch {
  final entries = <BatchEntry>[];

  bool get isEmpty => entries.isEmpty;

  /// Convenience method to set multiple fields at once
  void setFields(
      String collection, List<String> ids, Map<String, dynamic> fields) {
    for (final entry in fields.entries) {
      setField(collection, ids, entry.key, entry.value);
    }
  }

  void setField(
      String collection, List<String> ids, String field, dynamic value) {
    assert(!collection.contains(':'));
    entries.add(BatchEntry(collection, ids, field, value));
  }

  void setDeleted(String collection, List<String> ids,
          [bool isDeleted = true]) =>
      setField(collection, ids, SqfliteCrdt.deletedField, isDeleted);
}

/// Records all field changes without `hlc` or `modified` timestamps.
/// The value for those is generated when the batch is applied.
class BatchEntry {
  final String collection;
  final List<String> ids;
  final String field;
  final dynamic value;

  BatchEntry(this.collection, this.ids, this.field, this.value);
}
