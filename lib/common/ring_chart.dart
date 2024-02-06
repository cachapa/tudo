import 'dart:math';

import 'package:flutter/material.dart';

class AnimatedRingChart extends ImplicitlyAnimatedWidget {
  final double size;
  final Color color;
  final double progress;
  final double total;

  const AnimatedRingChart({
    super.key,
    required this.size,
    required this.color,
    required this.progress,
    required this.total,
  }) : super(
            duration: const Duration(milliseconds: 1000),
            curve: Curves.fastOutSlowIn);

  @override
  ImplicitlyAnimatedWidgetState<ImplicitlyAnimatedWidget> createState() =>
      _AnimatedRingChartState();
}

class _AnimatedRingChartState
    extends AnimatedWidgetBaseState<AnimatedRingChart> {
  ColorTween? _color;
  Tween<double>? _progress;
  Tween<double>? _total;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _color = visitor(
            _color, widget.color, (dynamic value) => ColorTween(begin: value))
        as ColorTween;
    _progress = visitor(_progress, widget.progress,
        (dynamic value) => Tween<double>(begin: value)) as Tween<double>;
    _total = visitor(_total, widget.total,
        (dynamic value) => Tween<double>(begin: value)) as Tween<double>;
  }

  @override
  Widget build(BuildContext context) {
    return RingChart(
      size: widget.size,
      color: _color!.evaluate(animation)!,
      progress: _progress!.evaluate(animation),
      total: _total!.evaluate(animation),
    );
  }
}

class RingChart extends StatelessWidget {
  final double size;
  final Color color;
  final double progress;
  final double total;

  const RingChart({
    super.key,
    this.size = 100,
    this.color = Colors.blue,
    required this.progress,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _ChartPainter(
        color: color,
        progress: progress,
        total: total,
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final Color color;
  final double progress;
  final double total;

  final Color _backgroundColor;
  final Paint _fillPaint;
  final Paint _ringPaint = Paint()
    ..strokeWidth = 2
    ..style = PaintingStyle.stroke;

  double get ratio => total == 0 ? 0 : progress / total;

  _ChartPainter(
      {required this.color, required this.progress, required this.total})
      : _backgroundColor = color.withAlpha(100),
        _fillPaint = Paint()..color = color;

  @override
  void paint(Canvas canvas, Size size) {
    var center = size.center(Offset.zero);
    var radius = (size.width - _ringPaint.strokeWidth) / 2;

    // Draw ring background
    _ringPaint.color = _backgroundColor;
    canvas.drawCircle(center, radius, _ringPaint);

    // Draw fill background
    canvas.drawCircle(center, radius - 2, _fillPaint);

    // Draw Progress
    _ringPaint.color = color;
    const startAngle = -pi / 2;
    final endAngle = 2 * pi * ratio;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle,
        endAngle, false, _ringPaint);
  }

  @override
  bool shouldRepaint(_ChartPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.total != total ||
      oldDelegate.progress != progress;
}
