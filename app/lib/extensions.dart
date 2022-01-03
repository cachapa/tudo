import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tudo_app/util/store.dart';

import 'auth/auth_provider.dart';
import 'crdt/hlc.dart';
import 'lists/list_provider.dart';
import 'sync/sync_provider.dart';

export 'package:provider/provider.dart';

extension StringX on String {
  void get log {
    // ignore: avoid_print
    if (!kReleaseMode) print(this);
  }

  DateTime get asDateTime => DateTime.parse(this);

  Hlc get asHlc => Hlc.parse(this);

  Color get asColor =>
      Color(int.parse(replaceFirst('#', ''), radix: 16) + 0xFF000000);
}

extension ListX<T> on List<T> {
  T get random => this[Random().nextInt(length)];
}

extension ColorX on Color {
  String get hexValue =>
      '#${(value & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

  Color darken(double strength) =>
      Color.alphaBlend(Colors.black.withOpacity(strength), this);
}

extension BrightnessExtensions on Brightness {
  Brightness get invert =>
      this == Brightness.light ? Brightness.dark : Brightness.light;
}

extension ContextExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);

  Future<T?> push<T>(Widget Function() builder) =>
      Navigator.of(this).push<T>(MaterialPageRoute(builder: (_) => builder()));

  void pop<T>([T? result]) => Navigator.of(this).pop<T>(result);

  void showSnackBar(SnackBar snackBar) =>
      ScaffoldMessenger.of(this).showSnackBar(snackBar);

  EdgeInsets get padding => MediaQuery.of(this).padding;

  // Providers
  StoreProvider get storeProvider => read<StoreProvider>();

  AuthProvider get authProvider => read<AuthProvider>();

  ListProvider get listProvider => read<ListProvider>();

  SyncProvider get syncProvider => read<SyncProvider>();
}

extension PlatformX on Platform {
  static bool get isMobile => Platform.isAndroid || Platform.isIOS;

  static bool get isDesktop =>
      Platform.isLinux || Platform.isMacOS || Platform.isWindows;

  static bool get isApple => Platform.isMacOS || Platform.isIOS;
}
