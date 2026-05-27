import 'package:image_picker/image_picker.dart';

class ImagePickerService {
  static Future<XFile?> getImageFromGallery() async {
    /*
    ?iOS*/
    final ImagePicker picker = ImagePicker();
    return await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 100,
      maxHeight: 800,
      maxWidth: 800,
    );
  }

  static Future<XFile?> getImageFromCamera() async {
    /*
    ?iOS*/
    final ImagePicker picker = ImagePicker();
    return await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 100,
      maxHeight: 800,
      maxWidth: 800,
    );
  }
}
