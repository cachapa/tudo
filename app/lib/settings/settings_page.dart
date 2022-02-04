import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tudo_app/common/segmented_control.dart';
import 'package:tudo_app/common/value_builders.dart';
import 'package:tudo_app/extensions.dart';
import 'package:tudo_app/util/build_info.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final t = context.t;

    return Scaffold(
      appBar: AppBar(
        systemOverlayStyle: context.theme.brightness == Brightness.light
            ? SystemUiOverlayStyle.dark
            : SystemUiOverlayStyle.light,
        elevation: 0,
        foregroundColor: context.theme.textTheme.headline6!.color,
        backgroundColor: context.theme.canvasColor,
        centerTitle: true,
        title: Text(t.settings),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            leading: const Icon(Icons.style_outlined),
            title: Text(t.theme),
            trailing: ValueStreamBuilder<ThemeMode>(
              stream: context.settingsProvider.theme,
              builder: (_, theme) => SegmentedControl<ThemeMode, IconData>(
                value: theme,
                items: const {
                  ThemeMode.light: Icons.light_mode_outlined,
                  ThemeMode.system: Icons.brightness_auto,
                  ThemeMode.dark: Icons.mode_night_outlined,
                },
                segmentBuilder: (_, data) => Icon(data),
                onChanged: context.settingsProvider.setTheme,
              ),
            ),
          ),
          Header(t.aboutTudo),
          ListTile(
            leading: const Icon(Icons.mail_outline),
            title: Text(t.sendFeedback),
            onTap: () =>
                launch('mailto:cachapa@gmail.com?subject=tudo%20feedback'),
          ),
          ListTile(
            leading: const Icon(Icons.bug_report_outlined),
            title: Text(t.reportIssues),
            onTap: () => launch('https://github.com/cachapa/tudo/issues'),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: Text(t.privacyPolicy),
            onTap: () => launch('https://tudo.cachapa.net/privacy.html'),
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
              applicationLegalese: "© Daniel Cachapa",
            ),
          ),
          Header(t.otherApps),
          ListTile(
            leading: Image.asset(
              'assets/images/storyark_icon.png',
              width: 32,
            ),
            title: const Text('StoryArk'),
            subtitle: Text(t.storyArkDescription),
            onTap: () => launch(Platform.isIOS
                ? 'https://apps.apple.com/US/app/id1558910365'
                : 'https://play.google.com/store/apps/details?id=de.storyark.app'),
          ),
          if (!Platform.isIOS)
            ListTile(
              leading: Image.asset(
                'assets/images/libra_icon.png',
                width: 32,
              ),
              title: const Text('Libra'),
              subtitle: Text(t.libraDescription),
              onTap: () => launch(
                  'https://play.google.com/store/apps/details?id=net.cachapa.libra'),
            ),
          const Spacer(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                t.version(BuildInfo.version),
                style: context.theme.textTheme.caption,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
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
        style: TextStyle(color: context.theme.textTheme.caption!.color),
      ),
    );
  }
}
