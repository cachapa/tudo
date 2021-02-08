import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tudo_client/list_manager/list_provider.dart';
import 'package:tudo_client/extensions.dart';

import 'share_list.dart';

editToDoList(BuildContext context, [ToDoList list, Function() onDelete]) {
  return showModalBottomSheet(
    shape: RoundedRectangleBorder(
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
  final _textController;
  final _colorController;

  final ToDoList list;
  final Function() onDelete;

  bool get editMode => list != null;

  _EditListForm({Key key, this.list, this.onDelete})
      : _textController = TextEditingController(text: list?.name),
        _colorController = ColorController(color: list?.color),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(24),
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
            autofocus: true,
            decoration: InputDecoration(labelText: 'Name'),
            onSubmitted: (_) => _create(context),
          ),
          SizedBox(height: 20),
          ColorSelector(controller: _colorController),
          SizedBox(height: 20),
          ButtonBar(
            mainAxisSize: MainAxisSize.max,
            alignment: MainAxisAlignment.spaceBetween,
            children: [
              if (!editMode) Container(),
              if (editMode)
                IconButton(
                  icon: Icon(
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
                shape: CircleBorder(),
                onPressed: () => _create(context),
                child: Text('OK'),
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
      list.name = name;
      list.color = color;
    } else {
      context.read<ListProvider>().create(name, color);
    }

    context.pop();
  }

  void _share(BuildContext context) {
    context.pop();
    shareToDoList(context, list);
  }

  void _delete(BuildContext context) {
    context.pop();
    onDelete();
  }
}

class ColorController {
  Color color;

  ColorController({this.color}) {
    if (color == null) {
      final i = Random().nextInt(ColorSelector.colors.length);
      color = ColorSelector.colors[i];
    }
  }
}

class ColorSelector extends StatefulWidget {
  static const colors = [
    Colors.purpleAccent,
    Colors.red,
    Colors.orange,
    Colors.green,
    Colors.blue,
    Colors.purple,
  ];

  final ColorController controller;

  const ColorSelector({Key key, @required this.controller}) : super(key: key);

  @override
  _ColorSelectorState createState() => _ColorSelectorState();
}

class _ColorSelectorState extends State<ColorSelector> {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: ColorSelector.colors
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
    Key key,
    @required this.color,
    @required this.selected,
    @required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialButton(
      elevation: selected ? null : 0,
      minWidth: 40,
      height: 40,
      color: color,
      shape: CircleBorder(),
      onPressed: onPressed,
      child: Icon(
        Icons.check,
        size: 18,
        color: selected ? Theme.of(context).dialogBackgroundColor : color,
      ),
    );
  }
}
