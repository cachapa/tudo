import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:platform_info/platform_info.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../common/appbars.dart';
import '../common/segmented_control.dart';
import '../common/dialogs.dart';
import '../common/value_builders.dart';
import '../config.dart';
import '../contacts/contact_provider.dart';
import '../extensions.dart';
import '../registry.dart';
import '../util/build_info.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final t = context.t;

    return Scaffold(
      appBar: DiscreteAppBar(title: t.settings),
      body: ListView(
        children: [
          ValueStreamBuilder<User>(
            stream: Registry.contactProvider.currentUser,
            builder: (_, user) => ListTile(
              leading: ValueStreamBuilder<bool>(
                stream: Registry.contactProvider.isNameSet,
                builder: (_, isNameSet) => Badge(
                  smallSize: isNameSet ? 0 : null,
                  child: const Icon(Icons.badge_outlined),
                ),
              ),
              title: Text(t.name),
              subtitle: Text(user.nameOr(context)),
              onTap: () => _setName(context, user.name),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.style_outlined),
            title: Text(t.theme),
            trailing: ValueStreamBuilder<ThemeMode>(
              stream: Registry.settingsProvider.theme,
              builder: (_, theme) => SegmentedControl<ThemeMode, IconData>(
                value: theme,
                items: const {
                  ThemeMode.light: Icons.light_mode_outlined,
                  ThemeMode.system: Icons.brightness_auto,
                  ThemeMode.dark: Icons.mode_night_outlined,
                },
                segmentBuilder: (_, data) => Icon(data),
                onChanged: Registry.settingsProvider.setTheme,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.phonelink_lock),
            title: Text(t.accountKey),
            onTap: () => _showAccountKey(context),
          ),
          Header(t.aboutTudo),
          ListTile(
            leading: const Icon(Icons.mail_outline),
            title: Text(t.sendFeedback),
            onTap: () => launchUrlString(
                'mailto:cachapa@gmail.com?subject=tudo%20feedback'),
          ),
          ListTile(
            leading: const Icon(Icons.bug_report_outlined),
            title: Text(t.reportIssues),
            onTap: () =>
                launchUrlString('https://github.com/cachapa/tudo/issues'),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: Text(t.privacyPolicy),
            onTap: () =>
                launchUrlString('https://tudo.cachapa.net/privacy.html'),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(t.licenses),
            onTap: () => showLicensePage(
              context: context,
              applicationIcon: Image.asset(
                'assets/images/icon_rounded.png',
                height: 60,
              ),
              applicationVersion: BuildInfo.version,
              applicationLegalese: '© Daniel Cachapa',
            ),
          ),
          Header(t.otherApps),
          ListTile(
            leading: Image.asset(
              'assets/images/libra_icon.png',
              width: 32,
            ),
            title: const Text('Libra'),
            subtitle: Text(t.libraDescription),
            onTap: () => launchUrlString(platform.isIOS
                ? 'https://apps.apple.com/us/app/libra-weight-manager/id1644353761'
                : 'https://play.google.com/store/apps/details?id=net.cachapa.libra'),
          ),
          ListTile(
            leading: Image.asset(
              'assets/images/storyark_icon.png',
              width: 32,
            ),
            title: const Text('StoryArk'),
            subtitle: Text(t.storyArkDescription),
            onTap: () => launchUrlString(platform.isIOS
                ? 'https://apps.apple.com/US/app/id1558910365'
                : 'https://play.google.com/store/apps/details?id=de.storyark.app'),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            t.version(BuildInfo.version),
            style: context.theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Future<void> _setName(BuildContext context, String? currentName) async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => TextInputDialog(
        title: context.t.name,
        value: currentName ?? '',
        caption: context.t.nameCaption,
        hint: context.t.anonymous,
        showClearButton: true,
        textCapitalization: TextCapitalization.words,
        positiveLabel: context.t.update,
      ),
    );
    if (context.mounted && name != null) {
      await Registry.contactProvider.setName(name);
    }
  }

  Future<void> _showAccountKey(BuildContext context) async {
    final localAuth = LocalAuthentication();
    try {
      if (await localAuth.canCheckBiometrics) {
        final isAuthenticated =
            await localAuth.authenticate(localizedReason: context.t.accountKey);
        if (!isAuthenticated) return;
      }
    } catch (e) {
      e.toString().log;
    }

    if (!context.mounted) return;
    final keyUrl =
        serverUri.apply('key/${Registry.authProvider.token}').toString();
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.t.accountKeyExplanation,
                style: context.theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: QrImageView(
                  size: 200,
                  padding: const EdgeInsets.all(12),
                  data: keyUrl,
                  version: QrVersions.auto,
                  backgroundColor: ThemeData.light().canvasColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                context.t.accountKeyAdvice,
                style: context.theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                icon: Icon(Icons.adaptive.share),
                label: Text(context.t.share.toUpperCase()),
                onPressed: () {
                  Share.share(keyUrl);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Header extends StatelessWidget {
  final String title;

  const Header(this.title, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8, left: 16, right: 16),
      child: Text(
        title,
        style: TextStyle(color: context.theme.textTheme.bodySmall!.color),
      ),
    );
  }
}
