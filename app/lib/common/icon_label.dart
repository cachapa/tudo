import 'package:flutter/material.dart';

import '../extensions.dart';

class IconLabel extends StatelessWidget {
  final IconData icon;
  final String label;

  const IconLabel(this.icon, this.label, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = context.theme.textTheme.bodySmall!.color;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: context.theme.textTheme.bodyMedium!.copyWith(color: color),
          softWrap: false,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
