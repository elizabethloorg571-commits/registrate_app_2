import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class RegistrateLogo extends StatelessWidget {
  final double fontSize;
  final bool showIcon;

  const RegistrateLogo({super.key, this.fontSize = 24, this.showIcon = false});

  @override
  Widget build(BuildContext context) {
    final text = RichText(
      text: TextSpan(
        style: TextStyle(
          fontFamily: 'NunitoSans',
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        children: const [
          TextSpan(
            text: 'Regístra',
            style: TextStyle(color: Color(0xFF7952FC)),
          ),
          TextSpan(
            text: 'Te',
            style: TextStyle(color: Color(0xFFB15CDE)),
          ),
        ],
      ),
    );

    if (!showIcon) return text;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          'assets/images/registraTe-app-icon.svg',
          height: fontSize * 3.8,
        ),
        SizedBox(height: fontSize * 0.3),
        text,
      ],
    );
  }
}
