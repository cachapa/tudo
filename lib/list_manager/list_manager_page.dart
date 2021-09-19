import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:implicitly_animated_reorderable_list/implicitly_animated_reorderable_list.dart';
import 'package:implicitly_animated_reorderable_list/transitions.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:tudo_client/common/drag_handler.dart';
import 'package:tudo_client/common/edit_list.dart';
import 'package:tudo_client/common/progress.dart';
import 'package:tudo_client/extensions.dart';
import 'package:tudo_client/list_manager/list_provider.dart';
import 'package:tudo_client/to_to_list/to_do_list_page.dart';
import 'package:tudo_client/util/settings_provider.dart';

final _controller = ScrollController();

class ListManagerPage extends StatelessWidget {
  const ListManagerPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarIconBrightness: context.theme.brightness.invert,
      ),
      child: Scaffold(
        body: Consumer<ListProvider>(
          builder: (_, listManager, __) =>
              ImplicitlyAnimatedReorderableList<ToDoList>(
            controller: _controller,
            padding: EdgeInsets.only(bottom: context.padding.bottom),
            items: listManager.lists,
            shrinkWrap: true,
            areItemsTheSame: (oldItem, newItem) => oldItem.id == newItem.id,
            onReorderFinished: (_, from, to, __) => listManager.swap(from, to),
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
                  'assets/images/tudo_rainbow_blur.png',
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
      leading: Progress(list: list),
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
    final action = await context.push(() => ToDoListPage(id: list.id));
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

  void _deleteList(BuildContext context) {
    final listManager = context.read<ListProvider>();
    final index = listManager.remove(list.id);
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
