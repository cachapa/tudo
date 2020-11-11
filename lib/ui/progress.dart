import 'package:flutter/material.dart';
import 'package:tudo_client/data/list_manager.dart';

import 'ring_chart.dart';

class Progress extends StatelessWidget {
  final double size;
  final ToDoList list;

  int get progress => list.toDos.where((element) => element.checked).length;

  int get total => list.toDos.length;

  const Progress({Key key, this.size = 30, this.list}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedRingChart(
          size: size,
          progress: progress.toDouble(),
          total: total.toDouble(),
          color: list.color,
        ),
        Text(
          total.toString(),
          style: Theme.of(context).primaryTextTheme.bodyText2,
        ),
      ],
    );
  }
}
