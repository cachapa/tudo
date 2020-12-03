import 'package:flutter/material.dart';
import 'package:implicitly_animated_reorderable_list/implicitly_animated_reorderable_list.dart';

class CustomHandle extends StatelessWidget {
  final Widget child;

  const CustomHandle({Key key, this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Handle(
      vibrate: false,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(),
            child: Icon(
              Icons.reorder,
              color: Colors.grey.withOpacity(0.5),
            ),
          ),
          SizedBox(width: 8),
          child,
        ],
      ),
    );
  }
}
