import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:http/http.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:running_app/src/data/api/constants.dart';
import '/app_localizations_context.dart';
import '/src/utils/navigator_key.dart';
import '/src/utils/error_messages_parser.dart';

class HttpError implements Exception {
  HttpError(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  @override
  String toString() => 'HttpError: $message';
}

class ApiService {
  static Map<String, dynamic> defaultResponse({
    String message = 'Ha ocurrido un error, intente nuevamente',
    Object? e,
  }) {
    if (e is ClientException || e is SocketException) {
      message = navigatorKey.currentContext!.l1on.networkErrorMessage;
    }
    if (e is TimeoutException) {
      message = navigatorKey.currentContext!.l1on.timeoutErrorMessage;
    }

    message = ErrorMessagesParser.sanitizeError(message);

    return <String, dynamic>{'response': false, 'message': message, 'data': []};
  }

  static Future<Map<String, dynamic>> getItemsByFilter(
    Map<String, dynamic> filter,
    String lang,
  ) async {
    log('Get items by filter API call');

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final Map<String, String> requestHeaders = <String, String>{
      'Content-Type': 'application/json',
      'Accept-Language': lang,
      if (token.isNotEmpty) 'Authorization': token,
    };

    final String uri = ApiConstants.itemsFilterUrl;
    log('url $uri');
    final Uri url = Uri.parse(uri);
    final Client client = http.Client();

    final Response response = await client.post(
      url,
      headers: requestHeaders,
      body: jsonEncode(filter),
    );
    client.close();

    log(response.body);

    return json.decode(utf8.decode(response.bodyBytes));
  }
}
