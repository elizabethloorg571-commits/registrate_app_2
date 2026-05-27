import 'marketplace_product.dart';

/// Entidad de item del carrito
class CartItem {
  CartItem({
    required this.id,
    required this.product,
    required this.quantity,
    required this.addedAt,
  });

  /// Crear desde JSON
  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] ?? '',
      product: MarketplaceProduct.fromJson(json['product']),
      quantity: json['quantity'] ?? 1,
      addedAt: DateTime.parse(json['addedAt']),
    );
  }
  final String id;
  final MarketplaceProduct product;
  final int quantity;
  final DateTime addedAt;

  /// Precio total del item (precio x cantidad)
  double get totalPrice => product.effectivePrice * quantity;

  /// Copiar con modificaciones
  CartItem copyWith({
    String? id,
    MarketplaceProduct? product,
    int? quantity,
    DateTime? addedAt,
  }) {
    return CartItem(
      id: id ?? this.id,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  /// Convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product': product.toJson(),
      'quantity': quantity,
      'addedAt': addedAt.toIso8601String(),
    };
  }
}
