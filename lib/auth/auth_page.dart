import 'dart:ui';

import 'package:flutter/material.dart';

import '../common/dialogs.dart';
import '../common/qr_widgets.dart';
import '../config.dart';
import '../extensions.dart';
import '../registry.dart';
import '../util/build_info.dart';
import 'server_configuration_panel.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // _Background(),
          Image.asset('assets/images/icon_bg.png', fit: BoxFit.fill),
          _Foreground(),
        ],
      ),
    );
  }
}

class _Foreground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // SizedBox(height: 40),
          const Spacer(),
          Text(
            'tudo',
            style: context.theme.textTheme.displayLarge!.apply(
                fontFamily: 'WaitingfortheSunrise',
                fontSizeFactor: 1.5,
                color: Colors.white),
          ),
          // Spacer(),
          const SizedBox(height: 80),
          TextButton.icon(
            icon: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
            ),
            label: Text(
              context.t.startFromCleanSlate.toUpperCase(),
              style: const TextStyle(color: Colors.white),
            ),
            onPressed: () => _createProfile(context),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 2,
                color: Colors.white30,
                margin: const EdgeInsets.only(right: 16, top: 2),
              ),
              Text(context.t.or, style: const TextStyle(color: Colors.white)),
              Container(
                width: 80,
                height: 2,
                color: Colors.white30,
                margin: const EdgeInsets.only(left: 16, top: 2),
              ),
            ],
          ),
          const SizedBox(height: 4),
          TextButton.icon(
            icon:
                const Icon(Icons.qr_code_scanner_rounded, color: Colors.white),
            onPressed: () => _loadProfile(context),
            label: Text(
              context.t.linkExistingAccount.toUpperCase(),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const Spacer(),
          if (!BuildInfo.isWeb)
            TextButton.icon(
              icon: const Icon(Icons.lan_rounded, color: Colors.white70),
              onPressed: () => showServerConfigurationPanel(context),
              label: Text(
                'Server configuration'.toUpperCase(),
                style: const TextStyle(color: Colors.white70),
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _createProfile(BuildContext context) => Registry.authProvider.create();

  Future<void> _loadProfile(BuildContext context) async {
    try {
      final tokenUrl = await (PlatformX.isMobile
          ? scanQrCode(
              context,
              message: context.t.scanAccountKeyExplanation,
            )
          : showTextInputDialog(
              context,
              hint: context.t.accountKey,
              caption: context.t.pasteAccountKeyExplanation,
            ));
      if (!context.mounted || tokenUrl == null || tokenUrl.isEmpty) return;

      if (BuildInfo.isWeb && !tokenUrl.startsWith('$defaultUri')) {
        throw 'This instance only supports accounts hosted in $defaultUri';
      }

      final tokenUri = Uri.parse(tokenUrl);
      final segments = tokenUri.pathSegments;
      if (segments.length < 2 || segments[segments.length - 2] != 'key') {
        throw 'Invalid token: $tokenUrl';
      }
      if (!context.mounted) return;

      // Remove /key/{uuid} from token url and store as server url
      final serverUri =
          tokenUri.replace(pathSegments: segments.take(segments.length - 2));

      final token = segments.last;
      Registry.settingsProvider.setServerUri('$serverUri');

      await showIndeterminateProgressDialog(
        context,
        message: context.t.restoringAccount,
        future: Registry.authProvider.login(token),
        onError: (e) {
          '$e'.log;
          if (context.mounted) context.showSnackBar('$e');
        },
      );
    } catch (e) {
      if (context.mounted) context.showSnackBar('$e');
    }
  }
}

// ignore: unused_element
class _Background extends StatelessWidget {
  static const sigma = 100.0;
  static const colors = [
    Colors.yellow,
    Colors.lightGreenAccent,
    Colors.cyanAccent,
    Colors.orange,
    Colors.blueGrey,
    Colors.blueAccent,
    Colors.red,
    Colors.purple,
    Colors.deepPurple,
  ];

  @override
  Widget build(BuildContext context) {
    var i = 0;
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: Container(color: colors[i++])),
                Expanded(child: Container(color: colors[i++])),
                Expanded(child: Container(color: colors[i++])),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(child: Container(color: colors[i++])),
                Expanded(child: Container(color: colors[i++])),
                Expanded(child: Container(color: colors[i++])),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(child: Container(color: colors[i++])),
                Expanded(child: Container(color: colors[i++])),
                Expanded(child: Container(color: colors[i++])),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
