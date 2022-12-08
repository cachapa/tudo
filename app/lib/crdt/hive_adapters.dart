import 'package:hive/hive.dart';
import 'package:sqlite_crdt/sqlite_crdt.dart';

class HlcAdapter extends TypeAdapter<Hlc> {
  @override
  final int typeId;

  HlcAdapter(this.typeId);

  @override
  Hlc read(BinaryReader reader) => Hlc.parse(reader.read());

  @override
  void write(BinaryWriter writer, Hlc obj) => writer.write(obj.toString());
}
