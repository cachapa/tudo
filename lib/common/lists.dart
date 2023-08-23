import 'package:animated_list_plus/animated_list_plus.dart';
import 'package:animated_list_plus/transitions.dart';
import 'package:flutter/widgets.dart';

import '../extensions.dart';
import '../util/durations.dart';

class AnimatedListBuilder<T extends IdObject> extends StatelessWidget {
  final Axis scrollDirection;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry? padding;
  final ScrollController? controller;
  final List<T> items;
  final Widget Function(BuildContext context, int i, T item) builder;

  const AnimatedListBuilder(
    this.items, {
    super.key,
    this.scrollDirection = Axis.vertical,
    this.shrinkWrap = false,
    this.physics,
    this.padding,
    this.controller,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return ImplicitlyAnimatedList<T>(
      scrollDirection: scrollDirection,
      shrinkWrap: shrinkWrap,
      physics: physics,
      padding: padding,
      controller: controller,
      items: items,
      areItemsTheSame: (a, b) => a.id == b.id,
      insertDuration: Durations.long,
      removeDuration: Durations.medium,
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
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final ReorderCallback onReorder;
  final Widget Function(BuildContext context, int i, T item) builder;
  final EdgeInsetsGeometry? padding;

  const AnimatedReorderableListBuilder(
    this.items, {
    super.key,
    this.controller,
    this.shrinkWrap = false,
    this.physics,
    required this.onReorder,
    required this.builder,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ImplicitlyAnimatedReorderableList<T>(
      shrinkWrap: shrinkWrap,
      physics: physics,
      padding: padding ?? (shrinkWrap ? null : context.padding),
      controller: controller,
      items: items,
      areItemsTheSame: (a, b) => a.id == b.id,
      onReorderFinished: (item, from, to, newItems) {
        if (from == to) return;
        onReorder(from, to);
      },
      insertDuration: Durations.long,
      removeDuration: Durations.medium,
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
