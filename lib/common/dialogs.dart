import 'package:flutter/material.dart';

import '../extensions.dart';

Future<void> showMessageDialog(BuildContext context, String message) async =>
    showAdaptiveDialog(
      context: context,
      builder: (context) => AlertDialog.adaptive(
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: Text(context.t.close.toUpperCase()),
          ),
        ],
      ),
    );

Future<T?> showIndeterminateProgressDialog<T>(
  BuildContext context, {
  required String message,
  required Future<T> future,
  Function(dynamic e)? onError,
}) async {
  // Do not wait on dialog since we rely on the Future below to close it
  // ignore: unawaited_futures
  showDialog(
    context: context,
    useRootNavigator: true,
    barrierDismissible: false,
    builder: (context) => AlertDialog.adaptive(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, style: context.theme.textTheme.titleMedium),
          const SizedBox(height: 24),
          const LinearProgressIndicator(),
        ],
      ),
    ),
  );

  try {
    return await future.whenComplete(() {
      if (context.mounted) context.pop();
    });
  } catch (e) {
    if (context.mounted) {
      context.pop();
      e.toString().log;
      onError?.call(e);
    }
    return null;
  }
}

Future<String?> showTextInputDialog(
  BuildContext context, {
  String? hint,
  String? caption,
}) => showAdaptiveDialog<String>(
  context: context,
  builder: (context) => TextInputDialog(hint: hint, caption: caption),
);

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
    super.key,
    this.title,
    this.caption,
    this.hint,
    this.showClearButton = false,
    this.info,
    this.positiveLabel = 'Set',
    String value = '',
    this.keyboardType,
    this.textCapitalization = TextCapitalization.sentences,
  }) : _controller = TextEditingController(text: value);

  @override
  Widget build(BuildContext context) {
    return AlertDialog.adaptive(
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
            Text(caption!, style: context.theme.textTheme.bodySmall),
          if (info != null) info!,
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => context.pop(),
          child: Text(context.t.cancel.toUpperCase()),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(elevation: 0),
          onPressed: () => context.pop(text),
          child: Text(positiveLabel.toUpperCase()),
        ),
      ],
    );
  }
}
