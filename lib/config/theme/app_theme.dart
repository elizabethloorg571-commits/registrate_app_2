import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:running_app/config/theme/helpers/hex_color.dart';

class AppTheme {
  static Color orange = hexOrRGBToColor("#E47E00");
  static Color cardsBackground = hexOrRGBToColor("#EEEDF4");
  static Color white = hexOrRGBToColor("#FFFFFF");
  static Color white950 = hexOrRGBToColor("#FAFAFA");
  static Color inscriptionsBackground = hexOrRGBToColor('#E8E8EC');
  static Color primary50 = hexOrRGBToColor("#EDE8FD");
  static const Color primary900 = Color.fromRGBO(121, 82, 252, 1);
  static const Color primary600 = Color.fromRGBO(186, 167, 253, 1);
  static const Color grey900 = Color.fromRGBO(30, 30, 30, 0.04);
  static Color secondary50 = hexOrRGBToColor("#F4E9FA");
  static Color green = hexOrRGBToColor("#74CA8D");
  static Color grey = hexOrRGBToColor("#C4C4C4");
  static const Color dark900 = Color.fromRGBO(19, 18, 58, 1);
  static Color dark700 = hexOrRGBToColor("#7A7A90");
  static Color cardsFooterColor = hexOrRGBToColor("#EDE8FD");
  static const Color primary = Color.fromRGBO(121, 82, 252, 1);
  static const Color secondary = Color.fromRGBO(177, 92, 222, 1);
  static Color competitionCardColor = hexOrRGBToColor("#EDE8FD");
  static Color bottomNavigationIconUnselectedColor = hexOrRGBToColor("#13123A");
  static Color yellow = hexOrRGBToColor("#FFEB62");
  static Color lightModeSuccessGreen = hexOrRGBToColor("#48B300");
  static Color lightModePrimaryAccentColor = hexOrRGBToColor("#5CC0FF");
  static Color primaryLowShade = hexOrRGBToColor("#E7E7FE");
  static Color profileButtonColor = hexOrRGBToColor("#D9D9D9");
  static Color primaryLowestShade = hexOrRGBToColor("#F8F9FF");
  static Color lightModeTextFieldBackgroundColor = hexOrRGBToColor("#EBEBEB");
  static Color lightModeTextFieldPlaceholderColor = hexOrRGBToColor("#7F8083");
  static Color lightModeTextFieldTextColor = hexOrRGBToColor("#000000");
  static Color lightModeTextFieldDisabledTextColor = Colors.black12;
  static Color lightModeFontsGray = hexOrRGBToColor("#C4C4C4");
  static Color lightModeBlack = hexOrRGBToColor("#3B414B");
  static Color lightModeNotificationUnread = hexOrRGBToColor("#D9D9D9");
  static Color lightModeTextFieldLabelColor = lightModeBlack;
  static Color lightModeBoxShadowColor = hexOrRGBToColor("#CBD6FF");
  static Color lightModeBlue = hexOrRGBToColor("#455E91");
  static Color lightModeBlueEmphasis = hexOrRGBToColor("#007AFF");
  static Color lightModeWarning = hexOrRGBToColor("#FF0000");
  static Color lightModeIconsBlue = hexOrRGBToColor("#3253A9");
  static Color cardsEmphasisBackground = hexOrRGBToColor("#E1E4DA");
  static Color lightModeGreen = hexOrRGBToColor("#18A000");
  static Color lightModeLightGreen = hexOrRGBToColor("#D7E8CC");
  static Color lightModeLightBlue = hexOrRGBToColor("#D8E2FF");
  static Color lightModeTileActiveBlue = hexOrRGBToColor("#DFE1F9");
  static Color lightModeButtonsSecondary = hexOrRGBToColor("#D8E2FF");
  static Color lightModeButtonsTertiary = hexOrRGBToColor("#DBE2F9");
  static Color lightModeErrorRed = hexOrRGBToColor("#BA1A1A");
  static Color scaffoldTitleColor = hexOrRGBToColor("#1A1B20");
  static Color calendarSelectionDayColor = hexOrRGBToColor("#715573");
  static Color deunaButtonColor = hexOrRGBToColor("#00DCAD");
  static Color segmentedButtonSelectedColor = hexOrRGBToColor("#D7E8CC");

  //? MARKETPLACE
  static const Color dividerColor = Color.fromRGBO(236, 236, 236, 1);
  static Color gbYellow500 = primary;
  static Color gbYellow400 = primary600;
  static Color gbYellow200 = primaryLowShade;
  static Color gbYellow50 = primaryLowestShade;
  static Color gbBlue50 = hexOrRGBToColor('#E6F0FF');
  static Color gbGreen100 = hexOrRGBToColor('#DCF2EC');
  static Color gbDark200 = hexOrRGBToColor('#ADB4C0');
  static Color searchBarBackgroundColor = hexOrRGBToColor('#F2F2F7');
  static const Color primaryYellow = primary;
  static const Color primaryViolet = Color.fromRGBO(110, 91, 195, 1);
  static Color gbWhite500 = hexOrRGBToColor('#FFFFFF');
  static Color gbWhite20 = hexOrRGBToColor('#FAFAFA');
  static Color gbGreen500 = hexOrRGBToColor('#1CBE8E');
  static Color secondaryGrey = hexOrRGBToColor('#4C4E55');
  static const Color gbDark600 = Color.fromARGB(255, 39, 54, 78);
  static const Color gbDark400 = Color.fromARGB(255, 90, 104, 121);
  static const Color backgroundColor = Color.fromARGB(255, 248, 248, 248);
  static const Color primaryLight = Color.fromARGB(255, 192, 194, 224);
  static const Color primaryDark = Color.fromARGB(255, 88, 92, 136);
  static const Color borderColor = Color.fromARGB(255, 37, 37, 58);
  static const Color secondaryLight = Color.fromARGB(255, 245, 222, 129);
  static const Color secondaryDark = Color.fromARGB(255, 88, 73, 0);
  static const Color gb97Blue = Color.fromARGB(255, 33, 46, 99);
  static Color blue = const Color.fromARGB(255, 33, 150, 243);
  static const Color tertiary = Colors.green;
  static Color redLight = Colors.red.shade300;
  static Color red = Colors.red;
  static Color redDark = Colors.red.shade900;
  static Color redError = hexOrRGBToColor('#C90303');
  static Color buttonsGreen = hexOrRGBToColor('#74DA7F');
  static Color serviceItemColor = Colors.teal.shade800;
  static Color black = Colors.grey.shade900;
  static Color secondayBlack = hexOrRGBToColor('#02050F');
  static Color greyDark = Colors.grey.shade700;
  static Color subtitle = Colors.black.withValues(alpha: 0.5);

  static ThemeData lightModeAndroid = ThemeData(
    brightness: Brightness.light,
    useMaterial3: true,
    colorScheme: ColorScheme.light(
      surface: white950,
      primary: primary,
      secondary: secondary,
    ),
  );

  static ThemeData darkModeAndroid = ThemeData(
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      surface: Colors.grey.shade900,
      primary: hexOrRGBToColor("#3253A9"),
      secondary: Colors.grey.shade700,
    ),
  );

  CupertinoThemeData lightModeIOS = CupertinoThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: Colors.grey.shade300,
    primaryColor: hexOrRGBToColor("#3253A9"),
    barBackgroundColor: Colors.grey.shade100,
    primaryContrastingColor: Colors.grey.shade900,
  );

  CupertinoThemeData darkModeIOS = CupertinoThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.grey.shade900,
    primaryColor: Colors.grey.shade800,
    barBackgroundColor: Colors.grey.shade700,
    primaryContrastingColor: Colors.grey.shade100,
  );

  TextStyle scaffoldTitleStyle = TextStyle(
    fontFamily: 'nunitoSans',
    fontSize: 24,
    fontWeight: FontWeight.w400,
    color: scaffoldTitleColor,
    decoration: TextDecoration.none,
  );

  TextStyle scaffoldSubtitleStyle = TextStyle(
    fontFamily: 'nunitoSans',
    fontWeight: FontWeight.w400,
    fontSize: 14,
    color: scaffoldTitleColor,
    decoration: TextDecoration.none,
  );

  TextStyle labelSmallStyle = TextStyle(
    fontFamily: 'nunitoSans',
    fontWeight: FontWeight.w500,
    fontSize: 10,
    color: lightModeTextFieldLabelColor,
    decoration: TextDecoration.none,
  );

  static TextStyle displayLargeTextStyle(
    BuildContext context, {
    Color color = AppTheme.gbDark600,

    FontWeight fontWeight = FontWeight.w500,
    TextDecoration decoration = TextDecoration.none,
  }) => Theme.of(context).textTheme.displayLarge!.copyWith(
    color: color,
    fontFamily: 'nunitoSans',
    fontWeight: fontWeight,
    decoration: decoration,
  );

  static TextStyle displayMediumTextStyle(
    BuildContext context, {
    Color color = AppTheme.gbDark600,
    FontWeight fontWeight = FontWeight.w500,
    TextDecoration decoration = TextDecoration.none,
  }) => Theme.of(context).textTheme.displayMedium!.copyWith(
    color: color,
    fontFamily: 'nunitoSans',
    fontWeight: fontWeight,
    decoration: decoration,
  );

  static TextStyle displaySmallTextStyle(
    BuildContext context, {
    Color color = AppTheme.gbDark600,
    FontWeight fontWeight = FontWeight.w500,
    TextDecoration decoration = TextDecoration.none,
  }) => Theme.of(context).textTheme.displaySmall!.copyWith(
    color: color,
    fontWeight: fontWeight,
    fontFamily: 'nunitoSans',
    decoration: decoration,
  );

  static TextStyle headlineLargeTextStyle(
    BuildContext context, {
    Color color = AppTheme.gbDark600,
    FontWeight fontWeight = FontWeight.w500,
    TextDecoration decoration = TextDecoration.none,
  }) => Theme.of(context).textTheme.headlineLarge!.copyWith(
    color: color,
    fontWeight: fontWeight,
    fontFamily: 'nunitoSans',
    decoration: decoration,
  );

  static TextStyle headlineMediumTextStyle(
    BuildContext context, {
    Color color = AppTheme.gbDark600,
    FontWeight fontWeight = FontWeight.w500,
    TextDecoration decoration = TextDecoration.none,
  }) => Theme.of(context).textTheme.headlineMedium!.copyWith(
    color: color,
    fontWeight: fontWeight,
    fontFamily: 'nunitoSans',
    decoration: decoration,
  );

  static TextStyle headlineSmallTextStyle(
    BuildContext context, {
    Color color = AppTheme.gbDark600,
    FontWeight fontWeight = FontWeight.w500,
    TextDecoration decoration = TextDecoration.none,
  }) => Theme.of(context).textTheme.headlineSmall!.copyWith(
    color: color,
    fontWeight: fontWeight,
    fontFamily: 'nunitoSans',
    decoration: decoration,
  );

  static TextStyle labelLargeTextStyle(
    BuildContext context, {
    Color color = AppTheme.gbDark600,
    FontWeight fontWeight = FontWeight.w500,
    TextDecoration decoration = TextDecoration.none,
  }) => Theme.of(context).textTheme.labelLarge!.copyWith(
    color: color,
    fontWeight: fontWeight,
    fontFamily: 'nunitoSans',
    decoration: decoration,
  );

  static TextStyle labelMediumTextStyle(
    BuildContext context, {
    Color color = AppTheme.gbDark600,
    FontWeight fontWeight = FontWeight.w500,
    TextDecoration decoration = TextDecoration.none,
  }) => Theme.of(context).textTheme.labelMedium!.copyWith(
    color: color,
    fontWeight: fontWeight,
    fontFamily: 'nunitoSans',
    decoration: decoration,
  );

  static TextStyle labelSmallTextStyle(
    BuildContext context, {
    Color color = AppTheme.gbDark600,
    FontWeight fontWeight = FontWeight.w500,
    TextDecoration decoration = TextDecoration.none,
  }) => Theme.of(context).textTheme.labelSmall!.copyWith(
    color: color,
    fontWeight: fontWeight,
    fontFamily: 'nunitoSans',
    decoration: decoration,
  );

  static TextStyle bodyLargeTextStyle(
    BuildContext context, {
    Color color = AppTheme.gbDark600,
    FontWeight fontWeight = FontWeight.normal,
    TextDecoration decoration = TextDecoration.none,
  }) => Theme.of(context).textTheme.bodyLarge!.copyWith(
    color: color,
    fontWeight: fontWeight,
    fontFamily: 'nunitoSans',
    decoration: decoration,
  );

  static TextStyle bodyMediumTextStyle(
    BuildContext context, {
    Color color = AppTheme.gbDark600,
    FontStyle fontStyle = FontStyle.normal,
    TextDecoration decoration = TextDecoration.none,
    FontWeight fontWeight = FontWeight.normal,
  }) => Theme.of(context).textTheme.bodyMedium!.copyWith(
    fontStyle: fontStyle,
    color: color,
    decoration: decoration,
    fontFamily: 'nunitoSans',
    fontWeight: fontWeight,
  );

  static TextStyle bodySmallTextStyle(
    BuildContext context, {
    Color color = AppTheme.gbDark600,
    TextDecoration decoration = TextDecoration.none,
    FontWeight fontWeight = FontWeight.normal,
  }) => Theme.of(context).textTheme.bodySmall!.copyWith(
    color: color,
    decoration: decoration,
    fontFamily: 'nunitoSans',
    fontWeight: fontWeight,
  );

  static TextStyle titleMediumTextStyle(
    BuildContext context, {
    Color color = AppTheme.gbDark600,
    TextDecoration decoration = TextDecoration.none,
    FontWeight fontWeight = FontWeight.w500,
  }) => Theme.of(context).textTheme.titleMedium!.copyWith(
    color: color,
    fontWeight: fontWeight,
    fontFamily: 'nunitoSans',
    decoration: decoration,
  );

  static TextStyle titleSmallTextStyle(
    BuildContext context, {
    Color color = AppTheme.gbDark600,
    TextDecoration decoration = TextDecoration.none,
    FontWeight fontWeight = FontWeight.w500,
  }) => Theme.of(context).textTheme.titleSmall!.copyWith(
    color: color,
    fontWeight: fontWeight,
    fontFamily: 'nunitoSans',
    decoration: decoration,
  );

  static TextStyle titleLargeTextStyle(
    BuildContext context, {
    Color color = AppTheme.gbDark600,
    TextDecoration decoration = TextDecoration.none,
    FontWeight fontWeight = FontWeight.w500,
  }) => Theme.of(context).textTheme.titleLarge!.copyWith(
    color: color,
    fontWeight: fontWeight,
    fontFamily: 'nunitoSans',
    decoration: decoration,
  );

  static TextStyle dialogTitleTextStyle(
    BuildContext context, {
    Color color = AppTheme.primaryDark,
  }) => Theme.of(context).textTheme.titleSmall!.copyWith(
    color: color,
    fontWeight: FontWeight.bold,
    fontFamily: 'nunitoSans',
  );

  static TextStyle dialogContentTextStyle(
    BuildContext context, {
    Color color = AppTheme.gbDark600,
    FontWeight fontWeight = FontWeight.normal,
  }) => Theme.of(context).textTheme.bodySmall!.copyWith(
    color: color,
    fontWeight: fontWeight,
    fontFamily: 'nunitoSans',
  );

  static TextStyle dialogActionTextStyle(
    BuildContext context, {
    Color color = AppTheme.gbDark600,
    FontWeight fontWeight = FontWeight.w600,
  }) => Theme.of(context).textTheme.bodySmall!.copyWith(
    color: color,
    fontWeight: fontWeight,
    fontFamily: 'nunitoSans',
  );
}
