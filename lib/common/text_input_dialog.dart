import 'package:flutter/material.dart';

class TextInputDialog extends StatelessWidget {
  final String? title;
  final String positiveLabel;
  final ValueChanged<String> onSet;
  final TextInputType? keyboardType;

  final TextEditingController _controller;

  TextInputDialog(
      {Key? key,
      this.title,
      this.positiveLabel = 'Set',
      required String value,
      required this.onSet,
      this.keyboardType})
      : _controller = TextEditingController(text: value),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: title == null ? null : Text(title!),
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
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'.toUpperCase()),
        ),
        ElevatedButton(
          style: ButtonStyle(elevation: MaterialStateProperty.all(0)),
          onPressed: () => _set(context, _controller.text),
          child: Text(positiveLabel.toUpperCase()),
        ),
      ],
    );
  }

  void _set(BuildContext context, String value) {
    onSet(value);
    Navigator.pop(context);
  }
}
