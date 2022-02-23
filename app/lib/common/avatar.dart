import 'package:flutter/material.dart';
import 'package:tudo_app/extensions.dart';

class Avatar extends StatelessWidget {
  const Avatar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      child: Icon(
        Icons.person,
        color: context.theme.canvasColor,
      ),
      backgroundColor: context.theme.primaryColor,
    );
  }
}
