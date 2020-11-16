import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class IconText extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const IconText(this.icon, this.text, {Key key, this.color}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color),
        SizedBox(width: 16),
        Text(text, style: TextStyle(color: color)),
      ],
    );
  }
}
