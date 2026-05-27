import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class UrlLauncherUtils {
  static Future<void> launchWhatsAppUri(
    BuildContext context,
    String? phoneNumber,
  ) async {
    final Uri httpsURL = Uri(
      scheme: 'https',
      host: 'api.whatsapp.com',
      path: '/send/',
      queryParameters: <String, dynamic>{
        'phone': phoneNumber ?? '+593998008022',
        'text': DateTime.now().hour < 12
            ? 'Buenos días, requiero información.'
            : DateTime.now().hour < 19
            ? 'Buenas tardes, requiero información.'
            : 'Buenas noches, requiero información.',
        'type': 'phone_number',
      },
    );
    await launchUrl(httpsURL, mode: LaunchMode.externalApplication);
  }

  static Future<void> launch(
    String url, {
    LaunchMode mode = LaunchMode.externalApplication,
  }) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: mode);
    } else {
      throw 'Could not launch $url';
    }
  }
}
