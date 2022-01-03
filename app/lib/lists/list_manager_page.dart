import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:implicitly_animated_reorderable_list/implicitly_animated_reorderable_list.dart';
import 'package:implicitly_animated_reorderable_list/transitions.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:tudo_app/common/edit_list.dart';
import 'package:tudo_app/common/offline_indicator.dart';
import 'package:tudo_app/common/progress.dart';
import 'package:tudo_app/common/value_builders.dart';
import 'package:tudo_app/extensions.dart';
import 'package:tudo_app/lists/to_do_list_page.dart';
import 'package:tudo_app/settings/settings_provider.dart';

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
            padding: EdgeInsets.only(bottom: context.padding.bottom),
            items: lists,
            shrinkWrap: true,
            areItemsTheSame: (oldItem, newItem) => oldItem.id == newItem.id,
            onReorderFinished: (_, from, to, __) =>
                _swap(context, lists, from, to),
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
          onPressed: () => _createList(context),
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

  Future<void> _createList(BuildContext context) async {
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

  void _swap(BuildContext context, List<ToDoList> lists, int from, int to) {
    lists = lists.toList();
    final item = lists.removeAt(from);
    lists.insert(to, item);
    context.listProvider.setListOrder(lists);
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: MaterialButton(
        padding: EdgeInsets.zero,
        elevation: 4,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: () => _openList(context),
        onLongPress: () => _editList(context),
        child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [list.color, list.color.darken(0.2)],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Text(
                      '🛒',
                      style: context.theme.primaryTextTheme.bodyText1!
                          .copyWith(fontSize: 36),
                    ),
                  ),
                  // const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          list.name,
                          style: context.theme.primaryTextTheme.headline6,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'You, Ramona',
                          style: context.theme.primaryTextTheme.subtitle2!
                              .copyWith(
                                  color: context
                                      .theme.primaryTextTheme.subtitle2!.color!
                                      .withOpacity(0.8)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Progress(
                    progress: list.doneCount,
                    total: list.itemCount,
                    color: list.color.darken(0.5),
                    size: 40,
                  ),
                ],
              ),
            )),
      ),
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
    final index = await listManager.delete(list.id);
    context.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('${list.name} deleted'),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () => listManager.import(list.id, index),
        ),
      ),
    );
  }
}
