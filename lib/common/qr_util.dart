import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

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
      embeddedImageStyle: const QrEmbeddedImageStyle(size: Size(36, 0)),
      embeddedImage: const AssetImage('assets/images/qr_icon.png'),
      version: QrVersions.auto,
      backgroundColor: ThemeData.light().canvasColor,
    );
  }
}
