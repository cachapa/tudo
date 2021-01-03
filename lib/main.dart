import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:uni_links/uni_links.dart';

import 'data/hive/hive_adapters.dart';
import 'data/list_manager.dart';
import 'data/random_id.dart';
import 'data/sync_manager.dart';
import 'ui/list_manager_page.dart';

void main() async {
  // Emulate platform
  // debugDefaultTargetPlatformOverride = TargetPlatform.android;
  // debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
  ));

  final nodeId = generateRandomId(32);

  try {
    final dir = Platform.isAndroid || Platform.isIOS
        ? (await getApplicationDocumentsDirectory()).path
        : 'store';
    Hive.init(dir);
  } catch (_) {
    // Is web
    Hive.init('');
  }

  // Adapters
  Hive.registerAdapter(RecordAdapter(0));
  Hive.registerAdapter(ModRecordAdapter(1));
  Hive.registerAdapter(HlcAdapter(2, nodeId));
  Hive.registerAdapter(ToDoAdapter(3));
  Hive.registerAdapter(ColorAdapter(4));

  final listManager = await ListManager.open(nodeId);
  _monitorDeeplinks(listManager);

  // TODO Remove this
  // listManager.import('test');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: listManager),
        ChangeNotifierProxyProvider<ListManager, SyncManager>(
          create: (_) => SyncManager(),
          update: (_, listManager, syncManager) =>
              syncManager..listManager = listManager,
        )
      ],
      child: MyApp(),
    ),
  );
}

void _monitorDeeplinks(ListManager listManager) {
  try {
    if (Platform.isAndroid || Platform.isIOS) {
      getInitialLink().then((link) async {
        if (link != null) {
          print('Initial link: $link');
          await listManager.import(link);
        }
      });
      getLinksStream().listen((link) async {
        print('Stream link: $link');
        await listManager.import(link);
      }).onError((e) => print(e));
    }
  } catch (_) {}
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  bool isAppVisible = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    setState(() => isAppVisible = state != AppLifecycleState.paused);
  }

  @override
  Widget build(BuildContext context) {
    _manageConnection(context);

    return Consumer<SyncManager>(builder: (_, syncManager, __) {
      return Column(
        children: [
          Expanded(
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              // themeMode: ThemeMode.dark,
              title: 'tudo',
              theme: ThemeData(
                primarySwatch: Colors.blue,
              ),
              darkTheme: ThemeData(
                brightness: Brightness.dark,
              ),
              home: ListManagerPage(),
            ),
          ),
          Container(
            color: syncManager.connected ? Colors.green : Colors.red,
            height: 2,
          ),
        ],
      );
    });
  }

  void _manageConnection(BuildContext context) {
    final syncManager = Provider.of<SyncManager>(context, listen: false);
    if (isAppVisible) {
      syncManager.connect();
    } else {
      syncManager.disconnect();
    }
  }
}
