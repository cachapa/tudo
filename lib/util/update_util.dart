import 'dart:io';

import 'package:in_app_update/in_app_update.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../registry.dart';

class UpdateUtil {
  static final Future<bool> updateAvailable = Platform.isAndroid
      ? (InAppUpdate.checkForUpdate().then(
          (v) => v.updateAvailability == UpdateAvailability.updateAvailable))
      : Registry.syncProvider.isUpdateRequired();

  UpdateUtil._();

  static Future<void> update() async {
    if (Platform.isAndroid) {
      final result = await InAppUpdate.performImmediateUpdate();
      if (result == AppUpdateResult.inAppUpdateFailed) {
        await launchUrlString(
          'https://play.google.com/store/apps/details?id=net.cachapa.tudo',
          mode: LaunchMode.externalApplication,
        );
      }
    } else {
      await launchUrlString(
        'https://apps.apple.com/us/app/tudo-lists/id1550819275',
        mode: LaunchMode.externalApplication,
      );
    }
  }
}
