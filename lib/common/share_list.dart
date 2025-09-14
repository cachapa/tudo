import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../extensions.dart';
import '../lists/list_provider.dart';
import '../registry.dart';

void shareToDoList(BuildContext context, ToDoList list) {
  showModalBottomSheet<String>(
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
    ),
    isScrollControlled: true,
    context: context,
    builder: (context) => _ShareListForm(list: list),
  );
}

class _ShareListForm extends StatelessWidget {
  final ToDoList list;

  String get shareUrl =>
      '${Registry.settingsProvider.serverUri}/list/${list.id}';

  const _ShareListForm({required this.list});

  @override
  Widget build(BuildContext context) {
    final t = context.t;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: 12,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              list.name,
              style: Theme.of(
                context,
              ).textTheme.titleLarge!.copyWith(color: list.color),
            ),
            const SizedBox(height: 20),
            QrImageView(
              data: shareUrl,
              version: QrVersions.auto,
              size: 250.0,
              backgroundColor: ThemeData.light().canvasColor,
            ),
            const SizedBox(height: 20),
            OverflowBar(
              alignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: list.color),
                  icon: const Icon(Icons.copy),
                  label: Text(t.copyLink.toUpperCase()),
                  onPressed: () {
                    FlutterClipboard.copy(shareUrl);
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(width: 16),
                TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: list.color),
                  icon: Icon(Icons.adaptive.share),
                  label: Text(context.t.share.toUpperCase()),
                  onPressed: () {
                    SharePlus.instance.share(
                      ShareParams(
                        text: t.listShareMessage(list.name, shareUrl),
                      ),
                    );
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
