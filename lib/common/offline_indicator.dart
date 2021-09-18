import 'package:flutter/material.dart';
import 'package:tudo_client/extensions.dart';
import 'package:tudo_client/util/sync_provider.dart';

const _height = 2.0;

class OfflineIndicator extends StatelessWidget {
  const OfflineIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, __) => Consumer<SyncProvider>(
        builder: (_, syncProvider, __) => AnimatedContainer(
          height: syncProvider.connected ? 0 : _height,
          duration: const Duration(milliseconds: 400),
          curve: Curves.fastOutSlowIn,
          color: context.theme.errorColor,
        ),
      ),
    );
  }
}
