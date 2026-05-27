import 'package:flutter/material.dart';
import 'package:running_app/src/utils/responsive.dart';
import 'package:running_app/config/theme/app_theme.dart';
import 'package:running_app/config/theme/fonts.dart';

class GlobalButtons {
  static ElevatedButton mainActionButton(
    BuildContext context, {
    required String text,
    required void Function()? onPressed,
    bool isLoading = false,
    double widthFactor = 1.0,
    double height = 50.0,
    EdgeInsetsGeometry? margin,
    Color? backgroundColor,
    Color? textColor,
    double borderRadius = 8.0,
    TextStyle? textStyle,
  }) {
    final responsive = Responsive(context);
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.lightModeGreen,
        padding: EdgeInsets.symmetric(
          horizontal: responsive.wp(30),
          vertical: responsive.hp(10),
        ),
        disabledBackgroundColor: AppTheme.lightModeGreen,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(responsive.wp(20)),
        ),
      ),
      child: isLoading
          ? SizedBox(
              width: height / 2,
              height: height / 2,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  textColor ?? Colors.white,
                ),
                strokeWidth: 2.0,
              ),
            )
          : Text(
              text,
              style:
                  textStyle ??
                  nunitoSansTitleSmallStyle(
                    context,
                    color: AppTheme.white950,
                    fontWeight: FontWeight.w600,
                  ),
            ),
    );
  }
}
