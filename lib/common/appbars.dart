import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../extensions.dart';

const blurSigma = 12.0;

class BlurredAppBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  final preferredSize = const Size.fromHeight(kToolbarHeight);

  final Widget? leading;
  final Widget title;
  final List<Widget>? actions;
  final Color? foregroundColor;
  final Color? backgroundColor;

  const BlurredAppBar({
    super.key,
    this.leading,
    required this.title,
    this.actions,
    this.foregroundColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: AppBar(
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarIconBrightness: context.theme.brightness.invert,
          ),
          centerTitle: true,
          foregroundColor: foregroundColor,
          backgroundColor:
              backgroundColor ?? context.theme.canvasColor.withAlpha(180),
          surfaceTintColor: Colors.transparent,
          leading: leading,
          title: title,
          actions: actions,
        ),
      ),
    );
  }
}

class DiscreteAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;

  @override
  final Size preferredSize = const Size.fromHeight(kToolbarHeight);

  const DiscreteAppBar({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      foregroundColor: context.theme.textTheme.titleLarge!.color,
      backgroundColor: context.theme.canvasColor,
      centerTitle: true,
      title: Column(
        children: [
          Text(title),
          if (subtitle != null)
            Text(
              subtitle!,
              style: context.theme.textTheme.bodySmall!.copyWith(
                color: context.theme.primaryColor,
              ),
            ),
        ],
      ),
    );
  }
}
