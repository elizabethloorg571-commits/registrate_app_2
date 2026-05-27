import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../config/theme/marketplace_theme.dart';
import '../../../domain/models/cart_item.dart';
import '../../../domain/models/marketplace_order.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/marketplace_button.dart';
import '../../widgets/marketplace_card.dart';
import 'marketplace_delivery_data_screen.dart';

/// Pantalla del carrito de compras – usa [cartProvider] de Riverpod.
class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key, this.embedded = false, this.onExploreProducts});

  final bool embedded;
  final VoidCallback? onExploreProducts;

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final _couponController = TextEditingController();
  bool _showCouponField = false;

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  // -----------------------------------------------------------------------
  // Acciones
  // -----------------------------------------------------------------------

  Future<void> _updateQuantity(CartItem item, int newQuantity) async {
    final success = await ref
        .read(cartProvider.notifier)
        .updateQuantity(item.id, newQuantity);
    if (!success && mounted) {
      _showErrorSnackBar('No hay suficiente stock disponible');
    }
  }

  Future<void> _removeItem(CartItem item) async {
    final snapshot = item;
    await ref.read(cartProvider.notifier).removeFromCart(item.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${snapshot.product.name} eliminado'),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Deshacer',
          textColor: MarketplaceTheme.gbYellow500,
          onPressed: () async {
            await ref
                .read(cartProvider.notifier)
                .addToCart(snapshot.product, snapshot.quantity);
          },
        ),
      ),
    );
  }

  Future<void> _clearCart() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Vaciar carrito'),
        content: const Text('¿Estás seguro de que deseas vaciar el carrito?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Vaciar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(cartProvider.notifier).clearCart();
    }
  }

  Future<void> _applyCoupon() async {
    final code = _couponController.text.trim();
    if (code.isEmpty) return;
    final valid = await ref.read(cartProvider.notifier).applyCoupon(code);
    if (!mounted) return;
    if (valid) {
      _couponController.clear();
      setState(() => _showCouponField = false);
      _showSuccessSnackBar('¡Cupón aplicado!');
    }
  }

  Future<void> _proceedToCheckout() async {
    final cart = ref.read(cartProvider);
    if (!cart.isCheckoutValid) {
      final names = cart.itemsOutOfStock
          .map((i) => '• ${i.product.name}')
          .join('\n');
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Problema con el stock'),
          content: Text(
            'Los siguientes productos no tienen suficiente stock:\n\n$names\n\nAjusta las cantidades para continuar.',
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Entendido'),
            ),
          ],
        ),
      );
      return;
    }
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MarketplaceDeliveryDataScreen()),
    );
  }

  void _showErrorSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // -----------------------------------------------------------------------
  // Build
  // -----------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final fmt = NumberFormat.currency(symbol: r'$', decimalDigits: 2);
    final pricing = MarketplaceOrderPricing.fromCart(
      items: cart.items,
      discountAmount: cart.discountAmount,
    );
    final content = cart.isLoading
        ? Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                MarketplaceTheme.gbYellow500,
              ),
            ),
          )
        : cart.isEmpty
        ? _buildEmptyCart()
        : Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: cart.items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return _buildCartItem(cart.items[index], fmt);
                  },
                ),
              ),
              _buildSummary(cart, fmt, pricing),
            ],
          );

    if (widget.embedded) {
      return ColoredBox(color: Colors.grey.shade50, child: content);
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mi Carrito',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (!cart.isEmpty)
              Text(
                '${cart.itemCount} ${cart.itemCount == 1 ? "artículo" : "artículos"}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
          ],
        ),
        actions: [
          if (!cart.isEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.black87),
              tooltip: 'Vaciar carrito',
              onPressed: _clearCart,
            ),
        ],
      ),
      body: content,
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 100,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 24),
            Text(
              'Tu carrito está vacío',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Agrega productos para comenzar tu compra',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 32),
            MarketplaceButton(
              text: 'Explorar productos',
              icon: Icons.shopping_bag_outlined,
              variant: MarketplaceButtonVariant.primary,
              size: MarketplaceButtonSize.large,
              onPressed:
                  widget.onExploreProducts ?? () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItem(CartItem item, NumberFormat fmt) {
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _removeItem(item),
      background: Container(
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white, size: 28),
      ),
      child: MarketplaceCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Imagen del producto
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: item.product.imageUrl != null
                    ? Image.network(
                        item.product.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              Icons.image,
                              size: 32,
                              color: Colors.grey,
                            ),
                      )
                    : const Icon(Icons.image, size: 32, color: Colors.grey),
              ),
            ),
            const SizedBox(width: 12),
            // Información del producto
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.product.category,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        fmt.format(item.product.effectivePrice),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (item.product.hasDiscount) ...[
                        const SizedBox(width: 8),
                        Text(
                          fmt.format(item.product.price),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade500,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (item.quantity > item.product.stockQuantity)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Solo ${item.product.stockQuantity} disponibles',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.red.shade600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Selector de cantidad
            _buildQuantitySelector(item),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantitySelector(CartItem item) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 32,
            height: 28,
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.add, size: 16),
              onPressed: item.quantity < item.product.stockQuantity
                  ? () => _updateQuantity(item, item.quantity + 1)
                  : null,
            ),
          ),
          Container(
            width: 32,
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              border: Border.symmetric(
                horizontal: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
            ),
            child: Text(
              '${item.quantity}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
          SizedBox(
            width: 32,
            height: 28,
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.remove, size: 16),
              onPressed: () => _updateQuantity(item, item.quantity - 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(
    CartState cart,
    NumberFormat fmt,
    MarketplaceOrderPricing pricing,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCouponSection(cart),
              const SizedBox(height: 12),
              _buildSummaryRow(
                'Subtotal',
                fmt.format(pricing.subtotalBeforeDiscount),
              ),
              if (cart.hasDiscount) ...[
                const SizedBox(height: 6),
                _buildSummaryRow(
                  'Descuento cupón',
                  '- ${fmt.format(pricing.discountAmount)}',
                  valueColor: Colors.green.shade600,
                ),
              ],
              const SizedBox(height: 6),
              _buildSummaryRow(
                'IVA ${(pricing.taxRate * 100).toStringAsFixed(0)}% (ítems gravados)',
                fmt.format(pricing.iva),
              ),
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 10),
              _buildSummaryRow(
                'Total',
                fmt.format(pricing.total),
                isTotal: true,
              ),
              const SizedBox(height: 16),
              MarketplaceButton(
                text: 'Continuar al checkout',
                icon: Icons.receipt_long_outlined,
                variant: MarketplaceButtonVariant.primary,
                size: MarketplaceButtonSize.large,
                fullWidth: true,
                onPressed: _proceedToCheckout,
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCouponSection(CartState cart) {
    if (cart.hasDiscount && cart.couponCode != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.local_offer, size: 16, color: Colors.green.shade700),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Cupón ${cart.couponCode} aplicado',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => ref.read(cartProvider.notifier).removeCoupon(),
              child: Icon(Icons.close, size: 16, color: Colors.green.shade700),
            ),
          ],
        ),
      );
    }

    if (_showCouponField) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _couponController,
                  textCapitalization: TextCapitalization.characters,
                  enabled: !cart.isApplyingCoupon,
                  decoration: InputDecoration(
                    hintText: 'Ingresa tu código',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: cart.couponError
                            ? Colors.red
                            : Colors.grey.shade300,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: cart.couponError
                            ? Colors.red
                            : Colors.grey.shade300,
                      ),
                    ),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _applyCoupon(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: cart.isApplyingCoupon ? null : _applyCoupon,
                style: ElevatedButton.styleFrom(
                  backgroundColor: MarketplaceTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: cart.isApplyingCoupon
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text('Aplicar'),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () {
                  _couponController.clear();
                  setState(() => _showCouponField = false);
                  if (cart.couponError) {
                    ref.read(cartProvider.notifier).removeCoupon();
                  }
                },
              ),
            ],
          ),
          if (cart.couponError)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4),
              child: Text(
                cart.couponErrorMessage ?? 'Código de cupón inválido',
                style: TextStyle(fontSize: 12, color: Colors.red.shade600),
              ),
            ),
        ],
      );
    }

    return TextButton.icon(
      onPressed: () => setState(() => _showCouponField = true),
      icon: const Icon(
        Icons.local_offer_outlined,
        size: 16,
        color: MarketplaceTheme.primary,
      ),
      label: const Text(
        '¿Tienes un cupón?',
        style: TextStyle(
          fontSize: 13,
          color: MarketplaceTheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: TextButton.styleFrom(padding: EdgeInsets.zero),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isTotal = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 18 : 15,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
            color: isTotal ? Colors.black87 : Colors.grey.shade700,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 20 : 16,
            fontWeight: FontWeight.w700,
            color: valueColor ?? (isTotal ? Colors.black87 : Colors.black87),
          ),
        ),
      ],
    );
  }
}
