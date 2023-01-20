// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:tudo_app/common/edit_list.dart';
import 'package:tudo_app/common/offline_indicator.dart';
import 'package:tudo_app/common/value_builders.dart';
import 'package:tudo_app/extensions.dart';
import 'package:tudo_app/settings/settings_page.dart';
import 'package:uni_links/uni_links.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'list_provider.dart';
import 'to_do_list_page.dart';
import 'to_do_list_tile.dart';

class ListManagerPage extends StatefulWidget {
  const ListManagerPage({Key? key}) : super(key: key);

  @override
  State<ListManagerPage> createState() => _ListManagerPageState();
}

class _ListManagerPageState extends State<ListManagerPage> {
  late final OfflineIndicator _offlineIndicator;
  final _bottomOfList = GlobalKey();

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _offlineIndicator = OfflineIndicator(context);
    });
    _monitorDeeplinks();

    _checkForUpdates();
  }

  @override
  void dispose() {
    _offlineIndicator.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarIconBrightness: context.theme.brightness.invert,
      ),
      child: Scaffold(
        body: ValueStreamBuilder<List<ToDoList>>(
          stream: context.listProvider.lists,
          builder: (_, lists) => CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: Logo()),
              SliverReorderableList(
                itemCount: lists.length,
                onReorder: (from, to) {
                  // Fix buggy swap indexes
                  if (from < to) to--;
                  if (from == to) return;
                  _swap(lists, from, to);
                },
                itemBuilder: (context, i) => ToDoListTile(
                  key: ValueKey(lists[i].id),
                  list: lists[i],
                  onTap: () => _openList(context, lists[i]),
                  onLongPress: () => _editList(context, lists[i]),
                  index: i,
                ),
              ),
              SliverPadding(
                key: _bottomOfList,
                padding: EdgeInsets.only(bottom: context.padding.bottom + 88),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          clipBehavior: Clip.antiAlias,
          backgroundColor: Colors.transparent,
          onPressed: _createList,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Image.asset('assets/images/icon_bg.png'),
              Image.asset(
                'assets/images/t.png',
                height: 32,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createList() async {
    final result = await editToDoList(context);
    if (result ?? false) {
      // Scroll to the new item
      await Future.delayed(const Duration(milliseconds: 100));
      _scrollToLastItem();
    }
  }

  void _openList(BuildContext context, ToDoList list) async {
    final action = await context.push(() => ToDoListPage(list: list));
    if (action != null && action == ListAction.delete) {
      Future.delayed(
        // Wait for pop animation to complete
        const Duration(milliseconds: 310),
        () => _deleteList(context, list),
      );
    }
  }

  void _editList(BuildContext context, ToDoList list) =>
      editToDoList(context, list);

  Future<void> _deleteList(BuildContext context, ToDoList list) async {
    final listManager = context.read<ListProvider>();
    await listManager.removeList(list.id);
    if (context.mounted) {
      context.showSnackBar(
        context.t.listDeleted(list.name),
        () => listManager.undoRemoveList(list.id),
      );
    }
  }

  void _scrollToLastItem() {
    final itemContext = _bottomOfList.currentContext;
    if (itemContext != null) {
      Scrollable.ensureVisible(
        itemContext,
        duration: const Duration(milliseconds: 300),
      );
    }
  }

  void _swap(List<ToDoList> lists, int from, int to) {
    final item = lists.removeAt(from);
    lists.insert(to, item);
    context.listProvider.setListOrder(lists);
  }

  void _monitorDeeplinks() {
    try {
      if (PlatformX.isMobile) {
        getInitialUri().then((uri) async {
          if (uri != null) {
            'Initial link: $uri'.log;
            await context.listProvider.import(uri.pathSegments.last);
          }
        });
        uriLinkStream.where((e) => e != null).listen((uri) async {
          if (uri != null) {
            'Stream link: $uri'.log;
            await context.listProvider.import(uri.pathSegments.last);
          }
        }).onError((e) => e.log);
      }
    } catch (e) {
      e.toString().log;
    }
  }

  Future<void> _checkForUpdates() async {
    if (await context.syncProvider.isUpdateRequired()) {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(context.t.updateRequired),
          content: Text(context.t.updateRequiredMessage),
          actions: [
            TextButton(
              child: Text(context.t.close),
              onPressed: () => context.pop(false),
            ),
            if (PlatformX.isMobile)
              TextButton(
                child: Text(context.t.update),
                onPressed: () => context.pop(true),
              ),
          ],
        ),
      );

      if (result == true) {
        if (Platform.isAndroid) {
          await InAppUpdate.performImmediateUpdate();
        } else {
          await launchUrlString(
              'https://apps.apple.com/us/app/tudo-lists/id1550819275');
        }
      }
    }
  }
}

class Logo extends StatelessWidget {
  const Logo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final color = context.theme.textTheme.bodyLarge!.color;

    return SafeArea(
      bottom: false,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(
            'assets/images/tudo_rainbow_bold.png',
            height: 40,
          ),
          Image.asset(
            'assets/images/tudo.png',
            height: 40,
            color: color,
          ),
          ButtonBar(
            buttonPadding: EdgeInsets.zero,
            children: [
              IconButton(
                padding: const EdgeInsets.all(20),
                icon: Icon(
                  Icons.qr_code_scanner,
                  color: color,
                ),
                tooltip: t.scanQrCode,
                onPressed: () => _launchQrScanner(context),
              ),
              ValueStreamBuilder<bool>(
                stream: context.contactProvider.isNameSet,
                initialData: true,
                builder: (_, isNameSet) => IconButton(
                  icon: Badge(
                    smallSize: isNameSet ? 0 : null,
                    child: const Icon(Icons.tune_rounded),
                  ),
                  tooltip: t.settings,
                  onPressed: () => context.push(() => const SettingsPage()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _launchQrScanner(BuildContext context) async {
    final code = await FlutterBarcodeScanner.scanBarcode(
      '#00000000',
      context.t.close.toUpperCase(),
      false,
      ScanMode.QR,
    );
    if (code == '-1') return;
    'Read QR: $code'.log;
    final uri = Uri.parse(code);
    if (context.mounted) {
      await context.read<ListProvider>().import(uri.pathSegments.last);
    }
  }
}
