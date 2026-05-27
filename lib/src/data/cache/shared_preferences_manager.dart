import 'dart:developer';

import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesManager {
  static Future<Map<String, dynamic>> setFields({
    Map<String, String> stringFields = const {},
    Map<String, int> intFields = const {},
    Map<String, double> doubleFields = const {},
    Map<String, bool> boolFields = const {},
  }) async {
    Map<String, dynamic> result = {
      'response': false,
      'message': 'Error al guardar los datos',
    };
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      stringFields.forEach((key, value) {
        prefs.setString(key, value);
      });
      intFields.forEach((key, value) {
        prefs.setInt(key, value);
      });
      doubleFields.forEach((key, value) {
        prefs.setDouble(key, value);
      });
      boolFields.forEach((key, value) {
        prefs.setBool(key, value);
      });
      result['response'] = true;
      result['message'] = 'Datos guardados correctamente';
      return result;
    } catch (e) {
      result['message'] = e.toString();
      return result;
    }
  }

  static Future<Map<String, dynamic>> getUserData() async {
    Map<String, dynamic> result = {
      'response': false,
      'message':
          'Error al obtener los datos, por favor inicie sesión nuevamente',
    };
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      Map<String, dynamic> userData = {
        'uuid': prefs.getString('uuid'),
        'email': prefs.getString('email'),
        'nombres': prefs.getString('nombres'),
        'apellidos': prefs.getString('apellidos'),
        'tipo_documento': prefs.getString('tipo_documento'),
        'num_documento': prefs.getString('num_documento'),
        'celular': prefs.getString('celular'),
        'tipo': prefs.getString('tipo'),
        'fecha_creacion': prefs.getString('fecha_creacion'),
        'foto': prefs.getString('foto'),
        'estado': prefs.getInt('estado'),
      };
      result['response'] = true;
      result['message'] = 'Datos obtenidos correctamente';
      result['data'] = userData;
      log(result.toString());
      return result;
    } catch (e) {
      log(e.toString());
      result['message'] = e.toString();
      return result;
    }
  }
}
