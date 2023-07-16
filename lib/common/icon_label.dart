import 'package:flutter/material.dart';

import '../extensions.dart';

class IconLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final TextStyle? style;

  const IconLabel(this.icon, this.label, {super.key, this.style});

  @override
  Widget build(BuildContext context) {
    final color = (style ?? context.theme.textTheme.bodySmall!).color;

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
          style: style ??
              context.theme.textTheme.bodyMedium!.copyWith(color: color),
          softWrap: false,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
