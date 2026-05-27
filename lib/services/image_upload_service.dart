import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:running_app/services/image_upload_result.dart';
import 'package:running_app/services/network_service.dart';
import 'package:running_app/src/data/constants/constants.dart';

class ImageUploadService {
  /// Sube una imagen con manejo detallado de errores
  Future<ImageUploadResult> uploadImageWithDetails(
    XFile image,
    String path,
    String imageName,
    String imgFormat,
  ) async {
    try {
      debugPrint('🚀 Starting image upload process for $imageName.$imgFormat');

      // Verificar conectividad de red antes de intentar subir
      final networkStatus = await NetworkService.getNetworkStatus();
      debugPrint('📶 Network status: $networkStatus');

      if (!networkStatus.isHealthy) {
        debugPrint('❌ Network not healthy, cannot upload image');
        return ImageUploadResult.failure(
          message: 'Network not available: ${networkStatus.error}',
          errorType: ImageUploadErrorType.networkError,
          errorCode: 'NETWORK_UNAVAILABLE',
        );
      }

      // Intentar obtener URL firmada con reintentos
      final signedUrlResult =
          await NetworkService.executeWithRetry<http.Response>(
            () => _getSignedURL(path, imageName, imgFormat),
            maxRetries: 3,
            delayBetweenRetries: Duration(seconds: 2),
          );

      if (signedUrlResult == null) {
        return ImageUploadResult.failure(
          message: 'Failed to get signed URL after retries',
          errorType: ImageUploadErrorType.serverError,
          errorCode: 'SIGNED_URL_TIMEOUT',
        );
      }

      if (signedUrlResult.statusCode == 401 ||
          signedUrlResult.statusCode == 403) {
        return ImageUploadResult.failure(
          message: 'Authentication error getting signed URL',
          errorType: ImageUploadErrorType.authenticationError,
          errorCode: 'AUTH_ERROR_${signedUrlResult.statusCode}',
        );
      }

      if (signedUrlResult.statusCode != 200) {
        return ImageUploadResult.failure(
          message:
              'Server error getting signed URL: ${signedUrlResult.statusCode}',
          errorType: ImageUploadErrorType.serverError,
          errorCode: 'SERVER_ERROR_${signedUrlResult.statusCode}',
        );
      }

      final signedUrl = jsonDecode(signedUrlResult.body)["signedUrl"] as String;
      debugPrint('✅ Signed URL obtained successfully');

      // Intentar subir la imagen con reintentos
      final uploadResult = await NetworkService.executeWithRetry<http.Response>(
        () => _upload(signedUrl, imgFormat, image),
        maxRetries: 2, // Menos reintentos para upload porque es más pesado
        delayBetweenRetries: Duration(seconds: 3),
      );

      if (uploadResult == null) {
        return ImageUploadResult.failure(
          message: 'Upload timeout after retries',
          errorType: ImageUploadErrorType.uploadFailed,
          errorCode: 'UPLOAD_TIMEOUT',
        );
      }

      if (uploadResult.statusCode != 200) {
        return ImageUploadResult.failure(
          message: 'Failed to upload to S3: ${uploadResult.statusCode}',
          errorType: ImageUploadErrorType.uploadFailed,
          errorCode: 'S3_ERROR_${uploadResult.statusCode}',
        );
      }

      debugPrint('✅ Image uploaded successfully');
      final finalUrl =
          "${ApiConstants.s3UploadUrl}/$path/$imageName.$imgFormat";
      return ImageUploadResult.success(finalUrl);
    } on NetworkException catch (e) {
      debugPrint('❌ Network error during image upload: ${e.message}');
      return ImageUploadResult.failure(
        message: e.message,
        errorType: ImageUploadErrorType.networkError,
        errorCode: 'NETWORK_EXCEPTION',
      );
    } on FormatException catch (e) {
      debugPrint('❌ Format error during image upload: ${e.message}');
      return ImageUploadResult.failure(
        message: 'Invalid response format: ${e.message}',
        errorType: ImageUploadErrorType.serverError,
        errorCode: 'FORMAT_ERROR',
      );
    } catch (e) {
      debugPrint('❌ Unexpected error during image upload: $e');
      return ImageUploadResult.failure(
        message: 'Unexpected error: $e',
        errorType: ImageUploadErrorType.unknown,
        errorCode: 'UNKNOWN_ERROR',
      );
    }
  }

  /// Método de compatibilidad que devuelve bool (mantener para no romper código existente)
  Future<bool> uploadImage(
    XFile image,
    String path,
    String imageName,
    String imgFormat,
  ) async {
    final result = await uploadImageWithDetails(
      image,
      path,
      imageName,
      imgFormat,
    );
    return result.isSuccess;
  }

  /// Obtiene una URL firmada para subir la imagen a S3
  Future<http.Response> _getSignedURL(
    String path,
    String imgName,
    String imgFormat,
  ) async {
    try {
      // Construir URL de manera segura
      final baseUrl = ApiConstants.s3SignedUrl;
      final encodedPath = Uri.encodeComponent(path);
      final encodedFilename = Uri.encodeComponent('$imgName.$imgFormat');

      final uploadUrl = '$baseUrl?path=$encodedPath&filename=$encodedFilename';

      debugPrint('🔗 Requesting signed URL: $uploadUrl');

      final response = await http
          .get(
            Uri.parse(uploadUrl),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(Duration(seconds: 15));

      debugPrint('📡 Signed URL response: ${response.statusCode}');
      return response;
    } catch (e) {
      debugPrint('❌ Error getting signed URL: $e');
      rethrow;
    }
  }

  /// Sube la imagen usando la URL firmada de S3
  Future<http.Response> _upload(
    String signedUrl,
    String imgFormat,
    XFile image,
  ) async {
    try {
      debugPrint('📤 Starting image upload to: $signedUrl');

      final file = File(image.path);
      if (!await file.exists()) {
        throw Exception('Image file does not exist: ${image.path}');
      }

      final contentLength = await file.length();
      debugPrint('📁 Image file size: $contentLength bytes');

      // Validar tamaño de archivo (ej: máximo 10MB)
      const maxSizeBytes = 10 * 1024 * 1024; // 10MB
      if (contentLength > maxSizeBytes) {
        throw Exception(
          'Image file too large: $contentLength bytes (max: $maxSizeBytes)',
        );
      }

      final requestHeaders = {
        'Content-Type': 'image/$imgFormat',
        'Accept': '*/*',
        'Content-Length': contentLength.toString(),
        'Connection': 'keep-alive',
      };

      debugPrint('📋 Upload headers: $requestHeaders');

      final request = http.Request('PUT', Uri.parse(signedUrl));
      request.headers.addAll(requestHeaders);
      request.bodyBytes = await file.readAsBytes();

      debugPrint('🚀 Uploading ${request.bodyBytes.length} bytes...');

      final http.StreamedResponse streamedResponse = await request
          .send()
          .timeout(
            Duration(minutes: 5), // Timeout más largo para uploads
            onTimeout: () {
              throw TimeoutException(
                'Image upload timed out after 5 minutes',
                Duration(minutes: 5),
              );
            },
          );

      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('📤 Upload completed with status: ${response.statusCode}');

      if (response.statusCode != 200) {
        debugPrint('❌ Upload failed with body: ${response.body}');
      }

      return response;
    } catch (e) {
      debugPrint('❌ Error uploading image: $e');
      rethrow;
    }
  }
}
