import 'package:flutter/material.dart';

class EmptyPage extends StatelessWidget {
  final String text;

  const EmptyPage({Key? key, required this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(text),
    );
  }
}
