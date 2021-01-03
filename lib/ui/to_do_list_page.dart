import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:implicitly_animated_reorderable_list/implicitly_animated_reorderable_list.dart';
import 'package:implicitly_animated_reorderable_list/transitions.dart';
import 'package:provider/provider.dart';
import 'package:tudo_client/data/list_manager.dart';
import 'package:tudo_client/extensions.dart';

import 'edit_list.dart';
import 'empty_page.dart';
import 'text_input_dialog.dart';

const titleBarHeight = 60.0;
const inputBarHeight = 60.0;
const blurSigma = 14.0;

enum ListAction { delete }

class ToDoListPage extends StatelessWidget {
  final String id;
  final _listKey = GlobalKey();
  final _uncheckedListKey = GlobalKey();
  final _controller = ScrollController();

  ToDoListPage({Key key, this.id}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Selector<ListManager, ToDoList>(
      selector: (_, listManager) => listManager.get(id),
      builder: (_, list, __) => Theme(
        data: context.theme.copyWith(
          colorScheme: context.theme.colorScheme.copyWith(primary: list.color),
          primaryColor: list.color,
          accentColor: list.color,
          primaryTextTheme: TextTheme(headline6: TextStyle(color: list.color)),
          primaryIconTheme: IconThemeData(color: list.color),
          iconTheme: IconThemeData(color: list.color),
          toggleableActiveColor: list.color,
          textSelectionTheme: TextSelectionThemeData(
            selectionHandleColor: list.color,
            cursorColor: list.color,
          ),
        ),
        child: Scaffold(
          extendBodyBehindAppBar: true,
          appBar: TitleBar(
            brightness: context.theme.brightness,
            list: list,
            actions: [
              IconButton(
                icon: Icon(Icons.edit),
                onPressed: () => editToDoList(
                    context, list, () => context.pop(ListAction.delete)),
              ),
            ],
          ),
          body: list.isEmpty
              ? EmptyPage(text: 'Create a new to-do item below')
              : ToDoListView(
                  key: _listKey,
                  checkedListKey: _uncheckedListKey,
                  controller: _controller,
                  toDoList: list,
                ),
          floatingActionButton: InputBar(
            onSubmitted: (value) => _addItem(list, value),
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
        ),
      ),
    );
  }

  void _addItem(ToDoList list, String value) {
    list.add(value);
    Future.delayed(
      Duration(milliseconds: 400),
      () {
        final screenHeight = MediaQuery.of(_listKey.currentContext).size.height;
        final uncheckedListHeight =
            ((_uncheckedListKey.currentContext.findRenderObject()) as RenderBox)
                .size
                .height;
        final maxOffset = uncheckedListHeight;
        final minOffset =
            max<double>(0.0, uncheckedListHeight - screenHeight) + 200.0;
        final offset = _controller.offset.clamp(minOffset, maxOffset);
        _controller.animateTo(
          offset,
          duration: Duration(milliseconds: 400),
          curve: Curves.fastOutSlowIn,
        );
      },
    );
  }
}

class TitleBar extends StatelessWidget implements PreferredSizeWidget {
  final Brightness brightness;
  final ToDoList list;
  final List<Widget> actions;

  const TitleBar({Key key, this.brightness, this.list, this.actions})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final primaryColor = context.theme.primaryColor;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: AppBar(
          brightness: brightness,
          centerTitle: true,
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
    final primaryColor = context.theme.primaryColor;
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
              style: context.theme.textTheme.subtitle1
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
  final Key checkedListKey;
  final ScrollController controller;

  const ToDoListView(
      {Key key, this.checkedListKey, this.controller, this.toDoList})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final insetTop = MediaQuery.of(context).padding.top;
    final insetBottom =
        MediaQuery.of(context).viewPadding.bottom + inputBarHeight + 20;

    final items = toDoList.toDos;
    final uncheckedItems = items.where((item) => !item.checked).toList();
    final checkedItems = items.where((item) => item.checked).toList();

    return ListView(
      controller: controller,
      padding: EdgeInsets.only(top: insetTop, bottom: insetBottom),
      children: [
        ImplicitlyAnimatedReorderableList<ToDo>(
          key: checkedListKey,
          items: uncheckedItems,
          shrinkWrap: true,
          physics: ClampingScrollPhysics(),
          reorderDuration: Duration(milliseconds: 200),
          areItemsTheSame: (oldItem, newItem) => oldItem == newItem,
          onReorderFinished: (_, from, to, __) {
            if (from == to) return;
            // Query the real position of the items in the complete list
            from = items.indexOf(uncheckedItems[from]);
            to = items.indexOf(uncheckedItems[to]);
            toDoList.swap(from, to);
          },
          itemBuilder: (_, itemAnimation, item, __) => Reorderable(
            key: Key(item.id),
            builder: (context, animation, inDrag) => SizeFadeTransition(
              sizeFraction: 0.7,
              curve: Curves.easeInOut,
              animation: itemAnimation,
              child: _ListTile(
                item: item,
                onToggle: () => _toggle(item),
                onEdit: () => _editItem(context, item),
                onDelete: () => _deleteItem(context, item),
              ),
            ),
          ),
        ),
        ImplicitlyAnimatedList(
          items: [
            if (checkedItems.isNotEmpty) ToDo('header', '', false),
            ...checkedItems,
          ],
          shrinkWrap: true,
          physics: ClampingScrollPhysics(),
          areItemsTheSame: (oldItem, newItem) => oldItem == newItem,
          itemBuilder: (context, itemAnimation, item, i) => SizeFadeTransition(
            sizeFraction: 0.7,
            curve: Curves.easeInOut,
            animation: itemAnimation,
            child: item.id == 'header'
                ? _CompletedHeader(
                    color: toDoList.color,
                    onClear: () => _clearCompleted(context, toDoList),
                  )
                : _ListTile(
                    item: item,
                    onToggle: () => _toggle(item),
                    onEdit: () => _editItem(context, item),
                    onDelete: () => _deleteItem(context, item),
                  ),
          ),
        ),
      ],
    );
  }

  void _toggle(ToDo toDo) => toDoList.set(toDo.id, checked: !toDo.checked);

  void _editItem(BuildContext context, ToDo toDo) {
    showDialog<String>(
      context: context,
      builder: (context) => TextInputDialog(
        title: 'Edit Item',
        value: toDo.name,
        positiveLabel: 'Update',
        onSet: (value) => toDoList.set(toDo.id, name: value),
      ),
    );
  }

  void _deleteItem(BuildContext context, ToDo toDo) {
    final index = toDoList.remove(toDo.id);
    context.showSnackBar(
      SnackBar(
        content: Text('Deleted "${toDo.name}"'),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () => toDoList.set(toDo.id,
              name: toDo.name, checked: toDo.checked, index: index),
        ),
      ),
    );
  }

  void _clearCompleted(BuildContext context, ToDoList list) {
    var checked = list.toDos.where((item) => item.checked).toList();
    if (checked.isEmpty) return;

    var indexes = checked.map((e) => list.remove(e.id)).toList();

    // Insert in reverse order when undoing so the old indexes match
    checked = checked.reversed.toList();
    indexes = indexes.reversed.toList();
    final count = checked.length;

    context.showSnackBar(
      SnackBar(
        content:
            Text('Cleared $count completed ${count == 1 ? 'item' : 'items'}'),
        action: SnackBarAction(
            label: 'UNDO',
            onPressed: () {
              for (var i = 0; i < checked.length; i++) {
                final item = checked[i];
                list.set(item.id,
                    name: item.name, checked: item.checked, index: indexes[i]);
              }
            }),
      ),
    );
  }
}

class _ListTile extends StatelessWidget {
  final ToDo item;
  final Function() onToggle;
  final Function() onEdit;
  final Function() onDelete;

  const _ListTile(
      {Key key, this.item, this.onToggle, this.onEdit, this.onDelete})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(item.id),
      child: ListTile(
        leading: Checkbox(
          onChanged: (_) => onToggle(),
          value: item.checked,
        ),
        title: Text(item.name),
        trailing: item.checked
            ? null
            : Handle(
                vibrate: false,
                child: Icon(Icons.reorder),
              ),
        onTap: () => onToggle(),
        onLongPress: onEdit,
      ),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.symmetric(horizontal: 20),
        color: Colors.red,
        child: Icon(Icons.delete,
            color: context.theme.canvasColor.withOpacity(0.9)),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.symmetric(horizontal: 20),
        color: Colors.red,
        child: Icon(Icons.delete,
            color: context.theme.canvasColor.withOpacity(0.9)),
      ),
      onDismissed: (_) {
        // Do nothing - deletions happen in confirmDismiss
      },
      confirmDismiss: (_) async {
        // Avoid conflicts between Dismissible and list animations
        // This removes the item and returns true so this widget remains in the
        // tree to be removed by the list animation rather than itself.
        onDelete();
        return false;
      },
    );
  }
}

class _CompletedHeader extends StatelessWidget {
  final Color color;
  final Function() onClear;

  const _CompletedHeader({Key key, this.color, this.onClear}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: color.withOpacity(0.4),
            width: 2,
          ),
        ),
      ),
      padding: EdgeInsets.only(left: 16, top: 8, right: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Completed',
              style: context.theme.textTheme.subtitle2.copyWith(color: color),
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: onClear,
          ),
        ],
      ),
    );
  }
}
