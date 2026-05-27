import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../src/presentation/ui/auth/views/login_view.dart';
import '../../../config/theme/marketplace_theme.dart';
import '../../../data/api/marketplace_api_service.dart';
import '../../../domain/models/marketplace_product.dart';
import '../../../services/favorites_service.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/marketplace_badge.dart';
import '../../widgets/marketplace_button.dart';
import '../../widgets/marketplace_dialog.dart';
import '/config/theme/app_theme.dart';
import 'cart_screen.dart';

/// Pantalla de detalle de producto con galería de imágenes
/// Diseño inspirado en: Amazon Product Detail, Apple Store Product Page
class ProductDetailScreen extends ConsumerStatefulWidget {
  // Opcional si ya se tiene el producto

  const ProductDetailScreen({super.key, required this.productId, this.product});
  final String productId;
  final MarketplaceProduct? product;

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen>
    with SingleTickerProviderStateMixin {
  MarketplaceProduct? _product;
  bool _isLoading = false;
  bool _isFavorite = false;
  bool _isFavoriteLoading = false;
  bool _isLoggedIn = false;
  int _selectedImageIndex = 0;
  int _quantity = 1;

  final PageController _pageController = PageController();
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  Timer? _addToCartSnackTimer;
  late final AnimationController _cartAnimController;
  late final Animation<double> _cartScaleAnim;

  @override
  void initState() {
    super.initState();
    _cartAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _cartScaleAnim =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.88), weight: 50),
          TweenSequenceItem(tween: Tween(begin: 0.88, end: 1.0), weight: 50),
        ]).animate(
          CurvedAnimation(parent: _cartAnimController, curve: Curves.easeInOut),
        );
    _checkLoginStatus();
    if (widget.product != null) {
      _product = widget.product;
    } else {
      _loadProduct();
    }
  }

  @override
  void dispose() {
    _addToCartSnackTimer?.cancel();
    _scaffoldMessengerKey.currentState?.clearSnackBars();
    _pageController.dispose();
    _cartAnimController.dispose();
    super.dispose();
  }

  void _showAddToCartSnackBar(String productName) {
    final messenger = _scaffoldMessengerKey.currentState;
    if (messenger == null) return;
    _addToCartSnackTimer?.cancel();

    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text('$productName agregado'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 1800),
          action: SnackBarAction(
            label: 'Ver carrito',
            textColor: Colors.white,
            onPressed: () {
              _addToCartSnackTimer?.cancel();
              messenger.hideCurrentSnackBar();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartScreen()),
              );
            },
          ),
        ),
      );

    _addToCartSnackTimer = Timer(const Duration(milliseconds: 1800), () {
      _scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
    });
  }

  void _showErrorSnackBar(String message) {
    final messenger = _scaffoldMessengerKey.currentState;
    if (messenger == null) return;

    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 1800),
        ),
      );
  }

  Future<void> _loadProduct() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await MarketplaceApiService.getProductById(
        widget.productId,
      );
      if (response['response'] == true) {
        setState(() {
          _product = response['data'];
        });
      }
    } catch (e) {
      debugPrint('Error loading product: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    if (!mounted) return;
    setState(() {
      _isLoggedIn = isLoggedIn;
    });

    if (isLoggedIn) {
      await FavoritesService.syncFavorites();
      await _loadFavoriteStatus();
      return;
    }

    if (!mounted) return;
    setState(() {
      _isFavorite = false;
    });
  }

  Future<void> _loadFavoriteStatus() async {
    final isFavorite = await FavoritesService.isFavorite(widget.productId);
    if (!mounted) return;
    setState(() {
      _isFavorite = isFavorite;
    });
  }

  Future<void> _toggleFavorite() async {
    // Verificar si el usuario ha iniciado sesión
    if (!_isLoggedIn) {
      MarketplaceDialog.show(
        context: context,
        icon: Icons.favorite_border,
        iconColor: Colors.red.shade400,
        title: 'Inicio de sesión requerido',
        message:
            'Para agregar productos a favoritos necesitas iniciar sesión primero.',
        primaryButtonText: 'Iniciar sesión',
        secondaryButtonText: 'Cancelar',
        onPrimaryPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const LoginView(needsSafeArea: false),
            ),
          ).then((_) => _checkLoginStatus());
        },
      );
      return;
    }

    if (_isFavoriteLoading) {
      return;
    }

    setState(() {
      _isFavoriteLoading = true;
    });

    final result = await FavoritesService.toggleFavorite(widget.productId);
    if (!mounted) return;

    setState(() {
      _isFavoriteLoading = false;
      if (result.success) {
        _isFavorite = result.isFavorite;
      }
    });

    if (!result.success) {
      _showErrorSnackBar(result.message);
    }
  }

  Future<void> _addToCart() async {
    if (_product == null) return;
    _cartAnimController.forward(from: 0);
    final success = await ref
        .read(cartProvider.notifier)
        .addToCart(_product!, _quantity);
    if (!mounted) return;
    if (success) {
      _showAddToCartSnackBar(_product!.name);
    } else {
      _showErrorSnackBar('No se pudo agregar al carrito');
    }
  }

  Future<void> _buyNow() async {
    if (_product == null) return;
    await ref.read(cartProvider.notifier).addToCart(_product!, _quantity);
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CartScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.gbYellow500),
          ),
        ),
      );
    }

    if (_product == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(child: Text('Producto no encontrado')),
      );
    }

    final currencyFormatter = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 2,
    );

    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: CustomScrollView(
          slivers: [
            // App Bar con imagen de fondo
            SliverAppBar(
              expandedHeight: 400,
              pinned: true,
              backgroundColor: Colors.white,
              leading: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black87),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              actions: [
                Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: _isFavoriteLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            _isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: _isFavorite ? Colors.red : Colors.black87,
                          ),
                    onPressed: _isFavoriteLoading ? null : _toggleFavorite,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              flexibleSpace: FlexibleSpaceBar(background: _buildImageGallery()),
            ),

            // Contenido del producto
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProductInfo(currencyFormatter),
                  const Divider(
                    height: 1,
                    thickness: 1,
                    indent: 20,
                    endIndent: 20,
                    color: AppTheme.dividerColor,
                  ),
                  _buildDescription(),
                  const Divider(
                    height: 1,
                    thickness: 1,
                    indent: 20,
                    endIndent: 20,
                    color: AppTheme.dividerColor,
                  ),
                  _buildSpecifications(),
                  const SizedBox(height: 100), // Espacio para botones flotantes
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomBar(currencyFormatter),
      ),
    );
  }

  Widget _buildImageGallery() {
    final images = _product!.images.isEmpty
        ? [_product!.imageUrl ?? '']
        : _product!.images;

    return Stack(
      children: [
        // Galería de imágenes
        PageView.builder(
          controller: _pageController,
          itemCount: images.length,
          onPageChanged: (index) {
            setState(() {
              _selectedImageIndex = index;
            });
          },
          itemBuilder: (context, index) {
            final imageUrl = images[index];
            return Container(
              color: Colors.grey.shade100,
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(
                            Icons.image,
                            size: 80,
                            color: Colors.grey,
                          ),
                        );
                      },
                    )
                  : const Center(
                      child: Icon(Icons.image, size: 80, color: Colors.grey),
                    ),
            );
          },
        ),

        // Indicador de página
        if (images.length > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                images.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _selectedImageIndex == index
                        ? AppTheme.gbYellow500
                        : Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProductInfo(NumberFormat currencyFormatter) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Categoría
          Text(
            _product!.category.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.gbYellow500,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),

          // Nombre
          Text(
            _product!.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.3,
            ),
          ),
          if (_product!.hasDiscount || _product!.isNew || _product!.isFeatured)
            const SizedBox(height: 12),
          if (_product!.hasDiscount || _product!.isNew || _product!.isFeatured)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (_product!.hasDiscount)
                  MarketplaceBadge(
                    text: '-${_product!.discountPercentage}% OFF',
                    type: MarketplaceBadgeType.sale,
                    small: true,
                  ),
                if (_product!.isNew)
                  const MarketplaceBadge(
                    text: 'Nuevo',
                    type: MarketplaceBadgeType.new_,
                    small: true,
                  ),
                if (_product!.isFeatured)
                  const MarketplaceBadge(
                    text: 'Destacado',
                    type: MarketplaceBadgeType.featured,
                    small: true,
                  ),
              ],
            ),
          const SizedBox(height: 16),

          // Precio
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (_product!.hasDiscount) ...[
                Text(
                  currencyFormatter.format(_product!.discountPrice),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  currencyFormatter.format(_product!.price),
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.grey.shade500,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ] else
                Text(
                  currencyFormatter.format(_product!.price),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Estado de stock
          if (!_product!.inStock)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.red.shade700,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Producto agotado',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.red.shade700,
                    ),
                  ),
                ],
              ),
            )
          else if (_product!.isLowStock)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryLowestShade,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.primaryLowShade),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 16,
                    color: AppTheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '¡Solo ${_product!.stockQuantity} unidades disponibles!',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 16,
                    color: Colors.green.shade700,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'En stock',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),

          // Selector de cantidad
          if (_product!.inStock) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                const Text(
                  'Cantidad:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 16),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove, size: 20),
                        onPressed: _quantity > 1
                            ? () => setState(() => _quantity--)
                            : null,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          '$_quantity',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, size: 20),
                        onPressed:
                            (_product!.stockQuantity >= 999999 ||
                                _quantity < _product!.stockQuantity)
                            ? () => setState(() => _quantity++)
                            : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDescription() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Descripción',
            style: MarketplaceTheme.titleMediumTextStyle(
              context,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _product!.description.isNotEmpty
                ? _product!.description
                : 'Este producto no tiene descripción disponible.',
            style: MarketplaceTheme.bodyMediumTextStyle(
              context,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecifications() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Información del producto',
            style: MarketplaceTheme.titleMediumTextStyle(
              context,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          _buildSpecRow('Categoría', _product!.category),
          if (_product!.subCategory != null)
            _buildSpecRow('Subcategoría', _product!.subCategory!),
          _buildSpecRow(
            'Stock',
            _product!.stockQuantity >= 999999
                ? 'Disponible'
                : '${_product!.stockQuantity} unidades',
          ),
          if (_product!.tags.isNotEmpty)
            _buildSpecRow('Etiquetas', _product!.tags.join(', ')),
        ],
      ),
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: MarketplaceTheme.bodyMediumTextStyle(
                context,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: MarketplaceTheme.bodyMediumTextStyle(
                context,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(NumberFormat currencyFormatter) {
    return Container(
      padding: const EdgeInsets.all(16),
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
        child: _product!.inStock
            ? Row(
                children: [
                  Expanded(
                    child: ScaleTransition(
                      scale: _cartScaleAnim,
                      child: MarketplaceButton(
                        text: 'Agregar al carrito',
                        icon: Icons.shopping_cart_outlined,
                        variant: MarketplaceButtonVariant.outline,
                        size: MarketplaceButtonSize.large,
                        onPressed: _addToCart,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MarketplaceButton(
                      text: 'Comprar ahora',
                      variant: MarketplaceButtonVariant.primary,
                      size: MarketplaceButtonSize.large,
                      onPressed: _buyNow,
                    ),
                  ),
                ],
              )
            : const MarketplaceButton(
                text: 'Producto no disponible',
                variant: MarketplaceButtonVariant.secondary,
                size: MarketplaceButtonSize.large,
                fullWidth: true,
                onPressed: null,
              ),
      ),
    );
  }
}
