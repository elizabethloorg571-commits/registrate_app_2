import 'package:flutter/material.dart';

import '../../config/theme/marketplace_theme.dart';

/// Diálogo reutilizable y estilizado para el Marketplace
/// Diseño premium: limpio, centrado, con botones bien definidos
class MarketplaceDialog {
  /// Mostrar un diálogo con icono, título, mensaje y botones personalizables
  static Future<void> show({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
    String primaryButtonText = 'Aceptar',
    String? secondaryButtonText,
    VoidCallback? onPrimaryPressed,
    VoidCallback? onSecondaryPressed,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: secondaryButtonText != null,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icono con fondo circular
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 32),
              ),
              const SizedBox(height: 20),

              // Título
              Text(
                title,
                style: MarketplaceTheme.titleMediumTextStyle(
                  context,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),

              // Mensaje
              Text(
                message,
                style: MarketplaceTheme.bodyMediumTextStyle(
                  context,
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Botón primario (ancho completo)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    onPrimaryPressed?.call();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MarketplaceTheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    primaryButtonText,
                    style: MarketplaceTheme.titleSmallTextStyle(
                      context,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              // Botón secundario (si existe)
              if (secondaryButtonText != null) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      onSecondaryPressed?.call();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      secondaryButtonText,
                      style: MarketplaceTheme.titleSmallTextStyle(
                        context,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
