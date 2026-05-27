/// Resultado de la operación de subida de imagen
class ImageUploadResult {
  final bool success;
  final String? errorMessage;
  final String? errorCode;
  final String? uploadedUrl;
  final ImageUploadErrorType? errorType;

  const ImageUploadResult._({
    required this.success,
    this.errorMessage,
    this.errorCode,
    this.uploadedUrl,
    this.errorType,
  });

  /// Resultado exitoso con URL de la imagen subida
  factory ImageUploadResult.success(String uploadedUrl) {
    return ImageUploadResult._(success: true, uploadedUrl: uploadedUrl);
  }

  /// Resultado de error con detalles específicos
  factory ImageUploadResult.failure({
    required String message,
    required ImageUploadErrorType errorType,
    String? errorCode,
  }) {
    return ImageUploadResult._(
      success: false,
      errorMessage: message,
      errorCode: errorCode,
      errorType: errorType,
    );
  }

  /// Verifica si la operación fue exitosa
  bool get isSuccess => success;

  /// Verifica si hubo un error
  bool get isFailure => !success;

  /// Obtiene un mensaje de error amigable para el usuario
  String get userFriendlyMessage {
    if (success) return 'Imagen subida exitosamente';

    switch (errorType) {
      case ImageUploadErrorType.networkError:
        return 'No tienes conexión a internet. Verifica tu conexión y vuelve a intentar.';
      case ImageUploadErrorType.serverError:
        return 'Error del servidor. Por favor intenta más tarde.';
      case ImageUploadErrorType.authenticationError:
        return 'Error de autenticación. Por favor inicia sesión nuevamente.';
      case ImageUploadErrorType.fileTooLarge:
        return 'La imagen es demasiado grande. Selecciona una imagen más pequeña.';
      case ImageUploadErrorType.invalidFormat:
        return 'Formato de imagen no válido. Usa JPG, PNG o WEBP.';
      case ImageUploadErrorType.uploadFailed:
        return 'Error al subir la imagen. Intenta nuevamente.';
      case ImageUploadErrorType.unknown:
        // Para errores desconocidos, solo usar mensaje personalizado si parece amigable
        // Excluir mensajes técnicos cortos como "test", "error", etc.
        if (errorMessage != null &&
            !errorMessage!.toLowerCase().contains('technical') &&
            !errorMessage!.toLowerCase().contains('exception') &&
            errorMessage!.toLowerCase() != 'test' &&
            errorMessage!.toLowerCase() != 'error' &&
            errorMessage!.length > 10) {
          return errorMessage!;
        }
        return 'Error desconocido al subir la imagen.';
      default:
        return 'Error desconocido al subir la imagen.';
    }
  }

  @override
  String toString() {
    if (success) {
      return 'ImageUploadResult.success(url: $uploadedUrl)';
    } else {
      return 'ImageUploadResult.failure(type: $errorType, message: $errorMessage, code: $errorCode)';
    }
  }
}

/// Tipos de errores específicos para subida de imágenes
enum ImageUploadErrorType {
  networkError, // Sin conexión o problemas de red
  serverError, // Error 5xx del servidor
  authenticationError, // Error 401/403 de autenticación
  fileTooLarge, // Archivo excede el tamaño permitido
  invalidFormat, // Formato de archivo no soportado
  uploadFailed, // Error específico durante la subida a S3
  unknown, // Error no categorizado
}
