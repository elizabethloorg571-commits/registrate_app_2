import 'package:running_app/src/domain/models/running_competition.dart';

class InscriptionResponse {
  final bool response;
  final String message;
  final List<Inscription> data;
  final PaginationInfo pagination;

  InscriptionResponse({
    required this.response,
    required this.message,
    required this.data,
    required this.pagination,
  });

  factory InscriptionResponse.fromJson(Map<String, dynamic> json) {
    try {
      final dataList = json['data'] as List<dynamic>?;

      final inscriptions = <Inscription>[];

      if (dataList != null) {
        for (var i = 0; i < dataList.length; i++) {
          try {
            final inscription = Inscription.fromJson(
              dataList[i] as Map<String, dynamic>,
            );
            inscriptions.add(inscription);
          } catch (e) {
            rethrow;
          }
        }
      }

      return InscriptionResponse(
        response: json['response'] ?? false,
        message: json['message'] ?? '',
        data: inscriptions,
        pagination: PaginationInfo.fromJson(
          json['pagination'] as Map<String, dynamic>? ?? {},
        ),
      );
    } catch (e, _) {
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'response': response,
      'message': message,
      'data': data.map((e) => e.toJson()).toList(),
      'pagination': pagination.toJson(),
    };
  }
}

class Inscription {
  final String id;
  final InscriptionCompany empresa;
  final dynamic carrera; // Puede ser String ID o InscriptionRace
  final dynamic buyer; // Puede ser String ID o InscriptionBuyer
  final dynamic items; // Puede ser List<String> IDs o List<InscriptionItem>
  final double subTotal;
  final double ivaPct;
  final double ivaValue;
  final double total;
  final InscriptionDiscountCode? discountCode;
  final double discountValue;
  final String status;
  final String gateway;
  final String? gatewayRef;
  final String? gatewayLink;
  final dynamic resultDetails;
  final SriInfo sri;
  final String logic;
  final DateTime createdAt;
  final DateTime updatedAt;

  Inscription({
    required this.id,
    required this.empresa,
    required this.carrera,
    required this.buyer,
    required this.items,
    required this.subTotal,
    required this.ivaPct,
    required this.ivaValue,
    required this.total,
    this.discountCode,
    required this.discountValue,
    required this.status,
    required this.gateway,
    this.gatewayRef,
    this.gatewayLink,
    this.resultDetails,
    required this.sri,
    required this.logic,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Inscription.fromJson(Map<String, dynamic> json) {
    try {
      // Parsear carrera: puede ser String ID o Map
      dynamic carreraData = json['carrera'];
      dynamic carreraParsed;

      if (carreraData is String) {
        carreraParsed = carreraData;
      } else if (carreraData is Map<String, dynamic>) {
        carreraParsed = RunningCompetition.fromJson(carreraData);
      } else {
        carreraParsed = '';
      }

      // Parsear buyer: puede ser String ID o Map
      dynamic buyerData = json['buyer'];
      dynamic buyerParsed;

      if (buyerData is String) {
        buyerParsed = buyerData;
      } else if (buyerData is Map<String, dynamic>) {
        buyerParsed = InscriptionBuyer.fromJson(buyerData);
      } else {
        buyerParsed = '';
      }

      // Si el JSON contiene los datos completos de una carrera (RunningCompetition)
      // pero no tiene los campos de inscripción, tratarlo como una carrera asociada
      final bool isCarreraOnly =
          json.containsKey('title') &&
          json.containsKey('venue_name') &&
          !json.containsKey('buyer') &&
          !json.containsKey('items');

      if (isCarreraOnly) {
        // Este es un objeto de carrera, no una inscripción completa
        // Crear una inscripción mínima con la carrera
        final carrera = RunningCompetition.fromJson(json);

        final inscription = Inscription(
          id: json['_id'] ?? '',
          empresa: InscriptionCompany.fromJson(
            json['empresa'] as Map<String, dynamic>? ?? {},
          ),
          carrera: carrera,
          buyer: '', // Sin información del comprador
          items: [],
          subTotal: 0.0,
          ivaPct: 0.0,
          ivaValue: 0.0,
          total: 0.0,
          discountCode: null,
          discountValue: 0.0,
          status: json['status'] ?? 'pending',
          gateway: '',
          gatewayRef: null,
          gatewayLink: null,
          resultDetails: null,
          sri: SriInfo(enviado: false),
          logic: json['logic'] ?? 'a',
          createdAt: DateTime.parse(
            json['createdAt'] ?? DateTime.now().toIso8601String(),
          ),
          updatedAt: DateTime.parse(
            json['updatedAt'] ?? DateTime.now().toIso8601String(),
          ),
        );

        return inscription;
      }

      // Parsear items: puede ser List<String> IDs o List<InscriptionItem>
      dynamic itemsData = json['items'];
      dynamic itemsParsed;

      if (itemsData is List) {
        if (itemsData.isEmpty) {
          itemsParsed = [];
        } else if (itemsData.first is String) {
          // Items son IDs
          itemsParsed = itemsData.cast<String>();
        } else if (itemsData.first is Map<String, dynamic>) {
          // Items son objetos completos
          itemsParsed = itemsData
              .map(
                (item) =>
                    InscriptionItem.fromJson(item as Map<String, dynamic>),
              )
              .toList();
        } else {
          itemsParsed = [];
        }
      } else {
        itemsParsed = [];
      }

      final discountCode = InscriptionDiscountCode.fromDynamic(
        json['discountCode'] ?? json['discount_code'],
        fallbackDiscount: json['discount_value'],
      );

      final inscription = Inscription(
        id: json['_id'] ?? '',
        empresa: InscriptionCompany.fromJson(
          json['empresa'] as Map<String, dynamic>? ?? {},
        ),
        carrera: carreraParsed,
        buyer: buyerParsed,
        items: itemsParsed,
        subTotal: _parseDecimal(json['sub_total']),
        ivaPct: _parseDecimal(json['iva_pct']),
        ivaValue: _parseDecimal(json['iva_value']),
        total: _parseDecimal(json['total']),
        discountCode: discountCode,
        discountValue:
            discountCode?.descuento ?? _parseDecimal(json['discount_value']),
        status: json['status'] ?? 'pending',
        gateway: json['gateway'] ?? '',
        gatewayRef: json['gateway_ref'],
        gatewayLink: json['gateway_link'],
        resultDetails: json['resultDetails'],
        sri: SriInfo.fromJson(json['sri'] as Map<String, dynamic>? ?? {}),
        logic: json['logic'] ?? 'a',
        createdAt: DateTime.parse(
          json['createdAt'] ?? DateTime.now().toIso8601String(),
        ),
        updatedAt: DateTime.parse(
          json['updatedAt'] ?? DateTime.now().toIso8601String(),
        ),
      );

      return inscription;
    } catch (e, _) {
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    // Parsear items según su tipo
    dynamic itemsJson;
    if (items is List<InscriptionItem>) {
      itemsJson = (items as List<InscriptionItem>)
          .map((e) => e.toJson())
          .toList();
    } else if (items is List<String>) {
      itemsJson = items;
    } else {
      itemsJson = [];
    }

    return {
      '_id': id,
      'empresa': empresa.toJson(),
      'carrera': carrera is InscriptionRace ? carrera.toJson() : carrera,
      'buyer': buyer is InscriptionBuyer ? buyer.toJson() : buyer,
      'items': itemsJson,
      'sub_total': {'\$numberDecimal': subTotal.toStringAsFixed(2)},
      'iva_pct': {'\$numberDecimal': ivaPct.toStringAsFixed(2)},
      'iva_value': {'\$numberDecimal': ivaValue.toStringAsFixed(2)},
      'total': {'\$numberDecimal': total.toStringAsFixed(2)},
      'discountCode': discountCode?.toJson(),
      'discount_code': discountCode?.codigo,
      'discount_value': {'\$numberDecimal': discountValue.toStringAsFixed(2)},
      'status': status,
      'gateway': gateway,
      'gateway_ref': gatewayRef,
      'gateway_link': gatewayLink,
      'resultDetails': resultDetails,
      'sri': sri.toJson(),
      'logic': logic,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static double _parseDecimal(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is Map && value.containsKey('\$numberDecimal')) {
      return double.tryParse(value['\$numberDecimal'].toString()) ?? 0.0;
    }
    return double.tryParse(value.toString()) ?? 0.0;
  }
}

class InscriptionDiscountCode {
  final String? codigo;
  final double descuento;

  const InscriptionDiscountCode({this.codigo, required this.descuento});

  factory InscriptionDiscountCode.fromJson(Map<String, dynamic> json) {
    return InscriptionDiscountCode(
      codigo: json['codigo']?.toString(),
      descuento: _parseInscriptionDecimal(json['descuento']),
    );
  }

  static InscriptionDiscountCode? fromDynamic(
    dynamic value, {
    dynamic fallbackDiscount,
  }) {
    if (value is Map<String, dynamic>) {
      final parsed = InscriptionDiscountCode.fromJson(value);
      if ((parsed.codigo == null || parsed.codigo!.isEmpty) &&
          parsed.descuento <= 0) {
        return null;
      }
      return parsed;
    }

    final descuento = _parseInscriptionDecimal(fallbackDiscount);
    if (value is String && value.isNotEmpty) {
      return InscriptionDiscountCode(codigo: value, descuento: descuento);
    }

    if (descuento > 0) {
      return InscriptionDiscountCode(descuento: descuento);
    }

    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'codigo': codigo,
      'descuento': {'\$numberDecimal': descuento.toStringAsFixed(2)},
    };
  }
}

double _parseInscriptionDecimal(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  if (value is Map && value.containsKey('\$numberDecimal')) {
    return double.tryParse(value['\$numberDecimal'].toString()) ?? 0.0;
  }
  return double.tryParse(value.toString()) ?? 0.0;
}

class InscriptionCompany {
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
  final String logic;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? maxTicket;

  InscriptionCompany({
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
    required this.logic,
    required this.createdAt,
    required this.updatedAt,
    this.maxTicket,
  });

  factory InscriptionCompany.fromJson(Map<String, dynamic> json) {
    return InscriptionCompany(
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
      estado: json['estado'] ?? 1,
      obligatorioContabilidad: json['obligatorio_contabilidad'] ?? false,
      requiereFacturacion: json['requiere_facturacion'] ?? false,
      logic: json['logic'] ?? 'a',
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
      maxTicket: json['maxTicket'],
    );
  }

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
      'datos_facturacion': [], // Campo requerido por Company
      'logic': logic,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      if (maxTicket != null) 'maxTicket': maxTicket,
    };
  }
}

class InscriptionRace {
  final String id;
  final String empresa;
  final int season;
  final DateTime date;
  final String hour;
  final String venueName;
  final String venueCity;
  final String venueDetails;
  final double latitude;
  final double longitude;
  final List<InscriptionRaceSetting> settings;
  final String logic;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String title;
  final int isActive;
  final String status;

  InscriptionRace({
    required this.id,
    required this.empresa,
    required this.season,
    required this.date,
    required this.hour,
    required this.venueName,
    required this.venueCity,
    required this.venueDetails,
    required this.latitude,
    required this.longitude,
    required this.settings,
    required this.logic,
    required this.createdAt,
    required this.updatedAt,
    required this.title,
    required this.isActive,
    required this.status,
  });

  factory InscriptionRace.fromJson(Map<String, dynamic> json) {
    return InscriptionRace(
      id: json['_id'] ?? '',
      empresa: json['empresa'] ?? '',
      season: json['season'] ?? DateTime.now().year,
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      hour: json['hour'] ?? '00:00',
      venueName: json['venue_name'] ?? '',
      venueCity: json['venue_city'] ?? '',
      venueDetails: json['venue_details'] ?? '',
      latitude: _parseDecimal(json['latitude']),
      longitude: _parseDecimal(json['longitude']),
      settings:
          (json['settings'] as List<dynamic>?)
              ?.map(
                (e) =>
                    InscriptionRaceSetting.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      logic: json['logic'] ?? 'a',
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
      title: json['title'] ?? '',
      isActive: json['isActive'] ?? 1,
      status: json['status'] ?? 'NS',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'empresa': empresa,
      'season': season,
      'date': date.toIso8601String(),
      'hour': hour,
      'image': '', // Campo requerido por RunningCompetition
      'venue_name': venueName,
      'venue_city': venueCity,
      'venue_details': venueDetails,
      'latitude': {'\$numberDecimal': latitude.toString()},
      'longitude': {'\$numberDecimal': longitude.toString()},
      'settings': settings.map((e) => e.toJson()).toList(),
      'logic': logic,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'title': title,
      'isActive': isActive,
      'status': status,
    };
  }

  static double _parseDecimal(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is Map && value.containsKey('\$numberDecimal')) {
      return double.tryParse(value['\$numberDecimal'].toString()) ?? 0.0;
    }
    return double.tryParse(value.toString()) ?? 0.0;
  }
}

class InscriptionRaceSetting {
  final String id;
  final String category;
  final List<InscriptionDistance> distance;
  final bool gender;
  final bool isTshirt;
  final List<InscriptionTshirt> detailsTshirt;
  final DateTime createdAt;
  final DateTime updatedAt;

  InscriptionRaceSetting({
    required this.id,
    required this.category,
    required this.distance,
    required this.gender,
    required this.isTshirt,
    required this.detailsTshirt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory InscriptionRaceSetting.fromJson(Map<String, dynamic> json) {
    return InscriptionRaceSetting(
      id: json['_id'] ?? '',
      category: json['category'] ?? '',
      distance:
          (json['distance'] as List<dynamic>?)
              ?.map(
                (e) => InscriptionDistance.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      gender: json['gender'] ?? false,
      isTshirt: json['is_tshirt'] ?? false,
      detailsTshirt:
          (json['details_tshirt'] as List<dynamic>?)
              ?.map(
                (e) => InscriptionTshirt.fromJson(e as Map<String, dynamic>),
              )
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

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'category': category,
      'distance': distance.map((e) => e.toJson()).toList(),
      'gender': gender,
      'is_tshirt': isTshirt,
      'details_tshirt': detailsTshirt.map((e) => e.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class InscriptionDistance {
  final String id;
  final String km;
  final double price;
  final DateTime createdAt;
  final DateTime updatedAt;

  InscriptionDistance({
    required this.id,
    required this.km,
    required this.price,
    required this.createdAt,
    required this.updatedAt,
  });

  factory InscriptionDistance.fromJson(Map<String, dynamic> json) {
    return InscriptionDistance(
      id: json['_id'] ?? '',
      km: json['km'] ?? '',
      price: _parseDecimal(json['price']),
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'km': km,
      'price': {'\$numberDecimal': price.toStringAsFixed(2)},
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static double _parseDecimal(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is Map && value.containsKey('\$numberDecimal')) {
      return double.tryParse(value['\$numberDecimal'].toString()) ?? 0.0;
    }
    return double.tryParse(value.toString()) ?? 0.0;
  }
}

class InscriptionTshirt {
  final String id;
  final String size;
  final double price;

  InscriptionTshirt({
    required this.id,
    required this.size,
    required this.price,
  });

  factory InscriptionTshirt.fromJson(Map<String, dynamic> json) {
    return InscriptionTshirt(
      id: json['_id'] ?? '',
      size: json['size'] ?? '',
      price: _parseDecimal(json['price']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'size': size,
      'price': {'\$numberDecimal': price.toStringAsFixed(2)},
    };
  }

  static double _parseDecimal(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is Map && value.containsKey('\$numberDecimal')) {
      return double.tryParse(value['\$numberDecimal'].toString()) ?? 0.0;
    }
    return double.tryParse(value.toString()) ?? 0.0;
  }
}

class InscriptionBuyer {
  final String id;
  final String? rol;
  final String nombres;
  final String apellidos;
  final String tipoDocumento;
  final String numDocumento;
  final String celular;
  final String email;
  final String tipo;
  final int estado;
  final String foto;
  final String? facebookId;
  final String? appleId;
  final String? googleId;
  final String? abonado;
  final String logic;
  final BuyerBillingData? datosFacturacion;
  final bool isEmailVerified;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? empresa;

  InscriptionBuyer({
    required this.id,
    this.rol,
    required this.nombres,
    required this.apellidos,
    required this.tipoDocumento,
    required this.numDocumento,
    required this.celular,
    required this.email,
    required this.tipo,
    required this.estado,
    required this.foto,
    this.facebookId,
    this.appleId,
    this.googleId,
    this.abonado,
    required this.logic,
    this.datosFacturacion,
    required this.isEmailVerified,
    required this.createdAt,
    required this.updatedAt,
    this.empresa,
  });

  factory InscriptionBuyer.fromJson(Map<String, dynamic> json) {
    return InscriptionBuyer(
      id: json['_id'] ?? '',
      rol: json['rol'],
      nombres: json['nombres'] ?? '',
      apellidos: json['apellidos'] ?? '',
      tipoDocumento: json['tipo_documento'] ?? '',
      numDocumento: json['num_documento'] ?? '',
      celular: json['celular'] ?? '',
      email: json['email'] ?? '',
      tipo: json['tipo'] ?? '',
      estado: json['estado'] ?? 1,
      foto: json['foto'] ?? '',
      facebookId: json['facebook_id'],
      appleId: json['apple_id'],
      googleId: json['google_id'],
      abonado: json['abonado'],
      logic: json['logic'] ?? 'a',
      datosFacturacion: json['datos_facturacion'] != null
          ? BuyerBillingData.fromJson(
              json['datos_facturacion'] as Map<String, dynamic>,
            )
          : null,
      isEmailVerified: json['isEmailVerified'] ?? false,
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
      empresa: json['empresa'],
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
      'tipo': tipo,
      'estado': estado,
      'foto': foto,
      'facebook_id': facebookId,
      'apple_id': appleId,
      'google_id': googleId,
      'abonado': abonado,
      'logic': logic,
      if (datosFacturacion != null)
        'datos_facturacion': datosFacturacion!.toJson(),
      'isEmailVerified': isEmailVerified,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      if (empresa != null) 'empresa': empresa,
    };
  }
}

class BuyerBillingData {
  final String id;
  final String nombres;
  final String apellidos;
  final String? tipoDocumento;
  final String numDocumento;
  final String direccion;
  final String celular;
  final String email;

  BuyerBillingData({
    required this.id,
    required this.nombres,
    required this.apellidos,
    this.tipoDocumento,
    required this.numDocumento,
    required this.direccion,
    required this.celular,
    required this.email,
  });

  factory BuyerBillingData.fromJson(Map<String, dynamic> json) {
    return BuyerBillingData(
      id: json['_id'] ?? '',
      nombres: json['nombres'] ?? '',
      apellidos: json['apellidos'] ?? '',
      tipoDocumento: json['tipo_documento'],
      numDocumento: json['num_documento'] ?? '',
      direccion: json['direccion'] ?? '',
      celular: json['celular'] ?? '',
      email: json['email'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'nombres': nombres,
      'apellidos': apellidos,
      'tipo_documento': tipoDocumento,
      'num_documento': numDocumento,
      'direccion': direccion,
      'celular': celular,
      'email': email,
    };
  }
}

class SriInfo {
  final String? numComprobante;
  final String? xml;
  final String? pdf;
  final String? estado;
  final String? respuesta;
  final String? claveAcceso;
  final bool enviado;

  SriInfo({
    this.numComprobante,
    this.xml,
    this.pdf,
    this.estado,
    this.respuesta,
    this.claveAcceso,
    required this.enviado,
  });

  factory SriInfo.fromJson(Map<String, dynamic> json) {
    return SriInfo(
      numComprobante: json['num_comprobante'],
      xml: json['xml'],
      pdf: json['pdf'],
      estado: json['estado'],
      respuesta: json['respuesta'],
      claveAcceso: json['clave_acceso'],
      enviado: json['enviado'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'num_comprobante': numComprobante,
      'xml': xml,
      'pdf': pdf,
      'estado': estado,
      'respuesta': respuesta,
      'clave_acceso': claveAcceso,
      'enviado': enviado,
    };
  }
}

class PaginationInfo {
  final int currentPage;
  final int totalPages;
  final int totalCount;
  final int limit;

  PaginationInfo({
    required this.currentPage,
    required this.totalPages,
    required this.totalCount,
    required this.limit,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      currentPage: json['currentPage'] ?? 1,
      totalPages: json['totalPages'] ?? 1,
      totalCount: json['totalCount'] ?? 0,
      limit: json['limit'] ?? 100,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentPage': currentPage,
      'totalPages': totalPages,
      'totalCount': totalCount,
      'limit': limit,
    };
  }
}

// Modelo de Item/Participante de Inscripción
class InscriptionItem {
  final String id;
  final String carrera;
  final String order;
  final String buyer;
  final String persona;
  final String dni;
  final String fullName;
  final String email;
  final String phone;
  final String category;
  final String distanceKm;
  final String gender;
  final String isTshirt;
  final String? tshirtSize;
  final String? tshirtPrice;
  final double basePrice;
  final double discountPct;
  final String? discountCode;
  final double subTotal;
  final double ivaPct;
  final double ivaValue;
  final double total;
  final String status;
  final String? dorsalNumber;
  final bool checkedIn;
  final DateTime? checkedInAt;
  final String? checkedInBy;
  final String logic;
  final String qrCode;
  final DateTime createdAt;
  final DateTime updatedAt;

  InscriptionItem({
    required this.id,
    required this.carrera,
    required this.order,
    required this.buyer,
    required this.persona,
    required this.dni,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.category,
    required this.distanceKm,
    required this.gender,
    required this.isTshirt,
    this.tshirtSize,
    this.tshirtPrice,
    required this.basePrice,
    required this.discountPct,
    this.discountCode,
    required this.subTotal,
    required this.ivaPct,
    required this.ivaValue,
    required this.total,
    required this.status,
    this.dorsalNumber,
    required this.checkedIn,
    this.checkedInAt,
    this.checkedInBy,
    required this.logic,
    required this.qrCode,
    required this.createdAt,
    required this.updatedAt,
  });

  factory InscriptionItem.fromJson(Map<String, dynamic> json) {
    return InscriptionItem(
      id: json['_id'] ?? '',
      carrera: json['carrera'] ?? '',
      order: json['order'] ?? '',
      buyer: json['buyer'] ?? '',
      persona: json['persona'] ?? '',
      dni: json['dni'] ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      category: json['category'] ?? '',
      distanceKm: json['distance_km'] ?? '',
      gender: json['gender'] ?? '',
      isTshirt: json['is_tshirt'] ?? '',
      tshirtSize: json['tshirt_size'],
      tshirtPrice: json['tshirt_price'],
      basePrice: _parseDecimal(json['base_price']),
      discountPct: _parseDecimal(json['discount_pct']),
      discountCode: json['discount_code'],
      subTotal: _parseDecimal(json['sub_total']),
      ivaPct: _parseDecimal(json['iva_pct']),
      ivaValue: _parseDecimal(json['iva_value']),
      total: _parseDecimal(json['total']),
      status: json['status'] ?? '',
      dorsalNumber: json['dorsalNumber'],
      checkedIn: json['checkedIn'] ?? false,
      checkedInAt: json['checkedInAt'] != null
          ? DateTime.parse(json['checkedInAt'])
          : null,
      checkedInBy: json['checkedInBy'],
      logic: json['logic'] ?? '',
      qrCode: json['qrCode'] ?? '',
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'carrera': carrera,
      'order': order,
      'buyer': buyer,
      'persona': persona,
      'dni': dni,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'category': category,
      'distance_km': distanceKm,
      'gender': gender,
      'is_tshirt': isTshirt,
      'tshirt_size': tshirtSize,
      'tshirt_price': tshirtPrice,
      'base_price': {'\$numberDecimal': basePrice.toStringAsFixed(2)},
      'discount_pct': {'\$numberDecimal': discountPct.toStringAsFixed(2)},
      'discount_code': discountCode,
      'sub_total': {'\$numberDecimal': subTotal.toStringAsFixed(2)},
      'iva_pct': {'\$numberDecimal': ivaPct.toStringAsFixed(2)},
      'iva_value': {'\$numberDecimal': ivaValue.toStringAsFixed(2)},
      'total': {'\$numberDecimal': total.toStringAsFixed(2)},
      'status': status,
      'dorsalNumber': dorsalNumber,
      'checkedIn': checkedIn,
      'checkedInAt': checkedInAt?.toIso8601String(),
      'checkedInBy': checkedInBy,
      'logic': logic,
      'qrCode': qrCode,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static double _parseDecimal(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is Map && value.containsKey('\$numberDecimal')) {
      return double.tryParse(value['\$numberDecimal'].toString()) ?? 0.0;
    }
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
