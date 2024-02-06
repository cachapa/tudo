import 'package:flutter/material.dart';

import '../extensions.dart';
import 'shape_borders.dart';

const _size = 18.0;

class Check extends StatelessWidget {
  final bool checked;
  final bool disabled;

  const Check({super.key, required this.checked, this.disabled = false});

  @override
  Widget build(BuildContext context) {
    final color =
        disabled ? context.theme.disabledColor : context.theme.primaryColor;
    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 8, top: 2),
      child: SizedBox(
        width: _size,
        height: _size,
        child: Material(
          borderOnForeground: true,
          clipBehavior: Clip.none,
          color: checked ? color : null,
          shape: SquircleBorder(side: BorderSide(color: color, width: 2)),
          child: checked
              ? Icon(
                  Icons.check,
                  color: context.theme.canvasColor,
                  size: 14,
                )
              : null,
        ),
      ),
    );
  }
}
