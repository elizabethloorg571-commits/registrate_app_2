import 'dart:convert';
import 'dart:developer';
import 'package:mime/mime.dart';
import 'package:running_app/services/image_upload_service.dart';
import 'package:running_app/src/data/constants/constants.dart';
import 'package:running_app/src/utils/http_utils.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UsersApiService {
  static Future<Map<String, dynamic>> getUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final uuid = prefs.getString('uuid') ?? '';
      Map<String, String> requestHeaders = {
        'Content-Type': 'application/json',
        'Accept-Language': 'en',
        'Authorization': token,
      };

      final url = Uri.parse("${ApiConstants.personasUrl}/$uuid");
      log("url $url");
      final response = await HttpUtils.get(url, headers: requestHeaders);
      log("\n${response.body}");

      return json.decode(utf8.decode(response.bodyBytes));
    } catch (e) {
      log(e.toString());
      return HttpUtils.defaultResponse(e: e);
    }
  }

  static Future<Map<String, dynamic>> getPersonaByEmail(String email) async {
    log('\nGet persona by email API call');
    try {
      Map<String, String> requestHeaders = {
        'Content-Type': 'application/json',
        'Accept-Language': 'en',
      };

      log("url ${ApiConstants.personaFilterCustom}");

      final url = Uri.parse(ApiConstants.personaFilterCustom);
      final body = jsonEncode({
        "customToken": ApiConstants.customToken,
        "email": email,
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

  static Future<Map<String, dynamic>> updateUser(
    Map<String, dynamic> userData, {
    XFile? image,
    String lang = "es",
    bool needsCustomToken = false,
  }) async {
    log('\nUser update API call');
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      String uuid = prefs.getString('uuid') ?? '';
      Map<String, String> requestHeaders = {
        'Content-Type': 'application/json',
        'Accept-Language': lang,
        'Authorization': token,
      };

      String endpoint = ApiConstants.personaUpdate;

      if (needsCustomToken) {
        userData.addAll({"customToken": ApiConstants.customToken});
        endpoint = ApiConstants.personaUpdateCustom;
        uuid = userData['_id'];
      }

      if (image != null) {
        final mimeType = lookupMimeType(image.path);
        final imgFormat = mimeType!.split("/")[1];
        final dateTimeNowIso = DateTime.now().toIso8601String();
        final imageName = "$uuid$dateTimeNowIso";
        const path = "users";

        final didUpload = await ImageUploadService().uploadImage(
          image,
          path,
          imageName,
          imgFormat,
        );

        if (didUpload) {
          userData["foto"] =
              "${ApiConstants.s3UploadUrl}/$path/$imageName.$imgFormat";

          await prefs.setString('foto', userData["foto"]);
        } else {
          return HttpUtils.defaultResponse(message: "Error al subir la imagen");
        }
      }

      final url = Uri.parse("$endpoint/$uuid");
      log("url $url");
      final body = jsonEncode(userData);
      log("body $body");
      final response = await HttpUtils.put(
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

  static Future<Map<String, dynamic>> resetPassword(
    Map<String, dynamic> resetData,
    String lang,
  ) async {
    log('\nUser reset password API call');
    try {
      Map<String, String> requestHeaders = {
        'Content-Type': 'application/json',
        'Accept-Language': lang,
      };

      final url = Uri.parse(ApiConstants.personaResetPass);
      log("url $url");
      final body = jsonEncode(resetData);
      log("body $body");
      final response = await HttpUtils.post(
        url,
        headers: requestHeaders,
        body: body,
      );
      log("\n${response.body}");
      final responseBody = json.decode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200) {
        responseBody['status'] = true;
      } else {
        responseBody['status'] = false;
      }

      return responseBody;
    } catch (e) {
      log(e.toString());
      return HttpUtils.defaultResponse(e: e);
    }
  }

  static Future<Map<String, dynamic>> confirmResetPassword(
    Map<String, dynamic> confirmData,
    String lang,
  ) async {
    log('\nUser confirm reset password API call');
    try {
      Map<String, String> requestHeaders = {
        'Content-Type': 'application/json',
        'Accept-Language': lang,
      };

      final url = Uri.parse(ApiConstants.personaConfirmCodePass);
      log("url $url");
      final body = jsonEncode(confirmData);
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

  static Future<Map<String, dynamic>> verifyEmail(
    Map<String, dynamic> verifyData,
    String lang,
  ) async {
    log('\nUser verify email API call');
    try {
      Map<String, String> requestHeaders = {
        'Content-Type': 'application/json',
        'Accept-Language': lang,
      };

      final url = Uri.parse(ApiConstants.validateEmail);
      log("url $url");
      final body = jsonEncode(verifyData);
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

  static Future<Map<String, dynamic>> login(
    Map<String, dynamic> loginData,
    String lang,
  ) async {
    log('\nUser login API call');
    try {
      Map<String, String> requestHeaders = {
        'Content-Type': 'application/json',
        'Accept-Language': lang,
      };

      final url = Uri.parse(ApiConstants.loginUrl);
      log("url $url");
      final body = jsonEncode(loginData);
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

  static Future<Map<String, dynamic>> register(
    Map<String, dynamic> registerData,
    String lang,
  ) async {
    log('\nUser register API call');
    try {
      Map<String, String> requestHeaders = {
        'Content-Type': 'application/json',
        'Accept-Language': lang,
      };

      final url = Uri.parse(ApiConstants.personasUrl);
      log("url $url");
      final body = jsonEncode(registerData);
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

  static Future<Map<String, dynamic>> deleteUserComplete() async {
    log('\nDelete user API call');
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final uuid = prefs.getString('uuid') ?? '';
      Map<String, String> requestHeaders = {
        'Content-Type': 'application/json',
        'Accept-Language': 'en',
        'Authorization': token,
      };

      final url = Uri.parse("${ApiConstants.personaDeleteComplete}/$uuid");

      final response = await HttpUtils.post(url, headers: requestHeaders);
      log("\n${response.body}");

      final responseJson = json.decode(utf8.decode(response.bodyBytes));

      return responseJson;
    } catch (e) {
      log(e.toString());
      return HttpUtils.defaultResponse(e: e);
    }
  }
}
