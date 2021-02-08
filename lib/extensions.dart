import 'package:flutter/material.dart';

export 'package:provider/provider.dart';

extension ColorExtensions on Color {
  String get hexValue =>
      '#${(value & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

  static Color fromHex(String hex) =>
      Color(int.parse(hex.replaceFirst('#', ''), radix: 16) + 0xFF000000);
}

extension BrightnessExtensions on Brightness {
  Brightness get invert =>
      this == Brightness.light ? Brightness.dark : Brightness.light;
}

extension ContextExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);

  Future<T> push<T>(Widget Function() builder) =>
      Navigator.of(this).push(MaterialPageRoute(builder: (_) => builder()));

  void pop<T>([T result]) => Navigator.of(this).pop(result);

  void showSnackBar(SnackBar snackBar) =>
      ScaffoldMessenger.of(this).showSnackBar(snackBar);

  EdgeInsets get padding => MediaQuery.of(this).padding;
}
