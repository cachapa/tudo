import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:implicitly_animated_reorderable_list/implicitly_animated_reorderable_list.dart';
import 'package:implicitly_animated_reorderable_list/transitions.dart';
import 'package:provider/provider.dart';
import 'package:tudo_client/data/list_manager.dart';

import 'edit_list_form.dart';
import 'progress.dart';
import 'to_do_list_page.dart';

class ListManagerPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ListManager>(
      builder: (_, listManager, __) => Scaffold(
        body: ImplicitlyAnimatedReorderableList<ToDoList>(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom + 80),
          items: listManager.lists,
          shrinkWrap: true,
          // dragDuration: Duration(milliseconds: 200),
          areItemsTheSame: (oldItem, newItem) => oldItem.id == newItem.id,
          onReorderFinished: (_, from, to, __) => listManager.swap(from, to),
          header: Logo(),
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
        floatingActionButton: FloatingActionButton(
          clipBehavior: Clip.antiAlias,
          backgroundColor: Colors.transparent,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Image.asset('assets/images/icon_bg.png'),
              Text(
                't',
                style: TextStyle(
                  fontFamily: 'WaitingfortheSunrise',
                  fontSize: 50,
                  height: 1.3,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          onPressed: () => createToDoList(context),
        ),
      ),
    );
  }
}

class Logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SafeArea(
        bottom: false,
        child: Container(
          height: 120,
          alignment: Alignment.center,
          child: Text(
            'tudo',
            style: TextStyle(
              fontFamily: 'WaitingfortheSunrise',
              fontSize: 100,
              height: 1.4,
            ),
          ),
        ),
      );
}

class _ListItem extends StatelessWidget {
  final ToDoList list;

  _ListItem({Key key, this.list}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Slidable(
      actionPane: const SlidableBehindActionPane(),
      secondaryActions: [
        SlideAction(
          color: Colors.red,
          child: Icon(
            Icons.delete,
            color: Theme.of(context).canvasColor,
          ),
          onTap: () => _deleteList(context, list.id),
        ),
      ],
      child: Stack(
        alignment: Alignment.centerRight,
        children: [
          ListTile(
            tileColor: Theme.of(context).canvasColor,
            leading: Progress(list: list),
            title: Text(
              list.name,
              style: Theme.of(context).textTheme.headline6,
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ToDoListPage(id: list.id)),
            ),
          ),
          Handle(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Icon(
                Icons.reorder,
                color: Theme.of(context).dividerColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteList(BuildContext context, String listId) {
    final listManager = Provider.of<ListManager>(context, listen: false);
    final index = listManager.remove(list.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("${list.name} deleted"),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () => listManager.import(list.id, index),
        ),
      ),
    );
  }
}
