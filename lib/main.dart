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
  WidgetsFlutterBinding.ensureInitialized();

  final nodeId = RandomId().generate(32);

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

  // TODO Remove this
  // listManager.import('LcRj5Ls_CgJGk_rLaNj0.at1JRBlk0BiYoaietUysGKBiWSoUVNPIEy90DUj3pkJRAUVImjXYJJ0_9EEYmWZ7.3D1b7k79D4pIgKxmC4xml2PjiAqjtT7VuIEzrJq7zC');

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

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // TODO Improve this crap
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        getInitialUri().then((uri) {
          if (uri != null) {
            print('URI: $uri');
            final id = uri.pathSegments[0];
            Provider.of<ListManager>(context, listen: false).import(id);
          }
        });
        getUriLinksStream().listen((uri) {
          print('URI: $uri');
          final id = uri.pathSegments[0];
          Provider.of<ListManager>(context, listen: false).import(id);
        }).onError((e) => print(e));
      }
    } catch (_) {}

    return Consumer<SyncManager>(
      builder: (_, syncManager, __) => Column(
        children: [
          Expanded(
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
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
      ),
    );
  }
}
