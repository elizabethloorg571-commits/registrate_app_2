import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/models/marketplace_product.dart';
import '/config/theme/app_theme.dart';
import 'marketplace_badge.dart';
import 'marketplace_card.dart';

enum ProductCardVariant {
  grid, // Vista en grid (2 columnas)
  list, // Vista en lista (item completo)
  featured, // Vista destacada (hero card)
}

/// ProductCard - Componente reutilizable para mostrar productos
/// Inspirado en: Amazon product cards, Walmart item cards
class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    this.variant = ProductCardVariant.grid,
    this.onTap,
    this.onFavorite,
    this.isFavorite = false,
  });
  final MarketplaceProduct product;
  final ProductCardVariant variant;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final bool isFavorite;

  @override
  Widget build(BuildContext context) {
    switch (variant) {
      case ProductCardVariant.grid:
        return _GridProductCard(
          product: product,
          onTap: onTap,
          onFavorite: onFavorite,
          isFavorite: isFavorite,
        );
      case ProductCardVariant.list:
        return _ListProductCard(
          product: product,
          onTap: onTap,
          onFavorite: onFavorite,
          isFavorite: isFavorite,
        );
      case ProductCardVariant.featured:
        return _FeaturedProductCard(
          product: product,
          onTap: onTap,
          onFavorite: onFavorite,
          isFavorite: isFavorite,
        );
    }
  }
}

/// Vista Grid - Compacta para grids de 2 columnas
class _GridProductCard extends StatelessWidget {
  const _GridProductCard({
    required this.product,
    this.onTap,
    this.onFavorite,
    required this.isFavorite,
  });
  final MarketplaceProduct product;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final bool isFavorite;

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 2,
    );

    return MarketplaceCard(
      padding: const EdgeInsets.all(8),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen con badges y favorito
          Stack(
            children: [
              // Imagen del producto
              Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: product.imageUrl != null
                      ? Image.network(
                          product.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.image,
                              size: 48,
                              color: Colors.grey,
                            );
                          },
                        )
                      : const Icon(Icons.image, size: 48, color: Colors.grey),
                ),
              ),
              // Badges superiores
              Positioned(
                top: 6,
                left: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (product.hasDiscount)
                      MarketplaceBadge(
                        text: '-${product.discountPercentage}%',
                        type: MarketplaceBadgeType.sale,
                        small: true,
                      ),
                    if (product.isNew) ...[
                      const SizedBox(height: 4),
                      const MarketplaceBadge(
                        text: 'Nuevo',
                        type: MarketplaceBadgeType.new_,
                        small: true,
                      ),
                    ],
                    if (product.isBestseller) ...[
                      const SizedBox(height: 4),
                      const MarketplaceBadge(
                        text: 'Mejor vendido',
                        type: MarketplaceBadgeType.bestseller,
                        small: true,
                      ),
                    ],
                  ],
                ),
              ),
              // Botón de favorito
              Positioned(
                top: 6,
                right: 6,
                child: GestureDetector(
                  onTap: onFavorite,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      size: 18,
                      color: isFavorite ? Colors.red : Colors.grey.shade700,
                    ),
                  ),
                ),
              ),
              // Indicador de stock
              if (!product.inStock)
                const Positioned(
                  bottom: 6,
                  right: 6,
                  child: MarketplaceBadge(
                    text: 'Agotado',
                    type: MarketplaceBadgeType.outOfStock,
                    small: true,
                  ),
                )
              else if (product.isLowStock)
                Positioned(
                  bottom: 6,
                  right: 6,
                  child: MarketplaceBadge(
                    text: '¡Últimas ${product.stockQuantity}!',
                    type: MarketplaceBadgeType.lowStock,
                    small: true,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          // Nombre del producto
          Text(
            product.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 4),
          // Categoría
          Text(
            product.category,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 6),
          // Precios
          if (product.hasDiscount)
            Row(
              children: [
                Text(
                  currencyFormatter.format(product.discountPrice),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.gbYellow500,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  currencyFormatter.format(product.price),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ],
            )
          else
            Text(
              currencyFormatter.format(product.price),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
        ],
      ),
    );
  }
}

/// Vista List - Horizontal para listas
class _ListProductCard extends StatelessWidget {
  const _ListProductCard({
    required this.product,
    this.onTap,
    this.onFavorite,
    required this.isFavorite,
  });
  final MarketplaceProduct product;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final bool isFavorite;

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 2,
    );

    return MarketplaceCard(
      padding: const EdgeInsets.all(12),
      onTap: onTap,
      child: Row(
        children: [
          // Imagen
          Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: product.imageUrl != null
                      ? Image.network(
                          product.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.image,
                              size: 32,
                              color: Colors.grey,
                            );
                          },
                        )
                      : const Icon(Icons.image, size: 32, color: Colors.grey),
                ),
              ),
              if (product.hasDiscount)
                Positioned(
                  top: 4,
                  left: 4,
                  child: MarketplaceBadge(
                    text: '-${product.discountPercentage}%',
                    type: MarketplaceBadgeType.sale,
                    small: true,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          // Información
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: onFavorite,
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        size: 20,
                        color: isFavorite ? Colors.red : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  product.category,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (product.hasDiscount) ...[
                      Text(
                        currencyFormatter.format(product.discountPrice),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.gbYellow500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        currencyFormatter.format(product.price),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ] else
                      Text(
                        currencyFormatter.format(product.price),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                if (!product.inStock)
                  const MarketplaceBadge(
                    text: 'Agotado',
                    type: MarketplaceBadgeType.outOfStock,
                    small: true,
                  )
                else if (product.isLowStock)
                  MarketplaceBadge(
                    text: 'Solo ${product.stockQuantity} disponibles',
                    type: MarketplaceBadgeType.lowStock,
                    small: true,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Vista Featured - Destacada para hero sections
class _FeaturedProductCard extends StatelessWidget {
  const _FeaturedProductCard({
    required this.product,
    this.onTap,
    this.onFavorite,
    required this.isFavorite,
  });
  final MarketplaceProduct product;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final bool isFavorite;

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 2,
    );

    return MarketplaceCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen grande
          Stack(
            children: [
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  child: product.imageUrl != null
                      ? Image.network(
                          product.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.image,
                              size: 64,
                              color: Colors.grey,
                            );
                          },
                        )
                      : const Icon(Icons.image, size: 64, color: Colors.grey),
                ),
              ),
              // Badge Featured
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.gbYellow500,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.star, size: 14, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'DESTACADO',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (product.hasDiscount)
                Positioned(
                  top: 12,
                  right: 12,
                  child: MarketplaceBadge(
                    text: '-${product.discountPercentage}% OFF',
                    type: MarketplaceBadgeType.sale,
                  ),
                ),
              // Botón favorito
              Positioned(
                bottom: 12,
                right: 12,
                child: GestureDetector(
                  onTap: onFavorite,
                  child: Container(
                    padding: const EdgeInsets.all(8),
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
                    child: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      size: 20,
                      color: isFavorite ? Colors.red : Colors.grey.shade700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Información
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.category.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.gbYellow500,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  product.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (product.hasDiscount) ...[
                      Text(
                        currencyFormatter.format(product.discountPrice),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        currencyFormatter.format(product.price),
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey.shade500,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ] else
                      Text(
                        currencyFormatter.format(product.price),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                // Indicador de stock
                if (!product.inStock)
                  const MarketplaceBadge(
                    text: 'Agotado',
                    type: MarketplaceBadgeType.outOfStock,
                  )
                else if (product.isLowStock)
                  MarketplaceBadge(
                    text: '¡Solo ${product.stockQuantity} disponibles!',
                    type: MarketplaceBadgeType.lowStock,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
