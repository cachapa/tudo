import 'package:flutter/material.dart';

import '../extensions.dart';

class TextInputDialog extends StatelessWidget {
  final String? title;
  final String? caption;
  final String? hint;
  final bool showClearButton;
  final Widget? info;
  final String positiveLabel;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;

  final TextEditingController _controller;

  String get text => _controller.text.trim();

  TextInputDialog({
    Key? key,
    this.title,
    this.caption,
    this.hint,
    this.showClearButton = false,
    this.info,
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
            decoration: InputDecoration(
              hintText: hint,
              suffixIcon: showClearButton
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => _controller.clear(),
                    )
                  : null,
            ),
            onSubmitted: (value) => context.pop(text),
          ),
          const SizedBox(height: 16),
          if (caption != null)
            Text(
              caption!,
              style: context.theme.textTheme.bodySmall,
            ),
          if (info != null) info!,
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => context.pop(),
          child: Text(context.t.cancel.toUpperCase()),
        ),
        ElevatedButton(
          style: ButtonStyle(elevation: MaterialStateProperty.all(0)),
          onPressed: () => context.pop(text),
          child: Text(positiveLabel.toUpperCase()),
        ),
      ],
    );
  }
}
