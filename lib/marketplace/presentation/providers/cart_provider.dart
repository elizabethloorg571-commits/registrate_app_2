import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api/marketplace_api_service.dart';
import '../../domain/models/cart_item.dart';
import '../../domain/models/marketplace_product.dart';
import '../../services/cart_service.dart';

// ---------------------------------------------------------------------------
// CartState
// ---------------------------------------------------------------------------

class CartState {
  const CartState({
    this.items = const [],
    this.couponCode,
    this.discountValue = 0.0,
    this.couponError = false,
    this.couponErrorMessage,
    this.isApplyingCoupon = false,
    this.isLoading = false,
  });

  final List<CartItem> items;
  final String? couponCode;
  final double discountValue;
  final bool couponError;
  final String? couponErrorMessage;
  final bool isApplyingCoupon;
  final bool isLoading;

  // ---- valores calculados ----

  int get itemCount => items.fold<int>(0, (s, i) => s + i.quantity);

  double get subtotal => items.fold<double>(0, (s, i) => s + i.totalPrice);

  double get discountAmount => math.min(math.max(0, discountValue), subtotal);

  double get discountPercentage =>
      subtotal > 0 ? (discountAmount / subtotal) : 0.0;

  double get discountedSubtotal => math.max(0, subtotal - discountAmount);

  double get shipping =>
      items.isEmpty ? 0 : (discountedSubtotal >= 50 ? 0 : 5.99);

  double get total => discountedSubtotal + shipping;

  bool get hasDiscount => discountAmount > 0;

  bool get isEmpty => items.isEmpty;

  // ---- validación de stock al checkout ----

  /// Retorna los ítems cuya cantidad supera el stock disponible.
  List<CartItem> get itemsOutOfStock =>
      items.where((i) => i.quantity > i.product.stockQuantity).toList();

  bool get isCheckoutValid => itemsOutOfStock.isEmpty;

  // ---- copyWith ----

  CartState copyWith({
    List<CartItem>? items,
    String? couponCode,
    double? discountValue,
    bool? couponError,
    String? couponErrorMessage,
    bool? isApplyingCoupon,
    bool? isLoading,
    bool clearCoupon = false,
  }) {
    return CartState(
      items: items ?? this.items,
      couponCode: clearCoupon ? null : (couponCode ?? this.couponCode),
      discountValue: clearCoupon ? 0.0 : (discountValue ?? this.discountValue),
      couponError: clearCoupon ? false : (couponError ?? this.couponError),
      couponErrorMessage: clearCoupon
          ? null
          : (couponErrorMessage ?? this.couponErrorMessage),
      isApplyingCoupon: isApplyingCoupon ?? this.isApplyingCoupon,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// ---------------------------------------------------------------------------
// CartNotifier
// ---------------------------------------------------------------------------

class CartNotifier extends Notifier<CartState> {
  @override
  CartState build() {
    _loadCart();
    return const CartState(isLoading: true);
  }

  // ---- carga inicial ----

  Future<void> _loadCart({bool clearCoupon = false}) async {
    final items = await CartService.getCartItems();
    state = state.copyWith(
      items: items,
      isLoading: false,
      isApplyingCoupon: false,
      clearCoupon: clearCoupon,
    );
  }

  // ---- agregar ----

  /// Agrega [quantity] unidades del [product] al carrito.
  /// Retorna `true` si tuvo éxito, `false` si se excede el stock.
  Future<bool> addToCart(MarketplaceProduct product, int quantity) async {
    final success = await CartService.addToCart(product, quantity);
    if (success) await _loadCart(clearCoupon: true);
    return success;
  }

  // ---- eliminar ----

  /// Elimina el ítem con [itemId] del carrito.
  Future<bool> removeFromCart(String itemId) async {
    final success = await CartService.removeFromCart(itemId);
    if (success) await _loadCart(clearCoupon: true);
    return success;
  }

  // ---- actualizar cantidad ----

  /// Actualiza la cantidad de un ítem. Si [quantity] <= 0, lo elimina.
  Future<bool> updateQuantity(String itemId, int quantity) async {
    if (quantity <= 0) return removeFromCart(itemId);
    final success = await CartService.updateQuantity(itemId, quantity);
    if (success) await _loadCart(clearCoupon: true);
    return success;
  }

  // ---- vaciar ----

  Future<void> clearCart() async {
    await CartService.clearCart();
    state = const CartState();
  }

  // ---- cupones ----

  /// Aplica un código de cupón. Retorna `true` si es válido.
  Future<bool> applyCoupon(String code) async {
    final key = code.trim().toUpperCase();
    if (key.isEmpty) return false;

    state = state.copyWith(
      couponError: false,
      couponErrorMessage: null,
      isApplyingCoupon: true,
    );

    final result = await MarketplaceApiService.validateDiscountCode(
      key,
      state.subtotal,
    );

    final appliedCoupon = _parseAppliedCoupon(result, key);
    final isSuccess = _isSuccessfulResponse(result) || appliedCoupon != null;

    if (isSuccess && appliedCoupon != null) {
      state = state.copyWith(
        couponCode: appliedCoupon.codigo,
        discountValue: appliedCoupon.descuento,
        couponError: false,
        couponErrorMessage: null,
        isApplyingCoupon: false,
      );
      return true;
    }

    state = state.copyWith(
      couponError: true,
      couponErrorMessage:
          result['message']?.toString() ??
          result['error']?.toString() ??
          'Código de cupón inválido',
      isApplyingCoupon: false,
    );
    return false;
  }

  void removeCoupon() {
    state = state.copyWith(clearCoupon: true, isApplyingCoupon: false);
  }

  bool _isSuccessfulResponse(Map<String, dynamic> result) {
    final status = result['response'] ?? result['status'];

    if (status is bool) return status;

    if (status is String) {
      final normalized = status.trim().toLowerCase();
      return normalized == 'success' || normalized == 'ok';
    }

    return false;
  }

  _AppliedCoupon? _parseAppliedCoupon(
    Map<String, dynamic> result,
    String fallbackCode,
  ) {
    final payload = result['data'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(result['data'] as Map<String, dynamic>)
        : result;

    final codigo = (payload['codigo'] ?? payload['code'] ?? fallbackCode)
        .toString()
        .trim();
    final descuento = _parseAmount(
      payload['descuento'] ?? payload['discount'] ?? payload['discount_value'],
    );

    if (codigo.isEmpty || descuento <= 0) {
      return null;
    }

    return _AppliedCoupon(codigo: codigo, descuento: descuento);
  }

  double _parseAmount(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is Map && value.containsKey('\$numberDecimal')) {
      return double.tryParse(value['\$numberDecimal'].toString()) ?? 0.0;
    }
    return double.tryParse(value.toString()) ?? 0.0;
  }
}

// ---------------------------------------------------------------------------
// Provider global (keepAlive para que persista entre pantallas)
// ---------------------------------------------------------------------------

final cartProvider = NotifierProvider<CartNotifier, CartState>(
  CartNotifier.new,
);

class _AppliedCoupon {
  const _AppliedCoupon({required this.codigo, required this.descuento});

  final String codigo;
  final double descuento;
}
