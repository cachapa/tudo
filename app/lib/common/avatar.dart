import 'package:flutter/material.dart';
import 'package:tudo_app/extensions.dart';

class Avatar extends StatelessWidget {
  final Color? color;

  const Avatar({Key? key, this.color}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      child: Icon(
        Icons.person,
        color: context.theme.canvasColor,
      ),
      backgroundColor: color ?? context.theme.primaryColor,
    );
  }
}
