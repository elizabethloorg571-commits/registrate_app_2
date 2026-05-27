import 'dart:convert';
import 'dart:developer';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:running_app/src/data/constants/constants.dart';
import 'package:running_app/src/utils/http_utils.dart';

class CompetitionsApiService {
  static Future<Map<String, dynamic>> fetchRuns() async {
    log('Get all runs by company API call');
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String token = prefs.getString('token') ?? '';

      Map<String, String> requestHeaders = {
        'Content-Type': 'application/json',
        'Authorization': token,
      };

      String uri = ApiConstants.runsUrl;
      final url = Uri.parse(uri);
      log("url $url");
      final response = await HttpUtils.get(url, headers: requestHeaders);

      log(response.body);

      return json.decode(utf8.decode(response.bodyBytes));
    } catch (e) {
      return HttpUtils.defaultResponse(e: e);
    }
  }

  static Future<Map<String, dynamic>> fetchRunDetails(String runId) async {
    log('Get Run details by ID API call');
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String token = prefs.getString('token') ?? '';

      Map<String, String> requestHeaders = {
        'Content-Type': 'application/json',
        'Authorization': token,
      };

      String uri = "${ApiConstants.runsUrl}/$runId";
      final url = Uri.parse(uri);
      log("url $url");
      final response = await HttpUtils.get(url, headers: requestHeaders);

      log(response.body);

      return json.decode(utf8.decode(response.bodyBytes));
    } catch (e) {
      return HttpUtils.defaultResponse(e: e);
    }
  }
}
