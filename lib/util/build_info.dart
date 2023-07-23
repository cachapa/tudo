import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:platform_info/platform_info.dart';

final _p = Platform.instance;

class BuildInfo {
  static late PackageInfo _packageInfo;
  static late String deviceModel;
  static late String platformVersion;

  static String get version => _packageInfo.version;

  static String get buildNumber => _packageInfo.buildNumber;

  static String get platform => _p.operatingSystem.name;

  static String get locale => _p.locale;

  static bool get isDebug => _p.buildMode.isDebug;

  static String get userAgent =>
      'tudo/$version $platform/$platformVersion ($deviceModel)';

  BuildInfo._();

  static Future<void> init() async {
    _packageInfo = await PackageInfo.fromPlatform();

    // Web
    if (_p.isWeb) {
      final info = await DeviceInfoPlugin().webBrowserInfo;
      deviceModel = info.browserName.name;
      platformVersion = info.appVersion ?? '';
    }
    // Mobile
    else if (_p.isAndroid) {
      final info = await DeviceInfoPlugin().androidInfo;
      deviceModel = info.model;
      platformVersion = info.version.release;
    } else if (_p.isIOS) {
      final info = await DeviceInfoPlugin().iosInfo;
      deviceModel = info.model;
      platformVersion = info.systemVersion;
    }
    // Desktop
    else if (_p.isLinux) {
      final info = await DeviceInfoPlugin().linuxInfo;
      deviceModel = info.name;
      platformVersion = info.versionId!;
    } else if (_p.isMacOS) {
      final info = await DeviceInfoPlugin().macOsInfo;
      deviceModel = info.model;
      platformVersion = info.osRelease;
    }
    // Fallback
    else {
      deviceModel = _p.operatingSystem.name.capitalized;
      platformVersion = _p.version;
    }
  }
}

extension on String {
  String get capitalized => '${this[0].toUpperCase()}${substring(1)}';
}
