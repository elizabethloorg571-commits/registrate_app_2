import 'dart:convert';
import 'dart:developer';
import 'package:running_app/src/data/constants/constants.dart';
import 'package:running_app/src/utils/http_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DevicesApiService {
  static Future<Map<String, dynamic>> registerDevice(String deviceType) async {
    log('\nRegister device API call');
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final fcmToken = prefs.getString('fcmToken') ?? '';

      if (fcmToken == "") {
        return HttpUtils.defaultResponse(
          message:
              "No se ha podido obtener información del Token de notificaciones",
        );
      }

      final uuid = prefs.getString('userUuid') ?? '';
      Map<String, String> requestHeaders = {
        'Content-Type': 'application/json',
        'Accept-Language': 'es',
        'Authorization': token,
      };

      final url = Uri.parse(ApiConstants.devicesUrl);
      log("url $url");
      final body = jsonEncode({
        "user_app": uuid,
        "token": fcmToken,
        "alias": deviceType,
      });
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
      return HttpUtils.defaultResponse(e: e);
    }
  }

  static Future<Map<String, dynamic>> deleteDeviceRegister(
    String deviceId,
  ) async {
    log('\nDelete device register API call');
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      Map<String, String> requestHeaders = {
        'Content-Type': 'application/json',
        'Accept-Language': 'es',
        'Authorization': token,
      };

      final url = Uri.parse("${ApiConstants.devicesDeleteUrl}/$deviceId");
      log("url $url");
      final response = await HttpUtils.post(url, headers: requestHeaders);
      log("\n${response.body}");

      return json.decode(utf8.decode(response.bodyBytes));
    } catch (e) {
      log(e.toString());
      return HttpUtils.defaultResponse(e: e);
    }
  }
}
