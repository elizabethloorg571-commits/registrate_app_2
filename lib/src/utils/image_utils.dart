import 'package:flutter/material.dart';

/// Utilidades para el manejo seguro de URLs de imágenes
class ImageUtils {
  /// Valida si una URL es válida para cargar imágenes desde la red
  /// Retorna true si es una URL HTTP/HTTPS válida, false en caso contrario
  static bool isValidNetworkImageUrl(String? url) {
    if (url == null || url.isEmpty) return false;

    try {
      final uri = Uri.parse(url);

      // Solo permitir esquemas HTTP y HTTPS para imágenes de red
      if (!uri.hasScheme || (uri.scheme != 'http' && uri.scheme != 'https')) {
        debugPrint(
          '⚠️ Invalid URL scheme for network image: $url (scheme: ${uri.scheme})',
        );
        return false;
      }

      // Verificar que tenga un host válido
      if (!uri.hasAuthority || uri.host.isEmpty) {
        debugPrint(
          '⚠️ Invalid URL host for network image: $url (host: ${uri.host})',
        );
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('❌ Error parsing image URL: $url - Error: $e');
      return false;
    }
  }

  /// Obtiene un ImageProvider seguro basado en la URL
  /// Si la URL no es válida para NetworkImage, retorna un AssetImage por defecto
  static ImageProvider getSafeImageProvider({
    required String? imageUrl,
    required String fallbackAsset,
    String? debugContext,
  }) {
    if (!isValidNetworkImageUrl(imageUrl)) {
      if (imageUrl != null && imageUrl.isNotEmpty) {
        debugPrint(
          '🔄 Using fallback image for invalid URL: $imageUrl ${debugContext != null ? "($debugContext)" : ""}',
        );
      }
      return AssetImage(fallbackAsset);
    } else {
      if (debugContext != null) {
        debugPrint('✅ Using network image: $imageUrl ($debugContext)');
      }
      return NetworkImage(imageUrl!);
    }
  }

  /// Widget helper que muestra una imagen de red con fallback automático
  static Widget safeNetworkImage({
    required String? imageUrl,
    required String fallbackAsset,
    double? width,
    double? height,
    BoxFit? fit,
    String? debugContext,
  }) {
    if (!isValidNetworkImageUrl(imageUrl)) {
      if (imageUrl != null && imageUrl.isNotEmpty) {
        debugPrint(
          '🔄 Using fallback image widget for invalid URL: $imageUrl ${debugContext != null ? "($debugContext)" : ""}',
        );
      }
      return Image.asset(fallbackAsset, width: width, height: height, fit: fit);
    } else {
      if (debugContext != null) {
        debugPrint('✅ Using network image widget: $imageUrl ($debugContext)');
      }
      return Image.network(
        imageUrl!,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          debugPrint(
            '❌ Network image failed to load: $imageUrl - Error: $error ${debugContext != null ? "($debugContext)" : ""}',
          );
          return Image.asset(
            fallbackAsset,
            width: width,
            height: height,
            fit: fit,
          );
        },
      );
    }
  }
}
