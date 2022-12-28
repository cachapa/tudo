import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tudo_app/extensions.dart';

import 'value_builders.dart';

class OfflineIndicator {
  final BuildContext context;
  late final StreamSubscription<bool> _subscription;
  late final OverlayEntry _overlay;

  OfflineIndicator(this.context) {
    _overlay = OverlayEntry(
      opaque: false,
      builder: (_) => ValueStreamBuilder<bool>(
        stream: context.syncProvider.connectionState,
        initialData: true,
        builder: (_, isConnected) => AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: isConnected ? Container() : const _Indicator(),
        ),
      ),
    );
    Overlay.of(context).insert(_overlay);
  }

  void dispose() {
    _subscription.cancel();
    _overlay.dispose();
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
