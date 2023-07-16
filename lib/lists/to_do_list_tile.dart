import 'package:animated_list_plus/animated_list_plus.dart';
import 'package:flutter/material.dart';

import '../common/progress.dart';
import '../extensions.dart';
import 'list_provider.dart';

class ToDoListTile extends StatelessWidget {
  final ToDoList list;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const ToDoListTile({
    super.key,
    required this.list,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
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
      trailing: const Handle(
        vibrate: true,
        child: Icon(Icons.drag_indicator),
      ),
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}
