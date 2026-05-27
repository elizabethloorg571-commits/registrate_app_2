import 'dart:async' show TimeoutException;
import 'dart:io' show SocketException;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class HttpUtils {
  /// Duración del timeout por defecto para todas las peticiones HTTP
  static const Duration defaultTimeout = Duration(seconds: 30);

  /// Cliente HTTP singleton con configuración de timeout
  static http.Client? _client;

  static http.Client get client {
    _client ??= http.Client();
    return _client!;
  }

  /// Realiza una petición GET con timeout y manejo de errores
  static Future<http.Response> get(
    Uri url, {
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    try {
      return await client
          .get(url, headers: headers)
          .timeout(timeout ?? defaultTimeout);
    } catch (e) {
      debugPrint('❌ GET request failed for $url: $e');
      rethrow;
    }
  }

  /// Realiza una petición POST con timeout y manejo de errores
  static Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Duration? timeout,
  }) async {
    try {
      return await client
          .post(url, headers: headers, body: body)
          .timeout(timeout ?? defaultTimeout);
    } catch (e) {
      debugPrint('❌ POST request failed for $url: $e');
      rethrow;
    }
  }

  /// Realiza una petición PUT con timeout y manejo de errores
  static Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Duration? timeout,
  }) async {
    try {
      return await client
          .put(url, headers: headers, body: body)
          .timeout(timeout ?? defaultTimeout);
    } catch (e) {
      debugPrint('❌ PUT request failed for $url: $e');
      rethrow;
    }
  }

  /// Realiza una petición DELETE con timeout y manejo de errores
  static Future<http.Response> delete(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Duration? timeout,
  }) async {
    try {
      return await client
          .delete(url, headers: headers, body: body)
          .timeout(timeout ?? defaultTimeout);
    } catch (e) {
      debugPrint('❌ DELETE request failed for $url: $e');
      rethrow;
    }
  }

  static Map<String, dynamic> defaultResponse({
    String message = "Error de conexión, intente nuevamente",
    Object? e,
  }) {
    if (e is http.ClientException || e is SocketException) {
      message =
          "Ha ocurrido un error en la red. Por favor, compruebe su conexión a internet";
    }
    if (e is TimeoutException) {
      message = "La solicitud ha expirado. Por favor, intente nuevamente";
    }

    return {"response": false, "message": message};
  }

  static final Map<String, bool> _resourceExistenceCache = {};

  static Future<bool> checkResourceExistsCached(String url) async {
    if (_resourceExistenceCache.containsKey(url)) {
      return _resourceExistenceCache[url]!;
    }

    final exists = await checkResourceExists(url);
    _resourceExistenceCache[url] = exists;
    return exists;
  }

  static Future<bool> checkResourceExists(String url) async {
    try {
      // Validar que la URL tenga un esquema HTTP/HTTPS válido
      if (url.isEmpty) return false;

      final uri = Uri.parse(url);

      // Solo permitir URLs HTTP/HTTPS
      if (!uri.hasScheme || (uri.scheme != 'http' && uri.scheme != 'https')) {
        debugPrint('❌ Invalid URL scheme for network request: $url');
        return false;
      }

      // Verificar que tenga un host válido
      if (!uri.hasAuthority || uri.host.isEmpty) {
        debugPrint('❌ Invalid URL host for network request: $url');
        return false;
      }

      final response = await http
          .head(uri)
          .timeout(
            Duration(seconds: 10),
            onTimeout: () {
              debugPrint('⏰ Timeout checking resource: $url');
              throw TimeoutException(
                'Resource check timeout',
                Duration(seconds: 10),
              );
            },
          );

      final exists = response.statusCode == 200;

      if (!exists) {
        debugPrint('⚠️ Resource check failed for $url: ${response.statusCode}');
      }

      return exists;
    } on SocketException catch (e) {
      debugPrint(
        '❌ Socket error checking resource existence for URL: $url - Error: ${e.message}',
      );
      // Para errores de DNS como "Failed host lookup", considerar como false
      return false;
    } on TimeoutException catch (e) {
      debugPrint(
        '❌ Timeout error checking resource existence for URL: $url - Error: ${e.message}',
      );
      return false;
    } on http.ClientException catch (e) {
      debugPrint(
        '❌ Client error checking resource existence for URL: $url - Error: ${e.message}',
      );
      return false;
    } catch (e) {
      debugPrint(
        '❌ Error checking resource existence for URL: $url - Error: $e',
      );
      return false;
    }
  }

  /// Verifica la conectividad a un dominio específico
  static Future<bool> canReachDomain(String domain) async {
    try {
      final testUrl = 'https://$domain';
      final response = await http
          .head(Uri.parse(testUrl))
          .timeout(Duration(seconds: 5));
      return response.statusCode < 400;
    } catch (e) {
      debugPrint('❌ Cannot reach domain $domain: $e');
      return false;
    }
  }
}
