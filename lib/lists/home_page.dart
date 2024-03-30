import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();

    Registry.listProvider.lists.listen((lists) {
      if (_list != null && !lists.map((e) => e.id).contains(_list!.id)) {
        setState(() => _list = null);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MasterDetail(
        masterWidth: 400,
        thresholdWidth: 800,
        masterBuilder: (_, __) => ListManagerPage(
          selectedId: _list?.id,
          onListSelected: (list) => setState(() => _list = list),
        ),
        detailBuilder: (_, __) => _list == null
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

  onListClose() {
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
        color: context.theme.dividerColor.withOpacity(0.2),
        size: 100,
      ),
    );
  }
}
