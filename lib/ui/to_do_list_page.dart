import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:implicitly_animated_reorderable_list/implicitly_animated_reorderable_list.dart';
import 'package:implicitly_animated_reorderable_list/transitions.dart';
import 'package:provider/provider.dart';
import 'package:share/share.dart';
import 'package:tudo_client/data/list_manager.dart';

import 'edit_list.dart';
import 'empty_page.dart';

const titleBarHeight = 60.0;
const inputBarHeight = 60.0;
const blurSigma = 14.0;

class ToDoListPage extends StatelessWidget {
  final String id;

  ToDoListPage({Key key, this.id}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Selector<ListManager, ToDoList>(
      selector: (_, listManager) => listManager.get(id),
      builder: (_, list, __) => Theme(
        data: Theme.of(context).copyWith(
          primaryColor: list.color,
          primaryTextTheme: TextTheme(headline6: TextStyle(color: list.color)),
          primaryIconTheme: IconThemeData(color: list.color),
          iconTheme: IconThemeData(color: list.color),
          toggleableActiveColor: list.color,
          textSelectionHandleColor: list.color,
          textSelectionColor: list.color,
          cursorColor: list.color,
        ),
        child: Scaffold(
          extendBodyBehindAppBar: true,
          appBar: TitleBar(
            list: list,
            actions: [
              IconButton(
                icon: Icon(Icons.share),
                onPressed: () => _share(list),
              ),
              IconButton(
                icon: Icon(Icons.edit),
                onPressed: () => editToDoList(context, list),
              ),
            ],
          ),
          body: list.toDos.isEmpty
              ? EmptyPage(text: 'Create a new to-do item below')
              : ToDoListView(toDoList: list),
          floatingActionButton: InputBar(
            onSubmitted: (value) => list.add(value),
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
        ),
      ),
    );
  }

  void _share(ToDoList list) =>
      Share.share('Tap to open "${list.name}" in your device:\n'
          'https://tudo.cachapa.net/${list.id}');
}

class TitleBar extends StatelessWidget implements PreferredSizeWidget {
  final ToDoList list;
  final List<Widget> actions;

  const TitleBar({Key key, this.list, this.actions}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: AppBar(
          centerTitle: true,
          // iconTheme: IconThemeData(color: list.color),
          backgroundColor: primaryColor.withAlpha(20),
          elevation: 0,
          title: Text(
            list.name,
            overflow: TextOverflow.fade,
          ),
          actions: actions,
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}

class InputBar extends StatelessWidget {
  final Function(String value) onSubmitted;

  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  InputBar({Key key, this.onSubmitted}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final insetBottom = MediaQuery.of(context).viewPadding.bottom;

    return Padding(
      padding: EdgeInsets.all(10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(100),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(
            padding: EdgeInsets.only(bottom: insetBottom),
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              textCapitalization: TextCapitalization.sentences,
              cursorColor: primaryColor,
              style: Theme.of(context)
                  .textTheme
                  .subtitle1
                  .copyWith(color: primaryColor),
              decoration: InputDecoration(
                filled: true,
                fillColor: primaryColor.withAlpha(30),
                contentPadding: EdgeInsets.all(20),
                hintText: 'Add Item',
                border: InputBorder.none,
                suffixIcon: IconButton(
                  padding: EdgeInsets.only(right: 10),
                  icon: Icon(Icons.add),
                  onPressed: () => _onSubmitted(_controller.text),
                ),
              ),
              maxLines: 1,
              onSubmitted: (text) => _onSubmitted(text),
            ),
          ),
        ),
      ),
    );
  }

  void _onSubmitted(String text) {
    onSubmitted(text);
    _controller.clear();
    _focusNode.requestFocus();
  }
}

class ToDoListView extends StatelessWidget {
  final ToDoList toDoList;

  const ToDoListView({Key key, this.toDoList}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final insetTop = MediaQuery.of(context).padding.top;
    final insetBottom =
        MediaQuery.of(context).viewPadding.bottom + inputBarHeight + 20;

    return ImplicitlyAnimatedReorderableList<ToDo>(
      padding: EdgeInsets.only(top: insetTop, bottom: insetBottom),
      items: toDoList.toDos,
      // dragDuration: Duration(milliseconds: 200),
      reorderDuration: Duration(milliseconds: 200),
      areItemsTheSame: (oldItem, newItem) => oldItem == newItem,
      onReorderFinished: (_, from, to, __) => toDoList.swap(from, to),
      itemBuilder: (_, itemAnimation, item, __) => Reorderable(
        key: ValueKey(item.id),
        builder: (context, animation, inDrag) => SizeFadeTransition(
          sizeFraction: 0.7,
          curve: Curves.easeInOut,
          animation: itemAnimation,
          child: Dismissible(
            key: Key(item.id),
            background: Container(color: Colors.red),
            onDismissed: (_) {
              // Do nothing - deletions happen in confirmDismiss
            },
            confirmDismiss: (_) async {
              // Avoid conflicts between Dismissible and list animations
              // This removes the item and waits 200 ms for the list animation
              // to run. By returning true this widget remains in the tree so it
              // can be removed by the list animation rather than it removing
              // itself.
              _removeItem(context, item);
              await Future.delayed(Duration(milliseconds: 400));
              return false;
            },
            child: Stack(
              alignment: Alignment.centerRight,
              children: [
                ListTile(
                  leading: Checkbox(
                    onChanged: (_) => _toggle(item),
                    value: item.checked,
                  ),
                  title: Text(item.name),
                  onTap: () => _toggle(item),
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
          ),
        ),
      ),
    );
  }

  _toggle(ToDo toDo) => toDoList.set(toDo.name, !toDo.checked);

  _removeItem(BuildContext context, ToDo toDo) {
    final index = toDoList.remove(toDo.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("${toDo.name} deleted"),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () => toDoList.set(toDo.name, toDo.checked, index),
        ),
      ),
    );
  }
}
