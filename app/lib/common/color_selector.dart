import 'package:flutter/material.dart';
import 'package:tudo_app/extensions.dart';

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

  const ColorSelector({Key? key, required this.controller}) : super(key: key);

  @override
  _ColorSelectorState createState() => _ColorSelectorState();
}

class _ColorSelectorState extends State<ColorSelector> {
  @override
  Widget build(BuildContext context) {
    final widgets = _colors.map(
      (color) => Expanded(
        child: ColorButton(
          color: color,
          selected: color.value == widget.controller.color.value,
          onPressed: () => setState(() => widget.controller.color = color),
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
}

class ColorButton extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onPressed;

  const ColorButton({
    Key? key,
    required this.color,
    required this.selected,
    required this.onPressed,
  }) : super(key: key);

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
              child: Icon(
                Icons.check,
                size: 18,
                color: selected ? Colors.white70 : color,
              ),
              onPressed: onPressed,
            ),
          ),
        ),
      ),
    );
  }
}
