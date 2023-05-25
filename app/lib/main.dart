import 'dart:async';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'common/value_builders.dart';
import 'extensions.dart';
import 'lists/list_manager_page.dart';
import 'registry.dart';
import 'util/build_info.dart';
import 'util/themes.dart';

void main() async {
  // Emulate platform
  // debugDefaultTargetPlatformOverride = TargetPlatform.android;
  // debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

  WidgetsFlutterBinding.ensureInitialized();

  await _setSystemColors();

  await BuildInfo.init();
  await Registry.init();

  runApp(const TudoApp());
}

class TudoApp extends StatefulWidget {
  const TudoApp({Key? key}) : super(key: key);

  @override
  State<TudoApp> createState() => _TudoAppState();
}

class _TudoAppState extends State<TudoApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    manageConnection(AppLifecycleState.resumed);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    manageConnection(state);
  }

  @override
  Widget build(BuildContext context) {
    return ValueStreamBuilder<ThemeMode>(
      stream: Registry.settingsProvider.theme,
      builder: (_, theme) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'tudo',
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: theme,
        home: const ListManagerPage(),
      ),
    );
  }

  void manageConnection(AppLifecycleState state) {
    final syncProvider = Registry.syncProvider;
    final appVisible = (state == AppLifecycleState.resumed ||
        state == AppLifecycleState.inactive);
    if (appVisible) {
      syncProvider.connect();
    } else {
      syncProvider.disconnect();
    }
  }
}

// Hack around a bug on earlier Android versions
// https://github.com/flutter/flutter/issues/90098
Future<void> _setSystemColors() async {
  final navigationBarColor = !PlatformX.isAndroid ||
          ((await DeviceInfoPlugin().androidInfo).version.sdkInt) >= 29
      ? Colors.transparent
      : Colors.black38;

  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: navigationBarColor,
  ));
}
