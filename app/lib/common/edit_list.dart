import 'package:flutter/material.dart';
import 'package:tudo_app/extensions.dart';
import 'package:tudo_app/lists/list_provider.dart';

import 'color_selector.dart';
import 'share_list.dart';

Future<bool?> editToDoList(BuildContext context,
    [ToDoList? list, Function()? onDelete]) {
  return showModalBottomSheet<bool>(
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14))),
    isScrollControlled: true,
    context: context,
    builder: (context) => _EditListForm(
      list: list,
      onDelete: onDelete,
    ),
  );
}

class _EditListForm extends StatelessWidget {
  final TextEditingController _textController;
  final ColorController _colorController;

  final ToDoList? list;
  final Function()? onDelete;

  bool get editMode => list != null;

  String get name => _textController.text;

  Color get color => _colorController.color;

  _EditListForm({Key? key, this.list, this.onDelete})
      : _textController = TextEditingController(text: list?.name),
        _colorController = ColorController(color: list?.color),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: context.padding.bottom + keyboardInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            editMode ? t.editList : t.createList,
            style: Theme.of(context).textTheme.headline6,
            textAlign: TextAlign.center,
          ),
          TextField(
            controller: _textController,
            textCapitalization: TextCapitalization.sentences,
            autofocus: !editMode,
            decoration: InputDecoration(labelText: t.name),
            onSubmitted: (_) => _create(context),
          ),
          const SizedBox(height: 20),
          ColorSelector(controller: _colorController),
          const SizedBox(height: 20),
          ButtonBar(
            mainAxisSize: MainAxisSize.max,
            alignment: MainAxisAlignment.spaceBetween,
            children: [
              if (!editMode) Container(),
              if (editMode)
                IconButton(
                  icon: const Icon(
                    Icons.delete,
                    color: Colors.red,
                  ),
                  onPressed: () => _delete(context),
                ),
              if (editMode)
                IconButton(
                  icon: Icon(
                    Icons.share,
                    color: context.theme.primaryColor,
                  ),
                  onPressed: () => _share(context),
                ),
              MaterialButton(
                minWidth: 48,
                height: 48,
                color: context.theme.primaryColor,
                shape: const CircleBorder(),
                onPressed: () => _create(context),
                child: Text(t.ok.toUpperCase()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _create(BuildContext context) {
    if (name.isEmpty) return;

    if (editMode) {
      if (list!.name != name) {
        context.listProvider.setName(list!.id, name);
      }
      if (list!.color != color) {
        context.listProvider.setColor(list!.id, color);
      }
    } else {
      context.read<ListProvider>().createList(name, color);
    }

    context.pop(true);
  }

  void _share(BuildContext context) {
    context.pop(false);
    shareToDoList(context, list!);
  }

  void _delete(BuildContext context) {
    context.pop(false);
    onDelete!();
  }
}
