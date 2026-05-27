import '../../../src/data/constants/constants.dart';

class MarketplaceConstants {
  static const String apiUrl = ApiConstants.apiUrl;
  static const String customToken = ApiConstants.customToken;
  static const String datafastApiUrl = ApiConstants.datafastApiUrl;

  /*
    * S3 URLS
  */
  static const String s3SignedUrl = ApiConstants
      .s3SignedUrl; // URL para obtener URLs firmadas para subir imágenes

  static const String s3UploadUrl =
      ApiConstants.s3UploadUrl; // URL base para acceder a imágenes subidas

  // * DeUna Payment
  static const String deUnaPaymentUrl = "$apiUrl/deuna";
  static const String deUnaPaymentInfoUrl = "$deUnaPaymentUrl/info-payment";
  static const String deUnaRequestPaymentUrl =
      "$deUnaPaymentUrl/request-payment";
  static const String deUnaRequestPaymentAbonadoUrl =
      "$deUnaPaymentUrl/request-payment-abonado";

  // * Discount Codes
  static const String discountCodeUrl = "$apiUrl/discount-code";
  static const String discountCodeValidateUrl =
      "$discountCodeUrl/validate-code";

  /*
    * FAVORITES ENDPOINTS (MARKETPLACE)
  */
  static const String favoriteUrl = '$apiUrl/favorite';
  static const String favoriteFilterUrl = '$favoriteUrl/filter';

  /*
    * CATEGORIES AND PRODUCTS ENDPOINTS (MARKETPLACE)
  */

  static const String itemsUrl = '$apiUrl/producto';
  static const String itemsFilterUrl = '$itemsUrl/filter';
  static const String categoriesUrl = '$apiUrl/categoria';
  static const String categoriesFilterUrl = '$categoriesUrl/filter';
  static const String catalogUrl = '$apiUrl/catalogo';
  static const String catalogFilterUrl = '$catalogUrl/filter';

  /*
    * COVERAGE ZONE ENDPOINTS
  */
  static const String coverageZoneUrl = '$apiUrl/coverage-zone';
  static const String coverageZoneValidateUrl = '$coverageZoneUrl/validate';

  /* 
    * ORDERS ENDPOINTS
  */
  static const String orderUrl = '$apiUrl/orden';
  static const String orderUpdateUrl = '$orderUrl/update';
  static const String orderFilterUrl = '$orderUrl/filter';

  /* 
    * USER ENDPOINTS
  */
  static const String personasUrl = '$apiUrl/persona';
  static const String loginUrl = '$apiUrl/persona/login';
  static const String personaUpdate = '$apiUrl/persona/update';
  static const String personaUpdateCustom = '$apiUrl/persona/update-app';
  static const String personaResetPass = '$apiUrl/persona/reset-pass';
  static const String personaConfirmCodePass =
      '$apiUrl/persona/confirm-code-pass';
  static const String personaDelete = '$apiUrl/persona/delete';
  static const String personaDeleteComplete = '$apiUrl/persona/delete-complete';
}
