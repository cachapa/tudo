import 'package:flutter/material.dart';

import 'ring_chart.dart';

class Progress extends StatelessWidget {
  final double size;
  final int progress;
  final int total;
  final Color color;

  const Progress({
    super.key,
    this.size = 30,
    required this.progress,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedRingChart(
          size: size,
          progress: progress.toDouble(),
          total: total.toDouble(),
          color: color,
        ),
        AnimatedCounter(value: total, size: size * 0.4),
      ],
    );
  }
}

class AnimatedCounter extends StatefulWidget {
  final int value;
  final double size;

  const AnimatedCounter({super.key, required this.value, required this.size});

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
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
      duration: const Duration(milliseconds: 200),
      transitionBuilder: (child, animation) {
        final d = (child.key as ValueKey<int>).value == widget.value ? 1 : -1;
        final offsetAnimation = Tween<Offset>(
          begin: Offset(0.0, direction * d * 0.5),
          end: Offset.zero,
        ).animate(animation);
        return SlideTransition(
          position: offsetAnimation,
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: Text(
        widget.value.toString(),
        key: ValueKey(widget.value),
        style: Theme.of(
          context,
        ).primaryTextTheme.bodyMedium!.copyWith(fontSize: widget.size),
      ),
    );
  }
}
