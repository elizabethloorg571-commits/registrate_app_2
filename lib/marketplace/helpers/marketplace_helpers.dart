import '../domain/models/marketplace_product.dart';

/// Servicio para gestionar productos del Marketplace
/// Incluye caché local, manejo de errores y retry logic
class MarketplaceHelpers {
  /// Obtener productos para el marketplace
  /// Usa caché local para mejorar rendimiento

  // ==================== MÉTODOS PRIVADOS ====================

  // ==================== HELPERS ====================

  static MarketplaceProduct mapItemToMarketplaceProduct(
    Map<String, dynamic> item,
  ) {
    final price = extractPrice(item);
    final stockQuantity = calculateStock(item);

    return MarketplaceProduct.fromJson({
      'id': item['_id'] ?? item['id'] ?? '',
      'name': item['name'] ?? '',
      'description': item['description'] ?? '',
      'price': price,
      'discountPrice': extractDiscountPrice(item, basePrice: price),
      'discountPercentage': extractDiscountPercentage(item),
      'imageUrl': extractFirstImage(item),
      'images': extractImages(item),
      'category': extractCategoryName(item),
      'subCategory': extractSubCategoryName(item),
      'inStock': stockQuantity > 0,
      'stockQuantity': stockQuantity,
      'isFeatured': hasCollection(item, 'featured'),
      'isNew': isNewProduct(item),
      'isBestseller': hasCollection(item, 'bestseller'),
      'rating': toDouble(item['rating']),
      'reviewCount': toInt(item['reviewCount']),
      'tags': extractTags(item),
      'companyId': extractCompanyId(item),
      'appliesIva': extractAppliesIva(item),
      'logic': item['logic']?.toString() ?? 'a',
      'createdAt': parseDateToString(item['createdAt']),
      'updatedAt': parseDateToString(item['updatedAt']),
    });
  }

  static String? extractCompanyId(Map<String, dynamic> item) {
    final company = item['empresa'] ?? item['company'] ?? item['organization'];
    if (company is String && company.isNotEmpty) {
      return company;
    }
    if (company is Map) {
      return company['_id']?.toString() ??
          company['id']?.toString() ??
          company['empresa']?.toString();
    }
    return null;
  }

  static bool extractAppliesIva(Map<String, dynamic> item) {
    final value = item['iva'];
    if (value == null) return true;
    if (value is bool) return value;
    if (value is num) return value != 0;

    final normalized = value.toString().trim().toLowerCase();
    if (normalized == 'true' || normalized == '1') return true;
    if (normalized == 'false' || normalized == '0') return false;

    return true;
  }

  static double extractPrice(Map<String, dynamic> item) {
    return toDouble(item['price']) ?? toDouble(item['basePrice']) ?? 0.0;
  }

  static double? extractDiscountPrice(
    Map<String, dynamic> item, {
    double? basePrice,
  }) {
    final discount = toDouble(item['discount']);
    if (discount == null || discount == 0) return null;

    final price = basePrice ?? extractPrice(item);
    return price * (1 - discount / 100);
  }

  static int? extractDiscountPercentage(Map<String, dynamic> item) {
    final discount = toDouble(item['discount']);
    return discount?.round();
  }

  static String? extractFirstImage(Map<String, dynamic> item) {
    final images = item['images'] ?? item['itemImages'];
    if (images != null && images is List && images.isNotEmpty) {
      final firstImage = extractImageValue(images[0]);
      if (firstImage != null && firstImage.isNotEmpty) {
        return firstImage;
      }
    }
    final imgUrl = extractImageValue(item['imgUrl'] ?? item['imageUrl']);
    if (imgUrl != null && imgUrl.isNotEmpty) {
      return imgUrl;
    }
    return null;
  }

  static List<String> extractImages(Map<String, dynamic> item) {
    final List<String> images = [];
    final rawImages = item['images'] ?? item['itemImages'];
    if (rawImages != null && rawImages is List) {
      for (var img in rawImages) {
        final imageValue = extractImageValue(img);
        if (imageValue != null && imageValue.isNotEmpty) {
          images.add(imageValue);
        }
      }
    }
    final fallbackImage = extractImageValue(item['imgUrl'] ?? item['imageUrl']);
    if (images.isEmpty && fallbackImage != null && fallbackImage.isNotEmpty) {
      images.add(fallbackImage);
    }
    return images;
  }

  static int calculateStock(Map<String, dynamic> item) {
    final stock = item['stock'];
    final variants = item['variants'];
    // stock puede ser int directo o null
    // Si es null, consideramos stock ilimitado (999999)
    if (stock == null) {
      if (variants is List && variants.isNotEmpty) {
        return variants.fold<int>(0, (sum, variant) {
          if (variant is Map<String, dynamic>) {
            final variantStock = toInt(variant['stock']);
            return sum + (variantStock ?? 0);
          }
          return sum;
        });
      }
      return 999999;
    }
    if (stock is int) return stock;
    if (stock is double) return stock.toInt();
    // Si es List (formato antiguo), sumar
    if (stock is List) {
      return stock.fold<int>(0, (sum, s) {
        if (s is int) return sum + s;
        if (s is double) return sum + s.toInt();
        if (s is Map) {
          final stockValue = s['stock'];
          if (stockValue is int) return sum + stockValue;
          if (stockValue is double) return sum + stockValue.toInt();
        }
        return sum;
      });
    }
    return 0;
  }

  static String extractCategoryName(Map<String, dynamic> item) {
    final category = item['category'] ?? item['group'];
    if (category is Map) {
      return category['name']?.toString() ?? '';
    }
    if (category is String) {
      return category;
    }
    return '';
  }

  static String? extractSubCategoryName(Map<String, dynamic> item) {
    final subCategory =
        item['subcategory'] ?? item['subCategory'] ?? item['subGroup'];
    if (subCategory is Map) {
      return subCategory['name']?.toString();
    }
    if (subCategory is String && subCategory.isNotEmpty) {
      return subCategory;
    }
    return null;
  }

  static bool hasCollection(Map<String, dynamic> item, String collectionName) {
    final collections = item['collections'];
    if (collections == null || collections is! List) return false;

    final normalizedCollectionName = collectionName.toLowerCase();
    return collections.any((c) {
      if (c is String) return c.toLowerCase() == normalizedCollectionName;
      if (c is Map) {
        final value =
            c['name']?.toString() ?? c['collectionId']?.toString() ?? '';
        return value.toLowerCase() == normalizedCollectionName;
      }
      return false;
    });
  }

  static bool isNewProduct(Map<String, dynamic> item) {
    final createdAt = parseDate(item['createdAt']);
    if (createdAt == null) return false;

    final daysOld = DateTime.now().difference(createdAt).inDays;
    return daysOld <= 30;
  }

  static List<String> extractTags(Map<String, dynamic> item) {
    final collections = item['collections'];
    if (collections == null || collections is! List) return [];

    return collections
        .map<String>((c) {
          if (c is String) return c;
          if (c is Map) {
            return c['name']?.toString() ?? c['collectionId']?.toString() ?? '';
          }
          return '';
        })
        .where((tag) => tag.isNotEmpty)
        .toList();
  }

  static String? extractImageValue(dynamic image) {
    if (image is String) return image;
    if (image is Map) {
      return image['url']?.toString() ??
          image['imgUrl']?.toString() ??
          image['path']?.toString();
    }
    return null;
  }

  static double? toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    if (value is Map) {
      final decimalValue =
          value['\$numberDecimal'] ?? value['value'] ?? value['amount'];
      return toDouble(decimalValue);
    }
    return null;
  }

  static int? toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static DateTime? parseDate(dynamic date) {
    if (date == null) return null;
    if (date is DateTime) return date;
    if (date is String) {
      try {
        return DateTime.parse(date);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// Convertir fecha a String ISO para fromJson
  static String parseDateToString(dynamic date) {
    if (date == null) return DateTime.now().toIso8601String();
    if (date is DateTime) return date.toIso8601String();
    if (date is String) return date;
    return DateTime.now().toIso8601String();
  }

  static List<Map<String, dynamic>> extractProductsFromCatalogData(List data) {
    final List<Map<String, dynamic>> products = [];

    for (final rawEntry in data) {
      if (rawEntry is! Map<String, dynamic>) continue;

      if (looksLikeProduct(rawEntry)) {
        products.add(rawEntry);
        continue;
      }

      final rawProducts = rawEntry['products'];
      if (rawProducts is! List) continue;

      for (final rawProduct in rawProducts) {
        if (rawProduct is Map<String, dynamic> &&
            looksLikeProduct(rawProduct)) {
          products.add(rawProduct);
        }
      }
    }

    return products;
  }

  static bool looksLikeProduct(Map<String, dynamic> item) {
    return item.containsKey('price') ||
        item.containsKey('images') ||
        item.containsKey('variants');
  }

  static List<MarketplaceProduct> applyLocalFilters(
    List<MarketplaceProduct> products, {
    String? searchQuery,
    double? minPrice,
    double? maxPrice,
    bool? inStockOnly,
    bool? onSaleOnly,
    int? minDiscount,
    String? availability,
  }) {
    var filtered = products.toList();

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final normalizedQuery = searchQuery.toLowerCase().trim();
      filtered = filtered
          .where(
            (product) => product.name.toLowerCase().contains(normalizedQuery),
          )
          .toList();
    }

    if (minPrice != null) {
      filtered = filtered
          .where((product) => product.effectivePrice >= minPrice)
          .toList();
    }

    if (maxPrice != null) {
      filtered = filtered
          .where((product) => product.effectivePrice <= maxPrice)
          .toList();
    }

    if (inStockOnly == true) {
      filtered = filtered.where((product) => product.inStock).toList();
    }

    if (onSaleOnly == true) {
      filtered = filtered.where((product) => product.hasDiscount).toList();
    }

    if (minDiscount != null && minDiscount > 0) {
      filtered = filtered
          .where((product) => (product.discountPercentage ?? 0) >= minDiscount)
          .toList();
    }

    switch (availability) {
      case 'instock':
        filtered = filtered.where((product) => product.inStock).toList();
        break;
      case 'lowstock':
        filtered = filtered.where((product) => product.isLowStock).toList();
        break;
    }

    return filtered;
  }

  static void sortProducts(List<MarketplaceProduct> products, String? sortBy) {
    switch (sortBy) {
      case 'priceasc':
        products.sort((a, b) => a.effectivePrice.compareTo(b.effectivePrice));
        break;
      case 'pricedesc':
        products.sort((a, b) => b.effectivePrice.compareTo(a.effectivePrice));
        break;
      case 'nameasc':
        products.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'namedesc':
        products.sort((a, b) => b.name.compareTo(a.name));
        break;
    }
  }

  static List<MarketplaceProduct> paginateProducts(
    List<MarketplaceProduct> products, {
    required int page,
    required int limit,
  }) {
    if (products.isEmpty || limit <= 0) return [];

    final startIndex = (page - 1) * limit;
    if (startIndex >= products.length) return [];

    final endIndex = startIndex + limit > products.length
        ? products.length
        : startIndex + limit;

    return products.sublist(startIndex, endIndex);
  }
}
