import 'package:flutter/material.dart';

/// Entidad de Categoría del Marketplace
class MarketplaceCategory {
  MarketplaceCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    this.backendIds = const [],
    this.imageUrl,
    this.productCount = 0,
    this.isPopular = false,
  });

  factory MarketplaceCategory.fromJson(Map<String, dynamic> json) {
    final name = (json['name'] ?? '').toString();
    return MarketplaceCategory(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: name,
      description: (json['description'] ?? '').toString(),
      icon: _iconFromJson(json['icon'], name),
      color: _colorFromJson(json['color'], name),
      backendIds: _backendIdsFromJson(json),
      imageUrl: json['imageUrl'],
      productCount: json['productCount'] ?? 0,
      isPopular: json['isPopular'] ?? false,
    );
  }
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final List<String> backendIds;
  final String? imageUrl;
  final int productCount;
  final bool isPopular;

  MarketplaceCategory copyWith({
    String? id,
    String? name,
    String? description,
    IconData? icon,
    Color? color,
    List<String>? backendIds,
    String? imageUrl,
    int? productCount,
    bool? isPopular,
  }) {
    return MarketplaceCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      backendIds: backendIds ?? this.backendIds,
      imageUrl: imageUrl ?? this.imageUrl,
      productCount: productCount ?? this.productCount,
      isPopular: isPopular ?? this.isPopular,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon.codePoint,
      'color': color.toARGB32(),
      'backendIds': backendIds,
      'imageUrl': imageUrl,
      'productCount': productCount,
      'isPopular': isPopular,
    };
  }

  static List<String> _backendIdsFromJson(Map<String, dynamic> json) {
    final ids = <String>{};
    final rawBackendIds = json['backendIds'];
    if (rawBackendIds is List) {
      for (final rawId in rawBackendIds) {
        final id = rawId?.toString() ?? '';
        if (id.isNotEmpty) ids.add(id);
      }
    }

    final id = (json['id'] ?? json['_id'] ?? '').toString();
    if (id.isNotEmpty) ids.add(id);

    return ids.toList();
  }

  /// Mapa de codepoints a iconos const para preservar round-trip sin
  /// instanciar IconData con valores dinámicos (requerido por tree-shake).
  static final _codePointToIcon = <int, IconData>{
    Icons.shopping_bag.codePoint: Icons.shopping_bag,
    Icons.local_drink.codePoint: Icons.local_drink,
    Icons.restaurant.codePoint: Icons.restaurant,
    Icons.sports_soccer.codePoint: Icons.sports_soccer,
    Icons.devices.codePoint: Icons.devices,
    Icons.home.codePoint: Icons.home,
    Icons.category.codePoint: Icons.category,
    Icons.store.codePoint: Icons.store,
    Icons.fitness_center.codePoint: Icons.fitness_center,
    Icons.checkroom.codePoint: Icons.checkroom,
  };

  static IconData _iconFromJson(dynamic iconData, String categoryName) {
    if (iconData is int) {
      return _codePointToIcon[iconData] ?? Icons.category;
    }
    final normalized = categoryName.toLowerCase();
    if (normalized.contains('ropa') || normalized.contains('moda')) {
      return Icons.shopping_bag;
    }
    if (normalized.contains('hidrat') ||
        normalized.contains('bebida') ||
        normalized.contains('agua')) {
      return Icons.local_drink;
    }
    if (normalized.contains('comida') || normalized.contains('alimento')) {
      return Icons.restaurant;
    }
    if (normalized.contains('deporte') || normalized.contains('sport')) {
      return Icons.sports_soccer;
    }
    if (normalized.contains('tecn') || normalized.contains('electr')) {
      return Icons.devices;
    }
    if (normalized.contains('hogar')) {
      return Icons.home;
    }
    return Icons.category;
  }

  static Color _colorFromJson(dynamic colorData, String categoryName) {
    if (colorData is int) return Color(colorData);

    final normalized = categoryName.toLowerCase();
    if (normalized.contains('ropa') || normalized.contains('moda')) {
      return const Color(0xFFFF6584);
    }
    if (normalized.contains('hidrat') ||
        normalized.contains('bebida') ||
        normalized.contains('agua')) {
      return const Color(0xFF26A69A);
    }
    if (normalized.contains('comida') || normalized.contains('alimento')) {
      return const Color(0xFFFFC312);
    }
    if (normalized.contains('deporte') || normalized.contains('sport')) {
      return const Color(0xFFFF9800);
    }
    if (normalized.contains('tecn') || normalized.contains('electr')) {
      return const Color(0xFF6C63FF);
    }
    if (normalized.contains('hogar')) {
      return const Color(0xFF26A69A);
    }
    return const Color(0xFF6C63FF);
  }

  /// Categorías por defecto para inicialización
  static List<MarketplaceCategory> getDefaultCategories() {
    return [
      MarketplaceCategory(
        id: 'electronics',
        name: 'Electrónica',
        description: 'Dispositivos y gadgets tecnológicos',
        icon: Icons.devices,
        color: const Color(0xFF6C63FF),
        productCount: 0,
        isPopular: true,
      ),
      MarketplaceCategory(
        id: 'fashion',
        name: 'Moda',
        description: 'Ropa, zapatos y accesorios',
        icon: Icons.shopping_bag,
        color: const Color(0xFFFF6584),
        productCount: 0,
        isPopular: true,
      ),
      MarketplaceCategory(
        id: 'home',
        name: 'Hogar',
        description: 'Muebles y decoración',
        icon: Icons.home,
        color: const Color(0xFF26A69A),
        productCount: 0,
        isPopular: true,
      ),
      MarketplaceCategory(
        id: 'sports',
        name: 'Deportes',
        description: 'Equipamiento deportivo',
        icon: Icons.sports_soccer,
        color: const Color(0xFFFF9800),
        productCount: 0,
        isPopular: false,
      ),
      MarketplaceCategory(
        id: 'books',
        name: 'Libros',
        description: 'Literatura y educación',
        icon: Icons.book,
        color: const Color(0xFF795548),
        productCount: 0,
        isPopular: false,
      ),
      MarketplaceCategory(
        id: 'toys',
        name: 'Juguetes',
        description: 'Juegos y entretenimiento',
        icon: Icons.toys,
        color: const Color(0xFFE91E63),
        productCount: 0,
        isPopular: false,
      ),
      MarketplaceCategory(
        id: 'beauty',
        name: 'Belleza',
        description: 'Cuidado personal y cosméticos',
        icon: Icons.face,
        color: const Color(0xFFFF4081),
        productCount: 0,
        isPopular: false,
      ),
      MarketplaceCategory(
        id: 'food',
        name: 'Alimentos',
        description: 'Comida y bebidas',
        icon: Icons.restaurant,
        color: const Color(0xFFFFC312),
        productCount: 0,
        isPopular: true,
      ),
    ];
  }
}
