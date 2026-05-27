import 'package:flutter/material.dart';

class Responsive {
  final BuildContext context;
  late double _width;
  late double _height;

  Responsive(this.context) {
    final Size size = MediaQuery.of(context).size;
    _width = size.width;
    _height = size.height;
  }

  static const baseWidth = 412.0;
  static const baseHeight = 892.0;
  double hPercent(double percent) => hp(baseHeight * percent / 100);
  double wPercent(double percent) => wp(baseWidth * percent / 100);

  double wp(double px) => (_width / baseWidth) * px;
  double hp(double px) => (_height / baseHeight) * px;
  double sp(double px) => ((_width + _height) / (baseWidth + baseHeight)) * px;

  /// Determina si el layout debe considerarse tablet.
  /// Usa el lado más corto >= 600 como referencia típica de Material Design.
  /// Alternativamente, podrías ajustar este umbral según requerimientos.
  static bool isTablet(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return size.shortestSide >= 600; // comúnmente 600 para tablet
  }
}
