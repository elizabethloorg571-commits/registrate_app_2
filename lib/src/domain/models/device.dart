class Device {
  final String id;
  final String? user;
  final String userApp;
  final String alias;
  final String token;
  final DateTime createdAt;
  final DateTime updatedAt;

  Device({
    required this.id,
    this.user,
    required this.userApp,
    required this.alias,
    required this.token,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['_id'],
      user: json['user'],
      userApp: json['user_app'],
      alias: json['alias'],
      token: json['token'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}
