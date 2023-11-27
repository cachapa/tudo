import 'package:flutter/material.dart';

final lightTheme = ThemeData(
  primarySwatch: Colors.blue,
  inputDecorationTheme: _inputDecorationTheme,
);

final darkTheme = ThemeData(
  brightness: Brightness.dark,
  primarySwatch: Colors.blue,
  primaryColor: Colors.blue,
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
