import 'package:flutter/material.dart';
import 'package:implicitly_animated_reorderable_list/implicitly_animated_reorderable_list.dart';
import 'package:implicitly_animated_reorderable_list/transitions.dart';
import 'package:tudo_app/common/appbars.dart';
import 'package:tudo_app/common/avatar.dart';
import 'package:tudo_app/common/value_builders.dart';
import 'package:tudo_app/contacts/contact_provider.dart';
import 'package:tudo_app/extensions.dart';
import 'package:tudo_app/lists/list_provider.dart';

class ManageParticipantsPage extends StatelessWidget {
  final String listId;

  const ManageParticipantsPage({Key? key, required this.listId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final t = context.t;

    return ValueStreamBuilder<ToDoList>(
      stream: context.listProvider.getList(listId),
      builder: (_, list) => Theme(
        data: context.theme.copyWith(
          colorScheme: context.theme.colorScheme.copyWith(primary: list.color),
          primaryColor: list.color,
        ),
        child: Scaffold(
          appBar: DiscreteAppBar(
            title: t.participants,
            subtitle: list.name,
          ),
          body: ImplicitlyAnimatedList<User>(
            items: list.members,
            areItemsTheSame: (a, b) => a.id == b.id,
            itemBuilder: (_, itemAnimation, user, __) => SizeFadeTransition(
              sizeFraction: 0.7,
              curve: Curves.easeInOut,
              animation: itemAnimation,
              child: ListTile(
                leading: Avatar(),
                title: Text(user.nameOr(context)),
                subtitle: user.isCurrentUser ? Text(t.you) : null,
                trailing: user.isCurrentUser
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        color: context.theme.errorColor,
                        onPressed: () => _removeUser(context, user),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _removeUser(BuildContext context, User user) async {
    final t = context.t;

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
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
              style: TextStyle(color: context.theme.errorColor),
            ),
            onPressed: () => context.pop(true),
          ),
        ],
      ),
    );

    if (result ?? false) {
      final listProvider = context.listProvider;
      await listProvider.removeUser(user.id, listId);

      context.showSnackBar(
        context.t.userRemoved(user.name),
        () => listProvider.undoRemoveUser(user.id, listId),
      );
    }
  }
}
