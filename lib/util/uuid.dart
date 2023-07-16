import 'package:uuid/uuid.dart';

Uuid _uuid = const Uuid();

String uuid() => _uuid.v4();
