import 'package:animated_list_plus/animated_list_plus.dart';
import 'package:animated_list_plus/transitions.dart';
import 'package:flutter/widgets.dart';

import '../extensions.dart';

class AnimatedListBuilder<T extends Object> extends StatelessWidget {
  final EdgeInsetsGeometry? padding;
  final ScrollController? controller;
  final List<T> items;
  final bool Function(T a, T b)? itemComparison;
  final Widget Function(BuildContext context, int i, T item) builder;

  const AnimatedListBuilder(
    this.items, {
    super.key,
    this.padding,
    this.controller,
    this.itemComparison,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return ImplicitlyAnimatedList<T>(
      padding: padding,
      controller: controller,
      items: items,
      areItemsTheSame: (a, b) => itemComparison?.call(a, b) ?? a == b,
      itemBuilder: (context, animation, item, i) => SizeFadeTransition(
        sizeFraction: 0.7,
        curve: Curves.easeInOut,
        animation: animation,
        child: builder(context, i, item),
      ),
    );
  }
}

class AnimatedReorderableListBuilder<T extends Object> extends StatelessWidget {
  final ScrollController? controller;
  final List<T> items;
  final bool Function(T a, T b)? itemComparison;
  final ReorderCallback onReorder;
  final Widget Function(BuildContext context, int i, T item) builder;

  const AnimatedReorderableListBuilder(
    this.items, {
    super.key,
    this.controller,
    this.itemComparison,
    required this.onReorder,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return ImplicitlyAnimatedReorderableList<T>(
      shrinkWrap: true,
      padding: context.padding,
      controller: controller,
      items: items,
      areItemsTheSame: (a, b) => itemComparison?.call(a, b) ?? a == b,
      onReorderFinished: (item, from, to, newItems) {
        if (from == to) return;
        onReorder(from, to);
      },
      itemBuilder: (context, animation, item, i) => Reorderable(
        key: ValueKey(item),
        child: SizeFadeTransition(
          sizeFraction: 0.7,
          curve: Curves.easeInOut,
          animation: animation,
          child: builder(context, i, item),
        ),
      ),
    );
  }
}
