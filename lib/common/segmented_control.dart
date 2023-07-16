import 'package:flutter/cupertino.dart';

class SegmentedControl<V, T> extends StatelessWidget {
  final V value;
  final Map<V, T> items;
  final ValueChanged<V> onChanged;
  final Widget Function(BuildContext context, T data) segmentBuilder;

  const SegmentedControl({
    Key? key,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.segmentBuilder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CupertinoSlidingSegmentedControl<V>(
      groupValue: value,
      children: items
          .map((key, value) => MapEntry(key, segmentBuilder(context, value))),
      onValueChanged: (value) => onChanged(value as V),
    );
  }
}
