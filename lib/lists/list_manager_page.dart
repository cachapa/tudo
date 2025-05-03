import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';

import '../common/appbars.dart';
import '../common/dialogs.dart';
import '../common/edit_list.dart';
import '../common/lists.dart';
import '../common/offline_indicator.dart';
import '../common/qr_widgets.dart';
import '../common/value_builders.dart';
import '../extensions.dart';
import '../registry.dart';
import '../settings/settings_page.dart';
import '../util/build_info.dart';
import '../util/update_util.dart';
import 'list_provider.dart';
import 'to_do_list_tile.dart';

class ListManagerPage extends StatefulWidget {
  final String? selectedId;
  final void Function(ToDoList? list) onListSelected;

  const ListManagerPage({
    super.key,
    required this.selectedId,
    required this.onListSelected,
  });

  @override
  State<ListManagerPage> createState() => _ListManagerPageState();
}

class _ListManagerPageState extends State<ListManagerPage>
    with WidgetsBindingObserver {
  late final OfflineIndicator _offlineIndicator;
  final _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _manageConnection(AppLifecycleState.resumed);

    SchedulerBinding.instance.addPostFrameCallback((_) {
      _offlineIndicator = OfflineIndicator(context);
    });
    _monitorDeeplinks();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    _manageConnection(state);
  }

  @override
  void dispose() {
    _offlineIndicator.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarIconBrightness: context.theme.brightness.invert,
      ),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: BlurredAppBar(
          title: Stack(
            alignment: Alignment.center,
            children: [
              Image.asset(
                'assets/images/tudo_rainbow_bold.png',
                height: 40,
              ),
              Image.asset(
                'assets/images/tudo.png',
                height: 40,
                color: context.theme.textTheme.bodyLarge!.color,
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.qr_code_scanner_rounded),
              tooltip: t.scanQrCode,
              onPressed: _launchQrScanner,
            ),
            ValueStreamBuilder<bool>(
              stream: Registry.contactProvider.isNameSet,
              initialValue: true,
              builder: (_, isNameSet) => IconButton(
                icon: Badge(
                  smallSize: isNameSet ? 0 : null,
                  child: const Icon(Icons.settings_rounded),
                ),
                tooltip: t.settings,
                onPressed: _showSettingsPage,
              ),
            ),
          ],
        ),
        body: ValueStreamBuilder<List<ToDoList>>(
          stream: Registry.listProvider.lists,
          builder: (context, lists) => lists.isEmpty
              ? _EmptyPage()
              : AnimatedReorderableListBuilder(
                  lists,
                  controller: _controller,
                  padding:
                      context.padding.add(const EdgeInsets.only(bottom: 80)),
                  onReorder: (from, to) => _swap(lists, from, to),
                  builder: (context, i, item) => ToDoListTile(
                    key: ValueKey(item.id),
                    isSelected: item.id == widget.selectedId,
                    list: item,
                    onTap: () => _openList(context, item),
                    onEdit: () => _editList(context, item),
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
        bottomNavigationBar: BuildInfo.isWeb
            ? const SizedBox()
            : ValueFutureBuilder(
                future: UpdateUtil.updateAvailable,
                errorBuilder: (context, error) => const SizedBox(),
                builder: (context, updateAvailable) => updateAvailable
                    ? SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.only(
                              left: 16, right: 16, bottom: 16),
                          child: FilledButton.icon(
                            icon: const Icon(Icons.system_update_rounded),
                            label: Text(t.updateApp.toUpperCase()),
                            onPressed: () => UpdateUtil.update(),
                          ),
                        ),
                      )
                    : const SizedBox(),
              ),
      ),
    );
  }

  void _manageConnection(AppLifecycleState state) {
    final syncProvider = Registry.syncProvider;
    switch (state) {
      case AppLifecycleState.resumed:
        syncProvider.connect();
      case AppLifecycleState.paused:
        syncProvider.disconnect();
      default:
      // Do nothing
    }
  }

  Future<void> _launchQrScanner() async {
    final code = await scanQrCode(context);

    if (code == null) return;
    'Read QR: $code'.log;
    final uri = Uri.parse(code);

    try {
      await _joinList(uri.pathSegments.last);
    } catch (e) {
      '$e'.log;
      if (mounted) context.showSnackBar('$e');
    }
  }

  Future<void> _joinList(String listId) async {
    try {
      if (!Registry.listProvider.hasList(listId)) {
        await showIndeterminateProgressDialog(
          context,
          message: context.t.joiningList,
          future: Registry.syncProvider.joinList(listId),
        );
      } else {
        context.showSnackBar(context.t.listAlreadyJoined);
      }
    } catch (e) {
      if (mounted) context.showSnackBar('$e');
    }
  }

  Future<void> _createList() async {
    await editToDoList(context);
    // Wait for entry animation to finish
    await Future.delayed(longDuration);
    // Scroll to bottom of list
    await _controller.animateTo(
      _controller.position.maxScrollExtent,
      duration: mediumDuration,
      curve: Curves.fastOutSlowIn,
    );
  }

  void _openList(BuildContext context, ToDoList list) =>
      widget.onListSelected(list);

  Future<void> _editList(BuildContext context, ToDoList list) =>
      editToDoList(context, list);

  void _swap(List<ToDoList> lists, int from, int to) {
    final item = lists.removeAt(from);
    lists.insert(to, item);
    Registry.listProvider.setListOrder(lists);
  }

  void _monitorDeeplinks() {
    try {
      if (PlatformX.isMobile) {
        AppLinks().getInitialLink().then((uri) async {
          if (uri != null) {
            'Initial link: $uri'.log;
            await _joinList(uri.pathSegments.last);
          }
        });
        AppLinks().uriLinkStream.listen((uri) async {
          'Stream link: $uri'.log;
          await _joinList(uri.pathSegments.last);
        }).onError((e) => e.log);
      }
    } catch (e) {
      e.toString().log;
    }
  }

  void _showSettingsPage() {
    context.push(() => const SettingsPage());
  }
}

class _EmptyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        padding:
            EdgeInsets.only(bottom: context.padding.bottom + 72, right: 80),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.rotate(
              angle: -0.2,
              child: Text(
                context.t.createAList,
                style: context.theme.textTheme.displaySmall!
                    .apply(fontFamily: 'WaitingfortheSunrise'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 80),
              child: SvgPicture.asset(
                'assets/images/arrow.svg',
                width: 40,
                colorFilter: ColorFilter.mode(
                  context.theme.textTheme.displaySmall!.color!,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
