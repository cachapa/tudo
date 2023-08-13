import 'package:flutter/material.dart';

import '../extensions.dart';

class EmptyPage extends StatelessWidget {
  final String text;

  const EmptyPage({Key? key, required this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: context.theme.textTheme.titleMedium,
      ),
    );
  }
}
