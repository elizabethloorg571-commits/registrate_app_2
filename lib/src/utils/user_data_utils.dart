import 'package:flutter/foundation.dart';
import 'package:running_app/src/utils/image_utils.dart';

/// Utilidades para sanitizar y validar datos de usuario
class UserDataUtils {
  /// Sanitiza los datos de usuario antes de usar, especialmente URLs de imagen
  static Map<String, dynamic> sanitizeUserData(Map<String, dynamic>? userData) {
    if (userData == null) return {};

    final sanitizedData = Map<String, dynamic>.from(userData);

    // Validar y limpiar URL de foto de perfil
    if (sanitizedData.containsKey('userPhotoUrl')) {
      final photoUrl = sanitizedData['userPhotoUrl'] as String?;

      if (photoUrl != null && photoUrl.isNotEmpty) {
        if (!ImageUtils.isValidNetworkImageUrl(photoUrl)) {
          debugPrint('⚠️ Invalid userPhotoUrl detected and removed: $photoUrl');
          sanitizedData['userPhotoUrl'] = '';
        } else {
          debugPrint('✅ Valid userPhotoUrl: $photoUrl');
        }
      }
    }

    // Validar otras URLs si existen
    _validateUrlField(sanitizedData, 'avatarUrl');
    _validateUrlField(sanitizedData, 'profileImageUrl');
    _validateUrlField(sanitizedData, 'imageUrl');

    return sanitizedData;
  }

  /// Valida un campo de URL específico
  static void _validateUrlField(Map<String, dynamic> data, String fieldName) {
    if (data.containsKey(fieldName)) {
      final url = data[fieldName] as String?;

      if (url != null && url.isNotEmpty) {
        if (!ImageUtils.isValidNetworkImageUrl(url)) {
          debugPrint('⚠️ Invalid $fieldName detected and removed: $url');
          data[fieldName] = '';
        } else {
          debugPrint('✅ Valid $fieldName: $url');
        }
      }
    }
  }

  /// Valida específicamente la URL de foto de perfil
  static String? validateProfilePhotoUrl(String? photoUrl) {
    if (photoUrl == null || photoUrl.isEmpty) return null;

    if (ImageUtils.isValidNetworkImageUrl(photoUrl)) {
      return photoUrl;
    } else {
      debugPrint('⚠️ Invalid profile photo URL rejected: $photoUrl');
      return null;
    }
  }
}
