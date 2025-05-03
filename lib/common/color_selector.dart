import 'package:flutter/material.dart';

import '../extensions.dart';

const _colors = <Color>[
  Colors.red,
  Colors.pink,
  Colors.purple,
  Colors.deepPurple,
  Colors.indigo,
  Colors.blue,
  Colors.lightBlue,
  Colors.cyan,
  Colors.teal,
  Colors.green,
  Colors.lightGreen,
  Colors.amber,
  Colors.orange,
  Colors.deepOrange,
  Colors.brown,
  Colors.blueGrey,
];

class ColorController {
  Color color;

  ColorController({Color? color}) : color = color ?? _colors.random;
}

class ColorSelector extends StatefulWidget {
  final ColorController controller;
  final void Function(Color color)? onColorSelected;

  const ColorSelector({
    super.key,
    required this.controller,
    this.onColorSelected,
  });

  @override
  State<ColorSelector> createState() => _ColorSelectorState();
}

class _ColorSelectorState extends State<ColorSelector> {
  @override
  Widget build(BuildContext context) {
    final widgets = _colors.map(
      (color) => Expanded(
        child: ColorButton(
          color: color,
          selected: color.toARGB32() == widget.controller.color.toARGB32(),
          onPressed: () => _setColor(color),
        ),
      ),
    );

    const elements = 8;
    final rows = (_colors.length / elements).ceil();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        rows,
        (i) => Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: widgets.skip(i * elements).take(elements).toList(),
        ),
      ),
    );
  }

  void _setColor(Color color) {
    setState(() => widget.controller.color = color);
    widget.onColorSelected?.call(color);
  }
}

class ColorButton extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onPressed;

  const ColorButton({
    super.key,
    required this.color,
    required this.selected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(2),
      child: Material(
        shadowColor: color,
        elevation: selected ? 4 : 0,
        color: selected ? color.lighten(0.7) : color,
        shape: const CircleBorder(),
        child: AspectRatio(
          aspectRatio: 1,
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: MaterialButton(
              padding: EdgeInsets.zero,
              shape: const CircleBorder(),
              color: color,
              elevation: 0,
              hoverElevation: 0,
              highlightElevation: 0,
              onPressed: onPressed,
              child: Icon(
                Icons.check,
                size: 18,
                color: selected ? Colors.white70 : color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
