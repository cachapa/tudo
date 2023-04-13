import 'package:flutter/material.dart';

import '../extensions.dart';
import '../registry.dart';
import 'value_builders.dart';

class OfflineIndicator {
  final BuildContext context;
  late final OverlayEntry _overlay;

  final connectionState = Registry.syncProvider.connectionState;

  OfflineIndicator(this.context) {
    _overlay = OverlayEntry(
      opaque: false,
      builder: (_) => ValueStreamBuilder<bool>(
        stream: connectionState,
        initialValue: true,
        builder: (_, isConnected) => AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: isConnected ? Container() : const _Indicator(),
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

class _Indicator extends StatelessWidget {
  const _Indicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(
            Icons.cloud_off,
            size: 14,
            color: context.theme.splashColor.withOpacity(0.7),
          ),
        ),
      ),
    );
  }
}
