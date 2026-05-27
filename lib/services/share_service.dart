import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ShareService {
  static Future shareImage(
    Uint8List bytes,
    String subject, {
    required BuildContext context,
    String fileName = 'shared_image',
    Rect? sharePositionOrigin,
  }) async {
    final screenSize = MediaQuery.sizeOf(context);
    final directory = await getTemporaryDirectory();
    final directoryPath = directory.path;
    final path = '$directoryPath/$fileName.png';
    final image = File(path);
    await image.writeAsBytes(bytes);

    // Configurar posición de origen para iOS/iPad
    Rect? origin = sharePositionOrigin;
    origin ??= Rect.fromCenter(
      center: Offset(screenSize.width / 2, screenSize.height / 2),
      width: 100,
      height: 100,
    );

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(path)],
        subject: 'Entrada: $subject',
        sharePositionOrigin: origin,
      ),
    );

    /*await OpenFilex.open(path, type: "image/png");*/ // * Abrir el archivo para comprobar que el archivo se creó correctamente
  }
}
