class ApiConstants {
  //? DEV
  // static const String apiUrl = "https://api-runapp-dev.magdata.com.ec";

  //? PROD
  static const String apiUrl = "https://api-runapp.magdata.com.ec";
  /* 
    * LOGIN AND USERS ENDPOINTS
  */
  static const String usersUrl = '$apiUrl/user';
  static const String userUpdate = '$apiUrl/user/update';
  static const String userUpdateCustom = '$apiUrl/user/update-app';
  static const String loginUrl = '$apiUrl/user/login';
  static const String usersRegister = '$apiUrl/user/registro';
  static const String usersPasswordReset = '$apiUrl/user/reset-pass';
  static const String usersPasswordValidateCode = '$apiUrl/user/confirm-code';
  static const String usersPasswordChange = '$apiUrl/user/confirm-code-pass';
  static const String usersFilterUrl = '$apiUrl/user/filter';

  /*
    * CUSTOMERS AND PERSONS ENDPOINTS
  */

  static const String customersUrl = '$apiUrl/clientes';
  static const String customersFilterUrl = '$apiUrl/clientes/filter';
  static const String customersDeleteUrl = '$apiUrl/clientes/delete';
  static const String personsUrl = '$apiUrl/personas';
  static const String personsFilterUrl = '$apiUrl/personas/filter';
  static const String personsDeleteUrl = '$apiUrl/personas/delete';

  /*
    * FAVORITES ENDPOINTS (MARKETPLACE)
  */
  static const String favoriteUrl = '$apiUrl/favorite';
  static const String favoriteFilterUrl = '$favoriteUrl/filter';

  /*
    * QUOTATIONS ENDPOINTS
  */
  static const String quotationsUrl = '$apiUrl/cotizaciones';

  static const String quotationsFilterUrl = '$quotationsUrl/filter';

  /*
    * ITEMS, GROUPS, COMPLEMENTS AND COLLECTIONS ENDPOINTS
  */

  // static const String itemsUrl = '$apiUrl/items';
  // static const String itemsPdfCreation = '$documentsApiUrl/pdf-items';
  // static const String itemsFilterUrl = '$itemsUrl/filter';

  static const String itemsUrl = '$apiUrl/producto';
  static const String itemsFilterUrl = '$itemsUrl/filter';
  static const String categoriesUrl = '$apiUrl/categoria';
  static const String categoriesFilterUrl = '$categoriesUrl/filter';

  static const String catalogUrl = '$apiUrl/catalogo';
  static const String cataloFilterUrl = '$catalogUrl/filter';

  static const String groupsUrl = '$apiUrl/grupos';
  static const String groupsFilterUrl = '$groupsUrl/filter';

  static const String subgroupsUrl = '$apiUrl/subgroup';
  static const String subgroupsFilterUrl = '$subgroupsUrl/filter';

  static const String complementsUrl = '$apiUrl/aditamentos';
  static const String complementsFilterUrl = '$complementsUrl/filter';

  static const String collectionsUrl = '$apiUrl/collection';
  static const String collectionsFilterUrl = '$collectionsUrl/filter';

  /* 
    * ORDERS ENDPOINTS
  */
  static const String orderUrl = '$apiUrl/orden';
  static const String ordersUpdateUrl = '$orderUrl/update';
  static const String ordersFilterUrl = '$orderUrl/filter';

  /*
    * ORGANIZATIONS ENDPOINTS
  */
  static const String organizationsUrl = '$apiUrl/organizaciones';
  static const String organizationsFilterUrl = '$organizationsUrl/filter';

  /*
    * BRANCHES ENDPOINTS
  */

  static const String branchesUrl = '$apiUrl/sucursales';

  static const String branchesFilterUrl = '$branchesUrl/filter';

  static const String branchesDeleteUrl = '$branchesUrl/delete';

  /*
    * DELIVERY ENDPOINTS
  */

  static const String deliveryUrl = '$apiUrl/delivery';
  static const String deliveryFilterUrl = '$deliveryUrl/filter';

  /*
    * EXTRAS ENDPOINT
  */

  static const String extrasUrl = '$apiUrl/extra';

  static const String extrasFilterUrl = '$extrasUrl/filter';

  static const String extrasDeleteUrl = '$extrasUrl/delete';

  /*
    * COMBOS ENDPOINT
  */

  static const String combosUrl = '$apiUrl/combo';

  static const String combosFilterUrl = '$combosUrl/filter';

  static const String combosDeleteUrl = '$combosUrl/delete';

  /*
    * ROLES ENDPOINTS
  */

  static const String rolesUrl = '$apiUrl/rol';
  static const String rolesFilterUrl = '$apiUrl/rol/filter';

  /*
    * EMAIL SENDING ENDPOINT
  */

  static const String emailUrl = '$apiUrl/email';

  /*
    * S3 UPLOAD ENDPOINT
  */

  static const String imgUploadPath =
      'https://bucket-images-gb97-prod.s3.amazonaws.com/upload';

  static const String noPhotoUrl = '$imgUploadPath/no-photo.png';

  static const String privacyPolicyUrl =
      '$imgUploadPath/gb97order/es_ec_privacy_policy.html';

  static const String orderPrivacyPolicyUrl =
      '$imgUploadPath/ordergb97_privacy_policy.html';

  /*
    * AWS LAMBDA ENDPOINTS
  */

  static const String awsSignedUrlLambda =
      'https://dbxciqp8de.execute-api.us-east-1.amazonaws.com/prod/signedurl';

  /*
    * DEUNA PAYMENT ENDPOINTS
  */

  static const String deunaInfoPaymentUrl =
      'https://api-fanapp.magdata.com.ec/deuna/info-payment';

  static const String deunaRequestPaymentUrl =
      'https://api-runapp.magdata.com.ec/deuna/request-payment';

  /*
    * TEMPLATES AND DOCUMENTS URLs
  */

  static const String excelTemplateItemsUrl =
      'https://gb97.ec/plantilla_creacion_items_pedidos.xlsx';

  static const String excelTemplateCustomersUrl =
      '$imgUploadPath/plantillas/orderGB97/plantilla_creacion_clientes.xlsx';

  /*
    * MARKETPLACE ENDPOINTS
  */

  static const String marketplaceFavoritesUrl = '$apiUrl/marketplace/favorites';

  /*
    * DEVICES
  */

  static const String devicesUrl = '$apiUrl/device';
}
