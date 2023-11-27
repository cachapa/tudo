import 'package:crdt_sync/crdt_sync.dart';
import 'package:flutter/material.dart';

import '../extensions.dart';
import '../registry.dart';
import 'value_builders.dart';

class OfflineIndicator {
  final BuildContext context;
  late final OverlayEntry _overlay;

  OfflineIndicator(this.context) {
    _overlay = OverlayEntry(
      opaque: false,
      builder: (_) => ValueStreamBuilder(
        stream: Registry.syncProvider.connectionState,
        builder: (_, state) => Align(
          alignment: Alignment.topCenter,
          child: AnimatedOpacity(
            duration: longDuration,
            opacity: state == SocketState.connected ? 0 : 0.6,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                switch (state) {
                  SocketState.disconnected => Icons.cloud_off,
                  SocketState.connecting => Icons.cloud_off,
                  SocketState.connected => Icons.cloud_done_outlined,
                },
                size: 14,
                color: context.theme.colorScheme.onBackground,
              ),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_overlay);
  }

  void dispose() {
    _overlay
      ..remove()
      ..dispose();
  }
}
