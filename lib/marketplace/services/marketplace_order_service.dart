import 'dart:convert';
import 'dart:developer';
import '../data/api/marketplace_api_service.dart';
import '../utils/http_utils.dart';
import '../data/api/constants.dart';
import '../domain/models/cart_item.dart';
import '../domain/models/marketplace_billing_data.dart';
import '../domain/models/marketplace_delivery_data.dart';
import '../domain/models/marketplace_order.dart';
import '../presentation/providers/cart_provider.dart';
import '../domain/models/user.dart';

import 'package:shared_preferences/shared_preferences.dart';

class MarketplaceOrderService {
  static const double ivaRate = 0.15;

  static Future<Map<String, dynamic>> getOrders({
    required String persona,
    String logic = 'a',
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept-Language': 'es',
        if (token.isNotEmpty) 'Authorization': token,
      };

      final body = jsonEncode({'persona': persona, 'logic': logic});
      log(
        'Marketplace orders filter request'
        ' urls: ${[_orderFilterUrl(), MarketplaceConstants.orderFilterUrl]}'
        ' headers: ${_sanitizeHeaders(headers)}'
        ' body: $body',
      );

      final response = await _postOrdersFilter(headers: headers, body: body);
      final decoded = _decodeResponse(response);
      final orders = _extractOrders(decoded);

      return {
        ...decoded,
        'response': decoded['response'] ?? response.statusCode == 200,
        'data': orders,
      };
    } catch (e) {
      log('Error getting marketplace orders: $e');
      return HttpUtils.defaultResponse(e: e);
    }
  }

  static Future<Map<String, dynamic>> createOrder({
    required User user,
    required CartState cart,
    required MarketplaceBillingData billingData,
    required MarketplaceDeliveryData deliveryData,
    required String gateway,
    double deliveryFee = 0,
  }) async {
    try {
      if (cart.items.isEmpty) {
        return HttpUtils.defaultResponse(message: 'Tu carrito está vacío');
      }

      if (!cart.isCheckoutValid) {
        return HttpUtils.defaultResponse(
          message: 'Hay productos sin stock suficiente en el carrito',
        );
      }

      final refreshedItems = await _refreshCartItems(cart.items);
      final empresa = _resolveEmpresa(user: user, items: refreshedItems);
      if (empresa == null || empresa.isEmpty) {
        return HttpUtils.defaultResponse(
          message:
              'No se pudo determinar la empresa de la orden. Recarga los productos e inténtalo nuevamente.',
        );
      }

      final mixedCompany = _hasMixedCompany(
        items: refreshedItems,
        empresa: empresa,
      );
      if (mixedCompany) {
        return HttpUtils.defaultResponse(
          message:
              'Por ahora solo se permiten productos de una misma empresa por orden.',
        );
      }

      final draft = MarketplaceOrderDraft.fromCart(
        items: refreshedItems,
        empresa: empresa,
        persona: user.id,
        logic: 'i',
        gateway: gateway,
        billingData: billingData,
        deliveryData: deliveryData,
        discountAmount: cart.discountAmount,
        couponCode: cart.couponCode,
        taxRate: ivaRate,
        deliveryFee: deliveryFee,
      );

      final hasInvalidProductId = draft.items.any(
        (item) => item.productId.trim().isEmpty,
      );
      if (hasInvalidProductId) {
        return HttpUtils.defaultResponse(
          message:
              'Hay productos inválidos en el carrito. Elimina y vuelve a agregar los productos antes de continuar.',
        );
      }

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept-Language': 'es',
        if (token.isNotEmpty) 'Authorization': token,
      };

      final body = jsonEncode(draft.toJson());
      log(
        'Marketplace create order request'
        ' urls: ${[MarketplaceConstants.orderUrl]}'
        ' headers: ${_sanitizeHeaders(headers)}'
        ' body: $body',
      );

      final response = await _postOrder(headers: headers, body: body);
      final decoded = _decodeResponse(response);

      if (decoded['response'] == null) {
        decoded['response'] =
            response.statusCode >= 200 && response.statusCode < 300;
      }
      if (decoded['orderDraft'] == null) {
        decoded['orderDraft'] = draft.toJson();
      }
      if ((decoded['response'] ?? false) &&
          decoded['data'] is! Map<String, dynamic>) {
        decoded['data'] = {
          'order_code': draft.orderCode,
          'payload': draft.toJson(),
        };
      }

      return decoded;
    } catch (e) {
      log('Error creating marketplace order: $e');
      return HttpUtils.defaultResponse(e: e);
    }
  }

  static Future<List<CartItem>> _refreshCartItems(List<CartItem> items) async {
    final refreshedItems = <CartItem>[];

    for (final item in items) {
      final response = await MarketplaceApiService.getProductById(
        item.product.id,
      );
      if (response['response'] == true && response['data'] != null) {
        refreshedItems.add(item.copyWith(product: response['data']));
      } else {
        refreshedItems.add(item);
      }
    }

    return refreshedItems;
  }

  static String? _resolveEmpresa({
    required User user,
    required List<CartItem> items,
  }) {
    if (user.empresa != null && user.empresa!.isNotEmpty) {
      return user.empresa;
    }

    for (final item in items) {
      final companyId = item.product.companyId;
      if (companyId != null && companyId.isNotEmpty) {
        return companyId;
      }
    }

    return null;
  }

  static bool _hasMixedCompany({
    required List<CartItem> items,
    required String empresa,
  }) {
    for (final item in items) {
      final companyId = item.product.companyId;
      if (companyId != null && companyId.isNotEmpty && companyId != empresa) {
        return true;
      }
    }
    return false;
  }

  static Future<dynamic> _postOrder({
    required Map<String, String> headers,
    required String body,
  }) async {
    final candidateUrls = [Uri.parse(MarketplaceConstants.orderUrl)];

    dynamic lastResponse;

    for (final url in candidateUrls) {
      log('Marketplace create order trying endpoint: $url');
      final response = await HttpUtils.post(url, headers: headers, body: body);
      lastResponse = response;
      log(
        'Marketplace create order response'
        ' endpoint: $url'
        ' status: ${response.statusCode}'
        ' body: ${utf8.decode(response.bodyBytes)}',
      );

      if (response.statusCode != 404) {
        return response;
      }
    }

    return lastResponse;
  }

  static Future<dynamic> _postOrdersFilter({
    required Map<String, String> headers,
    required String body,
  }) async {
    final candidateUrls = [
      Uri.parse(_orderFilterUrl()),
      Uri.parse(MarketplaceConstants.orderFilterUrl),
    ];

    dynamic lastResponse;

    for (final url in candidateUrls) {
      log('Marketplace orders filter trying endpoint: $url');
      final response = await HttpUtils.post(url, headers: headers, body: body);
      lastResponse = response;
      log(
        'Marketplace orders filter response'
        ' endpoint: $url'
        ' status: ${response.statusCode}'
        ' body: ${utf8.decode(response.bodyBytes)}',
      );

      if (response.statusCode != 404) {
        return response;
      }
    }

    return lastResponse;
  }

  static Map<String, dynamic> _decodeResponse(dynamic response) {
    try {
      if (response == null) {
        return HttpUtils.defaultResponse(
          message: 'No se recibió respuesta del servidor',
        );
      }

      final decoded = json.decode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic>) {
        return {...decoded, 'statusCode': response.statusCode};
      }

      return {
        'response': response.statusCode >= 200 && response.statusCode < 300,
        'data': decoded,
        'statusCode': response.statusCode,
      };
    } catch (_) {
      return {
        'response': response.statusCode >= 200 && response.statusCode < 300,
        'statusCode': response.statusCode,
        'message': response.statusCode >= 200 && response.statusCode < 300
            ? 'Orden creada correctamente'
            : 'No se pudo procesar la respuesta del servidor (${response.statusCode})',
      };
    }
  }

  static Map<String, String> _sanitizeHeaders(Map<String, String> headers) {
    return {
      for (final entry in headers.entries)
        entry.key: entry.key.toLowerCase() == 'authorization'
            ? _maskToken(entry.value)
            : entry.value,
    };
  }

  static String _maskToken(String token) {
    if (token.isEmpty) return '<empty>';
    if (token.length <= 8) return '***';
    return '${token.substring(0, 4)}...${token.substring(token.length - 4)}';
  }

  static String _orderFilterUrl() => '${MarketplaceConstants.orderUrl}/filter';

  static List<MarketplaceOrderRecord> _extractOrders(
    Map<String, dynamic> decoded,
  ) {
    final rawData = decoded['data'];
    final rawOrders = switch (rawData) {
      List<dynamic> list => list,
      Map<String, dynamic> map when map['items'] is List<dynamic> =>
        map['items'] as List<dynamic>,
      Map<String, dynamic> map when map['docs'] is List<dynamic> =>
        map['docs'] as List<dynamic>,
      Map<String, dynamic> map when map['orders'] is List<dynamic> =>
        map['orders'] as List<dynamic>,
      _ => const <dynamic>[],
    };

    final orders =
        rawOrders
            .whereType<Map>()
            .map(
              (order) => MarketplaceOrderRecord.fromJson(
                Map<String, dynamic>.from(order),
              ),
            )
            .where((order) => order.isMarketplaceOrder)
            .toList()
          ..sort((a, b) {
            final left = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final right = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return right.compareTo(left);
          });

    return orders;
  }
}
