import 'package:flutter/material.dart';

import '../extensions.dart';

class Avatar extends StatelessWidget {
  final Color? color;

  const Avatar({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      backgroundColor: color ?? context.theme.primaryColor,
      child: Icon(
        Icons.person,
        color: context.theme.canvasColor,
      ),
    );
  }
}
