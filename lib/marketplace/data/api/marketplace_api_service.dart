import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../marketplace.dart';
import '../../services/image_upload_service.dart';
import '../../utils/http_utils.dart';
import '../api/constants.dart';

class MarketplaceApiService {
  /// Caches the empresa object from the last catalog fetch.
  /// Contains payment settings: isApplyTC, isApplyDeuna, isApplyManual, banckName, etc.
  static Map<String, dynamic>? catalogEmpresaInfo;

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

      String endpoint = MarketplaceConstants.personaUpdate;

      if (needsCustomToken) {
        userData.addAll({"customToken": MarketplaceConstants.customToken});
        endpoint = MarketplaceConstants.personaUpdateCustom;
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
              "${MarketplaceConstants.s3UploadUrl}/$path/$imageName.$imgFormat";

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

      final String uri = MarketplaceConstants.deUnaPaymentInfoUrl;
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

      String uri = MarketplaceConstants.deUnaRequestPaymentUrl;
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

      String uri = MarketplaceConstants.discountCodeValidateUrl;
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

  static Future<Map<String, dynamic>> _getAuthorizedCollection(Uri url) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String token = prefs.getString('token') ?? '';

      final Map<String, String> requestHeaders = <String, String>{
        'Content-Type': 'application/json',
        'Accept-Language': 'es',
        if (token.isNotEmpty) 'Authorization': token,
      };

      final http.Client client = http.Client();
      final http.Response response = await client.get(
        url,
        headers: requestHeaders,
      );
      client.close();

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      }

      String responseMessage = 'Error al obtener datos: ${response.statusCode}';
      try {
        final decodedResponse = json.decode(utf8.decode(response.bodyBytes));
        responseMessage =
            decodedResponse['message']?.toString() ?? responseMessage;
      } catch (_) {}

      return {'response': false, 'message': responseMessage};
    } catch (e) {
      log('Error in _getAuthorizedCollection: $e');
      return {'response': false, 'message': 'Error de conexión'};
    }
  }

  static Future<Map<String, dynamic>> _postAuthorizedCollection(
    Uri url,
    Map<String, dynamic> body,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String token = prefs.getString('token') ?? '';

      final Map<String, String> requestHeaders = <String, String>{
        'Content-Type': 'application/json',
        'Accept-Language': 'es',
        if (token.isNotEmpty) 'Authorization': token,
      };

      final http.Client client = http.Client();
      final http.Response response = await client.post(
        url,
        headers: requestHeaders,
        body: json.encode(body),
      );
      client.close();

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      }

      String responseMessage = 'Error al obtener datos: ${response.statusCode}';
      try {
        final decodedResponse = json.decode(utf8.decode(response.bodyBytes));
        responseMessage =
            decodedResponse['message']?.toString() ?? responseMessage;
      } catch (_) {}

      return {'response': false, 'message': responseMessage};
    } catch (e) {
      log('Error in _postAuthorizedCollection: $e');
      return {'response': false, 'message': 'Error de conexión'};
    }
  }

  static Future<List<Map<String, dynamic>>> _fetchCatalogProducts({
    List<String>? categoryIds,
  }) async {
    final Set<String> seenProductIds = <String>{};
    final List<Map<String, dynamic>> products = [];

    final normalizedCategoryIds = (categoryIds ?? []).where(
      (id) => id.isNotEmpty,
    );
    final requests = normalizedCategoryIds.isEmpty
        ? [null]
        : normalizedCategoryIds.toList();

    for (final categoryId in requests) {
      final Uri url = Uri.parse(
        MarketplaceConstants.catalogFilterUrl,
      ).replace(queryParameters: {'page': '1', 'limit': '100'});

      final body = <String, dynamic>{'name': 'general'};
      if (categoryId != null) {
        body['category'] = categoryId;
      }

      final response = await _postAuthorizedCollection(url, body);
      if (response['response'] != true) {
        log('Error loading catalog products: ${response['message']}');
        continue;
      }

      final List data = response['data'] ?? [];
      log('Fetched ${jsonEncode(data)}');

      // Extract and cache empresa payment settings from first catalog entry
      if (catalogEmpresaInfo == null && data.isNotEmpty) {
        final firstEntry = data.first;
        if (firstEntry is Map<String, dynamic>) {
          final rawEmpresa = firstEntry['empresa'];
          if (rawEmpresa is Map<String, dynamic>) {
            catalogEmpresaInfo = rawEmpresa;
          }
        }
      }

      final extractedProducts =
          MarketplaceHelpers.extractProductsFromCatalogData(data);
      for (final product in extractedProducts) {
        final productId = product['_id']?.toString() ?? '';
        if (productId.isEmpty || !seenProductIds.add(productId)) {
          continue;
        }
        products.add(product);
      }
    }

    return products;
  }

  static Future<Map<String, dynamic>> getMarketplaceProducts({
    int page = 1,
    int limit = 20,
    String? category,
    List<String>? categoryIds,
    String? searchQuery,
    double? minPrice,
    double? maxPrice,
    bool? inStockOnly,
    bool? onSaleOnly,
    int? minDiscount,
    String? sortBy,
    String? availability,
    bool forceRefresh = false,
  }) async {
    try {
      log(
        'Get marketplace products - page: $page, category: $category, search: $searchQuery',
      );
      final resolvedCategoryIds = <String>{
        if (category != null && category.isNotEmpty) category,
        ...?categoryIds?.where((id) => id.isNotEmpty),
      }.toList();

      final rawCatalogProducts = await _fetchCatalogProducts(
        categoryIds: resolvedCategoryIds,
      );

      final products = rawCatalogProducts
          .map((item) {
            try {
              return MarketplaceHelpers.mapItemToMarketplaceProduct(item);
            } catch (e, stackTrace) {
              log('Error converting catalog item to MarketplaceProduct: $e');
              log('Stack trace: $stackTrace');
              log('Catalog item ID: ${item['_id']}');
              return null;
            }
          })
          .whereType<MarketplaceProduct>()
          .toList();

      final filteredProducts = MarketplaceHelpers.applyLocalFilters(
        products,
        searchQuery: searchQuery,
        minPrice: minPrice,
        maxPrice: maxPrice,
        inStockOnly: inStockOnly,
        onSaleOnly: onSaleOnly,
        minDiscount: minDiscount,
        availability: availability,
      );

      MarketplaceHelpers.sortProducts(filteredProducts, sortBy);

      final paginatedProducts = MarketplaceHelpers.paginateProducts(
        filteredProducts,
        page: page,
        limit: limit,
      );

      final totalPages = filteredProducts.isEmpty
          ? 0
          : ((filteredProducts.length + limit - 1) / limit).floor();

      final result = {
        'response': true,
        'data': paginatedProducts,
        'total': filteredProducts.length,
        'page': page,
        'message': 'Productos cargados exitosamente',
        'pagination': {
          'currentPage': page,
          'totalPages': totalPages,
          'totalCount': filteredProducts.length,
          'limit': limit,
        },
      };

      log('Successfully converted ${paginatedProducts.length} products');

      return result;
    } catch (e) {
      log('Error in getMarketplaceProducts: $e');
      return {
        'response': false,
        'message': 'Ha ocurrido un error, intente nuevamente',
        'data': <MarketplaceProduct>[],
      };
    }
  }

  /// Obtener categorías disponibles para filtros del marketplace
  static Future<List<MarketplaceCategory>> getMarketplaceCategories() async {
    try {
      final Uri url = Uri.parse(
        MarketplaceConstants.categoriesUrl,
      ).replace(queryParameters: {'page': '1', 'limit': '100'});

      final response = await _getAuthorizedCollection(url);
      if (response['response'] != true) {
        log('Error loading marketplace categories: ${response['message']}');
        return [];
      }

      final List data = response['data'] ?? [];
      final Map<String, MarketplaceCategory> categoriesByName = {};
      final List<String> categoryOrder = [];

      for (final rawCategory in data) {
        if (rawCategory is! Map<String, dynamic>) continue;
        if (rawCategory['parent'] != null) continue;

        final String name = (rawCategory['name'] ?? '').toString().trim();
        if (name.isEmpty) continue;

        final String normalizedName = name.toLowerCase();
        final parsedCategory = MarketplaceCategory.fromJson(rawCategory);
        final existingCategory = categoriesByName[normalizedName];

        if (existingCategory == null) {
          categoriesByName[normalizedName] = parsedCategory.copyWith(
            isPopular: categoryOrder.length < 4,
          );
          categoryOrder.add(normalizedName);
          continue;
        }

        categoriesByName[normalizedName] = existingCategory.copyWith(
          backendIds: {
            ...existingCategory.backendIds,
            ...parsedCategory.backendIds,
          }.toList(),
          productCount:
              existingCategory.productCount + parsedCategory.productCount,
        );
      }

      final categories = categoryOrder
          .map((categoryKey) => categoriesByName[categoryKey]!)
          .toList();

      log('Loaded ${categories.length} marketplace categories');
      return categories;
    } catch (e) {
      log('Error in getMarketplaceCategories: $e');
      return [];
    }
  }

  /// Obtener producto por ID
  static Future<Map<String, dynamic>> getProductById(String productId) async {
    try {
      log('Get product by id: $productId');

      final rawCatalogProducts = await _fetchCatalogProducts();
      for (final item in rawCatalogProducts) {
        if (item['_id']?.toString() == productId) {
          return {
            'response': true,
            'data': MarketplaceHelpers.mapItemToMarketplaceProduct(item),
            'message': 'Producto encontrado',
          };
        }
      }

      return {'response': false, 'message': 'Producto no encontrado'};
    } catch (e) {
      log('Error in getProductById: $e');
      return {
        'response': false,
        'message': 'Ha ocurrido un error, intente nuevamente',
        'data': [],
      };
    }
  }

  /// Valida si unas coordenadas están dentro de una zona de cobertura y retorna
  /// el costo de entrega (`value`) de la zona encontrada, o 0 si no aplica.
  static Future<Map<String, dynamic>> validateCoverageZone({
    required double lat,
    required double lng,
  }) async {
    log('Validate coverage zone API call lat=$lat lng=$lng');
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final Map<String, String> requestHeaders = {
        'Content-Type': 'application/json',
        if (token.isNotEmpty) 'Authorization': token,
      };

      final url = Uri.parse(MarketplaceConstants.coverageZoneValidateUrl);
      final body = jsonEncode({'lat': lat, 'lng': lng});
      log('url $url body $body');

      final response = await HttpUtils.post(
        url,
        headers: requestHeaders,
        body: body,
      );
      log(response.body);

      return json.decode(utf8.decode(response.bodyBytes));
    } catch (e) {
      log('Error in validateCoverageZone: $e');
      return HttpUtils.defaultResponse(e: e);
    }
  }

  /// Obtener una lista específica de productos por sus IDs.
  static Future<List<MarketplaceProduct>> getMarketplaceProductsByIds(
    List<String> productIds,
  ) async {
    try {
      final normalizedIds = productIds.where((id) => id.isNotEmpty).toSet();
      if (normalizedIds.isEmpty) {
        return [];
      }

      final idOrder = <String, int>{
        for (var index = 0; index < productIds.length; index++)
          productIds[index]: index,
      };

      final rawCatalogProducts = await _fetchCatalogProducts();
      final products = rawCatalogProducts
          .where((item) => normalizedIds.contains(item['_id']?.toString()))
          .map(MarketplaceHelpers.mapItemToMarketplaceProduct)
          .toList();

      products.sort(
        (a, b) => (idOrder[a.id] ?? productIds.length).compareTo(
          idOrder[b.id] ?? productIds.length,
        ),
      );

      return products;
    } catch (e) {
      log('Error in getMarketplaceProductsByIds: $e');
      return [];
    }
  }
}
