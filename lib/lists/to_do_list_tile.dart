import 'package:flutter/material.dart';

import '../common/progress.dart';
import '../extensions.dart';
import 'list_provider.dart';

class ToDoListTile extends StatelessWidget {
  final ToDoList list;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;

  const ToDoListTile({
    super.key,
    required this.list,
    this.onTap,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 16, right: 8),
      leading: Progress(
        color: list.color,
        progress: list.doneCount,
        total: list.itemCount,
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
      trailing: IconButton(
        onPressed: onEdit,
        icon: Icon(Icons.adaptive.more_rounded),
      ),
      onTap: onTap,
    );
  }
}
