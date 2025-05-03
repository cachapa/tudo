import 'dart:math';
import 'dart:ui';

import 'package:animated_list_plus/transitions.dart';
import 'package:flutter/material.dart';

import '../common/appbars.dart';
import '../common/check.dart';
import '../common/dialogs.dart';
import '../common/edit_list.dart';
import '../common/icon_label.dart';
import '../common/lists.dart';
import '../common/progress.dart';
import '../common/value_builders.dart';
import '../extensions.dart';
import '../registry.dart';
import 'list_provider.dart';

class ToDoListPage extends StatelessWidget {
  final Function() onClose;
  final ToDoList list;
  final _listKey = GlobalKey();

  late final _stream = Registry.listProvider.getList(list.id);

  ToDoListPage({super.key, required this.onClose, required this.list});

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
        errorBuilder: (_, __) => const SizedBox(),
        builder: (_, list) => Theme(
          data: context.theme.copyWith(
            colorScheme:
                context.theme.colorScheme.copyWith(primary: list.color),
            primaryColor: list.color,
            primaryTextTheme:
                TextTheme(titleLarge: TextStyle(color: list.color)),
          ),
          child: Scaffold(
            extendBodyBehindAppBar: true,
            extendBody: true,
            appBar: TitleBar(
              onClose: onClose,
              list: list,
              actions: [
                IconButton(
                  tooltip: t.deletedItems,
                  icon: const Icon(Icons.restore_rounded),
                  onPressed: () => _showDeletedItems(context),
                ),
                IconButton(
                  tooltip: t.editList,
                  icon: const Icon(Icons.tune_rounded),
                  onPressed: () => _editList(context),
                ),
              ],
            ),
            body: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: list.items.isEmpty
                  ? _EmptyPage()
                  : ToDoListView(
                      list: list,
                      toDoListKey: _listKey,
                    ),
            ),
            bottomNavigationBar: Padding(
              padding: EdgeInsets.only(bottom: bottom),
              child: InputBar(
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
    await Future.delayed(longDuration);
    // Scroll to bottom of list
    final dividerContext = _listKey.currentContext;
    if (context.mounted && dividerContext != null) {
      await Scrollable.ensureVisible(
        dividerContext,
        duration: mediumDuration,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      );
    }
  }

  Future<void> _showDeletedItems(BuildContext context) => showDialog(
        context: context,
        barrierColor: Colors.transparent,
        builder: (context) => _RestoreItemsDialog(list: list),
      );

  Future<void> _editList(BuildContext context) => editToDoList(context, list);
}

class _RestoreItemsDialog extends StatelessWidget {
  const _RestoreItemsDialog({required this.list});

  final ToDoList list;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: context.padding.add(const EdgeInsets.fromLTRB(12, 64, 12, 80)),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Material(
          color: list.color.withAlpha(25),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  context.t.deletedItems,
                  style: context.theme.textTheme.titleLarge,
                ),
              ),
              const Divider(),
              Expanded(
                child: ValueStreamBuilder<List<ToDo>>(
                  stream: Registry.listProvider.getDeletedTodos(list.id),
                  emptyBuilder: (_) =>
                      Center(child: Text(context.t.noDeletedItems)),
                  builder: (_, items) {
                    return AnimatedListBuilder(
                      items,
                      builder: (_, i, item) => ListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        leading: Check(
                          checked: item.done,
                          disabled: true,
                        ),
                        title: Text(item.name),
                        trailing: IconButton(
                          tooltip: context.t.restore,
                          color: list.color,
                          onPressed: () =>
                              Registry.listProvider.undeleteItem(item.id),
                          icon: const Icon(Icons.restore_rounded),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TitleBar extends StatelessWidget implements PreferredSizeWidget {
  final ToDoListWithItems list;
  final List<Widget> actions;
  final VoidCallback onClose;

  const TitleBar(
      {super.key,
      required this.list,
      required this.actions,
      required this.onClose});

  @override
  Widget build(BuildContext context) {
    final primaryColor = context.theme.primaryColor;

    return BlurredAppBar(
      foregroundColor: primaryColor,
      backgroundColor: primaryColor.withAlpha(20),
      leading: InkResponse(
        onTap: onClose,
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Positioned(
              left: 8,
              child: Icon(
                Icons.arrow_back_ios_rounded,
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

  const InputBar({super.key, required this.onSubmitted});

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
                color: primaryColor,
                padding: const EdgeInsets.only(right: 10),
                icon: const Icon(Icons.add_rounded),
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
  final ToDoListWithItems list;
  final GlobalKey toDoListKey;

  const ToDoListView({
    super.key,
    required this.list,
    required this.toDoListKey,
  });

  @override
  State<ToDoListView> createState() => _ToDoListViewState();
}

class _ToDoListViewState extends State<ToDoListView> {
  String? _deletingItemId;

  late List<ToDo> toDoItems;
  late List<ToDo> doneItems;

  @override
  Widget build(BuildContext context) {
    toDoItems = widget.list.items.where((e) => !e.done).toList();
    doneItems = widget.list.items.where((e) => e.done).toList()
      ..sort((a, b) => a.doneAt != null && b.doneAt != null
          ? b.doneAt!.compareTo(a.doneAt!)
          : a.position.compareTo(b.position));

    return SafeArea(
      child: SingleChildScrollView(
        clipBehavior: Clip.none,
        child: Column(
          children: [
            AnimatedReorderableListBuilder(
              toDoItems,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              onReorder: _swap,
              builder: (context, i, item) => item.id == _deletingItemId
                  ? const SizedBox.shrink()
                  : _ListTile(
                      item: item,
                      onToggle: () => _toggle(context, item),
                      onEdit: () => _editItem(context, item),
                      onDelete: () => _deleteItem(context, item),
                    ),
            ),
            AnimatedSwitcher(
              key: widget.toDoListKey,
              duration: mediumDuration,
              transitionBuilder: (child, animation) => SizeFadeTransition(
                animation: animation,
                child: child,
              ),
              child: widget.list.doneCount == 0
                  ? const SizedBox.shrink()
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 16, right: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(context.t.completed,
                                  style: context.theme.textTheme.titleMedium!
                                      .copyWith(
                                          color: context.theme.primaryColor)),
                              IconButton(
                                color: context.theme.primaryColor,
                                onPressed: () => _clearCompleted(context),
                                icon: const Icon(Icons.delete_sweep_rounded),
                                tooltip: context.t.clearCompleted,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          color: context.theme.primaryColor,
                          height: 2,
                          margin: const EdgeInsets.only(top: 8),
                        ),
                      ],
                    ),
            ),
            AnimatedListBuilder(
              doneItems,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              builder: (context, i, item) => item.id == _deletingItemId
                  ? const SizedBox.shrink()
                  : _ListTile(
                      item: item,
                      onToggle: () => _toggle(context, item),
                      onEdit: () => _editItem(context, item),
                      onDelete: () => _deleteItem(context, item),
                    ),
            ),
          ],
        ),
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

  void _swap(int from, int to) {
    final item = toDoItems.removeAt(from);
    toDoItems.insert(to, item);
    Registry.listProvider.setItemOrder(toDoItems);
  }

  void _deleteItem(BuildContext context, ToDo toDo) {
    _deletingItemId = toDo.id;
    final listProvider = Registry.listProvider;
    listProvider.deleteItem(toDo.id);

    // Hack: reset _deletingItemId after the delete animation has finished.
    // This works around the item would remaining invisible when restored.
    Future.delayed(longDuration, () => _deletingItemId = null);
  }

  Future<void> _clearCompleted(BuildContext context) async {
    if (doneItems.isEmpty) return;

    // Copy deleted ids in case the user wants to undo the operation
    final deleted = doneItems.map((e) => e.id);

    await Registry.listProvider.deleteCompleted(widget.list.id);

    if (!context.mounted) return;
    context.showSnackBar(
      context.t.itemsCleared(deleted.length),
      () => Registry.listProvider.undeleteItems(deleted),
    );
  }
}

class _ListTile extends StatelessWidget {
  final ToDo item;
  final Function() onToggle;
  final Function() onEdit;
  final Function() onDelete;

  const _ListTile({
    required this.item,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(item.id),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Icon(
          Icons.delete_outline_rounded,
          color: context.theme.canvasColor,
        ),
      ),
      secondaryBackground: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Icon(
          Icons.delete_outline_rounded,
          color: context.theme.canvasColor,
        ),
      ),
      onDismissed: (direction) => onDelete(),
      child: Container(
        color: context.theme.canvasColor,
        child: ListTile(
          contentPadding: const EdgeInsets.only(left: 16, right: 8),
          leading: Check(
            key: ValueKey('${item.id}${item.done}'),
            checked: item.done,
          ),
          title: Text(item.name),
          trailing: IconButton(
            onPressed: onEdit,
            icon: Icon(
              Icons.adaptive.more_rounded,
              color: context.theme.disabledColor,
            ),
          ),
          onTap: () => onToggle(),
          // onLongPress: onEdit,
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
            child: Icon(
              Icons.check_rounded,
              size: size,
              color: context.theme.primaryColor,
            ),
          ),
          Icon(
            Icons.check_rounded,
            size: size,
            color: context.theme.primaryColor,
          )
        ],
      ),
    );
  }
}
