import 'package:flutter/material.dart';
import 'package:tudo_app/extensions.dart';

class Badge extends StatelessWidget {
  final Widget child;
  final double size;
  final bool showBadge;

  const Badge({
    Key? key,
    required this.child,
    this.size = 6,
    this.showBadge = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topRight,
      children: [
        child,
        if (showBadge)
          Positioned(
            top: -3,
            right: -3,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.theme.errorColor,
              ),
            ),
          ),
      ],
    );
  }
}
