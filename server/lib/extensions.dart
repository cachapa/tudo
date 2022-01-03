import 'crdt/hlc.dart';

extension StringX on String {
  void get log => print(this);

  DateTime get asDateTime => DateTime.parse(this);

  Hlc get asHlc => Hlc.parse(this);
}
