import 'package:uuid/uuid.dart';

late Uuid _uuid = const Uuid();

String uuid() => _uuid.v4();
