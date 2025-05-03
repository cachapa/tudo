import 'package:crdt_sync/crdt_sync.dart';
import 'package:flutter/material.dart';

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
          child: AnimatedSwitcher(
            duration: longDuration,
            child: state == SocketState.connected
                ? const SizedBox(
                    key: ValueKey('gone'),
                    height: 4,
                  )
                : LinearProgressIndicator(
                    key: const ValueKey('visible'),
                    minHeight: 4,
                    color: Colors.amber.withAlpha(100),
                    backgroundColor: Colors.amber.withAlpha(50),
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
