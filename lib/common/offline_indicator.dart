import 'package:flutter/material.dart';
import 'package:tudo_client/util/sync_manager.dart';

import '../extensions.dart';

class OfflineIndicator extends StatelessWidget {
  final _color = Colors.red.shade50;

  @override
  Widget build(BuildContext context) {
    return Consumer<SyncManager>(
      builder: (_, syncManager, __) => AnimatedContainer(
        constraints:
            BoxConstraints.expand(height: syncManager.connected ? 0 : 16),
        duration: Duration(milliseconds: 400),
        curve: Curves.fastOutSlowIn,
        color: Colors.red,
        child: SafeArea(
          top: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.wifi_off,
                size: 12,
                color: _color,
              ),
              SizedBox(width: 4),
              Text(
                'offline',
                style:
                    context.theme.textTheme.overline!.copyWith(color: _color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
