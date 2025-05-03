import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:platform_info/platform_info.dart';

export 'package:flutter_gen/gen_l10n/app_localizations.dart';

extension BoolX on bool {
  int get toInt => this ? 1 : 0;
}

extension StringX on String {
  void get log {
    // ignore: avoid_print
    if (!kReleaseMode) print(this);
  }

  DateTime get asDateTime => DateTime.parse(this);

  Color get asColor =>
      Color(int.parse(replaceFirst('#', ''), radix: 16) + 0xFF000000);
}

extension DateTimeX on DateTime {
  String get toUtcString => toUtc().toIso8601String();

  String get toLocalString => toLocal().toIso8601String();

  String toTimeString(BuildContext context) =>
      '${hour.toString()}:${minute.toString().padLeft(2, '0')}';

  String toRelativeString(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final now = DateTime.now();

    if (year == now.year) {
      if (month == now.month) {
        if (day == now.day) return toTimeString(context);
        if (day == now.day - 1) return context.t.yesterday;
        if (weekday < now.weekday && now.day - day < 7) {
          return DateFormat.EEEE(languageCode).format(this);
        }
      }
      return DateFormat.MMMd(languageCode).format(this);
    }
    return DateFormat.y(languageCode).format(this);
  }
}

extension ListX<T> on List<T> {
  T get random => this[Random().nextInt(length)];
}

extension ColorX on Color {
  String get hexValue =>
      '#${(toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

  Color blend(Color color, double strength) =>
      Color.alphaBlend(color.withAlpha((strength * 256).round()), this);

  Color lighten(double strength) => blend(Colors.white, strength);

  Color darken(double strength) => blend(Colors.black, strength);
}

extension BrightnessExtensions on Brightness {
  Brightness get invert =>
      this == Brightness.light ? Brightness.dark : Brightness.light;
}

extension ContextExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);

  AppLocalizations get t => AppLocalizations.of(this);

  Future<T?> push<T>(Widget Function() builder) =>
      Navigator.of(this).push<T>(MaterialPageRoute(builder: (_) => builder()));

  void pop<T>([T? result]) => Navigator.of(this).pop<T>(result);

  void showSnackBar(String message, [VoidCallback? onUndo]) {
    final scaffold = ScaffoldMessenger.of(this);
    scaffold.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Row(
          children: [
            Expanded(child: Text(message)),
            if (onUndo != null)
              SizedBox(
                height: 24,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    Icons.undo,
                    color: theme.primaryColor,
                  ),
                  onPressed: () {
                    onUndo();
                    scaffold.hideCurrentSnackBar(
                        reason: SnackBarClosedReason.action);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  EdgeInsets get padding => MediaQuery.of(this).padding;
}

extension UriX on Uri {
  Uri apply(String path,
          {String? scheme, Map<String, String>? queryParameters}) =>
      replace(
        scheme: scheme,
        path: '${this.path}/$path',
        queryParameters: {
          ...?queryParameters,
        },
      );
}

class PlatformX {
  static bool get isAndroid => platform.android;

  static bool get isMobile => isAndroid || platform.iOS;

  static bool get isDesktop =>
      platform.linux || platform.macOS || platform.windows;

  static bool get isApple => platform.macOS || platform.iOS;
}
