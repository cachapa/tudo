import 'package:flutter/material.dart';

import '../extensions.dart';

class PopupMenu extends StatelessWidget {
  final List<PopupEntry> entries;

  const PopupMenu({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<PopupEntry>(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 1,
      offset: const Offset(0, 40),
      itemBuilder: (context) => entries
          .map(
            (e) => PopupMenuItem<PopupEntry>(
              value: e,
              child: Row(
                children: [
                  Icon(e.icon, color: e.color ?? context.theme.hintColor),
                  const SizedBox(width: 16),
                  Text(e.title),
                ],
              ),
            ),
          )
          .toList(),
      onSelected: (e) => e.onTap(),
    );
  }
}

class PopupEntry {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? color;

  PopupEntry(this.icon, this.title, this.onTap, [this.color]);
}
