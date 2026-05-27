class User {
  String id;
  String rol;
  String nombres;
  String apellidos;
  String tipoDocumento;
  String numDocumento;
  String celular;
  String email;
  String? password;
  String tipo;
  String? empresa;
  String logic;
  int estado;
  String foto;
  String? facebookId;
  String? appleId;
  String? googleId;
  Map<String, dynamic>? datosFacturacion;
  DateTime createdAt;
  DateTime updatedAt;

  User({
    required this.id,
    required this.rol,
    required this.nombres,
    required this.apellidos,
    required this.tipoDocumento,
    required this.numDocumento,
    required this.celular,
    required this.email,
    this.password,
    required this.tipo,
    this.empresa,
    this.logic = 'a',
    this.foto = '',
    required this.estado,
    required this.facebookId,
    required this.appleId,
    required this.googleId,
    required this.datosFacturacion,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'],
      rol: json['rol'] ?? 'cliente',
      nombres: json['nombres'],
      apellidos: json['apellidos'],
      tipoDocumento: json['tipo_documento'] ?? '',
      numDocumento: json['num_documento'] ?? '',
      celular: json['celular'] ?? '',
      email: json['email'] ?? '',
      password: json['password'],
      tipo: json['tipo'] ?? 'usuario',
      empresa: json['empresa']?.toString(),
      logic: json['logic'] ?? 'a',
      foto: json['foto'] ?? '',
      estado: json['estado'] ?? 1,
      facebookId: json['facebook_id'],
      appleId: json['apple_id'],
      googleId: json['google_id'],
      datosFacturacion: json['datos_facturacion'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'rol': rol,
      'nombres': nombres,
      'apellidos': apellidos,
      'tipo_documento': tipoDocumento,
      'num_documento': numDocumento,
      'celular': celular,
      'email': email,
      'password': password,
      'tipo': tipo,
      'empresa': empresa,
      'logic': logic,
      'foto': foto,
      'estado': estado,
      'facebook_id': facebookId,
      'apple_id': appleId,
      'google_id': googleId,
      'datos_facturacion': datosFacturacion,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  //mock user
  static User mockUser() {
    return User(
      id: 'mock_user_id',
      rol: 'cliente',
      nombres: 'John',
      apellidos: 'Doe',
      tipoDocumento: 'cedula',
      numDocumento: '1234567890',
      celular: '+593987654321',
      email: 'john.doe@example.com',
      password: 'password123',
      tipo: 'usuario',
      empresa: 'mock_company_id',
      logic: 'a',
      foto: 'https://example.com/avatar.jpg',
      estado: 1,
      facebookId: null,
      appleId: null,
      googleId: null,
      datosFacturacion: {
        'razon_social': 'John Doe',
        'ruc': '1234567890001',
        'direccion': 'Av. Principal 123',
        'telefono': '+593987654321',
        'email': 'john.doe@example.com',
      },
      createdAt: DateTime.now().subtract(Duration(days: 30)),
      updatedAt: DateTime.now(),
    );
  }
}
