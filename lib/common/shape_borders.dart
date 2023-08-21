import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

// Adapted from https://gist.github.com/slightfoot/e35e8d5877371417e9803143e2501b0a

class SquircleBorder extends OutlinedBorder {
  final Color color;
  final double superRadius;

  const SquircleBorder({
    super.side = BorderSide.none,
    required this.color,
    this.superRadius = 5.0,
  });

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.width);

  @override
  ShapeBorder scale(double t) {
    return SquircleBorder(
      side: side.scale(t),
      color: color,
      superRadius: superRadius * t,
    );
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return _squirclePath(rect.deflate(side.strokeInset), superRadius);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return _squirclePath(rect, superRadius);
  }

  static Path _squirclePath(Rect rect, double superRadius) {
    final c = rect.center;
    final dx = c.dx * (1.0 / superRadius);
    final dy = c.dy * (1.0 / superRadius);
    return Path()
      ..moveTo(c.dx, 0)
      ..relativeCubicTo(c.dx - dx, 0, c.dx, dy, c.dx, c.dy)
      ..relativeCubicTo(0, c.dy - dy, -dx, c.dy, -c.dx, c.dy)
      ..relativeCubicTo(-(c.dx - dx), 0, -c.dx, -dy, -c.dx, -c.dy)
      ..relativeCubicTo(0, -(c.dy - dy), dx, -c.dy, c.dx, -c.dy)
      ..close();
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    switch (side.style) {
      case BorderStyle.none:
        break;
      case BorderStyle.solid:
        final path = getOuterPath(rect, textDirection: textDirection);
        canvas.drawPath(path, side.toPaint()..color = color);
    }
  }

  @override
  SquircleBorder copyWith(
      {BorderSide? side, Color? color, double? superRadius}) {
    return SquircleBorder(
      side: side ?? this.side,
      color: color ?? this.color,
      superRadius: superRadius ?? this.superRadius,
    );
  }
}
