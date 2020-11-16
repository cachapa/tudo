import 'package:flutter/material.dart';

class TextInputDialog extends StatelessWidget {
  final String title;
  final ValueChanged<String> onSet;
  final TextInputType keyboardType;

  final TextEditingController _controller;

  TextInputDialog(
      {Key key, this.title, String value, this.onSet, this.keyboardType})
      : _controller = TextEditingController(text: value),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: title == null ? null : Text(title),
      content: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              autofocus: true,
              maxLines: 1,
              keyboardType: keyboardType,
              onSubmitted: (value) => _set(context, value),
            ),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          child: Text('Cancel'.toUpperCase()),
          onPressed: () => Navigator.pop(context),
        ),
        ElevatedButton(
          style: ButtonStyle(elevation: MaterialStateProperty.all(0)),
          child: Text('Set'.toUpperCase()),
          onPressed: () => _set(context, _controller.text),
        ),
      ],
    );
  }

  void _set(BuildContext context, String value) {
    onSet(value);
    Navigator.pop(context);
  }
}
