import 'dart:math' as math;
import 'cart_item.dart';
import 'marketplace_billing_data.dart';
import 'marketplace_delivery_data.dart';

class MarketplaceOrderPricing {
  const MarketplaceOrderPricing({
    required this.subtotalBeforeDiscount,
    required this.discountAmount,
    required this.subtotal,
    required this.iva,
    required this.total,
    required this.taxRate,
    required this.lineTotalsByItemId,
    this.deliveryFee = 0,
  });

  final double subtotalBeforeDiscount;
  final double discountAmount;
  final double subtotal;
  final double iva;
  final double total;
  final double taxRate;
  final Map<String, double> lineTotalsByItemId;
  final double deliveryFee;

  static MarketplaceOrderPricing fromCart({
    required List<CartItem> items,
    required double discountAmount,
    double taxRate = 0.15,
    double deliveryFee = 0,
  }) {
    final subtotalBeforeDiscount = _roundMoney(
      items.fold<double>(0, (sum, item) => sum + item.totalPrice),
    );
    final appliedDiscountAmount = _roundMoney(
      discountAmount.clamp(0, subtotalBeforeDiscount),
    );
    final lineTotalsByItemId = _buildDiscountedLineTotals(
      items: items,
      discountAmount: appliedDiscountAmount,
    );
    final subtotal = _roundMoney(
      lineTotalsByItemId.values.fold<double>(0, (sum, value) => sum + value),
    );
    final taxableSubtotal = _roundMoney(
      items.fold<double>(
        0,
        (sum, item) =>
            sum +
            (item.product.appliesIva
                ? (lineTotalsByItemId[item.id] ?? 0.0)
                : 0),
      ),
    );
    final iva = _roundMoney(taxableSubtotal * taxRate);
    final appliedDeliveryFee = _roundMoney(
      deliveryFee.clamp(0, double.infinity),
    );
    final total = _roundMoney(subtotal + iva + appliedDeliveryFee);

    return MarketplaceOrderPricing(
      subtotalBeforeDiscount: subtotalBeforeDiscount,
      discountAmount: appliedDiscountAmount,
      subtotal: subtotal,
      iva: iva,
      total: total,
      taxRate: taxRate,
      lineTotalsByItemId: lineTotalsByItemId,
      deliveryFee: appliedDeliveryFee,
    );
  }

  double lineTotalFor(String itemId) => lineTotalsByItemId[itemId] ?? 0.0;
}

class MarketplaceOrderLine {
  const MarketplaceOrderLine({
    required this.productId,
    required this.nameSnapshot,
    required this.imageSnapshot,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  final String productId;
  final String nameSnapshot;
  final String? imageSnapshot;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  Map<String, dynamic> toJson() {
    return {
      'kind': 'product',
      'product': productId,
      'product_variant_id': null,
      'size': null,
      'color': null,
      'gender': null,
      'name_snapshot': nameSnapshot,
      'image_snapshot': imageSnapshot,
      'quantity': quantity,
      'unit_price': _moneyString(unitPrice),
      'total_price': _moneyString(totalPrice),
    };
  }
}

class MarketplaceOrderDraft {
  const MarketplaceOrderDraft({
    required this.empresa,
    required this.persona,
    required this.logic,
    required this.gateway,
    required this.orderCode,
    required this.items,
    required this.pricing,
    required this.billingData,
    required this.deliveryData,
    this.discountCode,
    this.deliveryFee = 0,
  });

  final String empresa;
  final String persona;
  final String logic;
  final String gateway;
  final String orderCode;
  final List<MarketplaceOrderLine> items;
  final MarketplaceOrderPricing pricing;
  final MarketplaceBillingData billingData;
  final MarketplaceDeliveryData deliveryData;
  final Map<String, dynamic>? discountCode;
  final double deliveryFee;

  factory MarketplaceOrderDraft.fromCart({
    required List<CartItem> items,
    required String empresa,
    required String persona,
    required String logic,
    required String gateway,
    required MarketplaceBillingData billingData,
    required MarketplaceDeliveryData deliveryData,
    required double discountAmount,
    String? couponCode,
    String? orderCode,
    double taxRate = 0.15,
    double deliveryFee = 0,
  }) {
    final pricing = MarketplaceOrderPricing.fromCart(
      items: items,
      discountAmount: discountAmount,
      taxRate: taxRate,
      deliveryFee: deliveryFee,
    );
    final orderItems = _buildLines(items: items, pricing: pricing);

    return MarketplaceOrderDraft(
      empresa: empresa,
      persona: persona,
      logic: logic,
      gateway: gateway,
      orderCode: orderCode ?? generateOrderCode(),
      items: orderItems,
      pricing: pricing,
      billingData: billingData,
      deliveryData: deliveryData,
      deliveryFee: deliveryFee,
      discountCode: couponCode == null || pricing.discountAmount <= 0
          ? null
          : {
              'codigo': couponCode,
              'descuento': _roundMoney(pricing.discountAmount),
            },
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'empresa': empresa,
      'source_module': 'store',
      'persona': persona,
      if (gateway != "manual") 'gateway': gateway,
      'order_code': orderCode,
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': _moneyString(pricing.subtotal),
      'iva': _moneyString(pricing.iva),
      if (deliveryFee > 0) 'delivery_fee': _moneyString(deliveryFee),
      'total': _moneyString(pricing.total),
      if (discountCode != null) 'discountCode': discountCode,
      'payment_status': 'pending',
      if (gateway != "manual") 'payment_provider': gateway,
      'payment_reference': null,
      'delivery_status': 'pending',
      'billingData': billingData.toOrderJson(),
      'deliveryData': deliveryData.toJson(),
      'logic': logic,
    };
  }

  static String generateOrderCode() {
    final now = DateTime.now();
    final compactDate =
        '${now.year.toString().padLeft(4, '0')}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final compactTime =
        '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}${now.millisecond.toString().padLeft(3, '0')}';
    return 'ORD-$compactDate$compactTime';
  }
}

class MarketplaceOrderRecordItem {
  const MarketplaceOrderRecordItem({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.imageUrl,
    this.kind = 'product',
  });

  final String name;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final String? imageUrl;
  final String kind;

  factory MarketplaceOrderRecordItem.fromJson(Map<String, dynamic> json) {
    return MarketplaceOrderRecordItem(
      name:
          json['name_snapshot']?.toString() ??
          json['name']?.toString() ??
          'Producto',
      quantity: _parseOrderInt(json['quantity'], fallback: 1),
      unitPrice: _parseOrderMoney(json['unit_price']),
      totalPrice: _parseOrderMoney(json['total_price']),
      imageUrl: json['image_snapshot']?.toString() ?? json['image']?.toString(),
      kind: json['kind']?.toString() ?? 'product',
    );
  }
}

class MarketplaceOrderRecord {
  const MarketplaceOrderRecord({
    required this.id,
    required this.orderCode,
    required this.total,
    required this.subtotal,
    required this.iva,
    required this.paymentStatus,
    required this.deliveryStatus,
    required this.createdAt,
    required this.updatedAt,
    required this.persona,
    required this.logic,
    required this.sourceModule,
    required this.items,
    required this.raw,
  });

  final String id;
  final String orderCode;
  final double total;
  final double subtotal;
  final double iva;
  final String paymentStatus;
  final String deliveryStatus;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String persona;
  final String logic;
  final String sourceModule;
  final List<MarketplaceOrderRecordItem> items;
  final Map<String, dynamic> raw;

  int get itemCount => items.fold<int>(0, (sum, item) => sum + item.quantity);

  String get displayCode => orderCode.isNotEmpty ? orderCode : id;

  bool get isMarketplaceOrder {
    if (sourceModule.isEmpty) return true;
    return sourceModule.toLowerCase() == 'store';
  }

  String get itemsPreview {
    if (items.isEmpty) return 'Sin detalle de productos';
    return items.take(2).map((item) => item.name).join(', ');
  }

  factory MarketplaceOrderRecord.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items = rawItems is List
        ? rawItems
              .whereType<Map>()
              .map(
                (item) => MarketplaceOrderRecordItem.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList()
        : <MarketplaceOrderRecordItem>[];

    return MarketplaceOrderRecord(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      orderCode:
          json['order_code']?.toString() ?? json['code']?.toString() ?? '',
      total: _parseOrderMoney(json['total']),
      subtotal: _parseOrderMoney(json['subtotal']),
      iva: _parseOrderMoney(json['iva']),
      paymentStatus: json['payment_status']?.toString() ?? 'pending',
      deliveryStatus: json['delivery_status']?.toString() ?? 'pending',
      createdAt: _parseOrderDate(json['createdAt'] ?? json['created_at']),
      updatedAt: _parseOrderDate(json['updatedAt'] ?? json['updated_at']),
      persona: json['persona']?.toString() ?? '',
      logic: json['logic']?.toString() ?? 'a',
      sourceModule: json['source_module']?.toString() ?? '',
      items: items,
      raw: Map<String, dynamic>.from(json),
    );
  }
}

List<MarketplaceOrderLine> _buildLines({
  required List<CartItem> items,
  required MarketplaceOrderPricing pricing,
}) {
  return items.map((item) {
    final totalPrice = pricing.lineTotalFor(item.id);
    final unitPrice = item.quantity > 0
        ? _roundMoney(totalPrice / item.quantity)
        : 0.0;

    return MarketplaceOrderLine(
      productId: item.product.id,
      nameSnapshot: item.product.name,
      imageSnapshot: item.product.imageUrl,
      quantity: item.quantity,
      unitPrice: unitPrice,
      totalPrice: totalPrice,
    );
  }).toList();
}

double _roundMoney(double value) => (value * 100).roundToDouble() / 100;

Map<String, double> _buildDiscountedLineTotals({
  required List<CartItem> items,
  required double discountAmount,
}) {
  final totals = <String, double>{};
  if (items.isEmpty) return totals;

  final subtotalBeforeDiscount = _roundMoney(
    items.fold<double>(0, (sum, item) => sum + item.totalPrice),
  );
  var remainingDiscount = _roundMoney(
    discountAmount.clamp(0, subtotalBeforeDiscount),
  );
  var remainingSubtotal = subtotalBeforeDiscount;

  for (var i = 0; i < items.length; i++) {
    final item = items[i];
    final lineTotal = _roundMoney(item.totalPrice);
    final isLast = i == items.length - 1;

    double lineDiscount;
    if (isLast) {
      lineDiscount = math.min(lineTotal, remainingDiscount);
    } else if (remainingDiscount <= 0 || remainingSubtotal <= 0) {
      lineDiscount = 0.0;
    } else {
      lineDiscount = _roundMoney(
        remainingDiscount * (lineTotal / remainingSubtotal),
      );
      lineDiscount = math.min(lineTotal, lineDiscount);
    }

    final discountedTotal = _roundMoney(
      math.max(0.0, lineTotal - lineDiscount),
    );
    totals[item.id] = discountedTotal;

    remainingDiscount = _roundMoney(
      math.max(0.0, remainingDiscount - lineDiscount),
    );
    remainingSubtotal = _roundMoney(
      math.max(0.0, remainingSubtotal - lineTotal),
    );
  }

  return totals;
}

String _moneyString(double value) => _roundMoney(value).toStringAsFixed(2);

double _parseOrderMoney(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  if (value is Map && value.containsKey('\$numberDecimal')) {
    return double.tryParse(value['\$numberDecimal'].toString()) ?? 0;
  }
  return double.tryParse(value.toString()) ?? 0;
}

int _parseOrderInt(dynamic value, {int fallback = 0}) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is double) return value.toInt();
  return int.tryParse(value.toString()) ?? fallback;
}

DateTime? _parseOrderDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }
  return null;
}
