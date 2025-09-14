import 'package:flutter/material.dart';
import 'package:quick_actions/quick_actions.dart';

import '../common/master_detail.dart';
import '../extensions.dart';
import '../registry.dart';
import 'list_manager_page.dart';
import 'list_provider.dart';
import 'to_do_list_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  ToDoList? _list;

  final _quickActions = const QuickActions();

  @override
  void initState() {
    super.initState();

    _quickActions.initialize((listId) async {
      final list = await Registry.listProvider.getList(listId).first;
      setState(() => _list = list);
    });

    Registry.listProvider.lists.listen((lists) {
      // Detect when the currently selected list is deleted
      if (_list != null && !lists.map((e) => e.id).contains(_list!.id)) {
        setState(() => _list = null);
      }

      // Populate quick actions menu
      _quickActions.setShortcutItems(
        lists
            .map(
              (list) => ShortcutItem(
                type: list.id,
                localizedTitle: list.name,
                icon: 'list_shortcut',
              ),
            )
            .toList(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MasterDetail(
        masterWidth: 400,
        thresholdWidth: 800,
        masterBuilder: (_, _) => ListManagerPage(
          selectedId: _list?.id,
          onListSelected: (list) => setState(() => _list = list),
        ),
        detailBuilder: (_, _) => _list == null
            ? null
            : ToDoListPage(
                key: ValueKey(_list!.id),
                onClose: onListClose,
                list: _list!,
              ),
        emptyBuilder: (_) => const EmptyList(),
        onPopDetail: onListClose,
      ),
    );
  }

  void onListClose() {
    setState(() => _list = null);
  }
}

class EmptyList extends StatelessWidget {
  const EmptyList({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        Icons.list_alt_rounded,
        color: context.theme.dividerColor.withAlpha(50),
        size: 100,
      ),
    );
  }
}
