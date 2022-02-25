import 'package:flutter/material.dart';
import 'package:tudo_app/common/drag_handler.dart';
import 'package:tudo_app/common/icon_label.dart';
import 'package:tudo_app/common/progress.dart';
import 'package:tudo_app/extensions.dart';

import 'list_provider.dart';

class ToDoListTile extends StatelessWidget {
  final ToDoList list;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const ToDoListTile(
      {Key? key, required this.list, this.onTap, this.onLongPress})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Hero(
        tag: 'progress_${list.id}',
        child: Progress(
          color: list.color,
          progress: list.doneCount,
          total: list.itemCount,
        ),
      ),
      title: Hero(
        tag: 'name_${list.id}',
        child: Text(
          list.name,
          style: context.theme.textTheme.headline6,
        ),
      ),
      subtitle: list.isShared
          ? IconLabel(
              Icons.supervised_user_circle,
              list.members
                  .where((e) => !e.isCurrentUser)
                  .map((e) => e.nameOr(context))
                  .join(' • '),
            )
          : null,
      trailing: const DragHandle(),
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}
