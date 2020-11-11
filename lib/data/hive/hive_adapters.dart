import 'dart:ui';

import 'package:crdt/crdt.dart';
import 'package:hive/hive.dart';

import '../list_manager.dart';
import 'hive_crdt.dart';

class HlcAdapter extends TypeAdapter<Hlc> {
  @override
  final int typeId;

  final String nodeId;

  HlcAdapter(this.typeId, this.nodeId);

  @override
  Hlc read(BinaryReader reader) => Hlc.fromLogicalTime(reader.read(), nodeId);

  @override
  void write(BinaryWriter writer, Hlc obj) => writer.write(obj.logicalTime);
}

class RecordAdapter extends TypeAdapter<Record> {
  @override
  final typeId;

  RecordAdapter(this.typeId);

  @override
  Record read(BinaryReader reader) {
    return Record(reader.read(), reader.read());
  }

  @override
  void write(BinaryWriter writer, Record obj) {
    writer.write(obj.hlc);
    writer.write(obj.value);
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
    return ToDo(reader.readString(), reader.readBool());
  }

  @override
  void write(BinaryWriter writer, ToDo obj) {
    writer.writeString(obj.name);
    writer.writeBool(obj.checked);
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
