import 'dart:convert';
import 'dart:developer';

import 'package:running_app/src/data/constants/constants.dart';
import 'package:running_app/src/utils/http_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InscriptionsApiService {
  static Future<Map<String, dynamic>> fetchAllInscriptions() async {
    log('Get all inscriptions API call');
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String token = prefs.getString('token') ?? '';

      Map<String, String> requestHeaders = {
        'Content-Type': 'application/json',
        'Authorization': token,
      };

      String uri = ApiConstants.inscriptionsUrl;
      final url = Uri.parse(uri);
      log("url $url");
      final response = await HttpUtils.get(url, headers: requestHeaders);

      log(response.body);

      return json.decode(utf8.decode(response.bodyBytes));
    } catch (e) {
      return HttpUtils.defaultResponse(e: e);
    }
  }

  static Future<Map<String, dynamic>> requestDeUnaPaymentInfo(
    Map<String, dynamic> data,
  ) async {
    log('Request de una payment info API call');
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String token = prefs.getString('token') ?? '';

      Map<String, String> requestHeaders = {
        'Content-Type': 'application/json',
        'Authorization': token,
      };

      String uri = ApiConstants.deUnaPaymentInfoUrl;
      final url = Uri.parse(uri);
      log("url $url");
      final body = jsonEncode(data);
      log("body $body");
      final response = await HttpUtils.post(
        url,
        headers: requestHeaders,
        body: body,
      );

      log(response.body);

      return json.decode(utf8.decode(response.bodyBytes));
    } catch (e) {
      return HttpUtils.defaultResponse(e: e);
    }
  }

  static Future<Map<String, dynamic>> requestDeUnaPayment(
    String serviceLabel,
    String serviceId,
  ) async {
    log('Request de una payment API call');
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String token = prefs.getString('token') ?? '';

      Map<String, String> requestHeaders = {
        'Content-Type': 'application/json',
        'Authorization': token,
      };

      String uri = ApiConstants.deUnaRequestPaymentUrl;
      final url = Uri.parse(uri);
      log("url $url");
      final body = jsonEncode({serviceLabel: serviceId});
      log("body $body");
      final response = await HttpUtils.post(
        url,
        headers: requestHeaders,
        body: body,
      );

      log(response.body);

      return json.decode(utf8.decode(response.bodyBytes));
    } catch (e) {
      return HttpUtils.defaultResponse(e: e);
    }
  }

  static Future<Map<String, dynamic>> getUserInscriptionsCount(
    String matchId,
    String userUuid,
  ) async {
    log('Get user inscriptions count per match API call');
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String token = prefs.getString('token') ?? '';

      Map<String, String> requestHeaders = {
        'Content-Type': 'application/json',
        'Authorization': token,
      };

      String uri = ApiConstants.inscriptionsCountUrl;
      final url = Uri.parse(uri);
      log("url $url");
      final body = jsonEncode({'user': userUuid, 'match': matchId});
      log("body $body");
      final response = await HttpUtils.post(
        url,
        headers: requestHeaders,
        body: body,
      );

      log(response.body);

      return json.decode(utf8.decode(response.bodyBytes));
    } catch (e) {
      return HttpUtils.defaultResponse(e: e);
    }
  }

  static Future<Map<String, dynamic>> getInscriptionFilter(
    Map<String, dynamic> filter, {
    bool self = false,
  }) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String token = prefs.getString('token') ?? '';

      Map<String, String> requestHeaders = {
        'Content-Type': 'application/json',
        'Authorization': token,
      };

      String uri = ApiConstants.inscriptionsFilter;
      final url = Uri.parse(uri);
      log("url $url");
      if (self) {
        final userUuid = prefs.getString('uuid') ?? '';
        filter['buyer'] = userUuid;
      }
      final body = jsonEncode(filter);
      log("body $body");
      final response = await HttpUtils.post(
        url,
        headers: requestHeaders,
        body: body,
      );

      return json.decode(utf8.decode(response.bodyBytes));
    } catch (e) {
      return HttpUtils.defaultResponse(e: e);
    }
  }

  static Future<Map<String, dynamic>> insertInscription(
    Map<String, dynamic> inscriptionData,
  ) async {
    log('Buy inscription API call');
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String token = prefs.getString('token') ?? '';

      Map<String, String> requestHeaders = {
        'Content-Type': 'application/json',
        'Authorization': token,
      };

      String uri = ApiConstants.inscriptionsUrl;
      final url = Uri.parse(uri);
      log("url $url");
      final body = jsonEncode(inscriptionData);
      log("body $body");
      final response = await HttpUtils.post(
        url,
        headers: requestHeaders,
        body: body,
      );

      log(response.body);

      return json.decode(utf8.decode(response.bodyBytes));
    } catch (e) {
      return HttpUtils.defaultResponse(e: e);
    }
  }

  static Future<Map<String, dynamic>> validateDiscountCode(
    String code,
    double total,
  ) async {
    log('Validate discount code API call');
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String token = prefs.getString('token') ?? '';

      Map<String, String> requestHeaders = {
        'Content-Type': 'application/json',
        'Authorization': token,
      };

      String uri = ApiConstants.discountCodeValidateUrl;
      final url = Uri.parse(uri);
      log("url $url");
      final body = jsonEncode({'code': code, 'total': total});
      log("body $body");
      final response = await HttpUtils.post(
        url,
        headers: requestHeaders,
        body: body,
      );

      log(response.body);

      return json.decode(utf8.decode(response.bodyBytes));
    } catch (e) {
      return HttpUtils.defaultResponse(e: e);
    }
  }
}
