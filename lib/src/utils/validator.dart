import 'dart:typed_data';
import 'dart:ui';

class Validator {
  static bool areCoordinatesValid({
    required String? lat,
    required String? lng,
  }) {
    if (lat == null || lng == null) {
      return false;
    }
    final latDouble = double.tryParse(lat);
    final lngDouble = double.tryParse(lng);
    return latDouble != null && lngDouble != null;
  }

  static Future<bool> isImageValid(List<int> rawList) async {
    final uInt8List = rawList is Uint8List
        ? rawList
        : Uint8List.fromList(rawList);

    try {
      final codec = await instantiateImageCodec(uInt8List, targetWidth: 32);
      final frameInfo = await codec.getNextFrame();
      return frameInfo.image.width > 0;
    } catch (e) {
      return false;
    }
  }

  static bool isEmailValid(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  static bool thereIsNotEmptyFields(List<String> fieldsText) {
    for (var field in fieldsText) {
      if (field.isEmpty) {
        return false;
      }
    }
    return true;
  }

  static bool isPasswordValid(String password) {
    // final passwordRegex = RegExp(r'^(?=.*[A-Za-z])(?=.*\d).{8,}$');
    // return passwordRegex.hasMatch(password);
    return password.length >= 8;
  }

  static bool isPasswordStrong(String password) {
    final passwordRegex = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,}$',
    );
    return passwordRegex.hasMatch(password);
  }

  static bool isValidCardNumber(String cardNumber) {
    final cardNumberRegex = RegExp(r'^[0-9]{16}$');
    return cardNumberRegex.hasMatch(cardNumber);
  }

  static bool isValidExpirationDate(String expirationDate) {
    final expirationDateRegex = RegExp(r'^[0-9]{2}/[0-9]{2}$');
    return expirationDateRegex.hasMatch(expirationDate);
  }

  static bool isValidCVV(String cvv) {
    final cvvRegex3 = RegExp(r'^[0-9]{3}$');
    final cvvRegex4 = RegExp(r'^[0-9]{4}$');
    return cvvRegex3.hasMatch(cvv) || cvvRegex4.hasMatch(cvv);
  }

  static bool validate(ValidatorType validatorType, String value) {
    switch (validatorType) {
      case ValidatorType.minLength:
        return value.length >= 8;
      case ValidatorType.email:
        return isEmailValid(value);
      case ValidatorType.password:
        return isPasswordValid(value);
      case ValidatorType.celular:
        return value.length == 10 && int.tryParse(value) != null;
      case ValidatorType.passwordStrong:
        return isPasswordStrong(value);
      case ValidatorType.onlyNotEmptyFields:
        return value.isNotEmpty;
      case ValidatorType.onlyNumbers:
        return int.tryParse(value) != null;
      case ValidatorType.cedula:
        return value.length == 10 && int.tryParse(value) != null;
      case ValidatorType.ruc:
        return value.length == 13 && int.tryParse(value) != null;
      case ValidatorType.document:
        return (value.length >= 10) &&
            (value.length <= 13) &&
            int.tryParse(value) != null;
      case ValidatorType.passport:
        return true; // TODO: Implement passport validation
      case ValidatorType.date:
        return DateTime.tryParse(value) != null;
      case ValidatorType.hour:
        return RegExp(r'^([01]?[0-9]|2[0-3]):[0-5][0-9]$').hasMatch(value);
      case ValidatorType.phone:
        return RegExp(r'^[0-9]{10}$').hasMatch(value);
      case ValidatorType.phoneFormattedWithSpaces:
        if (value.contains("+593")) {
          //Ecuador number like "+59399 999 9999"
          return RegExp(r'^\+593[0-9]{2} [0-9]{3} [0-9]{4}$').hasMatch(value);
        }

        final cleanedValue = value.replaceAll(RegExp(r'[\s+]'), '');
        return int.tryParse(cleanedValue) != null;
      case ValidatorType.none:
        return true;
    }
  }
}

enum ValidatorType {
  minLength,
  email,
  password,
  passwordStrong,
  onlyNotEmptyFields,
  onlyNumbers,
  cedula,
  celular,
  ruc,
  phone,
  phoneFormattedWithSpaces,
  passport,
  document,
  date,
  hour,
  none,
}
