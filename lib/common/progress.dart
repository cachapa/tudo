import 'package:flutter/material.dart';
import 'package:tudo_client/list_manager/list_provider.dart';

import 'ring_chart.dart';

class Progress extends StatelessWidget {
  final double size;
  final ToDoList list;

  int get progress => list.completedLength;

  int get total => list.length;

  const Progress({Key? key, this.size = 30, required this.list})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedRingChart(
          size: size,
          progress: progress.toDouble(),
          total: total.toDouble(),
          color: list.color,
        ),
        AnimatedCounter(value: total),
      ],
    );
  }
}

class AnimatedCounter extends StatefulWidget {
  final int value;

  const AnimatedCounter({Key? key, required this.value}) : super(key: key);

  @override
  _AnimatedCounterState createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter> {
  var direction = 0;

  @override
  void didUpdateWidget(covariant AnimatedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);

    direction = oldWidget.value < widget.value
        ? 1
        : oldWidget.value > widget.value
            ? -1
            : direction;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: Duration(milliseconds: 200),
      transitionBuilder: (child, animation) {
        final d = (child.key as ValueKey<int>).value == widget.value ? 1 : -1;
        final offsetAnimation = Tween<Offset>(
                begin: Offset(0.0, direction * d * 0.5), end: Offset(0.0, 0.0))
            .animate(animation);
        return SlideTransition(
          position: offsetAnimation,
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      child: Text(
        widget.value.toString(),
        key: ValueKey(widget.value),
        style: Theme.of(context).primaryTextTheme.bodyText2,
      ),
    );
  }
}
