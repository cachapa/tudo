import 'package:flutter/material.dart';
import 'package:tudo_app/extensions.dart';
import 'package:tudo_app/lists/list_provider.dart';

import 'share_list.dart';

Future<dynamic> editToDoList(BuildContext context,
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

  _EditListForm({Key? key, this.list, this.onDelete})
      : _textController = TextEditingController(text: list?.name),
        _colorController = ColorController(color: list?.color),
        super(key: key);

  @override
  Widget build(BuildContext context) {
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
            editMode ? 'Edit list' : 'Create list',
            style: Theme.of(context).textTheme.headline6,
            textAlign: TextAlign.center,
          ),
          TextField(
            controller: _textController,
            textCapitalization: TextCapitalization.sentences,
            autofocus: !editMode,
            decoration: const InputDecoration(labelText: 'Name'),
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
                child: const Text('OK'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _create(BuildContext context) {
    final name = _textController.text;
    final color = _colorController.color;

    if (name.isEmpty) return;

    if (editMode) {
      context.listProvider.setName(list!.id, name);
      context.listProvider.setColor(list!.id, color);
    } else {
      context.read<ListProvider>().createList(name, color);
    }

    context.pop();
  }

  void _share(BuildContext context) {
    context.pop();
    shareToDoList(context, list!);
  }

  void _delete(BuildContext context) {
    context.pop();
    onDelete!();
  }
}

const _colors = <Color>[
  Colors.purpleAccent,
  Colors.red,
  Colors.orange,
  Colors.green,
  Colors.blue,
  Colors.purple,
];

class ColorController {
  Color color;

  ColorController({Color? color}) : color = color ?? _colors.random;
}

class ColorSelector extends StatefulWidget {
  final ColorController controller;

  const ColorSelector({Key? key, required this.controller}) : super(key: key);

  @override
  _ColorSelectorState createState() => _ColorSelectorState();
}

class _ColorSelectorState extends State<ColorSelector> {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: _colors
          .map(
            (color) => ColorButton(
              color: color,
              selected: color.value == widget.controller.color.value,
              onPressed: () => setState(() => widget.controller.color = color),
            ),
          )
          .toList(),
    );
  }
}

class ColorButton extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onPressed;

  const ColorButton({
    Key? key,
    required this.color,
    required this.selected,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialButton(
      elevation: selected ? null : 0,
      minWidth: 40,
      height: 40,
      color: color,
      shape: const CircleBorder(),
      onPressed: onPressed,
      child: Icon(
        Icons.check,
        size: 18,
        color: selected ? Theme.of(context).dialogBackgroundColor : color,
      ),
    );
  }
}
