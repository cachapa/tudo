import 'package:flutter/material.dart';
import 'package:tudo_app/extensions.dart';

class TextInputDialog extends StatelessWidget {
  final String? title;
  final String? caption;
  final String positiveLabel;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;

  final TextEditingController _controller;

  TextInputDialog({
    Key? key,
    this.title,
    this.caption,
    this.positiveLabel = 'Set',
    required String value,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.sentences,
  })  : _controller = TextEditingController(text: value),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: title == null ? null : Text(title!),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            maxLines: 1,
            keyboardType: keyboardType,
            textCapitalization: textCapitalization,
            onSubmitted: (value) => _set(context, value),
          ),
          const SizedBox(height: 16),
          if (caption != null)
            Text(
              caption!,
              style: context.theme.textTheme.caption,
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

  void _set(BuildContext context, String value) => context.pop(value);
}
