import 'package:animated_list_plus/animated_list_plus.dart';
import 'package:animated_list_plus/transitions.dart';
import 'package:flutter/widgets.dart';

import '../extensions.dart';

class AnimatedListBuilder<T extends IdObject> extends StatelessWidget {
  final EdgeInsetsGeometry? padding;
  final ScrollController? controller;
  final List<T> items;
  final Widget Function(BuildContext context, int i, T item) builder;

  const AnimatedListBuilder(
    this.items, {
    super.key,
    this.padding,
    this.controller,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return ImplicitlyAnimatedList<T>(
      padding: padding,
      controller: controller,
      items: items,
      areItemsTheSame: (a, b) => a.id == b.id,
      itemBuilder: (context, animation, item, i) => SizeFadeTransition(
        key: ValueKey(item.id),
        sizeFraction: 0.7,
        curve: Curves.easeInOut,
        animation: animation,
        child: builder(context, i, item),
      ),
    );
  }
}

class AnimatedReorderableListBuilder<T extends IdObject>
    extends StatelessWidget {
  final ScrollController? controller;
  final List<T> items;
  final ReorderCallback onReorder;
  final Widget Function(BuildContext context, int i, T item) builder;
  final EdgeInsetsGeometry? padding;

  const AnimatedReorderableListBuilder(
    this.items, {
    super.key,
    this.controller,
    required this.onReorder,
    required this.builder,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ImplicitlyAnimatedReorderableList<T>(
      shrinkWrap: true,
      padding: padding ?? context.padding,
      controller: controller,
      items: items,
      areItemsTheSame: (a, b) => a.id == b.id,
      onReorderFinished: (item, from, to, newItems) {
        if (from == to) return;
        onReorder(from, to);
      },
      itemBuilder: (context, animation, item, i) => Reorderable(
        key: ValueKey(item.id),
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

abstract class IdObject {
  final String id;

  const IdObject(this.id);
}
