import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:implicitly_animated_reorderable_list/implicitly_animated_reorderable_list.dart';
import 'package:implicitly_animated_reorderable_list/transitions.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:tudo_app/common/drag_handler.dart';
import 'package:tudo_app/common/edit_list.dart';
import 'package:tudo_app/common/offline_indicator.dart';
import 'package:tudo_app/common/progress.dart';
import 'package:tudo_app/common/value_builders.dart';
import 'package:tudo_app/extensions.dart';
import 'package:tudo_app/lists/to_do_list_page.dart';
import 'package:tudo_app/settings/settings_provider.dart';
import 'package:uni_links/uni_links.dart';

import 'list_provider.dart';

final _controller = ScrollController();

class ListManagerPage extends StatefulWidget {
  const ListManagerPage({Key? key}) : super(key: key);

  @override
  State<ListManagerPage> createState() => _ListManagerPageState();
}

class _ListManagerPageState extends State<ListManagerPage> {
  late final OfflineIndicator _offlineIndicator;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance!.addPostFrameCallback((_) {
      _offlineIndicator = OfflineIndicator(context);
    });
    _monitorDeeplinks();
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
          builder: (_, lists) => ImplicitlyAnimatedReorderableList<ToDoList>(
            controller: _controller,
            padding: EdgeInsets.only(bottom: context.padding.bottom + 88),
            items: lists,
            shrinkWrap: true,
            areItemsTheSame: (oldItem, newItem) => oldItem.id == newItem.id,
            onReorderFinished: (_, from, to, __) => _swap(lists, from, to),
            header: const Logo(),
            itemBuilder: (_, itemAnimation, item, __) => Reorderable(
              key: ValueKey(item.id),
              builder: (_, __, ___) => SizeFadeTransition(
                sizeFraction: 0.7,
                curve: Curves.easeInOut,
                animation: itemAnimation,
                child: _ListItem(list: item),
              ),
            ),
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
      // Scroll to the bottom of the list
      Future.delayed(
        const Duration(milliseconds: 400),
        () => _controller.animateTo(
          _controller.position.maxScrollExtent + 200,
          duration: const Duration(milliseconds: 400),
          curve: Curves.fastOutSlowIn,
        ),
      );
    }
  }

  void _swap(List<ToDoList> lists, int from, int to) {
    lists = lists.toList();
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
    } catch (_) {}
  }
}

class Logo extends StatelessWidget {
  const Logo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = context.theme.textTheme.bodyText1!.color;

    return SafeArea(
      bottom: false,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            padding: const EdgeInsets.all(20),
            icon: Selector<SettingsProvider, ThemeMode>(
              selector: (_, settingsProvider) => settingsProvider.theme,
              builder: (_, theme, __) => Icon(
                theme == ThemeMode.system
                    ? Icons.brightness_auto
                    : theme == ThemeMode.light
                        ? Icons.light_mode_outlined
                        : Icons.mode_night_outlined,
                color: color,
              ),
            ),
            tooltip: 'Toggle theme',
            onPressed: () => _toggleTheme(context),
          ),
          MaterialButton(
            padding: const EdgeInsets.symmetric(vertical: 20),
            onPressed: () => _showAbout(context),
            child: Stack(
              children: [
                Image.asset(
                  'assets/images/tudo_rainbow_bold.png',
                  height: 72,
                ),
                Image.asset(
                  'assets/images/tudo.png',
                  height: 72,
                  color: color,
                ),
              ],
            ),
          ),
          IconButton(
            padding: const EdgeInsets.all(20),
            icon: Icon(
              Icons.qr_code_scanner,
              color: color,
            ),
            tooltip: 'Import using QR code',
            onPressed: () => _launchQrScanner(context),
          ),
        ],
      ),
    );
  }

  Future<void> _showAbout(BuildContext context) async {
    final version = (await PackageInfo.fromPlatform()).version;
    showAboutDialog(
      context: context,
      applicationVersion: version,
      applicationIcon: Image.asset(
        'assets/images/icon_rounded.png',
        height: 48,
        filterQuality: FilterQuality.high,
      ),
    );
  }

  void _toggleTheme(BuildContext context) {
    final settingsProvider = context.read<SettingsProvider>();
    settingsProvider.theme = ThemeMode
        .values[(settingsProvider.theme.index + 1) % ThemeMode.values.length];
  }

  Future<void> _launchQrScanner(BuildContext context) async {
    final code = await FlutterBarcodeScanner.scanBarcode(
      '#00000000',
      'CLOSE',
      false,
      ScanMode.QR,
    );
    if (code == '-1') return;
    'Read QR: $code'.log;
    final uri = Uri.parse(code);
    await context.read<ListProvider>().import(uri.pathSegments.last);
  }
}

class _ListItem extends StatelessWidget {
  final ToDoList list;

  const _ListItem({Key? key, required this.list}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Progress(
        color: list.color,
        progress: list.doneCount,
        total: list.itemCount,
      ),
      title: Text(
        list.name,
        style: context.theme.textTheme.headline6,
      ),
      trailing: const DragHandle(),
      onTap: () => _openList(context),
      onLongPress: () => _editList(context),
    );
  }

  void _openList(BuildContext context) async {
    final action = await context.push(() => ToDoListPage(listId: list.id));
    if (action != null && action == ListAction.delete) {
      Future.delayed(
        // Wait for pop animation to complete
        const Duration(milliseconds: 310),
        () => _deleteList(context),
      );
    }
  }

  void _editList(BuildContext context) =>
      editToDoList(context, list, () => _deleteList(context));

  Future<void> _deleteList(BuildContext context) async {
    final listManager = context.read<ListProvider>();
    final index = list.position;
    await listManager.removeList(list.id);
    context.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('${list.name} deleted'),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () => listManager.undoRemoveList(list.id),
        ),
      ),
    );
  }
}
