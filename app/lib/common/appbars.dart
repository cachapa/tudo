import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tudo_app/extensions.dart';

class DiscreteAppBar extends StatelessWidget with PreferredSizeWidget {
  final String title;

  @override
  final Size preferredSize = const Size.fromHeight(kToolbarHeight);

  const DiscreteAppBar({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      systemOverlayStyle: context.theme.brightness == Brightness.light
          ? SystemUiOverlayStyle.dark
          : SystemUiOverlayStyle.light,
      elevation: 0,
      foregroundColor: context.theme.textTheme.headline6!.color,
      backgroundColor: context.theme.canvasColor,
      centerTitle: true,
      title: Text(title),
    );
  }
}
