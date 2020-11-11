import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tudo_client/data/list_manager.dart';

void createToDoList(BuildContext context, [ToDoList list]) async {
  showModalBottomSheet<String>(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(14))),
      isScrollControlled: true,
      context: context,
      builder: (context) {
        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: _EditListForm(toDoList: list),
        );
      });
}

class _EditListForm extends StatelessWidget {
  final _textController;
  final _colorController;

  final ToDoList toDoList;

  bool get editMode => toDoList != null;

  _EditListForm({Key key, this.toDoList})
      : _textController = TextEditingController(text: toDoList?.name),
        _colorController = ColorController(color: toDoList?.color),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 24, right: 24, top: 24),
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
            children: [
              TextButton(
                child: Text('Cancel'.toUpperCase()),
                onPressed: () => Navigator.pop(context),
              ),
              ElevatedButton(
                style: ButtonStyle(elevation: MaterialStateProperty.all(0)),
                child: Text((editMode ? 'Update' : 'Create').toUpperCase()),
                onPressed: () => _create(context),
              ),
            ],
          )
        ],
      ),
    );
  }

  _create(BuildContext context) {
    final name = _textController.text;
    final color = _colorController.color;

    if (name.isEmpty) return;

    if (editMode) {
      toDoList.name = name;
      toDoList.color = color;
    } else {
      Provider.of<ListManager>(context, listen: false).create(name, color);
    }

    Navigator.pop(context);
  }
}

class ColorController {
  Color color;

  ColorController({this.color});
}

class ColorSelector extends StatefulWidget {
  static const colors = [
    Colors.pink,
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
  void initState() {
    print(widget.controller.color);
    print(ColorSelector.colors.map((e) => Color(e.value)));
    if (widget.controller.color == null) {
      final i = Random().nextInt(ColorSelector.colors.length);
      widget.controller.color ??= ColorSelector.colors[i];
    }
    super.initState();
  }

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
    return FlatButton(
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
