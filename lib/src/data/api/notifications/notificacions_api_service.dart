import 'dart:convert';
import 'dart:developer';

import 'package:running_app/src/data/constants/constants.dart';
import 'package:running_app/src/utils/http_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificacionsApiService {
  static Future<Map<String, dynamic>> getAllNotificationsByCurrentUser() async {
    log('\nGet all notifications by current user API call');
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final uuid = prefs.getString('userUuid') ?? '';
      Map<String, String> requestHeaders = {
        'Content-Type': 'application/json',
        'Accept-Language': 'es',
        'Authorization': token,
      };

      final url = Uri.parse(ApiConstants.notificationsFilter);
      log("url $url");
      final body = jsonEncode({"usuario_app._id": uuid});
      log("body $body");
      final response = await HttpUtils.post(
        url,
        headers: requestHeaders,
        body: body,
      );
      log("\n${response.body}");

      return json.decode(utf8.decode(response.bodyBytes));
    } catch (e) {
      log(e.toString());
      return HttpUtils.defaultResponse(message: "$e");
    }
  }
}
