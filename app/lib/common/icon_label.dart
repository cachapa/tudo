import 'package:flutter/material.dart';
import 'package:tudo_app/extensions.dart';

class IconLabel extends StatelessWidget {
  final IconData icon;
  final String label;

  const IconLabel(this.icon, this.label, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: context.theme.textTheme.caption!.color,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
