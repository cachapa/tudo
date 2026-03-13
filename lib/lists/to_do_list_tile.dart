import 'package:animated_list_plus/animated_list_plus.dart';
import 'package:flutter/material.dart';

import '../common/check.dart';
import '../extensions.dart';
import 'list_provider.dart';

class ToDoListTile extends StatelessWidget {
  final ToDo item;
  final Function() onToggle;
  final Function() onEdit;
  final Function() onDelete;

  const ToDoListTile({
    super.key,
    required this.item,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(item.id),
      background: _DeletePlaceholder(alignment: Alignment.centerLeft),
      secondaryBackground: _DeletePlaceholder(alignment: Alignment.centerRight),
      onDismissed: (direction) => onDelete(),
      child: _ToDoListTile(item: item, onToggle: onToggle, onEdit: onEdit),
    );
  }
}

class _ToDoListTile extends StatelessWidget {
  final ToDo item;
  final Function() onToggle;
  final Function() onEdit;

  const _ToDoListTile({
    required this.item,
    required this.onToggle,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: Check(
        key: ValueKey('${item.id}${item.done}'),
        checked: item.done,
      ),
      title: Text(item.name),
      trailing: item.done
          ? null
          : Handle(
              vibrate: true,
              child: Icon(
                Icons.drag_handle_rounded,
                color: context.theme.colorScheme.outlineVariant,
              ),
            ),
      onTap: onToggle,
      onLongPress: onEdit,
    );
  }
}

class _DeletePlaceholder extends StatelessWidget {
  final Alignment alignment;

  const _DeletePlaceholder({required this.alignment});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.theme.colorScheme.error,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      alignment: alignment,
      child: Icon(
        Icons.delete_outline_rounded,
        color: context.theme.colorScheme.onError,
      ),
    );
  }
}
