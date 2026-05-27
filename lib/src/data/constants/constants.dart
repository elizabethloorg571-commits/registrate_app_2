class ApiConstants {
  //? DEV
  // static const String apiUrl = "https://api-runapp-dev.magdata.com.ec";

  //? PROD
  static const String apiUrl = "https://api-runapp.magdata.com.ec";

  static const String datafastApiUrl = "https://registrate.magdata.com.ec/";

  static const String customToken =
      "aswsasHKHVHw21321VKsdssad213421BKJKJBK5%%sdsh3sds2&d23234324fsdfdsfsddfdsfBKHKd342esBMKHBs";

  static const String matchesUrl = "$apiUrl/match";

  static const String runsUrl = "$apiUrl/carrera";

  static const String ticketsUrl = "$apiUrl/ticket";

  static const String ticketsFilterUrl = "$ticketsUrl/filter";

  static const String ticketsCountUrl = "$ticketsUrl/count";

  static const String discountCodeUrl = "$apiUrl/discount-code";

  static const String discountCodeValidateUrl =
      "$discountCodeUrl/validate-code";

  /* 
    * LOGIN AND PERSONAS ENDPOINTS
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
  static const String personaFilterCustom =
      '$apiUrl/persona/filter-custom-auth';
  static const String validateToken = '$apiUrl/persona/validate-token';
  static const String validateEmail =
      '$apiUrl/persona/verificar-email'; // Endpoint to validate email existence
  static const String resetPass = '$apiUrl/persona/reset-pass';
  static const String confirmCodePass = '$apiUrl/persona/confirm-code-pass';
  static const String registerUrl = '$apiUrl/user/register';

  /*
    * S3 URLS
  */
  static const String s3SignedUrl =
      'https://pfoe9ldpy1.execute-api.us-east-1.amazonaws.com/prod/signedurl';

  static const String s3UploadUrl =
      'https://files-gear-prod.s3.amazonaws.com/upload';

  /*
    * PAYMENT GATEWAY ENDPOINTS
  */

  static const String gatewayUrl = '$apiUrl/pasarela';
  static const String gatewayCheckoutUrl = '$gatewayUrl/checkout';
  static const String gatewayStatusUrl = '$gatewayUrl/status';
  static const String deUnaPaymentUrl = "$apiUrl/deuna";
  static const String deUnaRequestPaymentUrl =
      "$deUnaPaymentUrl/request-payment";
  static const String deUnaRequestPaymentAbonadoUrl =
      "$deUnaPaymentUrl/request-payment-abonado";
  static const String deUnaPaymentInfoUrl = "$deUnaPaymentUrl/info-payment";

  /*
    * DEVICES ENDPOINTS
  */
  static const String devicesUrl = '$apiUrl/device';
  static const String devicesDeleteUrl = '$devicesUrl-app/delete';

  /*
    * SPONSORS ENDPOINTS
  */

  static const String sponsorsUrl = '$apiUrl/sponsor';

  /*
    * SUBSCRIPTIONS ENDPOINTS
  */
  static const String subscriptionsUrl = '$apiUrl/abono';
  static const String subscriberUrl = '$apiUrl/abonado';
  static const String buySubscriptionsUrl = '$subscriberUrl/comprar-abonados';

  /*
    * NOTIFICATIONS ENDPOINTS
  */
  static const String notificationsUrl = '$apiUrl/notificacion';

  static const String notificationsFilter = '$apiUrl/notificacion/filter-app';

  static const String notificationsUpdate = '$apiUrl/notificacion/update';

  /*
    * INSCRIPTIONS ENDPOINTS
  */

  static const String inscriptionsUrl = '$apiUrl/order-inscription';
  static const String inscriptionsFilter = '$inscriptionsUrl/filter';
  static const String inscriptionsUpdate = '$inscriptionsUrl/update';
  static const String inscriptionsDelete = '$inscriptionsUrl/delete';
  static const String inscriptionsCountUrl = '$inscriptionsUrl/count';
}
