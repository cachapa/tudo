import 'package:flutter/widgets.dart';

class ChangeNotifierBuilder<T extends ChangeNotifier> extends StatefulWidget {
  final T value;
  final Widget Function(BuildContext context, T value, Widget? child) builder;
  final Widget? child;

  const ChangeNotifierBuilder(
      {Key? key, required this.value, required this.builder, this.child})
      : super(key: key);

  @override
  State<ChangeNotifierBuilder<T>> createState() =>
      _ChangeNotifierBuilderState<T>();
}

class _ChangeNotifierBuilderState<T extends ChangeNotifier>
    extends State<ChangeNotifierBuilder<T>> {
  @override
  void initState() {
    super.initState();
    widget.value.addListener(_valueChanged);
  }

  @override
  void didUpdateWidget(ChangeNotifierBuilder<T> oldWidget) {
    if (oldWidget.value != widget.value) {
      widget.value.addListener(_valueChanged);
      oldWidget.value.removeListener(_valueChanged);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    widget.value.removeListener(_valueChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, widget.value, widget.child);
  }

  void _valueChanged() {
    setState(() {});
  }
}
