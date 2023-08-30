import 'dart:ui';

import 'package:flutter/material.dart';

import '../extensions.dart';
import '../lists/list_manager_page.dart';
import '../registry.dart';
import '../common/qr_widgets.dart';

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
          // TextButton(
          //   onPressed: () {},
          //   child: Text(
          //     'Select server'.toUpperCase(),
          //     style: TextStyle(color: Colors.white),
          //   ),
          // ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _createProfile(BuildContext context) {
    Registry.authProvider.create();
    context
      ..pop()
      ..push(() => const ListManagerPage());
  }

  Future<void> _loadProfile(BuildContext context) async {
    final tokenUrl = await scanQrCode(
      context,
      message: context.t.scanAccountKeyExplanation,
    );
    if (!context.mounted || tokenUrl == null) return;

    try {
      final segments = Uri.parse(tokenUrl).pathSegments;
      if (segments.length < 2 || segments[segments.length - 2] != 'key') {
        throw 'Invalid token: $tokenUrl';
      }
      await Registry.authProvider.login(segments.last);
      if (context.mounted) {
        context
          ..pop()
          // ignore: unawaited_futures
          ..push(() => const ListManagerPage());
      }
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
