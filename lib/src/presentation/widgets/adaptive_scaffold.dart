import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:running_app/src/presentation/widgets/global_widgets.dart';
import 'package:running_app/config/theme/app_theme.dart';

/// Mantiene el mismo ancho lógico que tendría en modo vertical,
/// centrando el contenido en horizontal cuando el dispositivo esté en landscape.
///
/// Úsalo como padre de tu pantalla actual:
/// ```dart
/// return FixedPortraitWidth(
///   minHorizontalPadding: 16, // opcional
///   child: MiPantallaActual(),
/// );
/// ```
class FixedPortraitWidth extends StatelessWidget {
  const FixedPortraitWidth({
    super.key,
    required this.child,
    this.minHorizontalPadding = 0,
    this.constrainHeight = false,
  });

  /// Tu contenido.
  final Widget child;

  /// Padding horizontal mínimo a mantener siempre (en px).
  /// Útil si quieres respiración también en portrait.
  final double minHorizontalPadding;

  /// Si lo pones en true, también iguala la altura al lado más corto
  /// (útil para algunas UIs fijas). Normalmente déjalo en false.
  final bool constrainHeight;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final size = mq.size;

    // El lado más corto del dispositivo: coincide con el ancho en modo vertical.
    final targetSpan = size.shortestSide;

    // El ancho y alto máximos del contenedor disponible (padre).
    // Usamos LayoutBuilder para respetar cualquier restricción superior.
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : size.width;
        final maxH = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : size.height;

        // El ancho objetivo no debe exceder el espacio realmente disponible.
        final targetWidth = math.min(targetSpan, maxW);

        // Calculamos padding lateral para centrar el targetWidth.
        final autoSidePadding = ((maxW - targetWidth) / 2).clamp(
          0,
          double.infinity,
        );

        // Aseguramos un padding mínimo configurable.
        final horizontalPadding =
            math.max(autoSidePadding, minHorizontalPadding) as double;

        // (Opcional) también forzar altura igual al lado más corto si se desea.
        final targetHeight = constrainHeight
            ? math.min(targetSpan, maxH)
            : null;

        Widget content = ConstrainedBox(
          constraints: BoxConstraints(
            // Fijamos el ancho para que en landscape siga siendo el mismo que en portrait.
            maxWidth: targetWidth,
            // Si piden igualar altura, la fijamos; si no, dejamos que fluya.
            maxHeight: targetHeight ?? double.infinity,
          ),
          child: child,
        );

        // Centramos y aplicamos padding lateral calculado.
        content = Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: content,
          ),
        );

        return content;
      },
    );
  }
}

/// Variante con Scaffold + SafeArea + Scroll opcional.
/// Úsala si quieres "enchufar" rápidamente una pantalla sin cambiar tu árbol.
///
/// Ejemplo:
/// ```dart
/// return AdaptiveScaffold(
///   title: const Text('Mi pantalla'),
///   body: MiPantallaActual(),
///   scrollable: true,
///   minHorizontalPadding: 16,
/// );
/// ```
class AdaptiveScaffold extends StatelessWidget {
  const AdaptiveScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.backgroundColor,
    this.minHorizontalPadding = 0,
    this.scrollable = false,
    this.useSafeArea = true,
    this.constrainHeight = false,
    this.showBackButton = true,
    this.onBackButtonPressed,
    this.centerTitle = false,
    this.showAppBar = true,
    this.title = '',
    this.resizeToAvoidBottomInset = true,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final Color? backgroundColor;

  /// Propaga al `FixedPortraitWidth`.
  final double minHorizontalPadding;

  /// Si true, envuelve `body` en un `SingleChildScrollView`.
  final bool scrollable;

  /// Si true, envuelve todo en `SafeArea`.
  final bool useSafeArea;

  /// Si true, iguala altura al lado más corto (casos muy específicos).
  final bool constrainHeight;

  final String title;

  final bool centerTitle;

  final bool showBackButton;

  final Function()? onBackButtonPressed;

  final bool showAppBar;
  final bool resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    Widget content = FixedPortraitWidth(
      minHorizontalPadding: minHorizontalPadding,
      constrainHeight: constrainHeight,
      child: scrollable ? SingleChildScrollView(child: body) : body,
    );

    if (useSafeArea) {
      content = SafeArea(child: content);
    }

    return Scaffold(
      backgroundColor: backgroundColor ?? AppTheme.white950,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      appBar: showAppBar
          ? appBar ??
                GlobalWidgets.customAppBar(
                  context,
                  title: title,
                  backgroundColor: backgroundColor ?? AppTheme.white950,
                  showBackButton: showBackButton,
                  centerTitle: centerTitle,
                  onBackButtonPressed: onBackButtonPressed,
                )
          : null,

      body: content,
      floatingActionButton: floatingActionButton,
    );
  }
}
