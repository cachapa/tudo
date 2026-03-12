import 'package:flutter/material.dart';

final lightTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
  inputDecorationTheme: _inputDecorationTheme,
);

final darkTheme = ThemeData(
  brightness: Brightness.dark,
  colorScheme: ColorScheme.fromSeed(
    brightness: Brightness.dark,
    seedColor: Colors.blueGrey,
  ),
  inputDecorationTheme: _inputDecorationTheme,
);

final _inputDecorationTheme = InputDecorationTheme(
  filled: true,
  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: BorderSide.none,
  ),
);
