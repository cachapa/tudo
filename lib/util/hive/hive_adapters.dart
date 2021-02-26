import 'dart:ui';

import 'package:crdt/crdt.dart';
import 'package:hive/hive.dart';

import '../../list_manager/list_provider.dart';
import 'hive_crdt.dart';

class HlcAdapter extends TypeAdapter<Hlc> {
  @override
  final int typeId;

  final String nodeId;

  HlcAdapter(this.typeId, this.nodeId);

  @override
  Hlc read(BinaryReader reader) {
    // Migrate from µs-based logical time
    final logicalTime = reader.read();
    return logicalTime < 10000000000000000
        ? Hlc(
            (logicalTime & 0xFFFFFFFFFFFF0000) ~/ 1000,
            logicalTime & 0xFFFF,
            nodeId,
          )
        : Hlc.fromLogicalTime(logicalTime, nodeId);
  }

  @override
  void write(BinaryWriter writer, Hlc obj) => writer.write(obj.logicalTime);
}

class RecordAdapter extends TypeAdapter<Record> {
  @override
  final typeId;

  RecordAdapter(this.typeId);

  @override
  Record read(BinaryReader reader) {
    final hlc = reader.read();
    final value = reader.read();
    final modified = reader.read();
    return Record(hlc, value, modified);
  }

  @override
  void write(BinaryWriter writer, Record obj) {
    writer.write(obj.hlc);
    writer.write(obj.value);
    writer.write(obj.modified);
  }
}

class ModRecordAdapter extends TypeAdapter<ModRecord> {
  @override
  final typeId;

  ModRecordAdapter(this.typeId);

  @override
  ModRecord read(BinaryReader reader) {
    return ModRecord(reader.read(), reader.read());
  }

  @override
  void write(BinaryWriter writer, ModRecord obj) {
    writer.write(obj.record);
    writer.write(obj.modified);
  }
}

class ToDoAdapter extends TypeAdapter<ToDo> {
  @override
  final typeId;

  ToDoAdapter(this.typeId);

  @override
  ToDo read(BinaryReader reader) {
    /* Convert from old id-less values
     Old format: String, Bool
     New format: String, String, Bool
     So check the available bytes after first field
    */
    final id = reader.readString();
    final name = reader.readString();
    final checked = reader.readBool();
    final isDeleted = reader.availableBytes == 21 ? reader.readBool() : false;
    return ToDo(id, name, checked, false);
  }

  @override
  void write(BinaryWriter writer, ToDo obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeBool(obj.checked);
    writer.writeBool(obj.isDeleted);
  }
}

class ColorAdapter extends TypeAdapter<Color> {
  @override
  final int typeId;

  ColorAdapter(this.typeId);

  @override
  Color read(BinaryReader reader) {
    return Color(reader.readInt32());
  }

  @override
  void write(BinaryWriter writer, Color obj) {
    writer.writeInt32(obj.value);
  }
}
