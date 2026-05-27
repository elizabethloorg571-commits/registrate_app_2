import 'package:flutter/material.dart';
import '../../../src/presentation/widgets/global_widgets.dart';

class Global {
  static EdgeInsets pagePadding(BuildContext context) {
    return GlobalWidgets.pagePadding(context);
  }

  static Widget circularProgressIndicator({Color? color, double radius = 16}) {
    return GlobalWidgets.circularProgressIndicator(
      color: color,
      radius: radius,
    );
  }

  static Future<void> showBasicAlert(
    String title,
    String message,
    String buttonText,
  ) {
    return GlobalWidgets.showBasicAlert(title, message, buttonText);
  }
}
