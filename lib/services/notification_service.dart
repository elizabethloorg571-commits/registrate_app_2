import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Servicio centralizado para gestionar permisos y registro de notificaciones
class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  static const _tokenKey = 'notif_last_token';

  /// Registrar/actualizar token FCM si el usuario YA está autenticado.
  /// - iOS: solo registra si ya hay permiso (authorized o provisional).
  /// - Android: registra el token sin solicitar permisos (no muestra prompt).
  Future<void> ensureRegisteredForSignedInUser({
    required String? userId,
  }) async {
    if (userId == null || userId.isEmpty) return;

    if (Platform.isIOS) {
      final settings = await FirebaseMessaging.instance
          .getNotificationSettings();
      final allowed =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
      if (!allowed) return; // No pedir permiso aquí
    }

    await _registerOrUpdateToken(userId);
  }

  /// Pedir permisos (cuando tú lo decidas, por ejemplo post-login) y registrar token si se concede.
  Future<void> requestPermissionsAndRegister({required String? userId}) async {
    if (userId == null || userId.isEmpty) return;

    if (Platform.isIOS) {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      final allowed =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
      if (!allowed) return;
    }
    // En Android evitamos solicitar permisos aquí para no forzar prompt; igual registramos el token.
    await _registerOrUpdateToken(userId);
  }

  Future<void> _registerOrUpdateToken(String userId) async {
    final prefs = await SharedPreferences.getInstance();

    // En iOS, esperar a que el token APNS esté disponible con reintentos
    String? token;
    if (Platform.isIOS) {
      token = await _getTokenWithRetry();
    } else {
      token = await FirebaseMessaging.instance.getToken();
    }

    if (token == null) return;

    final lastToken = prefs.getString(_tokenKey);
    if (lastToken == token) return;

    // TODO: enviar token a backend asociado a userId si aplica
    // await DevicesApiService.registerFcmToken(userId: userId, token: token);

    await prefs.setString(_tokenKey, token);
  }

  /// Intenta obtener el token FCM con reintentos en iOS
  Future<String?> _getTokenWithRetry({
    int maxAttempts = 5,
    Duration delay = const Duration(seconds: 2),
  }) async {
    for (int i = 0; i < maxAttempts; i++) {
      try {
        final token = await FirebaseMessaging.instance.getToken();
        if (token != null) {
          return token;
        }
      } catch (e) {
        // Ignorar error y reintentar
      }

      if (i < maxAttempts - 1) {
        await Future.delayed(delay);
      }
    }
    return null;
  }
}
