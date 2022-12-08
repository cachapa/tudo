extension StringX on String {
  String get short {
    final i = indexOf('-');
    return i > 0 ? substring(0, i) : this;
  }
}
