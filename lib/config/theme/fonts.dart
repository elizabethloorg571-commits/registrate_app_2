import 'package:flutter/material.dart';
import 'package:running_app/extensions/responsive_extensions.dart';
import 'package:running_app/config/theme/app_theme.dart';

TextStyle nunitoSansStyle(
  int weight,
  double size, {
  Color color = AppTheme.dark900,
  TextDecoration decoration = TextDecoration.none,
}) {
  return TextStyle(
    fontFamily: 'NunitoSans',
    fontWeight: FontWeight.values.firstWhere(
      (element) => element.value == weight,
    ),
    fontSize: size,
    color: color,
    decoration: decoration,
    decorationColor: color,
  );
}

TextStyle nunitoSansStyleWithUnderline(
  int weight,
  double size, {
  Color color = AppTheme.dark900,
  Color underlineColor = AppTheme.dark900,
}) {
  return TextStyle(
    fontFamily: 'NunitoSans',
    fontWeight: FontWeight.values.firstWhere(
      (element) => element.value == weight,
    ),
    fontSize: size,
    color: color,
    decoration: TextDecoration.underline,
    decorationColor: underlineColor,
  );
}

TextStyle nunitoSansStyleWithLetterSpacing(
  int weight,
  double size,
  double letterSpacing, {
  Color color = AppTheme.dark900,
}) {
  return TextStyle(
    fontFamily: 'NunitoSans',
    fontWeight: FontWeight.values.firstWhere(
      (element) => element.value == weight,
    ),
    fontSize: size,
    color: color,
    letterSpacing: letterSpacing,
    decoration: TextDecoration.none,
  );
}

TextStyle nunitoSansTitleLargeStyle(
  BuildContext context, {
  Color color = AppTheme.dark900,
  FontWeight fontWeight = FontWeight.normal,
  TextDecoration decoration = TextDecoration.none,
}) {
  return TextStyle(
    fontFamily: 'NunitoSans',
    fontWeight: fontWeight,
    fontSize: context.sp(24),
    color: color,
    decoration: decoration,
  );
}

TextStyle nunitoSansTitleMediumStyle(
  BuildContext context, {
  Color color = AppTheme.dark900,
  FontWeight fontWeight = FontWeight.normal,
  TextDecoration decoration = TextDecoration.none,
}) {
  return TextStyle(
    fontFamily: 'NunitoSans',
    fontWeight: fontWeight,
    fontSize: context.sp(20),
    color: color,
    decoration: decoration,
  );
}

TextStyle nunitoSansTitleSmallStyle(
  BuildContext context, {
  Color color = AppTheme.dark900,
  FontWeight fontWeight = FontWeight.normal,
  TextDecoration decoration = TextDecoration.none,
}) {
  return TextStyle(
    fontFamily: 'NunitoSans',
    fontWeight: fontWeight,
    fontSize: context.sp(16),
    color: color,
    decoration: decoration,
    decorationColor: color,
  );
}

TextStyle nunitoSansBodyLargeStyle(
  BuildContext context, {
  Color color = AppTheme.dark900,
  FontWeight fontWeight = FontWeight.normal,
  TextDecoration decoration = TextDecoration.none,
}) {
  return TextStyle(
    fontFamily: 'NunitoSans',
    fontWeight: fontWeight,
    fontSize: context.sp(18),
    color: color,
    decoration: decoration,
  );
}

TextStyle nunitoSansBodyMediumStyle(
  BuildContext context, {
  Color color = AppTheme.dark900,
  FontWeight fontWeight = FontWeight.normal,
  TextDecoration decoration = TextDecoration.none,
}) {
  return TextStyle(
    fontFamily: 'NunitoSans',
    fontWeight: fontWeight,
    fontSize: context.sp(16),
    color: color,
    decoration: decoration,
  );
}

TextStyle nunitoSansBodySmallStyle(
  BuildContext context, {
  Color color = AppTheme.dark900,
  FontWeight fontWeight = FontWeight.normal,
  TextDecoration decoration = TextDecoration.none,
}) {
  return TextStyle(
    fontFamily: 'NunitoSans',
    fontWeight: fontWeight,
    fontSize: context.sp(14),
    color: color,
    decoration: decoration,
    decorationColor: color,
  );
}

TextStyle nunitoSansLabelLargeStyle(
  BuildContext context, {
  Color color = AppTheme.dark900,
  FontWeight fontWeight = FontWeight.normal,
  TextDecoration decoration = TextDecoration.none,
}) {
  return TextStyle(
    fontFamily: 'NunitoSans',
    fontWeight: fontWeight,
    fontSize: context.sp(14),
    color: color,
    decorationColor: color,
    decoration: decoration,
  );
}

TextStyle nunitoSansLabelMediumStyle(
  BuildContext context, {
  Color color = AppTheme.dark900,
  FontWeight fontWeight = FontWeight.normal,
  TextDecoration decoration = TextDecoration.none,
  double height = 1.2,
}) {
  return TextStyle(
    fontFamily: 'NunitoSans',
    height: height,
    fontWeight: fontWeight,
    fontSize: context.sp(12),
    color: color,
    decoration: decoration,
  );
}

TextStyle nunitoSansLabelSmallStyle(
  BuildContext context, {
  Color color = AppTheme.dark900,
  FontWeight fontWeight = FontWeight.normal,
  TextDecoration decoration = TextDecoration.none,
}) {
  return TextStyle(
    fontFamily: 'NunitoSans',
    fontWeight: fontWeight,
    fontSize: context.sp(10),
    color: color,
    decoration: decoration,
  );
}

TextStyle interStyle(
  int weight,
  double size, {
  Color color = AppTheme.dark900,
}) {
  return TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.values.firstWhere(
      (element) => element.value == weight,
    ),
    fontSize: size,
    color: color,
    decoration: TextDecoration.none,
  );
}

TextStyle interStyleWithLetterSpacing(
  int weight,
  double size,
  double letterSpacing, {
  Color color = AppTheme.dark900,
}) {
  return TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.values.firstWhere(
      (element) => element.value == weight,
    ),
    fontSize: size,
    color: color,
    letterSpacing: letterSpacing,
    decoration: TextDecoration.none,
  );
}

TextStyle openSansStyle(
  int weight,
  double size, {
  Color color = AppTheme.dark900,
}) {
  return TextStyle(
    fontFamily: 'OpenSans',
    fontWeight: FontWeight.values.firstWhere(
      (element) => element.value == weight,
    ),
    fontSize: size,
    color: color,
    decoration: TextDecoration.none,
  );
}
