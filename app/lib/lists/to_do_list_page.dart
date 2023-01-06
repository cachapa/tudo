import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tudo_app/common/check.dart';
import 'package:tudo_app/common/edit_list.dart';
import 'package:tudo_app/common/empty_page.dart';
import 'package:tudo_app/common/icon_label.dart';
import 'package:tudo_app/common/popup_menu.dart';
import 'package:tudo_app/common/progress.dart';
import 'package:tudo_app/common/share_list.dart';
import 'package:tudo_app/common/text_input_dialog.dart';
import 'package:tudo_app/common/value_builders.dart';
import 'package:tudo_app/extensions.dart';

import 'list_provider.dart';
import 'manage_participants.dart';

const blurSigma = 14.0;

enum ListAction { delete }

class ToDoListPage extends StatelessWidget {
  final ToDoList list;
  final _bottomOfList = GlobalKey();

  ToDoListPage({super.key, required this.list});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final bottom = max(MediaQuery.of(context).viewInsets.bottom,
        MediaQuery.of(context).viewPadding.bottom);

    return GestureDetector(
      // Close keyboard when tapping a non-focusable area
      onTap: () => FocusScope.of(context).unfocus(),
      child: ValueStreamBuilder<ToDoListWithItems>(
        stream: context.listProvider.getList(list.id),
        initialData: ToDoListWithItems.fromList(list, []),
        errorWidget: Material(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                t.listUnavailable,
                style: context.theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              MaterialButton(
                child: Text(t.close),
                onPressed: () => context.pop(),
              ),
            ],
          ),
        ),
        builder: (_, list) => Theme(
          data: context.theme.copyWith(
            colorScheme:
                context.theme.colorScheme.copyWith(primary: list.color),
            primaryColor: list.color,
            primaryTextTheme:
                TextTheme(titleLarge: TextStyle(color: list.color)),
            primaryIconTheme: IconThemeData(color: list.color),
            iconTheme: IconThemeData(color: list.color),
            textSelectionTheme: TextSelectionThemeData(
              selectionHandleColor: list.color,
              cursorColor: list.color,
            ),
            checkboxTheme: CheckboxThemeData(
              fillColor: MaterialStateProperty.resolveWith<Color?>(
                  (Set<MaterialState> states) {
                if (states.contains(MaterialState.disabled)) {
                  return null;
                }
                if (states.contains(MaterialState.selected)) {
                  return list.color;
                }
                return null;
              }),
            ),
            radioTheme: RadioThemeData(
              fillColor: MaterialStateProperty.resolveWith<Color?>(
                  (Set<MaterialState> states) {
                if (states.contains(MaterialState.disabled)) {
                  return null;
                }
                if (states.contains(MaterialState.selected)) {
                  return list.color;
                }
                return null;
              }),
            ),
            switchTheme: SwitchThemeData(
              thumbColor: MaterialStateProperty.resolveWith<Color?>(
                  (Set<MaterialState> states) {
                if (states.contains(MaterialState.disabled)) {
                  return null;
                }
                if (states.contains(MaterialState.selected)) {
                  return list.color;
                }
                return null;
              }),
              trackColor: MaterialStateProperty.resolveWith<Color?>(
                  (Set<MaterialState> states) {
                if (states.contains(MaterialState.disabled)) {
                  return null;
                }
                if (states.contains(MaterialState.selected)) {
                  return list.color;
                }
                return null;
              }),
            ),
          ),
          child: Scaffold(
            extendBodyBehindAppBar: true,
            extendBody: true,
            appBar: TitleBar(
              list: list,
              actions: [
                IconButton(
                  tooltip: t.clearCompleted,
                  icon: const Icon(Icons.delete_sweep_outlined),
                  onPressed: list.doneCount == 0
                      ? null
                      : () => _clearCompleted(context, list.items),
                ),
                PopupMenu(
                  entries: [
                    PopupEntry(
                      Icons.share,
                      t.share,
                      () => shareToDoList(context, list),
                    ),
                    PopupEntry(
                      Icons.edit,
                      t.editList,
                      () => editToDoList(context, list),
                    ),
                    if (list.isShared)
                      PopupEntry(
                        Icons.supervised_user_circle,
                        t.participants,
                        () => editParticipants(context),
                      ),
                    PopupEntry(
                      Icons.exit_to_app,
                      t.leaveList,
                      () => context.pop(ListAction.delete),
                      context.theme.colorScheme.error,
                    ),
                  ],
                ),
              ],
            ),
            body: list.items.isEmpty
                ? EmptyPage(text: t.toDoListEmptyMessage)
                : ToDoListView(list: list, bottomOfListKey: _bottomOfList),
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

  void editParticipants(BuildContext context) =>
      manageParticipants(context, list.id);

  Future<void> _addItem(
      BuildContext context, String listID, String name) async {
    final itemId = await context.listProvider.createItem(list.id, name);

    // Scroll to bottom of list
    await Future.delayed(const Duration(milliseconds: 100));
    final itemContext = _bottomOfList.currentContext;
    if (itemContext != null) {
      Scrollable.ensureVisible(
        itemContext,
        duration: const Duration(milliseconds: 300),
        alignment: 0.90,
      );
    }
  }

  Future<void> _clearCompleted(BuildContext context, List<ToDo> items) async {
    var checked = items.where((item) => item.done).toList();
    if (checked.isEmpty) return;

    var indexes =
        checked.map((e) => context.listProvider.deleteItem(e.id)).toList();

    // Insert in reverse order when undoing so the old indexes match
    checked = checked.reversed.toList();
    indexes = indexes.reversed.toList();
    final count = checked.length;

    context.showSnackBar(
      context.t.itemsCleared(count),
      () {
        for (var i = 0; i < checked.length; i++) {
          final item = checked[i];
          context.listProvider.undeleteItem(item.id);
        }
      },
    );
  }
}

class TitleBar extends StatelessWidget implements PreferredSizeWidget {
  final ToDoListWithItems list;
  final List<Widget> actions;

  const TitleBar({Key? key, required this.list, required this.actions})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final primaryColor = context.theme.primaryColor;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: AppBar(
          systemOverlayStyle: SystemUiOverlayStyle(
              statusBarIconBrightness: context.theme.brightness.invert),
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
                  child: Hero(
                    tag: 'progress_${list.id}',
                    child: Progress(
                      progress: list.doneCount,
                      total: list.itemCount,
                      color: list.color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          title: Column(
            children: [
              Text(
                list.name,
                style: context.theme.textTheme.titleLarge,
              ),
              if (list.isShared)
                Text(
                  list.memberNames(context),
                  softWrap: false,
                  overflow: TextOverflow.fade,
                  style: context.theme.textTheme.bodyMedium!.copyWith(
                      color: context.theme.textTheme.bodySmall!.color),
                ),
            ],
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
  State<InputBar> createState() => _InputBarState();
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
            style: context.theme.textTheme.titleMedium!
                .copyWith(color: primaryColor),
            decoration: InputDecoration(
              filled: true,
              fillColor: primaryColor.withAlpha(30),
              contentPadding: const EdgeInsets.all(20),
              hintText: context.t.addItem,
              border: InputBorder.none,
              suffixIcon: IconButton(
                padding: const EdgeInsets.only(right: 10),
                icon: const Icon(Icons.add),
                onPressed: _controller.text.isEmpty
                    ? null
                    : () => _onSubmitted(_controller.text),
              ),
            ),
            maxLines: 1,
            onChanged: (_) => setState(() {}),
            onSubmitted: (text) => _onSubmitted(text),
          ),
        ),
      ),
    );
  }

  void _onSubmitted(String text) {
    if (text.isEmpty) return;

    widget.onSubmitted(text);
    _controller.clear();
    _focusNode.requestFocus();
  }
}

class ToDoListView extends StatelessWidget {
  final ToDoListWithItems list;
  final GlobalKey bottomOfListKey;

  const ToDoListView(
      {super.key, required this.list, required this.bottomOfListKey});

  List<ToDo> get items => list.items;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      // padding: context.padding,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        const SliverSafeArea(
          bottom: false,
          sliver: SliverToBoxAdapter(),
        ),
        SliverReorderableList(
          itemCount: items.length,
          onReorder: (from, to) {
            // Fix buggy swap indexes
            if (from < to) to--;
            if (from == to) return;
            _swap(context, from, to);
          },
          itemBuilder: (context, i) => _ListTile(
            key: ValueKey(items[i].id),
            index: i,
            item: items[i],
            onToggle: () => _toggle(context, items[i]),
            onEdit: () => _editItem(context, items[i]),
            onDelete: () => _deleteItem(context, items[i]),
            isShared: list.isShared,
          ),
        ),
        SliverSafeArea(
          top: false,
          sliver: SliverToBoxAdapter(key: bottomOfListKey),
        ),
      ],
    );
  }

  void _toggle(BuildContext context, ToDo toDo) =>
      context.listProvider.setDone(toDo.id, !toDo.done);

  Future<void> _editItem(BuildContext context, ToDo toDo) async {
    final title = await showDialog<String>(
      context: context,
      builder: (context) => TextInputDialog(
        title: context.t.editItem,
        value: toDo.name,
        positiveLabel: context.t.update,
      ),
    );
    if (context.mounted && title != null) {
      await context.listProvider.setItemName(toDo.id, title);
    }
  }

  void _deleteItem(BuildContext context, ToDo toDo) {
    final listProvider = context.listProvider;
    listProvider.deleteItem(toDo.id);

    context.showSnackBar(
      context.t.itemDeleted(toDo.name),
      () => listProvider.undeleteItem(toDo.id),
    );
  }

  void _swap(BuildContext context, int from, int to) {
    final item = items.removeAt(from);
    items.insert(to, item);
    context.listProvider.setItemOrder(items);
  }
}

class _ListTile extends StatelessWidget {
  final int index;
  final ToDo item;
  final Function() onToggle;
  final Function() onEdit;
  final Function() onDelete;
  final bool isShared;

  const _ListTile({
    super.key,
    required this.index,
    required this.item,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
    required this.isShared,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
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
      onDismissed: (_) => onDelete(),
      child: Material(
        child: ListTile(
          leading: Check(
            checked: item.done,
            onChanged: onToggle,
          ),
          title: Text(item.name),
          subtitle: isShared && item.done
              ? IconLabel(
                  Icons.account_circle, item.doneBy ?? context.t.anonymous)
              : null,
          trailing: ReorderableDragStartListener(
            index: index,
            child: const Icon(Icons.drag_indicator),
          ),
          onTap: () => onToggle(),
          onLongPress: onEdit,
        ),
      ),
    );
  }
}
