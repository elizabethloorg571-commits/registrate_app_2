class Abono {
  final String id;
  final String empresa;
  final String nombre;
  final double precioBase;
  final String logoUrl;
  final String color;
  final DateTime dateStartSuscriber;
  final DateTime dateEndSuscriber;
  final int suscriberQuantityDiscount;
  final int suscriberDiscount;
  final bool incluyeIva;
  final bool requiereAdulto;
  final String logic;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int v;

  Abono({
    required this.id,
    required this.empresa,
    required this.nombre,
    required this.precioBase,
    required this.logoUrl,
    required this.color,
    required this.dateStartSuscriber,
    required this.dateEndSuscriber,
    required this.suscriberQuantityDiscount,
    required this.suscriberDiscount,
    required this.incluyeIva,
    required this.requiereAdulto,
    required this.logic,
    required this.createdAt,
    required this.updatedAt,
    required this.v,
  });

  factory Abono.fromJson(Map<String, dynamic> json) {
    return Abono(
      id: json['_id'],
      empresa: json['empresa'],
      nombre: json['nombre'],
      precioBase: double.parse(json['precio_base']?['\$numberDecimal'] ?? '0'),
      logoUrl: json['logo_url'] ?? '',
      color: json['color'] ?? '',
      dateStartSuscriber: DateTime.parse(json['date_start_suscriber']),
      dateEndSuscriber: DateTime.parse(json['date_end_suscriber']),
      suscriberQuantityDiscount: json['suscriber_quantity_discount'] ?? 0,
      suscriberDiscount: json['suscriber_discount'] ?? 0,
      incluyeIva: json['incluye_iva'] ?? false,
      requiereAdulto: json['requiere_adulto'] ?? false,
      logic: json['logic'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      v: json['__v'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'empresa': empresa,
      'nombre': nombre,
      'precio_base': {'\$numberDecimal': precioBase.toString()},
      'logo_url': logoUrl,
      'color': color,
      'date_start_suscriber': dateStartSuscriber.toIso8601String(),
      'date_end_suscriber': dateEndSuscriber.toIso8601String(),
      'suscriber_quantity_discount': suscriberQuantityDiscount,
      'suscriber_discount': suscriberDiscount,
      'incluye_iva': incluyeIva,
      'requiere_adulto': requiereAdulto,
      'logic': logic,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      '__v': v,
    };
  }
}

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
  List<Abonado>? abonados;
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
    this.abonados,
    required this.datosFacturacion,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isAbonado {
    return abonados != null &&
        abonados!.any((abonado) => abonado.documentId == numDocumento);
  }

  Abonado? get abonado {
    try {
      return abonados?.firstWhere(
        (abonado) => abonado.documentId == numDocumento,
      );
    } catch (e) {
      return null;
    }
  }

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
      abonados: json['abonados'] != null
          ? (json['abonados'] as List).map((e) => Abonado.fromJson(e)).toList()
          : null,
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
      'abonados': abonados?.map((e) => e.toJson()).toList(),
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
      abonados: [],
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

class Abonado {
  String id;
  String empresa;
  String documentId;
  String? numberSubscriber;
  String typeSubscriber;
  DateTime dateStartSuscriber;
  DateTime dateEndSuscriber;
  int suscriberDiscount;
  int suscriberQuantityDiscount;
  int numberChild;
  String names;
  String lastNames;
  String? documentType;
  String cellphone;
  String email;
  String main;
  String? subSuscriber;
  Abono abono;
  bool isChild;
  String type;
  String? idDeuna;
  String? linkDeuna;
  String? idDatafast;
  String logic;
  String loteId;
  DateTime createdAt;
  DateTime updatedAt;

  Abonado({
    required this.id,
    required this.empresa,
    required this.names,
    required this.lastNames,
    required this.documentType,
    required this.documentId,
    required this.dateStartSuscriber,
    required this.dateEndSuscriber,
    required this.suscriberDiscount,
    required this.suscriberQuantityDiscount,
    this.numberChild = 0,
    required this.typeSubscriber,
    required this.cellphone,
    required this.email,
    this.numberSubscriber,
    required this.main,
    this.subSuscriber,
    required this.abono,
    required this.isChild,
    required this.type,
    this.idDeuna,
    this.linkDeuna,
    this.idDatafast,
    required this.loteId,
    required this.logic,
    required this.createdAt,
    required this.updatedAt,
  });

  String get fullName {
    return '$names $lastNames';
  }

  factory Abonado.fromJson(Map<String, dynamic> json) {
    return Abonado(
      id: json['_id'],
      empresa: json['empresa'],
      documentId: json['document_id'],
      numberSubscriber: json['number_subscriber'],
      typeSubscriber: json['type_subscriber'],
      dateStartSuscriber: DateTime.parse(json['date_start_suscriber']),
      dateEndSuscriber: DateTime.parse(json['date_end_suscriber']),
      suscriberDiscount: json['suscriber_discount'],
      suscriberQuantityDiscount: json['suscriber_quantity_discount'],
      numberChild: json['number_child'] ?? 0,
      names: json['names'],
      lastNames: json['last_names'],
      documentType: json['document_type'],
      cellphone: json['cellphone'],
      email: json['email'],
      main: json['main'],
      subSuscriber: json['sub_suscriber'],
      abono: Abono.fromJson(json['abono']),
      isChild: json['isChild'] ?? false,
      type: json['type'],
      idDeuna: json['idDeuna'],
      linkDeuna: json['linkDeuna'],
      idDatafast: json['idDatafast'],
      loteId: json['loteId'] ?? '',
      logic: json['logic'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'empresa': empresa,
      'names': names,
      'last_names': lastNames,
      'document_type': documentType,
      'document_id': documentId,
      'cellphone': cellphone,
      'email': email,
      'number_subscriber': numberSubscriber,
      'main': main,
      'sub_suscriber': subSuscriber,
      'abono': abono,
      'isChild': isChild,
      'type': type,

      'idDeuna': idDeuna,
      'linkDeuna': linkDeuna,
      'idDatafast': idDatafast,
      'loteId': loteId,
      'logic': logic,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
