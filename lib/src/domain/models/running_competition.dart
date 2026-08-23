import 'dart:convert';

// Modelo principal de la competencia
class RunningCompetition {
  final String id;
  final Company empresa;
  final int season;
  final DateTime date;
  final String hour;
  final String title;
  final String image;
  final String venueName;
  final String venueCity;
  final String venueDetails;
  final double latitude;
  final double longitude;
  final String status;
  final List<CompetitionSetting> settings;
  final bool? isApplyCodeDiscount;
  final bool? isApplyInvoice;
  final bool? isApplyDeuna;
  final bool? isApplyManual;
  final bool? isApplyTC;
  final String? banckName;
  final String? accountNumber;
  final String? accountType;
  final String? accountHoldersName;
  final String? documentNumber;
  final List<Sponsor> sponsors;
  final String logic;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RunningCompetition({
    required this.id,
    required this.empresa,
    required this.season,
    required this.date,
    required this.hour,
    required this.title,
    required this.image,
    required this.venueName,
    required this.venueCity,
    required this.venueDetails,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.settings,
    this.isApplyCodeDiscount,
    this.isApplyInvoice,
    this.isApplyDeuna,
    this.isApplyManual,
    this.isApplyTC,
    this.banckName,
    this.accountNumber,
    this.accountType,
    this.accountHoldersName,
    this.documentNumber,
    this.sponsors = const [],
    required this.logic,
    required this.createdAt,
    required this.updatedAt,
  });

  RunningCompetition copyWith({
    String? id,
    Company? empresa,
    int? season,
    DateTime? date,
    String? hour,
    String? image,
    String? title,
    String? venueName,
    String? venueCity,
    String? venueDetails,
    double? latitude,
    double? longitude,
    String? status,
    List<CompetitionSetting>? settings,
    bool? isApplyCodeDiscount,
    bool? isApplyInvoice,
    bool? isApplyDeuna,
    bool? isApplyManual,
    bool? isApplyTC,
    String? banckName,
    String? accountNumber,
    String? accountType,
    String? accountHoldersName,
    String? documentNumber,
    List<Sponsor>? sponsors,
    String? logic,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RunningCompetition(
      id: id ?? this.id,
      empresa: empresa ?? this.empresa,
      season: season ?? this.season,
      date: date ?? this.date,
      hour: hour ?? this.hour,
      image: image ?? this.image,
      title: title ?? this.title,
      venueName: venueName ?? this.venueName,
      venueCity: venueCity ?? this.venueCity,
      venueDetails: venueDetails ?? this.venueDetails,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
      settings: settings ?? this.settings,
      isApplyCodeDiscount: isApplyCodeDiscount ?? this.isApplyCodeDiscount,
      isApplyInvoice: isApplyInvoice ?? this.isApplyInvoice,
      isApplyDeuna: isApplyDeuna ?? this.isApplyDeuna,
      isApplyManual: isApplyManual ?? this.isApplyManual,
      isApplyTC: isApplyTC ?? this.isApplyTC,
      banckName: banckName ?? this.banckName,
      accountNumber: accountNumber ?? this.accountNumber,
      accountType: accountType ?? this.accountType,
      accountHoldersName: accountHoldersName ?? this.accountHoldersName,
      documentNumber: documentNumber ?? this.documentNumber,
      sponsors: sponsors ?? this.sponsors,
      logic: logic ?? this.logic,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'empresa': empresa.toJson(),
      'season': season,
      'date': date.toIso8601String(),
      'hour': hour,
      'title': title,
      'image': image,
      'venue_name': venueName,
      'venue_city': venueCity,
      'venue_details': venueDetails,
      'latitude': {'\$numberDecimal': latitude.toString()},
      'longitude': {'\$numberDecimal': longitude.toString()},
      'status': status,
      'settings': settings.map((s) => s.toJson()).toList(),
      'isApplyCodeDiscount': isApplyCodeDiscount,
      'isApplyInvoice': isApplyInvoice,
      'isApplyDeuna': isApplyDeuna,
      'isApplyManual': isApplyManual,
      'isApplyTC': isApplyTC,
      'banckName': banckName,
      'accountNumber': accountNumber,
      'accountType': accountType,
      'accountHoldersName': accountHoldersName,
      'documentNumber': documentNumber,
      'sponsors': sponsors.map((s) => s.toJson()).toList(),
      'logic': logic,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory RunningCompetition.fromJson(Map<String, dynamic> json) {
    // Parsear empresa: puede ser String ID o Map
    dynamic empresaData = json['empresa'];
    Company empresaParsed;

    if (empresaData is String) {
      // Si es un String ID, crear una Company vacía con solo el ID
      empresaParsed = Company(
        id: empresaData,
        razonSocial: '',
        nombreComercial: '',
        direccionMatriz: '',
        ruc: '',
        email: '',
        telefono: '',
        logo: '',
        iva: 0,
        codigoIva: 0,
        estado: 0,
        obligatorioContabilidad: false,
        requiereFacturacion: false,
        datosFacturacion: [],
        logic: 'a',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } else if (empresaData is Map<String, dynamic>) {
      empresaParsed = Company.fromJson(empresaData);
    } else {
      // Si es null o tipo desconocido, crear Company vacía
      empresaParsed = Company(
        id: '',
        razonSocial: '',
        nombreComercial: '',
        direccionMatriz: '',
        ruc: '',
        email: '',
        telefono: '',
        logo: '',
        iva: 0,
        codigoIva: 0,
        estado: 0,
        obligatorioContabilidad: false,
        requiereFacturacion: false,
        datosFacturacion: [],
        logic: 'a',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    return RunningCompetition(
      id: json['_id'] ?? '',
      empresa: empresaParsed,
      season: json['season'] ?? 0,
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      hour: json['hour'] ?? '',
      image: json['image'] ?? '',
      title: json['title'] ?? 'Nombre no disponible',
      venueName: json['venue_name'] ?? '',
      venueCity: json['venue_city'] ?? '',
      venueDetails: json['venue_details'] ?? '',
      latitude: _parseDecimal(json['latitude']),
      longitude: _parseDecimal(json['longitude']),
      status: json['status'] ?? '',
      settings:
          (json['settings'] as List<dynamic>?)
              ?.map((s) => CompetitionSetting.fromJson(s))
              .toList() ??
          [],
      isApplyCodeDiscount: json['isApplyCodeDiscount'],
      isApplyInvoice: json['isApplyInvoice'],
      isApplyDeuna: json['isApplyDeuna'],
      isApplyManual: json['isApplyManual'],
      isApplyTC: json['isApplyTC'],
      banckName: json['banckName'],
      accountNumber: json['accountNumber'],
      accountType: json['accountType'],
      accountHoldersName: json['accountHoldersName'],
      documentNumber: json['documentNumber'],
      sponsors: json['sponsors'] != null
          ? (json['sponsors'] as List<dynamic>)
                .whereType<Map<String, dynamic>>() // Filtrar solo Maps
                .map((s) => Sponsor.fromJson(s))
                .toList()
          : [],
      logic: json['logic'] ?? '',
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  static double _parseDecimal(dynamic value) {
    if (value == null) return 0.0;
    if (value is Map && value.containsKey('\$numberDecimal')) {
      return double.tryParse(value['\$numberDecimal'].toString()) ?? 0.0;
    }
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static List<RunningCompetition> parseCompetitions(String jsonString) {
    final parsed = jsonDecode(jsonString);
    final data = parsed['data'] as List<dynamic>;
    return data
        .map<RunningCompetition>((json) => RunningCompetition.fromJson(json))
        .toList();
  }
}

// Modelo de Empresa
class Company {
  final String id;
  final String razonSocial;
  final String nombreComercial;
  final String direccionMatriz;
  final String ruc;
  final String email;
  final String telefono;
  final String logo;
  final int iva;
  final int codigoIva;
  final int estado;
  final bool obligatorioContabilidad;
  final bool requiereFacturacion;
  final List<BillingData> datosFacturacion;
  final String logic;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? maxTicket;
  final bool? isApplyDeuna;
  final bool? isApplyManual;
  final bool? isApplyTC;
  final String? banckName;
  final String? accountNumber;
  final String? accountType;
  final String? accountHoldersName;
  final String? documentNumber;

  const Company({
    required this.id,
    required this.razonSocial,
    required this.nombreComercial,
    required this.direccionMatriz,
    required this.ruc,
    required this.email,
    required this.telefono,
    required this.logo,
    required this.iva,
    required this.codigoIva,
    required this.estado,
    required this.obligatorioContabilidad,
    required this.requiereFacturacion,
    required this.datosFacturacion,
    required this.logic,
    required this.createdAt,
    required this.updatedAt,
    this.maxTicket,
    this.isApplyDeuna,
    this.isApplyManual,
    this.isApplyTC,
    this.banckName,
    this.accountNumber,
    this.accountType,
    this.accountHoldersName,
    this.documentNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'razon_social': razonSocial,
      'nombre_comercial': nombreComercial,
      'direccion_matriz': direccionMatriz,
      'ruc': ruc,
      'email': email,
      'telefono': telefono,
      'logo': logo,
      'iva': iva,
      'codigo_iva': codigoIva,
      'estado': estado,
      'obligatorio_contabilidad': obligatorioContabilidad,
      'requiere_facturacion': requiereFacturacion,
      'datos_facturacion': datosFacturacion.map((d) => d.toJson()).toList(),
      'logic': logic,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      if (maxTicket != null) 'maxTicket': maxTicket,
      if (isApplyDeuna != null) 'isApplyDeuna': isApplyDeuna,
      if (isApplyManual != null) 'isApplyManual': isApplyManual,
      if (isApplyTC != null) 'isApplyTC': isApplyTC,
      if (banckName != null) 'banckName': banckName,
      if (accountNumber != null) 'accountNumber': accountNumber,
      if (accountType != null) 'accountType': accountType,
      if (accountHoldersName != null) 'accountHoldersName': accountHoldersName,
      if (documentNumber != null) 'documentNumber': documentNumber,
    };
  }

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['_id'] ?? '',
      razonSocial: json['razon_social'] ?? '',
      nombreComercial: json['nombre_comercial'] ?? '',
      direccionMatriz: json['direccion_matriz'] ?? '',
      ruc: json['ruc'] ?? '',
      email: json['email'] ?? '',
      telefono: json['telefono'] ?? '',
      logo: json['logo'] ?? '',
      iva: json['iva'] ?? 0,
      codigoIva: json['codigo_iva'] ?? 0,
      estado: json['estado'] ?? 0,
      obligatorioContabilidad: json['obligatorio_contabilidad'] ?? false,
      requiereFacturacion: json['requiere_facturacion'] ?? false,
      datosFacturacion:
          (json['datos_facturacion'] as List<dynamic>?)
              ?.map((d) => BillingData.fromJson(d))
              .toList() ??
          [],
      logic: json['logic'] ?? '',
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
      maxTicket: json['maxTicket'],
      isApplyDeuna: json['isApplyDeuna'],
      isApplyManual: json['isApplyManual'],
      isApplyTC: json['isApplyTC'],
      banckName: json['banckName'],
      accountNumber: json['accountNumber'],
      accountType: json['accountType'],
      accountHoldersName: json['accountHoldersName'],
      documentNumber: json['documentNumber'],
    );
  }
}

// Modelo de Datos de Facturación
class BillingData {
  final String numeroDocumento;
  final String nombres;
  final String email;
  final String celular;
  final String direccion;
  final String id;

  const BillingData({
    required this.numeroDocumento,
    required this.nombres,
    required this.email,
    required this.celular,
    required this.direccion,
    required this.id,
  });

  Map<String, dynamic> toJson() {
    return {
      'numero_documento': numeroDocumento,
      'nombres': nombres,
      'email': email,
      'celular': celular,
      'direccion': direccion,
      '_id': id,
    };
  }

  factory BillingData.fromJson(Map<String, dynamic> json) {
    return BillingData(
      numeroDocumento: json['numero_documento'] ?? '',
      nombres: json['nombres'] ?? '',
      email: json['email'] ?? '',
      celular: json['celular'] ?? '',
      direccion: json['direccion'] ?? '',
      id: json['_id'] ?? '',
    );
  }
}

// Modelo de Configuración de Competencia
class CompetitionSetting {
  final String id;
  final String category;
  final List<Distance> distance;
  final bool gender;
  final bool isTshirt;
  final bool isDisabled;
  final List<TshirtDetail> detailsTshirt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CompetitionSetting({
    required this.id,
    required this.category,
    required this.distance,
    required this.gender,
    required this.isTshirt,
    this.isDisabled = false,
    required this.detailsTshirt,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'category': category,
      'distance': distance.map((d) => d.toJson()).toList(),
      'gender': gender,
      'is_tshirt': isTshirt,
      'is_disabled': isDisabled,
      'details_tshirt': detailsTshirt.map((t) => t.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory CompetitionSetting.fromJson(Map<String, dynamic> json) {
    return CompetitionSetting(
      id: json['_id'] ?? '',
      category: json['category'] ?? '',
      distance:
          (json['distance'] as List<dynamic>?)
              ?.map((d) => Distance.fromJson(d))
              .toList() ??
          [],
      gender: json['gender'] ?? false,
      isTshirt: json['is_tshirt'] ?? false,
      isDisabled: json['is_disabled'] ?? false,
      detailsTshirt:
          (json['details_tshirt'] as List<dynamic>?)
              ?.map((t) => TshirtDetail.fromJson(t))
              .toList() ??
          [],
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}

// Modelo de Distancia
class Distance {
  final String id;
  final String km;
  final double price;
  final int availableSlots;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Distance({
    required this.id,
    required this.km,
    required this.price,
    required this.availableSlots,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'km': km,
      'price': {'\$numberDecimal': price.toString()},
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Distance.fromJson(Map<String, dynamic> json) {
    return Distance(
      id: json['_id'] ?? '',
      km: json['km'] ?? '',
      availableSlots: json['availableSlots'] ?? 0,
      price: _parseDecimal(json['price']),
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  static double _parseDecimal(dynamic value) {
    if (value == null) return 0.0;
    if (value is Map && value.containsKey('\$numberDecimal')) {
      return double.tryParse(value['\$numberDecimal'].toString()) ?? 0.0;
    }
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

// Modelo de Detalle de Camiseta
class TshirtDetail {
  final String id;
  final String size;
  final double price;

  const TshirtDetail({
    required this.id,
    required this.size,
    required this.price,
  });

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'size': size,
      'price': {'\$numberDecimal': price.toString()},
    };
  }

  factory TshirtDetail.fromJson(Map<String, dynamic> json) {
    return TshirtDetail(
      id: json['_id'] ?? '',
      size: json['size'] ?? '',
      price: _parseDecimal(json['price']),
    );
  }

  static double _parseDecimal(dynamic value) {
    if (value == null) return 0.0;
    if (value is Map && value.containsKey('\$numberDecimal')) {
      return double.tryParse(value['\$numberDecimal'].toString()) ?? 0.0;
    }
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

// Modelo de Sponsor
class Sponsor {
  final String id;
  final String empresa;
  final String logo;
  final String title;
  final String logic;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Sponsor({
    required this.id,
    required this.empresa,
    required this.logo,
    required this.title,
    required this.logic,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'empresa': empresa,
      'logo': logo,
      'title': title,
      'logic': logic,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Sponsor.fromJson(Map<String, dynamic> json) {
    return Sponsor(
      id: json['_id'] ?? '',
      empresa: json['empresa'] ?? '',
      logo: json['logo'] ?? '',
      title: json['title'] ?? '',
      logic: json['logic'] ?? '',
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}
