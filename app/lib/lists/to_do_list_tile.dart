import 'package:flutter/material.dart';
import 'package:tudo_app/common/progress.dart';
import 'package:tudo_app/extensions.dart';

import 'list_provider.dart';

class ToDoListTile extends StatelessWidget {
  final int index;
  final ToDoList list;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const ToDoListTile({
    super.key,
    required this.index,
    required this.list,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      child: ListTile(
        leading: Hero(
          tag: 'progress_${list.id}',
          child: Progress(
            color: list.color,
            progress: list.doneCount,
            total: list.itemCount,
          ),
        ),
        title: Text(
          list.name,
          style: context.theme.textTheme.titleLarge,
        ),
        subtitle: list.isShared
            ? Text(
                list.memberNames(context),
                softWrap: false,
                overflow: TextOverflow.fade,
              )
            : null,
        trailing: ReorderableDragStartListener(
          index: index,
          child: const Icon(Icons.drag_indicator),
        ),
        onTap: onTap,
        onLongPress: onLongPress,
      ),
    );
  }
}
