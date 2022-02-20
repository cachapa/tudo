import 'package:flutter/material.dart';
import 'package:tudo_app/extensions.dart';

class Badge extends StatelessWidget {
  final Widget child;
  final double size;
  final bool showBadge;

  const Badge({
    Key? key,
    required this.child,
    this.size = 10,
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
            top: -4,
            right: -4,
            child: Container(
              width: size,
              height: size,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.theme.canvasColor,
              ),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.theme.errorColor,
                ),
              ),
            ),
          )
      ],
    );
  }
}
