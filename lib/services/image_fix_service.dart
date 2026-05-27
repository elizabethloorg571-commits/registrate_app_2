import 'package:image/image.dart' as img;
import 'dart:io';

Future<File> fixImageOrientationAndSave(File file) async {
  final bytes = await file.readAsBytes();
  final image = img.decodeImage(bytes);

  if (image != null) {
    // Optionally fix orientation
    final fixedImage = img.bakeOrientation(image);

    // Re-encode as JPEG to fix color profile
    final jpg = img.encodeJpg(fixedImage);

    final newFile = File(
      '${file.parent.path}/fixed_${file.path.split('/').last}',
    );
    await newFile.writeAsBytes(jpg);
    return newFile;
  }
  return file; // fallback if decode fails
}
