import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../extensions.dart';

Future<String?> scanQrCode(BuildContext context, {String? message}) async {
  var detected = false;
  final code = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog.adaptive(
      backgroundColor: Colors.transparent,
      contentPadding: EdgeInsets.zero,
      titlePadding: const EdgeInsets.all(24),
      title: message != null
          ? Text(
              message,
              style: context.theme.primaryTextTheme.titleMedium,
            )
          : null,
      content: AspectRatio(
        aspectRatio: 1,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: MobileScanner(
            placeholderBuilder: (p0, p1) => Container(
              color: Colors.black,
              alignment: Alignment.center,
              child: const Icon(Icons.qr_code_scanner_rounded,
                  color: Colors.white),
            ),
            fit: BoxFit.cover,
            onDetect: (barcodes) {
              if (!detected) {
                // Avoid subsequent triggers
                detected = true;
                context.pop(barcodes.barcodes.first.rawValue);
              }
            },
          ),
        ),
      ),
    ),
  );

  return code;
}

class QrView extends StatelessWidget {
  final double? size;
  final String data;

  const QrView(this.data, {super.key, this.size});

  @override
  Widget build(BuildContext context) {
    return QrImageView(
      size: size,
      padding: const EdgeInsets.all(16),
      data: data,
      version: QrVersions.auto,
      backgroundColor: Colors.white,
    );
  }
}
