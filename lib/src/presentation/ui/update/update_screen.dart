import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:running_app/services/shared_service.dart';
import 'package:running_app/config/theme/app_theme.dart';
import 'package:running_app/config/theme/fonts.dart';
import 'package:running_app/src/utils/navigator_key.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateScreen extends StatefulWidget {
  const UpdateScreen({
    super.key,
    required this.storeUrl,
    required this.storeVersion,
  });

  final String storeUrl;
  final String storeVersion;
  static const String name = '/update';

  @override
  State<UpdateScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<UpdateScreen> {
  Future<void> _launchUrl() async {
    final storeUrl = Uri.parse(widget.storeUrl);
    log(storeUrl.toString());
    if (!await launchUrl(storeUrl, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.lightModeErrorRed,
          content: Text(
            'No se pudo realizar la conexión con la tienda, revise su conexión a Internet e inténtelo de nuevo.',
            style: nunitoSansStyle(400, 14, color: Colors.white),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/splash_background.png'),
            fit: BoxFit.fill,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Nueva actualización disponible',
              style: nunitoSansTitleLargeStyle(
                context,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            Lottie.asset(
              'assets/json/animations/man_running.json',
              fit: BoxFit.contain,
              repeat: true,
              height: 150,
            ),
            const SizedBox(height: 20),
            Text(
              'Versión de la tienda',
              style: nunitoSansTitleSmallStyle(
                context,
                fontWeight: FontWeight.w300,
              ),
            ),
            Text(
              'v:${widget.storeVersion}',
              style: nunitoSansTitleSmallStyle(
                context,
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              SharedService.storeReleaseNotes.isNotEmpty
                  ? SharedService.storeReleaseNotes
                  : 'Tenemos una nueva actualización para ti, por favor actualiza la aplicación para continuar.',
              style: nunitoSansBodyMediumStyle(context),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.lightModeBlue,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 13,
                  ),
                  disabledBackgroundColor: AppTheme.lightModeBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: () => _launchUrl(),
                icon: Icon(
                  Icons.system_update_alt_outlined,
                  color: AppTheme.white950,
                ),
                label: Text(
                  'Actualizar ahora',
                  style: nunitoSansStyle(600, 15, color: AppTheme.white950),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
