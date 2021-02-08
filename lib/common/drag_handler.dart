import 'package:flutter/material.dart';
import 'package:implicitly_animated_reorderable_list/implicitly_animated_reorderable_list.dart';
import 'package:tudo_client/extensions.dart';

class DragHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => print('tap'),
      onHorizontalDragStart: (_) => print('tap'),
      onVerticalDragStart: (_) => print('tap'),
      child: Handle(
        vibrate: true,
        child: Padding(
          padding: EdgeInsets.all(4),
          child: Icon(
            Icons.reorder,
            color: context.theme.dividerColor,
          ),
        ),
      ),
    );
  }
}
