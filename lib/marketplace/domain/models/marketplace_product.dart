/// Entidad MarketplaceProduct
/// Modelo optimizado para el marketplace basado en Item existente
/// pero con estructura simplificada para consumo del cliente
class MarketplaceProduct {
  MarketplaceProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.discountPrice,
    this.discountPercentage,
    this.imageUrl,
    required this.images,
    required this.category,
    this.subCategory,
    required this.inStock,
    required this.stockQuantity,
    this.isFeatured = false,
    this.isNew = false,
    this.isBestseller = false,
    this.rating,
    this.reviewCount,
    this.tags = const [],
    this.companyId,
    this.appliesIva = true,
    this.logic = 'a',
    required this.createdAt,
    required this.updatedAt,
  });

  /// Crear desde Item existente (adaptador)
  factory MarketplaceProduct.fromItem(dynamic item) {
    // Extraer precio base
    double price = 0.0;
    if (item.basePrice != null) {
      price = item.basePrice is int
          ? (item.basePrice as int).toDouble()
          : (item.basePrice as double);
    }

    // Extraer primera imagen - itemImages es List<String>, no List<Object>
    String? imageUrl;
    List<String> images = [];
    if (item.itemImages != null &&
        item.itemImages is List &&
        item.itemImages.isNotEmpty) {
      images = List<String>.from(item.itemImages);
      imageUrl = images.isNotEmpty ? images[0] : null;
    } else if (item.imgUrl != null) {
      imageUrl = item.imgUrl;
      images = [item.imgUrl];
    }

    // Extraer categoría
    String category = '';
    String? subCategory;
    if (item.group != null) {
      category = item.group.name ?? '';
    }
    if (item.subGroup != null) {
      subCategory = item.subGroup.name ?? '';
    }

    // Determinar stock - stock es int?, no List
    // Si stock es null, consideramos stock ilimitado (999999)
    bool inStock = true;
    int stockQuantity = 999999;
    if (item.stock != null) {
      stockQuantity = item.stock is int ? item.stock as int : 0;
      inStock = stockQuantity > 0;
    }

    // Calcular descuento si existe
    double? discountPrice;
    int? discountPercentage;
    if (item.discount != null && item.discount > 0) {
      discountPercentage = item.discount.round();
      discountPrice = price * (1 - item.discount / 100);
    }

    // Determinar si es nuevo (creado en últimos 30 días)
    // createdAt ya es DateTime, no String
    bool isNew = false;
    if (item.createdAt != null) {
      final daysOld = DateTime.now()
          .difference(item.createdAt as DateTime)
          .inDays;
      isNew = daysOld <= 30;
    }

    // Extraer tags de collections - collections es List<Collection>, no List<String>
    final List<String> tags = [];
    bool isFeatured = false;
    bool isBestseller = false;
    if (item.collections != null && item.collections is List) {
      for (var collection in item.collections) {
        if (collection.name != null) {
          final collectionName = collection.name.toString().toLowerCase();
          tags.add(collection.name.toString());

          if (collectionName == 'featured' || collectionName == 'destacado') {
            isFeatured = true;
          }
          if (collectionName == 'bestseller' ||
              collectionName == 'más vendido') {
            isBestseller = true;
          }
        }
      }
    }

    return MarketplaceProduct(
      id: item.id ?? '',
      name: item.name ?? '',
      description: item.description ?? '',
      price: price,
      discountPrice: discountPrice,
      discountPercentage: discountPercentage,
      imageUrl: imageUrl,
      images: images,
      category: category,
      subCategory: subCategory,
      inStock: inStock,
      stockQuantity: stockQuantity,
      isFeatured: isFeatured,
      isNew: isNew,
      isBestseller: isBestseller,
      tags: tags,
      appliesIva: item.iva ?? true,
      createdAt: item.createdAt ?? DateTime.now(),
      updatedAt: item.updatedAt ?? DateTime.now(),
    );
  }

  /// Crear desde JSON
  factory MarketplaceProduct.fromJson(Map<String, dynamic> json) {
    return MarketplaceProduct(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      discountPrice: json['discountPrice']?.toDouble(),
      discountPercentage: json['discountPercentage'],
      imageUrl: json['imageUrl'],
      images: List<String>.from(json['images'] ?? []),
      category: json['category'] ?? '',
      subCategory: json['subCategory'],
      inStock: json['inStock'] ?? false,
      stockQuantity: json['stockQuantity'] ?? 0,
      isFeatured: json['isFeatured'] ?? false,
      isNew: json['isNew'] ?? false,
      isBestseller: json['isBestseller'] ?? false,
      rating: json['rating']?.toDouble(),
      reviewCount: json['reviewCount'],
      tags: List<String>.from(json['tags'] ?? []),
      companyId: json['companyId']?.toString(),
      appliesIva: _parseAppliesIva(json['appliesIva'] ?? json['iva']),
      logic: json['logic']?.toString() ?? 'a',
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
  final String id;
  final String name;
  final String description;
  final double price;
  final double? discountPrice;
  final int? discountPercentage;
  final String? imageUrl;
  final List<String> images;
  final String category;
  final String? subCategory;
  final bool inStock;
  final int stockQuantity;
  final bool isFeatured;
  final bool isNew;
  final bool isBestseller;
  final double? rating;
  final int? reviewCount;
  final List<String> tags;
  final String? companyId;
  final bool appliesIva;
  final String logic;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'discountPrice': discountPrice,
      'discountPercentage': discountPercentage,
      'imageUrl': imageUrl,
      'images': images,
      'category': category,
      'subCategory': subCategory,
      'inStock': inStock,
      'stockQuantity': stockQuantity,
      'isFeatured': isFeatured,
      'isNew': isNew,
      'isBestseller': isBestseller,
      'rating': rating,
      'reviewCount': reviewCount,
      'tags': tags,
      'companyId': companyId,
      'appliesIva': appliesIva,
      'logic': logic,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Obtener precio efectivo (con descuento si aplica)
  double get effectivePrice => discountPrice ?? price;

  /// Tiene descuento activo
  bool get hasDiscount => discountPrice != null && discountPrice! < price;

  /// Stock bajo (menos de 5 unidades, excluyendo stock ilimitado)
  bool get isLowStock => inStock && stockQuantity > 0 && stockQuantity < 5;

  /// Copiar con modificaciones
  MarketplaceProduct copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    double? discountPrice,
    int? discountPercentage,
    String? imageUrl,
    List<String>? images,
    String? category,
    String? subCategory,
    bool? inStock,
    int? stockQuantity,
    bool? isFeatured,
    bool? isNew,
    bool? isBestseller,
    double? rating,
    int? reviewCount,
    List<String>? tags,
    String? companyId,
    bool? appliesIva,
    String? logic,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MarketplaceProduct(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      discountPrice: discountPrice ?? this.discountPrice,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      imageUrl: imageUrl ?? this.imageUrl,
      images: images ?? this.images,
      category: category ?? this.category,
      subCategory: subCategory ?? this.subCategory,
      inStock: inStock ?? this.inStock,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      isFeatured: isFeatured ?? this.isFeatured,
      isNew: isNew ?? this.isNew,
      isBestseller: isBestseller ?? this.isBestseller,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      tags: tags ?? this.tags,
      companyId: companyId ?? this.companyId,
      appliesIva: appliesIva ?? this.appliesIva,
      logic: logic ?? this.logic,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

bool _parseAppliesIva(dynamic value) {
  if (value == null) return true;
  if (value is bool) return value;
  if (value is num) return value != 0;

  final normalized = value.toString().trim().toLowerCase();
  if (normalized == 'true' || normalized == '1') return true;
  if (normalized == 'false' || normalized == '0') return false;

  return true;
}
