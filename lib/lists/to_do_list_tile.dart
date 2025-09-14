import 'package:flutter/material.dart';

import '../common/progress.dart';
import '../extensions.dart';
import 'list_provider.dart';

class ToDoListTile extends StatelessWidget {
  final ToDoList list;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;

  const ToDoListTile({
    super.key,
    required this.list,
    required this.isSelected,
    this.onTap,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      selected: isSelected,
      selectedTileColor: list.color.withAlpha(25),
      tileColor: context.theme.canvasColor,
      contentPadding: const EdgeInsets.only(left: 16, right: 8),
      leading: Progress(
        color: list.color,
        progress: list.doneCount,
        total: list.itemCount,
      ),
      title: Text(list.name, style: context.theme.textTheme.titleLarge),
      subtitle: list.isShared
          ? Text(
              list.memberNames(context),
              softWrap: false,
              overflow: TextOverflow.fade,
            )
          : null,
      trailing: IconButton(
        onPressed: onEdit,
        icon: Icon(Icons.adaptive.more_rounded),
      ),
      onTap: onTap,
    );
  }
}
