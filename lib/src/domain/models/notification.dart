import 'dart:convert';

import 'package:running_app/src/domain/models/user.dart';

class Notification {
  final String id;
  final User user;
  final String title;
  final String message;
  final bool read;
  final DateTime createdAt;
  final DateTime updatedAt;

  Notification({
    required this.id,
    required this.user,
    required this.title,
    required this.message,
    required this.read,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['_id'],
      user: User.fromJson(json['usuario_app']),
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      read: json['read'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'usuario_app': user.toJson(),
      'title': title,
      'message': message,
      'read': read,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static List<Notification> parseNotifications(String responseBody) {
    final parsed = jsonDecode(responseBody);
    final data = parsed['data'] as List<dynamic>;
    return data
        .map<Notification>((json) => Notification.fromJson(json))
        .toList();
  }
}
