import 'package:flutter/material.dart';

extension ResponsiveExtension on BuildContext {
  static const tabletBaseWidth = 825.0;
  static const tabletBaseHeight = 1194.0;
  static const phoneBaseWidth = 392.0;
  static const phoneBaseHeight = 915.0;

  double get baseWidth =>
      MediaQuery.of(this).size.width >= 600 ? tabletBaseWidth : phoneBaseWidth;
  double get baseHeight => MediaQuery.of(this).size.width >= 600
      ? tabletBaseHeight
      : phoneBaseHeight;

  double get _screenWidth => MediaQuery.of(this).size.width;
  double get _screenHeight => MediaQuery.of(this).size.height;

  double hPercent(double percent) => hp(baseHeight * percent / 100);
  double wPercent(double percent) => wp(baseWidth * percent / 100);
  double wp(double px) => (_screenWidth / baseWidth) * px;
  double hp(double px) => (_screenHeight / baseHeight) * px;
  double sp(double px) =>
      ((_screenWidth + _screenHeight) / (baseWidth + baseHeight)) * px;
}
