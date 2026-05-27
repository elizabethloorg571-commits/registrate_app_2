import 'dart:convert';
import 'dart:developer';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models/cart_item.dart';
import '../domain/models/marketplace_product.dart';

/// Servicio para gestionar el carrito de compras
/// Usa SharedPreferences para persistencia local
class CartService {
  static const String _cartKey = 'marketplace_cart';

  /// Obtener todos los items del carrito
  static Future<List<CartItem>> getCartItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = prefs.getString(_cartKey);

      if (cartJson == null) {
        return [];
      }

      final List<dynamic> cartList = json.decode(cartJson);
      return cartList.map((item) => CartItem.fromJson(item)).toList();
    } catch (e) {
      log('Error getting cart items: $e');
      return [];
    }
  }

  /// Agregar producto al carrito
  static Future<bool> addToCart(
    MarketplaceProduct product,
    int quantity,
  ) async {
    try {
      final items = await getCartItems();

      // Verificar si el producto ya existe
      final existingIndex = items.indexWhere(
        (item) => item.product.id == product.id,
      );

      if (existingIndex != -1) {
        // Actualizar cantidad del item existente
        final existingItem = items[existingIndex];
        final newQuantity = existingItem.quantity + quantity;

        // Verificar stock disponible (solo si no es stock ilimitado)
        if (product.stockQuantity < 999999 &&
            newQuantity > product.stockQuantity) {
          log('Cannot add more items: stock limit reached');
          return false;
        }

        items[existingIndex] = existingItem.copyWith(quantity: newQuantity);
      } else {
        // Agregar nuevo item
        items.add(
          CartItem(
            id: '${product.id}_${DateTime.now().millisecondsSinceEpoch}',
            product: product,
            quantity: quantity,
            addedAt: DateTime.now(),
          ),
        );
      }

      await _saveCart(items);
      log('Product added to cart: ${product.name} x$quantity');
      return true;
    } catch (e) {
      log('Error adding to cart: $e');
      return false;
    }
  }

  /// Actualizar cantidad de un item
  static Future<bool> updateQuantity(String itemId, int quantity) async {
    try {
      if (quantity <= 0) {
        return await removeFromCart(itemId);
      }

      final items = await getCartItems();
      final index = items.indexWhere((item) => item.id == itemId);

      if (index == -1) {
        log('Item not found in cart');
        return false;
      }

      final item = items[index];

      // Verificar stock disponible (solo si no es stock ilimitado)
      if (item.product.stockQuantity < 999999 &&
          quantity > item.product.stockQuantity) {
        log('Cannot update: stock limit reached');
        return false;
      }

      items[index] = item.copyWith(quantity: quantity);
      await _saveCart(items);
      log('Cart item quantity updated: ${item.product.name} = $quantity');
      return true;
    } catch (e) {
      log('Error updating cart quantity: $e');
      return false;
    }
  }

  /// Eliminar item del carrito
  static Future<bool> removeFromCart(String itemId) async {
    try {
      final items = await getCartItems();
      items.removeWhere((item) => item.id == itemId);
      await _saveCart(items);
      log('Item removed from cart: $itemId');
      return true;
    } catch (e) {
      log('Error removing from cart: $e');
      return false;
    }
  }

  /// Limpiar todo el carrito
  static Future<bool> clearCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cartKey);
      log('Cart cleared');
      return true;
    } catch (e) {
      log('Error clearing cart: $e');
      return false;
    }
  }

  /// Obtener cantidad total de items en el carrito
  static Future<int> getCartCount() async {
    final items = await getCartItems();
    return items.fold<int>(0, (sum, item) => sum + item.quantity);
  }

  /// Obtener precio total del carrito
  static Future<double> getCartTotal() async {
    final items = await getCartItems();
    return items.fold<double>(0, (sum, item) => sum + item.totalPrice);
  }

  /// Verificar si un producto está en el carrito
  static Future<bool> isInCart(String productId) async {
    final items = await getCartItems();
    return items.any((item) => item.product.id == productId);
  }

  /// Obtener cantidad de un producto en el carrito
  static Future<int> getProductQuantity(String productId) async {
    final items = await getCartItems();
    final item = items.firstWhere(
      (item) => item.product.id == productId,
      orElse: () => CartItem(
        id: '',
        product: MarketplaceProduct(
          id: '',
          name: '',
          description: '',
          price: 0,
          images: [],
          category: '',
          inStock: false,
          stockQuantity: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        quantity: 0,
        addedAt: DateTime.now(),
      ),
    );
    return item.quantity;
  }

  // ==================== MÉTODOS PRIVADOS ====================

  /// Guardar carrito en SharedPreferences
  static Future<void> _saveCart(List<CartItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final cartJson = json.encode(items.map((item) => item.toJson()).toList());
    await prefs.setString(_cartKey, cartJson);
  }
}
