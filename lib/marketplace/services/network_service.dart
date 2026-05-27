import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Servicio para manejar la conectividad de red y validar URLs
class NetworkService {
  static final Connectivity _connectivity = Connectivity();

  /// Verifica si hay conectividad de red
  static Future<bool> hasNetworkConnection() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result.any(
        (element) =>
            element == ConnectivityResult.mobile ||
            element == ConnectivityResult.wifi ||
            element == ConnectivityResult.ethernet,
      );
    } catch (e) {
      debugPrint('❌ Error checking network connectivity: $e');
      return false;
    }
  }

  /// Verifica si una URL específica es alcanzable
  static Future<bool> isUrlReachable(
    String url, {
    Duration timeout = const Duration(seconds: 10),
    bool acceptForbidden = false,
  }) async {
    try {
      final uri = Uri.parse(url);

      // Validar que la URI sea válida
      if (!uri.hasScheme || !uri.hasAuthority) {
        debugPrint('❌ Invalid URL format: $url');
        return false;
      }

      // Realizar una petición HEAD para verificar conectividad sin descargar contenido
      final response = await http.head(uri).timeout(timeout);

      // Considerar exitoso si el código de estado es 2xx, 3xx, o 403 si se permite
      final isReachable =
          (response.statusCode >= 200 && response.statusCode < 400) ||
          (acceptForbidden && response.statusCode == 403);

      if (isReachable) {
        debugPrint('✅ URL reachable: $url (${response.statusCode})');
      } else {
        debugPrint('⚠️ URL returned error: $url (${response.statusCode})');
      }

      return isReachable;
    } on SocketException catch (e) {
      debugPrint('❌ Socket error for URL $url: ${e.message}');
      return false;
    } on TimeoutException catch (e) {
      debugPrint('❌ Timeout error for URL $url: ${e.message}');
      return false;
    } on http.ClientException catch (e) {
      debugPrint('❌ Client error for URL $url: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('❌ Unexpected error for URL $url: $e');
      return false;
    }
  }

  /// Verifica la conectividad a AWS S3 específicamente
  static Future<bool> isAwsS3Reachable({String region = 'us-east-1'}) async {
    final testUrl = 'https://s3.$region.amazonaws.com';
    return await isUrlReachable(testUrl, acceptForbidden: true);
  }

  /// Obtiene información detallada del estado de la red
  static Future<NetworkStatus> getNetworkStatus() async {
    try {
      final hasConnection = await hasNetworkConnection();

      if (!hasConnection) {
        return NetworkStatus(
          isConnected: false,
          connectionType: 'none',
          canReachInternet: false,
          error: 'No network connection available',
        );
      }

      final result = await _connectivity.checkConnectivity();
      final connectionType = result.first.name;

      // Verificar si realmente puede acceder a internet
      final canReachInternet = await isUrlReachable(
        'https://www.google.com',
        timeout: Duration(seconds: 5),
      );

      return NetworkStatus(
        isConnected: hasConnection,
        connectionType: connectionType,
        canReachInternet: canReachInternet,
        error: canReachInternet ? null : 'Connected but cannot reach internet',
      );
    } catch (e) {
      return NetworkStatus(
        isConnected: false,
        connectionType: 'unknown',
        canReachInternet: false,
        error: 'Error checking network status: $e',
      );
    }
  }

  /// Ejecuta una operación de red con reintentos y manejo de errores
  static Future<T?> executeWithRetry<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration delayBetweenRetries = const Duration(seconds: 2),
    bool checkNetworkFirst = true,
  }) async {
    if (checkNetworkFirst) {
      final hasNetwork = await hasNetworkConnection();
      if (!hasNetwork) {
        debugPrint('❌ No network connection available for operation');
        throw NetworkException('No network connection available');
      }
    }

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        debugPrint('🔄 Network operation attempt $attempt/$maxRetries');
        final result = await operation();
        debugPrint('✅ Network operation successful on attempt $attempt');
        return result;
      } on SocketException catch (e) {
        debugPrint('❌ SocketException on attempt $attempt: ${e.message}');
        if (attempt == maxRetries) {
          throw NetworkException(
            'DNS lookup failed after $maxRetries attempts: ${e.message}',
          );
        }
      } on TimeoutException catch (e) {
        debugPrint('❌ TimeoutException on attempt $attempt: ${e.message}');
        if (attempt == maxRetries) {
          throw NetworkException(
            'Request timeout after $maxRetries attempts: ${e.message}',
          );
        }
      } on http.ClientException catch (e) {
        debugPrint('❌ ClientException on attempt $attempt: ${e.message}');
        if (attempt == maxRetries) {
          throw NetworkException(
            'Client error after $maxRetries attempts: ${e.message}',
          );
        }
      } catch (e) {
        debugPrint('❌ Unexpected error on attempt $attempt: $e');
        if (attempt == maxRetries) {
          throw NetworkException(
            'Unexpected error after $maxRetries attempts: $e',
          );
        }
      }

      if (attempt < maxRetries) {
        debugPrint(
          '⏳ Waiting ${delayBetweenRetries.inSeconds}s before retry...',
        );
        await Future.delayed(delayBetweenRetries);
      }
    }

    return null;
  }
}

/// Información del estado de la red
class NetworkStatus {
  final bool isConnected;
  final String connectionType;
  final bool canReachInternet;
  final String? error;

  NetworkStatus({
    required this.isConnected,
    required this.connectionType,
    required this.canReachInternet,
    this.error,
  });

  bool get isHealthy => isConnected && canReachInternet && error == null;

  @override
  String toString() {
    return 'NetworkStatus(connected: $isConnected, type: $connectionType, internet: $canReachInternet, error: $error)';
  }
}

/// Excepción personalizada para errores de red
class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);

  @override
  String toString() => 'NetworkException: $message';
}
