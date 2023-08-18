import 'package:flutter/material.dart';

import '../common/avatar.dart';
import '../common/icon_label.dart';
import '../common/lists.dart';
import '../common/value_builders.dart';
import '../contacts/contact_provider.dart';
import '../extensions.dart';
import '../registry.dart';
import 'list_provider.dart';

Future<bool?> manageParticipants(BuildContext context, String listId) {
  return showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    isScrollControlled: true,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.5,
      maxChildSize: 0.5,
      expand: false,
      builder: (context, controller) =>
          _ManageParticipantsPage(controller: controller, listId: listId),
    ),
  );
}

class _ManageParticipantsPage extends StatelessWidget {
  final ScrollController controller;
  final String listId;

  const _ManageParticipantsPage(
      {Key? key, required this.controller, required this.listId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final t = context.t;

    return Scaffold(
      body: ValueStreamBuilder<ToDoList>(
        stream: Registry.listProvider.getList(listId),
        builder: (context, list) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 24, bottom: 16),
              child: Text(
                t.participants,
                style: context.theme.textTheme.titleLarge,
              ),
            ),
            Expanded(
              child: AnimatedListBuilder<Member>(
                list.members,
                controller: controller,
                padding: EdgeInsets.only(bottom: context.padding.bottom),
                builder: (context, i, user) => ListTile(
                  leading: Avatar(color: list.color),
                  title: Text(user.nameOr(context)),
                  subtitle: user.joinedAt != null
                      ? IconLabel(
                          Icons.person_add,
                          user.joinedAt!.toRelativeString(context),
                        )
                      : null,
                  trailing: user.isCurrentUser
                      ? Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: Text(t.you),
                        )
                      : IconButton(
                          icon: const Icon(Icons.close),
                          color: context.theme.colorScheme.error,
                          onPressed: () => _removeUser(context, user),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _removeUser(BuildContext context, User user) async {
    final t = context.t;

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog.adaptive(
        title: Text(t.removeConfirmation),
        content: Text(user.nameOr(context)),
        actions: [
          TextButton(
            child: Text(t.cancel.toUpperCase()),
            onPressed: () => context.pop(),
          ),
          TextButton(
            child: Text(
              t.remove.toUpperCase(),
              style: TextStyle(color: context.theme.colorScheme.error),
            ),
            onPressed: () => context.pop(true),
          ),
        ],
      ),
    );

    if (context.mounted && (result ?? false)) {
      final listProvider = Registry.listProvider;
      await listProvider.removeUser(user.id, listId);

      if (context.mounted) {
        context.showSnackBar(
          context.t.userRemoved(user.name),
          () => listProvider.undoRemoveUser(user.id, listId),
        );
      }
    }
  }
}
