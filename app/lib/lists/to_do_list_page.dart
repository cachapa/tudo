import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:implicitly_animated_reorderable_list/implicitly_animated_reorderable_list.dart';
import 'package:implicitly_animated_reorderable_list/transitions.dart';
import 'package:tudo_app/common/drag_handler.dart';
import 'package:tudo_app/common/edit_list.dart';
import 'package:tudo_app/common/empty_page.dart';
import 'package:tudo_app/common/progress.dart';
import 'package:tudo_app/common/text_input_dialog.dart';
import 'package:tudo_app/common/value_builders.dart';
import 'package:tudo_app/extensions.dart';

import 'list_provider.dart';

const blurSigma = 14.0;

enum ListAction { delete }

class ToDoListPage extends StatelessWidget {
  final String listId;
  final _listKey = GlobalKey();
  final _uncheckedListKey = GlobalKey();
  final _controller = ScrollController();

  ToDoListPage({Key? key, required this.listId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bottom = max(MediaQuery.of(context).viewInsets.bottom,
        MediaQuery.of(context).viewPadding.bottom);

    return GestureDetector(
      // Close keyboard when tapping a non-focusable area
      onTap: () => FocusScope.of(context).unfocus(),
      child: ValueStreamBuilder<ToDoListWithItems>(
        stream: context.listProvider.getList(listId),
        builder: (_, list) => Theme(
          data: context.theme.copyWith(
            colorScheme:
                context.theme.colorScheme.copyWith(primary: list.color),
            primaryColor: list.color,
            primaryTextTheme:
                TextTheme(headline6: TextStyle(color: list.color)),
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
            extendBody: true,
            appBar: TitleBar(
              brightness: context.theme.brightness,
              list: list,
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => editToDoList(
                      context, list, () => context.pop(ListAction.delete)),
                ),
              ],
            ),
            body: list.isEmpty
                ? const EmptyPage(text: 'Create a new to-do item below')
                : ToDoListView(
                    key: _listKey,
                    list: list,
                    checkedListKey: _uncheckedListKey,
                    controller: _controller,
                  ),
            bottomNavigationBar: Padding(
              padding: EdgeInsets.only(bottom: bottom),
              child: InputBar(
                // key: inputKey,
                onSubmitted: (value) => _addItem(context, list.id, value),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _addItem(BuildContext context, String listID, String name) {
    context.listProvider.createItem(listId, name);
    // list.add(value);
    // Future.delayed(
    //   const Duration(milliseconds: 400),
    //   () {
    //     final screenHeight =
    //         MediaQuery.of(_listKey.currentContext!).size.height;
    //     final uncheckedListHeight = ((_uncheckedListKey.currentContext!
    //             .findRenderObject()) as RenderBox)
    //         .size
    //         .height;
    //     final maxOffset = uncheckedListHeight;
    //     final minOffset =
    //         max<double>(0.0, uncheckedListHeight - screenHeight) + 200.0;
    //     final offset = _controller.offset.clamp(minOffset, maxOffset);
    //     _controller.animateTo(
    //       offset,
    //       duration: const Duration(milliseconds: 400),
    //       curve: Curves.fastOutSlowIn,
    //     );
    //   },
    // );
  }
}

class TitleBar extends StatelessWidget implements PreferredSizeWidget {
  final Brightness brightness;
  final ToDoList list;
  final List<Widget> actions;

  const TitleBar(
      {Key? key,
      required this.brightness,
      required this.list,
      required this.actions})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final primaryColor = context.theme.primaryColor;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: AppBar(
          systemOverlayStyle: context.theme.brightness == Brightness.light
              ? SystemUiOverlayStyle.dark
              : SystemUiOverlayStyle.light,
          foregroundColor: primaryColor,
          centerTitle: true,
          backgroundColor: primaryColor.withAlpha(20),
          elevation: 0,
          leading: InkResponse(
            onTap: () => context.pop(),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Positioned(
                  left: 8,
                  child: Icon(
                    Icons.arrow_back_ios,
                    size: 16,
                  ),
                ),
                Positioned(
                  right: 4,
                  child: Progress(
                    progress: list.doneCount,
                    total: list.itemCount,
                    color: list.color,
                  ),
                ),
              ],
            ),
          ),
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
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class InputBar extends StatefulWidget {
  final Function(String value) onSubmitted;

  const InputBar({Key? key, required this.onSubmitted}) : super(key: key);

  @override
  _InputBarState createState() => _InputBarState();
}

class _InputBarState extends State<InputBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    final primaryColor = context.theme.primaryColor;

    return Padding(
      padding: const EdgeInsets.all(10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(100),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            textCapitalization: TextCapitalization.sentences,
            cursorColor: primaryColor,
            style: context.theme.textTheme.subtitle1!
                .copyWith(color: primaryColor),
            decoration: InputDecoration(
              filled: true,
              fillColor: primaryColor.withAlpha(30),
              contentPadding: const EdgeInsets.all(20),
              hintText: 'Add Item',
              border: InputBorder.none,
              suffixIcon: IconButton(
                padding: const EdgeInsets.only(right: 10),
                icon: const Icon(Icons.add),
                onPressed: () => _onSubmitted(_controller.text),
              ),
            ),
            maxLines: 1,
            onSubmitted: (text) => _onSubmitted(text),
          ),
        ),
      ),
    );
  }

  void _onSubmitted(String text) {
    widget.onSubmitted(text);
    _controller.clear();
    _focusNode.requestFocus();
  }
}

class ToDoListView extends StatelessWidget {
  final ToDoListWithItems list;
  final Key checkedListKey;
  final ScrollController controller;

  const ToDoListView({
    Key? key,
    required this.list,
    required this.checkedListKey,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final uncheckedItems = list.items.where((item) => !item.done).toList();
    final checkedItems = list.items.where((item) => item.done).toList();

    return ListView(
      controller: controller,
      clipBehavior: Clip.none,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        ImplicitlyAnimatedReorderableList<ToDo>(
          key: checkedListKey,
          items: uncheckedItems,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          reorderDuration: const Duration(milliseconds: 200),
          areItemsTheSame: (oldItem, newItem) => oldItem == newItem,
          onReorderFinished: (_, from, to, __) {
            if (from == to) return;
            _swap(context, uncheckedItems[from], uncheckedItems[to]);
          },
          itemBuilder: (_, itemAnimation, item, __) => Reorderable(
            key: Key(item.id),
            builder: (context, animation, inDrag) => SizeFadeTransition(
              sizeFraction: 0.7,
              curve: Curves.easeInOut,
              animation: itemAnimation,
              child: _ListTile(
                item: item,
                onToggle: () => _toggle(context, item),
                onEdit: () => _editItem(context, item),
                onDelete: () => _deleteItem(context, item),
              ),
            ),
          ),
        ),
        ImplicitlyAnimatedList<ToDo>(
          items: [
            if (checkedItems.isNotEmpty)
              ToDo('header', '', false, 0, null, null),
            ...checkedItems,
          ],
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          areItemsTheSame: (oldItem, newItem) => oldItem == newItem,
          itemBuilder: (context, itemAnimation, item, i) => SizeFadeTransition(
            sizeFraction: 0.7,
            curve: Curves.easeInOut,
            animation: itemAnimation,
            child: item.id == 'header'
                ? _CompletedHeader(
                    color: list.color,
                    onClear: () => _clearCompleted(context),
                  )
                : _ListTile(
                    item: item,
                    onToggle: () => _toggle(context, item),
                    onEdit: () => _editItem(context, item),
                    onDelete: () => _deleteItem(context, item),
                  ),
          ),
        ),
      ],
    );
  }

  void _toggle(BuildContext context, ToDo toDo) =>
      context.listProvider.setDone(toDo.id, !toDo.done);

  void _editItem(BuildContext context, ToDo toDo) {
    showDialog<String>(
      context: context,
      builder: (context) => TextInputDialog(
        title: 'Edit Item',
        value: toDo.name,
        positiveLabel: 'Update',
        onSet: (value) => context.listProvider.setItemName(toDo.id, value),
      ),
    );
  }

  void _deleteItem(BuildContext context, ToDo toDo) {
    // Hide item while the list removal animation runs
    toDo.isDeleted = true;

    final listProvider = context.listProvider;
    listProvider.deleteItem(toDo.id);

    context.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('Deleted "${toDo.name}"'),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () => listProvider.undeleteItem(toDo.id),
        ),
      ),
    );
  }

  Future<void> _clearCompleted(BuildContext context) async {
    var checked = list.items.where((item) => item.done).toList();
    if (checked.isEmpty) return;

    var indexes =
        checked.map((e) => context.listProvider.deleteItem(e.id)).toList();

    // Insert in reverse order when undoing so the old indexes match
    checked = checked.reversed.toList();
    indexes = indexes.reversed.toList();
    final count = checked.length;

    context.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content:
            Text('Cleared $count completed ${count == 1 ? 'item' : 'items'}'),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () {
            for (var i = 0; i < checked.length; i++) {
              final item = checked[i];
              context.listProvider.undeleteItem(item.id);
            }
          },
        ),
      ),
    );
  }

  void _swap(BuildContext context, ToDo from, ToDo to) {
    final fromIndex = list.items.indexOf(from);
    final toIndex = list.items.indexOf(to);

    // Copy list
    final items = list.items.toList();
    final item = items.removeAt(fromIndex);
    items.insert(toIndex, item);
    context.listProvider.setItemOrder(items);
  }
}

class _ListTile extends StatelessWidget {
  final ToDo item;
  final Function() onToggle;
  final Function() onEdit;
  final Function() onDelete;

  const _ListTile({
    Key? key,
    required this.item,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: item.isDeleted ? 0 : 1,
      child: Dismissible(
        key: Key(item.id),
        background: Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: const Icon(
            Icons.delete,
            color: Colors.red,
          ),
        ),
        secondaryBackground: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: const Icon(
            Icons.delete,
            color: Colors.red,
          ),
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
        child: ListTile(
          leading: Checkbox(
            onChanged: (_) => onToggle(),
            value: item.done,
          ),
          title: Text(item.name),
          trailing: item.done ? null : const DragHandle(),
          onTap: () => onToggle(),
          onLongPress: onEdit,
        ),
      ),
    );
  }
}

class _CompletedHeader extends StatelessWidget {
  final Color color;
  final Function() onClear;

  const _CompletedHeader({Key? key, required this.color, required this.onClear})
      : super(key: key);

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
      padding: const EdgeInsets.only(left: 16, top: 8, right: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Completed',
              style: context.theme.textTheme.subtitle2!.copyWith(color: color),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: onClear,
          ),
        ],
      ),
    );
  }
}
