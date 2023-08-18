import 'dart:math';
import 'dart:ui';

import 'package:animated_list_plus/animated_list_plus.dart';
import 'package:flutter/material.dart';

import '../common/appbars.dart';
import '../common/check.dart';
import '../common/dialogs.dart';
import '../common/icon_label.dart';
import '../common/lists.dart';
import '../common/progress.dart';
import '../common/value_builders.dart';
import '../extensions.dart';
import '../registry.dart';
import 'list_provider.dart';

enum ListAction { delete }

class ToDoListPage extends StatelessWidget {
  final ToDoList list;
  final _controller = ScrollController();

  late final _stream = Registry.listProvider.getList(list.id);

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
        stream: _stream,
        initialValue: ToDoListWithItems.fromList(list, []),
        errorBuilder: (context, error) => Material(
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
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: list.doneCount == 0 ? 0 : 1,
                  child: IconButton(
                    tooltip: list.doneCount == 0 ? null : t.clearCompleted,
                    icon: const Icon(Icons.delete_sweep_outlined),
                    onPressed: () => _clearCompleted(context, list.items),
                  ),
                ),
                IconButton(
                  tooltip: t.editList,
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () => _clearCompleted(context, list.items),
                ),
              ],
            ),
            body: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: list.items.isEmpty
                  ? _EmptyPage()
                  : ToDoListView(
                      controller: _controller,
                      list: list,
                    ),
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

  Future<void> _addItem(
      BuildContext context, String listID, String name) async {
    await Registry.listProvider.createItem(list.id, name);

    // Wait for entry animation to finish
    await Future.delayed(const Duration(milliseconds: 400));
    // Scroll to bottom of list
    await _controller.animateTo(
      _controller.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.fastOutSlowIn,
    );
  }

  Future<void> _clearCompleted(BuildContext context, List<ToDo> items) async {
    var checked = items.where((item) => item.done).toList();
    if (checked.isEmpty) return;

    var indexes =
        checked.map((e) => Registry.listProvider.deleteItem(e.id)).toList();

    // Insert in reverse order when undoing so the old indexes match
    checked = checked.reversed.toList();
    indexes = indexes.reversed.toList();
    final count = checked.length;

    context.showSnackBar(
      context.t.itemsCleared(count),
      () {
        for (var i = 0; i < checked.length; i++) {
          final item = checked[i];
          Registry.listProvider.undeleteItem(item.id);
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

    return BlurredAppBar(
      foregroundColor: primaryColor,
      backgroundColor: primaryColor.withAlpha(20),
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
              style: context.theme.textTheme.bodyMedium!
                  .copyWith(color: context.theme.textTheme.bodySmall!.color),
            ),
        ],
      ),
      actions: actions,
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

  String get text => _controller.text.trim();

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
                onPressed: text.isEmpty ? null : () => _onSubmitted(text),
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

class ToDoListView extends StatefulWidget {
  final ScrollController? controller;
  final ToDoListWithItems list;

  const ToDoListView({super.key, this.controller, required this.list});

  @override
  State<ToDoListView> createState() => _ToDoListViewState();
}

class _ToDoListViewState extends State<ToDoListView> {
  String? _deletingItemId;

  List<ToDo> get items => widget.list.items;

  @override
  Widget build(BuildContext context) {
    return AnimatedReorderableListBuilder(
      controller: widget.controller,
      items,
      onReorder: (from, to) => _swap(context, from, to),
      builder: (context, i, item) => _ListTile(
        item: item,
        onToggle: () => _toggle(context, item),
        onEdit: () => _editItem(context, item),
        onDelete: () => _deleteItem(context, item),
        isShared: widget.list.isShared,
        isDeleted: item.id == _deletingItemId,
      ),
    );
  }

  void _toggle(BuildContext context, ToDo toDo) =>
      Registry.listProvider.setDone(toDo.id, !toDo.done);

  Future<void> _editItem(BuildContext context, ToDo toDo) async {
    final title = await showDialog<String>(
      context: context,
      builder: (context) => TextInputDialog(
        title: context.t.editItem,
        value: toDo.name,
        info: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (toDo.createdBy != null)
              IconLabel(
                Icons.create_rounded,
                toDo.createdBy!,
                style: context.theme.textTheme.bodySmall,
              ),
            if (toDo.doneBy != null)
              IconLabel(
                Icons.check_box_rounded,
                toDo.doneBy!,
                style: context.theme.textTheme.bodySmall,
              ),
          ],
        ),
        positiveLabel: context.t.update,
      ),
    );
    if (context.mounted && title != null) {
      await Registry.listProvider.setItemName(toDo.id, title);
    }
  }

  void _deleteItem(BuildContext context, ToDo toDo) {
    setState(() => _deletingItemId = toDo.id);
    final listProvider = Registry.listProvider;
    listProvider.deleteItem(toDo.id);

    context.showSnackBar(
      context.t.itemDeleted(toDo.name),
      () {
        _deletingItemId = null;
        listProvider.undeleteItem(toDo.id);
      },
    );
  }

  void _swap(BuildContext context, int from, int to) {
    final item = items.removeAt(from);
    items.insert(to, item);
    Registry.listProvider.setItemOrder(items);
  }
}

class _ListTile extends StatelessWidget {
  final ToDo item;
  final Function() onToggle;
  final Function() onEdit;
  final Function() onDelete;
  final bool isShared;
  final bool isDeleted;

  const _ListTile({
    required this.item,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
    required this.isShared,
    required this.isDeleted,
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
      confirmDismiss: (direction) async {
        // Avoid conflicts between Dismissible and list animations.
        // Calls the delete method to remove the item from the database
        // but returns false as if the dismiss gesture was cancelled avoiding
        // the Dismissible deletion animation.
        onDelete();
        return false;
      },
      child: Opacity(
        opacity: isDeleted ? 0 : 1,
        child: Container(
          color: context.theme.canvasColor,
          child: ListTile(
            leading: Check(
              checked: item.done,
              onChanged: onToggle,
            ),
            title: Text(item.name),
            trailing: const Handle(
              vibrate: true,
              child: Icon(Icons.drag_indicator),
            ),
            onTap: () => onToggle(),
            onLongPress: onEdit,
          ),
        ),
      ),
    );
  }
}

class _EmptyPage extends StatelessWidget {
  static const sigma = 16.0;
  static const size = 80.0;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        children: [
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
            child: const Icon(
              Icons.check_rounded,
              size: size,
            ),
          ),
          const Icon(
            Icons.check_rounded,
            size: size,
          )
        ],
      ),
    );
  }
}
