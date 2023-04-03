import 'package:shelf/shelf.dart';

extension StringX on String {
  String get short {
    final i = indexOf('-');
    return i > 0 ? substring(0, i) : this;
  }
}

extension RequestX on Request {
  Map<String, String> get queryParameters => requestedUri.queryParameters;
}
