import 'package:flutter/material.dart';

class CustomIconButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback? onPressed;
  final double? size;
  final Color? color;
  final Color? backgroundColor;
  final Color? splashColor;
  final Color? highlightColor;
  final double? padding;
  final BorderRadius? borderRadius;
  final BoxBorder? border;
  final String? tooltip;
  final EdgeInsetsGeometry? margin;
  final AlignmentGeometry? alignment;
  final BoxShape shape;
  final List<BoxShadow>? boxShadow;
  final Gradient? gradient;
  final double? iconOpacity;

  const CustomIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.size = 24.0,
    this.color,
    this.backgroundColor,
    this.splashColor,
    this.highlightColor,
    this.padding = 8.0,
    this.borderRadius,
    this.border,
    this.tooltip,
    this.margin,
    this.alignment = Alignment.center,
    this.shape = BoxShape.rectangle,
    this.boxShadow,
    this.gradient,
    this.iconOpacity = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorderRadius =
        borderRadius ??
        (shape == BoxShape.circle
            ? BorderRadius.circular(1000)
            : BorderRadius.circular(8.0));

    Widget button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        splashColor: splashColor ?? Theme.of(context).splashColor,
        highlightColor: highlightColor ?? Theme.of(context).highlightColor,
        borderRadius: shape == BoxShape.circle ? null : effectiveBorderRadius,
        customBorder: shape == BoxShape.circle ? const CircleBorder() : null,
        child: Container(
          padding: EdgeInsets.all(padding ?? 0),
          margin: margin,
          alignment: alignment,
          decoration: BoxDecoration(
            color: backgroundColor,
            gradient: gradient,
            border: border,
            borderRadius: shape == BoxShape.circle
                ? null
                : effectiveBorderRadius,
            shape: shape,
            boxShadow: boxShadow,
          ),
          child: Opacity(opacity: iconOpacity ?? 1.0, child: icon),
        ),
      ),
    );

    if (tooltip != null) {
      button = Tooltip(message: tooltip!, child: button);
    }

    return button;
  }
}
