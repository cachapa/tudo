import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

class BuildInfo {
  static late PackageInfo _packageInfo;
  static late String deviceModel;
  static late String platformVersion;

  static String get version => _packageInfo.version;

  static String get buildNumber => _packageInfo.buildNumber;

  static String get platform => Platform.operatingSystem;

  static String get locale => Platform.localeName;

  static bool get isDebug => kDebugMode;

  static String get userAgent =>
      'tudo/$version $platform/$platformVersion ($deviceModel)';

  BuildInfo._();

  static Future<void> init() async {
    _packageInfo = await PackageInfo.fromPlatform();

    // Mobile
    if (Platform.isAndroid) {
      final info = await DeviceInfoPlugin().androidInfo;
      deviceModel = info.model;
      platformVersion = info.version.release;
    } else if (Platform.isIOS) {
      final info = await DeviceInfoPlugin().iosInfo;
      deviceModel = info.model!;
      platformVersion = info.systemVersion!;
    }
    // Desktop
    else if (Platform.isLinux) {
      final info = await DeviceInfoPlugin().linuxInfo;
      deviceModel = info.name;
      platformVersion = info.versionId!;
    } else if (Platform.isMacOS) {
      final info = await DeviceInfoPlugin().macOsInfo;
      deviceModel = info.model;
      platformVersion = info.osRelease;
    }
    // Fallback
    else {
      deviceModel = Platform.operatingSystem.capitalized;
      platformVersion = Platform.operatingSystemVersion.split(' ')[1];
    }
  }
}

extension on String {
  String get capitalized => '${this[0].toUpperCase()}${substring(1)}';
}
