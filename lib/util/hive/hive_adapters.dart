import 'dart:ui';

import 'package:hive/hive.dart';
import 'package:tudo_client/list_manager/list_provider.dart';

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
    return ToDo(id, name, checked, isDeleted);
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
