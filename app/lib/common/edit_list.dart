import 'package:flutter/material.dart';
import 'package:tudo_app/extensions.dart';
import 'package:tudo_app/lists/list_provider.dart';

import 'color_selector.dart';

Future<bool?> editToDoList(BuildContext context, [ToDoList? list]) {
  return showModalBottomSheet<bool>(
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    isScrollControlled: true,
    context: context,
    builder: (context) => _EditListForm(
      list: list,
    ),
  );
}

class _EditListForm extends StatefulWidget {
  final ToDoList? list;

  const _EditListForm({Key? key, this.list}) : super(key: key);

  @override
  State<_EditListForm> createState() => _EditListFormState();
}

class _EditListFormState extends State<_EditListForm> {
  late final TextEditingController _textController;
  late final ColorController _colorController;

  bool get editMode => widget.list != null;

  String get name => _textController.text;

  Color get color => _colorController.color;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.list?.name);
    _colorController = ColorController(color: widget.list?.color);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: context.padding.bottom + keyboardInset + 8),
      child: Theme(
        data: context.theme.copyWith(
          colorScheme: context.theme.colorScheme.copyWith(primary: color),
          primaryColor: color,
        ),
        child: Builder(
          builder: (context) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                editMode ? t.editList : t.createList,
                style: context.theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _textController,
                textCapitalization: TextCapitalization.sentences,
                autofocus: !editMode,
                decoration: InputDecoration(
                  hintText: t.name,
                ),
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _create(context),
              ),
              const SizedBox(height: 20),
              ColorSelector(
                controller: _colorController,
                onColorSelected: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: name.isEmpty ? null : () => _create(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    (editMode ? t.update : t.create).toUpperCase(),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _create(BuildContext context) {
    if (name.isEmpty) return;

    if (editMode) {
      if (widget.list!.name != name) {
        context.listProvider.setName(widget.list!.id, name);
      }
      if (widget.list!.color != color) {
        context.listProvider.setColor(widget.list!.id, color);
      }
    } else {
      context.read<ListProvider>().createList(name, color);
    }

    context.pop(true);
  }
}
