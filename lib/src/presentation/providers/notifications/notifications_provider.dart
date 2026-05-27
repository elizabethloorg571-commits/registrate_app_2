import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:running_app/src/data/api/notifications/notificacions_api_service.dart';
import 'package:running_app/src/domain/models/notification.dart';

final notificationsProvider = FutureProvider.autoDispose((ref) async {
  final result =
      await NotificacionsApiService.getAllNotificationsByCurrentUser();
  List<Notification> notifications = [];
  if (result["response"] ?? false) {
    notifications = Notification.parseNotifications(jsonEncode(result));
    // sort competitions by date from newest to oldest
    notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Opcional: guardar información de la empresa del primer resultado
    // if (competitions.isNotEmpty) {
    //   final company = competitions.first.empresa;
    //   ref.read(companyIdProvider.notifier).state = company.id;
    //   ref.read(companyNameProvider.notifier).state = company.nombreComercial;
    //   ref.read(companyLogoUrlProvider.notifier).state = company.logo;
    // }

    return notifications;
  } else {
    final String message =
        result["message"] ?? result["error"] ?? "Error desconocido";
    throw Exception(message);
  }
});
