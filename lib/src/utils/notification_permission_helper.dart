import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:running_app/src/presentation/widgets/global_widgets.dart';
import 'package:running_app/config/theme/helpers/hex_color.dart';
import 'package:running_app/src/utils/navigator_key.dart';

class NotificationPermissionHelper {
  /// Show the "why" dialog, then request permission if accepted.
  static Future<void> promptForNotifications() async {
    final status = await FirebaseMessaging.instance.getNotificationSettings();

    if (status.authorizationStatus == AuthorizationStatus.authorized) {
      // Already granted, do nothing or show a message if needed
      return;
    }

    bool shouldRequest = await GlobalWidgets.showConfirmationModal(
      navigatorKey.currentContext!,
      title: '¡No te pierdas ningún partido!',
      content:
          'Activa las notificaciones para recibir alertas sobre nuevos partidos, compra de entradas y resultados en tiempo real.',
      confirmText: 'Activar notificaciones',
      cancelText: 'En otro momento',
      icon: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: hexOrRGBToColor("#EEEDF4"),
          borderRadius: BorderRadius.circular(50),
        ),
        child: const Icon(Icons.notifications_active_outlined, size: 40),
      ),
      height: 300,
    );

    if (shouldRequest) {
      final settings = await FirebaseMessaging.instance.requestPermission();

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
          const SnackBar(content: Text('¡Notificaciones activadas!')),
        );
      } else if (settings.authorizationStatus == AuthorizationStatus.denied) {
        ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
          const SnackBar(
            content: Text(
              'Notificaciones desactivadas. Puedes habilitarlas en Configuración.',
            ),
          ),
        );
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
          const SnackBar(
            content: Text(
              '¡Las notificaciones están habilitadas provisionalmente!',
            ),
          ),
        );
      }
    }
  }
}
