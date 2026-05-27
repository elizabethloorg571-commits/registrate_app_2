import 'package:flutter/material.dart';

import '../../config/theme/marketplace_theme.dart';

enum MarketplaceButtonVariant { primary, secondary, outline, ghost }

enum MarketplaceButtonSize { small, medium, large }

/// Botón personalizado del Marketplace siguiendo patrones Fortune 500
/// Inspirado en: Amazon, Walmart, Apple Store
class MarketplaceButton extends StatelessWidget {
  const MarketplaceButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = MarketplaceButtonVariant.primary,
    this.size = MarketplaceButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.fullWidth = false,
  });
  final String text;
  final VoidCallback? onPressed;
  final MarketplaceButtonVariant variant;
  final MarketplaceButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || isLoading;

    // Configuración de tamaños
    final double height;
    final double fontSize;
    final double iconSize;
    final EdgeInsets padding;

    switch (size) {
      case MarketplaceButtonSize.small:
        height = 36;
        fontSize = 13;
        iconSize = 16;
        padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
        break;
      case MarketplaceButtonSize.large:
        height = 56;
        fontSize = 16;
        iconSize = 22;
        padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 14);
        break;
      case MarketplaceButtonSize.medium:
        height = 44;
        fontSize = 14;
        iconSize = 18;
        padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 10);
    }

    // Configuración de colores según variante
    Color backgroundColor;
    Color foregroundColor;
    Color? borderColor;

    switch (variant) {
      case MarketplaceButtonVariant.primary:
        backgroundColor = disabled
            ? Colors.grey.shade300
            : MarketplaceTheme.gbYellow500;
        foregroundColor = disabled ? Colors.grey.shade600 : Colors.white;
        borderColor = null;
        break;
      case MarketplaceButtonVariant.secondary:
        backgroundColor = disabled
            ? Colors.grey.shade200
            : Colors.grey.shade100;
        foregroundColor = disabled ? Colors.grey.shade500 : Colors.black87;
        borderColor = disabled ? Colors.grey.shade300 : Colors.grey.shade300;
        break;
      case MarketplaceButtonVariant.outline:
        backgroundColor = Colors.transparent;
        foregroundColor = disabled
            ? Colors.grey.shade400
            : MarketplaceTheme.gbYellow500;
        borderColor = disabled
            ? Colors.grey.shade300
            : MarketplaceTheme.gbYellow500;
        break;
      case MarketplaceButtonVariant.ghost:
        backgroundColor = Colors.transparent;
        foregroundColor = disabled ? Colors.grey.shade400 : Colors.black87;
        borderColor = null;
        break;
    }

    final buttonChild = Row(
      mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          SizedBox(
            width: iconSize,
            height: iconSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
            ),
          )
        else if (icon != null)
          Icon(icon, size: iconSize, color: foregroundColor),
        if ((icon != null || isLoading) && text.isNotEmpty)
          const SizedBox(width: 8),
        if (text.isNotEmpty)
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                color: foregroundColor,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
      ],
    );

    return SizedBox(
      height: height,
      width: fullWidth ? double.infinity : null,
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: disabled ? null : onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: borderColor != null
                  ? Border.all(color: borderColor, width: 1.5)
                  : null,
            ),
            child: buttonChild,
          ),
        ),
      ),
    );
  }
}
