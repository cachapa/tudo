import 'dart:async';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:hive_crdt/hive_adapters.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:uni_links2/uni_links.dart';
import 'package:tudo_client/common/offline_indicator.dart';
import 'package:tudo_client/extensions.dart';
import 'package:tudo_client/util/settings_provider.dart';

import 'list_manager/list_manager_page.dart';
import 'list_manager/list_provider.dart';
import 'util/hive/hive_adapters.dart';
import 'util/sync_provider.dart';

void main() async {
  // Emulate platform
  // debugDefaultTargetPlatformOverride = TargetPlatform.android;
  // debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

  WidgetsFlutterBinding.ensureInitialized();

  _setSystemColors();

  final dir = Platform.isAndroid || Platform.isIOS
      ? (await getApplicationDocumentsDirectory()).path
      : 'store';
  Hive.init(dir);

  // Adapters
  Hive.registerAdapter(RecordAdapter(0));
  Hive.registerAdapter(HlcAdapter(2, nodeId));
  Hive.registerAdapter(ToDoAdapter(3));
  Hive.registerAdapter(ColorAdapter(4));

  final settingsProvider = await SettingsProvider.open();
  final nodeId = settingsProvider.nodeId;

  final listProvider = await ListProvider.open(nodeId);
  _monitorDeeplinks(listProvider);

  _deleteStaleLists(dir, listProvider);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settingsProvider),
        ChangeNotifierProvider.value(value: listProvider),
        ChangeNotifierProvider(create: (_) => SyncProvider(listProvider)),
      ],
      child: MyApp(),
    ),
  );
}

void _deleteStaleLists(String dir, ListProvider listManager) {
  final existingLists = listManager.listIds.map((e) => e.toLowerCase()).toSet();
  final allLists = Directory(dir)
      .listSync()
      .map((e) => e.path)
      .where((e) => e.endsWith('.hive'))
      .map((e) => e.substring(e.lastIndexOf('/') + 1, e.lastIndexOf('.')))
      .where((e) => e != 'store' && e != 'settings')
      .toSet();
  (allLists..removeAll(existingLists))
      .forEach((e) => Hive.deleteBoxFromDisk(e));
}

void _monitorDeeplinks(ListProvider listManager) {
  try {
    if (Platform.isAndroid || Platform.isIOS) {
      getInitialLink().then((link) async {
        // ignore: unnecessary_null_comparison
        if (link != null) {
          print('Initial link: $link');
          await listManager.import(link);
        }
      });
      linkStream.where((e) => e != null).listen((link) async {
        print('Stream link: $link');
        await listManager.import(link!);
      }).onError((e) => print(e));
    }
  } catch (_) {}
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  Timer? reconnectTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addObserver(this);
    manageConnection(AppLifecycleState.resumed);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    manageConnection(state);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'tudo',
            theme: ThemeData(
              primarySwatch: Colors.blue,
            ),
            darkTheme: ThemeData(
              primarySwatch: Colors.blue,
              primaryColor: Colors.blue,
              brightness: Brightness.dark,
            ),
            themeMode: context.select<SettingsProvider, ThemeMode>(
                (provider) => provider.theme),
            home: const ListManagerPage(),
          ),
        ),
        const OfflineIndicator(),
      ],
    );
  }

  void manageConnection(AppLifecycleState state) {
    final syncProvider = context.read<SyncProvider>();
    final appVisible = (state == AppLifecycleState.resumed ||
        state == AppLifecycleState.inactive);
    if (appVisible) {
      if (!(reconnectTimer?.isActive ?? false)) {
        reconnectTimer = Timer.periodic(
            const Duration(seconds: 10), (_) => syncProvider.connect());
        syncProvider.connect();
      }
    } else {
      reconnectTimer?.cancel();
      syncProvider.disconnect();
    }
  }
}

// Hack around a bug on earlier Android versions
// https://github.com/flutter/flutter/issues/90098
Future<void> _setSystemColors() async {
  final navigationBarColor = !Platform.isAndroid ||
          ((await DeviceInfoPlugin().androidInfo).version.sdkInt ?? 0) >= 29
      ? Colors.transparent
      : Colors.black38;

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: navigationBarColor,
  ));
}
