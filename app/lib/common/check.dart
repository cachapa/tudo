import 'package:flutter/material.dart';
import 'package:tudo_app/common/shape_borders.dart';
import 'package:tudo_app/extensions.dart';

const _size = 18.0;

class Check extends StatelessWidget {
  final bool checked;
  final VoidCallback onChanged;

  const Check({Key? key, required this.checked, required this.onChanged})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 8, top: 2),
      child: SizedBox(
        width: _size,
        height: _size,
        child: Material(
          borderOnForeground: true,
          clipBehavior: Clip.none,
          color: checked ? context.theme.primaryColor : null,
          shape: SquircleBorder(
            side: BorderSide(color: context.theme.primaryColor, width: 2),
          ),
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
