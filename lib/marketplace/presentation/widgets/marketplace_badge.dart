import 'package:flutter/material.dart';

import '../../config/theme/marketplace_theme.dart';

enum MarketplaceBadgeType {
  sale, // Ofertas/Descuentos
  new_, // Productos nuevos
  featured, // Destacados
  outOfStock, // Sin stock
  lowStock, // Stock bajo
  bestseller, // Más vendidos
  info, // Información general
}

/// Badge reutilizable para el Marketplace
/// Inspirado en: Amazon badges, Walmart tags
class MarketplaceBadge extends StatelessWidget {
  const MarketplaceBadge({
    super.key,
    required this.text,
    required this.type,
    this.small = false,
  });
  final String text;
  final MarketplaceBadgeType type;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final colors = _getBadgeColors(type);
    final double fontSize = small ? 10 : 11;
    final EdgeInsets padding = small
        ? const EdgeInsets.symmetric(horizontal: 6, vertical: 2)
        : const EdgeInsets.symmetric(horizontal: 8, vertical: 4);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: colors.backgroundColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: colors.borderColor, width: 1),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: colors.textColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  _BadgeColors _getBadgeColors(MarketplaceBadgeType type) {
    switch (type) {
      case MarketplaceBadgeType.sale:
        return _BadgeColors(
          backgroundColor: const Color(0xFFFF4757),
          textColor: Colors.white,
          borderColor: const Color(0xFFFF4757),
        );
      case MarketplaceBadgeType.new_:
        return _BadgeColors(
          backgroundColor: MarketplaceTheme.primary,
          textColor: Colors.white,
          borderColor: MarketplaceTheme.primary,
        );
      case MarketplaceBadgeType.featured:
        return _BadgeColors(
          backgroundColor: MarketplaceTheme.primaryLowestShade,
          textColor: MarketplaceTheme.primary,
          borderColor: MarketplaceTheme.primaryLowShade,
        );
      case MarketplaceBadgeType.bestseller:
        return _BadgeColors(
          backgroundColor: const Color(0xFF00D2D3),
          textColor: Colors.white,
          borderColor: const Color(0xFF00C4C5),
        );
      case MarketplaceBadgeType.outOfStock:
        return _BadgeColors(
          backgroundColor: Colors.grey.shade300,
          textColor: Colors.grey.shade700,
          borderColor: Colors.grey.shade400,
        );
      case MarketplaceBadgeType.lowStock:
        return _BadgeColors(
          backgroundColor: MarketplaceTheme.primaryLowestShade,
          textColor: MarketplaceTheme.primary,
          borderColor: MarketplaceTheme.primaryLowShade,
        );
      case MarketplaceBadgeType.info:
        return _BadgeColors(
          backgroundColor: MarketplaceTheme.primary.withValues(alpha: 0.1),
          textColor: MarketplaceTheme.primary,
          borderColor: MarketplaceTheme.primary.withValues(alpha: 0.3),
        );
    }
  }
}

class _BadgeColors {
  _BadgeColors({
    required this.backgroundColor,
    required this.textColor,
    required this.borderColor,
  });
  final Color backgroundColor;
  final Color textColor;
  final Color borderColor;
}
