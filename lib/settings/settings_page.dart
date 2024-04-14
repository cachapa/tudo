import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:local_auth/local_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../common/appbars.dart';
import '../common/dialogs.dart';
import '../common/qr_widgets.dart';
import '../common/segmented_control.dart';
import '../common/value_builders.dart';
import '../contacts/contact_provider.dart';
import '../extensions.dart';
import '../registry.dart';
import '../util/build_info.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

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
            title: Text(t.manageAccount),
            onTap: () => _manageAccount(context),
          ),
          Header(t.aboutTudo),
          ListTile(
            leading: const Icon(Icons.mail_outline),
            title: Text(t.sendFeedback),
            onTap: () => launchUrlString(
                'mailto:cachapa@gmail.com?subject=tudo%20feedback'),
          ),
          ListTile(
            leading: const Icon(Icons.translate_rounded),
            title: Text(t.translateApp),
            subtitle: Text(t.translateAppDescription),
            onTap: () => launchUrlString(
              'https://translate.libra-app.eu/projects/tudo/app',
              mode: LaunchMode.externalApplication,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.bug_report_outlined),
            title: Text(t.reportIssues),
            onTap: () =>
                launchUrlString('https://github.com/cachapa/tudo/issues'),
          ),
          const Divider(),
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

  Future<void> _manageAccount(BuildContext context) async {
    final localAuth = LocalAuthentication();
    try {
      if (await localAuth.canCheckBiometrics && context.mounted) {
        final isAuthenticated =
            await localAuth.authenticate(localizedReason: context.t.accountKey);
        if (!isAuthenticated) return;
      }
    } catch (e) {
      e.toString().log;
    }

    if (!context.mounted) return;
    final serverUri = Registry.settingsProvider.serverUri;
    final keyUrl = '$serverUri/key/${Registry.authProvider.token}';
    final qrKey = GlobalKey();
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.t.accountKeyExplanation,
                style: context.theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 16),
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: RepaintBoundary(
                    key: qrKey,
                    child: QrView(keyUrl, size: 200),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextField(
                  controller: TextEditingController(text: keyUrl),
                  readOnly: true,
                ),
              ),
              const SizedBox(height: 16),
              if (PlatformX.isMobile)
                FilledButton.icon(
                  icon: Icon(Icons.adaptive.share),
                  label: Text(context.t.share.toUpperCase()),
                  onPressed: () async {
                    final boundary = qrKey.currentContext!.findRenderObject()
                        as RenderRepaintBoundary;
                    ui.Image image = await boundary.toImage(pixelRatio: 3.0);
                    final byteData =
                        await image.toByteData(format: ui.ImageByteFormat.png);
                    var pngBytes = byteData!.buffer.asUint8List();
                    final path =
                        '${(await getApplicationCacheDirectory()).path}/tudo_account_key.png';
                    await File(path).writeAsBytes(pngBytes, flush: true);
                    await Share.shareXFiles(
                      [XFile(path)],
                      subject: context.t.tudoAccountKey,
                      text: keyUrl,
                    );
                    if (context.mounted) context.pop();
                  },
                ),
              const SizedBox(height: 40),
              TextButton(
                onPressed: () {
                  context.pop();
                  _deleteData(context);
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text(context.t.deleteData.toUpperCase()),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteData(BuildContext context) async {
    final r = Random();
    final code = '${r.nextInt(10)}${r.nextInt(10)}${r.nextInt(10)}';
    final result = await showDialog<String>(
      context: context,
      builder: (context) => TextInputDialog(
        keyboardType: TextInputType.number,
        title: context.t.deleteData,
        info: Text(context.t.deleteDataConfirmation(code)),
        value: '',
        positiveLabel: context.t.delete,
      ),
    );

    if (!context.mounted || result == null) return;
    if (result.trim() != code) {
      context.showSnackBar(context.t.codeFailedToMatch);
    } else {
      await showIndeterminateProgressDialog(
        context,
        message: '💣',
        future: _actuallyDeleteData(context),
        onError: (e) => context.showSnackBar('$e'),
      );
    }
  }

  Future<void> _actuallyDeleteData(BuildContext context) async {
    await Registry.authProvider.deleteData();
    if (context.mounted) context.showSnackBar(context.t.dataDeleted);
  }
}

class Header extends StatelessWidget {
  final String title;

  const Header(this.title, {super.key});

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
