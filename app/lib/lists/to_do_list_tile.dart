import 'package:flutter/material.dart';
import 'package:tudo_app/common/drag_handler.dart';
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
      subtitle: list.isShared ? _ListParticipants(list) : null,
      trailing: const DragHandle(),
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}

class _ListParticipants extends StatelessWidget {
  final ToDoList list;

  const _ListParticipants(this.list, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.supervised_user_circle,
          size: 14,
          color: context.theme.textTheme.caption!.color,
        ),
        const SizedBox(width: 4),
        Text(
          list.members
              .where((e) => !e.isCurrentUser)
              .map((e) => e.nameOr(context))
              .join(' • '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
