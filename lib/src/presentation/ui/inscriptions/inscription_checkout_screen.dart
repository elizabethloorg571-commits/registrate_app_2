import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:running_app/marketplace/domain/models/cart_item.dart';
import 'package:running_app/marketplace/domain/models/marketplace_order.dart';
import 'package:running_app/app_localizations_context.dart';
import 'package:running_app/extensions/num_extensions.dart';
import 'package:running_app/services/shared_service.dart';
import 'package:running_app/src/data/api/inscriptions/inscriptions_api_service.dart';
import 'package:running_app/src/domain/models/running_competition.dart';
import 'package:running_app/src/presentation/providers/inscriptions/inscriptions_provider.dart';
import 'package:running_app/src/presentation/providers/profile/profile_provider.dart';
import 'package:running_app/src/presentation/ui/inscriptions/datafast/datafast_payment_screen.dart';
import 'package:running_app/src/presentation/ui/inscriptions/deUna/deuna_payment_screen.dart';
import 'package:running_app/src/presentation/widgets/competition_card.dart';
import 'package:running_app/src/presentation/widgets/global_widgets.dart';
import 'package:running_app/config/theme/app_theme.dart';
import 'package:running_app/config/theme/fonts.dart';
import 'package:running_app/src/utils/navigator_key.dart';
import 'package:running_app/src/utils/responsive.dart';
import 'package:running_app/src/utils/url_launcher_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:running_app/src/presentation/ui/inscriptions/bank_transfer_screen.dart';
import 'package:running_app/src/domain/models/bank_transfer_info.dart';
import '../auth/views/login_view.dart';
import 'inscription_detail_screen.dart';
import 'widgets/confetti_widget.dart';

class InscriptionCheckoutScreen extends ConsumerStatefulWidget {
  const InscriptionCheckoutScreen({
    super.key,
    required this.competition,
    required this.participants,
    this.extraProducts = const [],
    required this.billingData,
  });

  final RunningCompetition competition;
  final List<Map<String, dynamic>> participants;
  final List<CartItem> extraProducts;
  final BillingData billingData;

  @override
  InscriptionCheckoutScreenState createState() =>
      InscriptionCheckoutScreenState();
}

class InscriptionCheckoutScreenState
    extends ConsumerState<InscriptionCheckoutScreen> {
  final TextEditingController _couponController = TextEditingController();
  String? _selectedPaymentMethod;
  bool _acceptedTerms = false;
  bool _isApplyingCoupon = false;
  _AppliedDiscountCode? _appliedDiscountCode;
  bool _success = false;
  bool _isProcessingPayment = false;
  Map<String, dynamic>? _inscriptionResult;

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  double _calculateParticipantsSubtotal() {
    double subtotal = 0.0;
    for (var participant in widget.participants) {
      final basePrice = participant['base_price'] as double;
      final tshirtPrice = (participant['tshirt_price'] ?? 0.0) as double;
      subtotal += basePrice + tshirtPrice;
    }
    return subtotal;
  }

  double _calculateProductsSubtotal() {
    return widget.extraProducts.fold<double>(
      0.0,
      (sum, item) => sum + item.totalPrice,
    );
  }

  double _calculateSubtotal() {
    return _calculateParticipantsSubtotal() + _calculateProductsSubtotal();
  }

  String? get _appliedCoupon => _appliedDiscountCode?.codigo;

  double get _discount {
    final rawDiscount = _appliedDiscountCode?.descuento ?? 0.0;
    final sanitizedDiscount = math.max(0.0, rawDiscount);
    return math.min(sanitizedDiscount, _calculateSubtotal());
  }

  double _calculateParticipantsDiscountPool() {
    final totalSubtotal = _calculateSubtotal();
    final participantsSubtotal = _calculateParticipantsSubtotal();
    if (totalSubtotal <= 0 || participantsSubtotal <= 0 || _discount <= 0) {
      return 0.0;
    }

    return math.min(
      participantsSubtotal,
      _discount * (participantsSubtotal / totalSubtotal),
    );
  }

  double _calculateProductsDiscountPool() {
    final productsSubtotal = _calculateProductsSubtotal();
    if (productsSubtotal <= 0 || _discount <= 0) {
      return 0.0;
    }

    return math.min(
      productsSubtotal,
      math.max(0.0, _discount - _calculateParticipantsDiscountPool()),
    );
  }

  double _calculateParticipantsDiscountedSubtotal() {
    return math.max(
      0.0,
      _calculateParticipantsSubtotal() - _calculateParticipantsDiscountPool(),
    );
  }

  MarketplaceOrderPricing _calculateProductsPricing() {
    return MarketplaceOrderPricing.fromCart(
      items: widget.extraProducts,
      discountAmount: _calculateProductsDiscountPool(),
      taxRate: widget.competition.isApplyInvoice ?? false ? 0.15 : 0.0,
    );
  }

  double _calculateDiscountedSubtotal() {
    return _calculateParticipantsDiscountedSubtotal() +
        _calculateProductsPricing().subtotal;
  }

  double _calculateParticipantsIVA() {
    final isApplyInvoice = widget.competition.isApplyInvoice ?? false;
    return isApplyInvoice
        ? _calculateParticipantsDiscountedSubtotal() * 0.15
        : 0.0;
  }

  double _calculateIVA() {
    return _calculateParticipantsIVA() + _calculateProductsPricing().iva;
  }

  double _calculateTotal() {
    return _calculateDiscountedSubtotal() + _calculateIVA();
  }

  double _parseAmount(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is Map && value.containsKey('\$numberDecimal')) {
      return double.tryParse(value['\$numberDecimal'].toString()) ?? 0.0;
    }
    return double.tryParse(value.toString()) ?? 0.0;
  }

  bool _isSuccessfulResponse(Map<String, dynamic> result) {
    final status = result['response'] ?? result['status'];

    if (status is bool) {
      return status;
    }

    if (status is String) {
      final normalized = status.trim().toLowerCase();
      return normalized == 'success' || normalized == 'ok';
    }

    return false;
  }

  _AppliedDiscountCode? _parseAppliedDiscountCode(
    Map<String, dynamic> result,
    String fallbackCode,
  ) {
    final payload = result['data'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(result['data'] as Map<String, dynamic>)
        : result;

    final codigo = (payload['codigo'] ?? payload['code'] ?? fallbackCode)
        .toString()
        .trim();
    final descuento = _parseAmount(
      payload['descuento'] ?? payload['discount'] ?? payload['discount_value'],
    );

    if (codigo.isEmpty || descuento <= 0) {
      return null;
    }

    return _AppliedDiscountCode(codigo: codigo, descuento: descuento);
  }

  Future<void> _applyCoupon() async {
    final code = _couponController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _isApplyingCoupon = true;
    });

    final result = await InscriptionsApiService.validateDiscountCode(
      code,
      _calculateSubtotal(),
    );

    if (!mounted) return;

    final appliedDiscount = _parseAppliedDiscountCode(result, code);
    final isSuccess = _isSuccessfulResponse(result) || appliedDiscount != null;

    setState(() {
      _isApplyingCoupon = false;
      if (isSuccess && appliedDiscount != null) {
        _appliedDiscountCode = appliedDiscount;
      }
    });

    if (isSuccess && appliedDiscount != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Cupón aplicado correctamente!'),
          backgroundColor: Colors.green,
        ),
      );
      return;
    }

    final message = result['message'] ?? result['error'] ?? 'Cupón inválido';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _processPayment() async {
    if (_selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecciona un método de pago'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes aceptar los términos y condiciones'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isProcessingPayment = true;
    });

    _addParticipantInscriptionFinalValues();
    final productsPayload = _buildProductsPayload();

    final discountedSubtotal = _calculateDiscountedSubtotal();
    final iva = _calculateIVA();

    final inscriptionData = {
      'empresa': widget.competition.empresa.id,
      'carrera': widget.competition.id,
      'buyer': SharedService.uuid,
      if (_selectedPaymentMethod != "manual") 'gateway': _selectedPaymentMethod,
      'participantes': widget.participants,
      'products': productsPayload,
      'items': productsPayload,
      "logic": "i",
      'billingData': widget.billingData.toJson(),
      'total': _calculateTotal(),
      'subtotal': discountedSubtotal,
      'iva': iva,
      'finalDescuento': _discount,
      'discountCode': _appliedDiscountCode?.toJson(),
    };

    final result = await InscriptionsApiService.insertInscription(
      inscriptionData,
    );

    setState(() {
      _isProcessingPayment = false;
    });

    if (result["response"] ?? result["status"] ?? false) {
      final data = Map<String, dynamic>.from(result['data'] ?? {});
      final inscriptionId = data['_id'] ?? data['orderId'];

      if (inscriptionId == null || inscriptionId.toString().isEmpty) {
        ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
          SnackBar(
            content: Text(
              navigatorKey.currentContext!.l1on.inscriptionIdNotReceived,
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      inscriptionData['_id'] = inscriptionId;
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      _inscriptionResult = result;
      // ? TESTING
      // setState(() {
      //   _success = true;
      // });
      // return;
      switch (_selectedPaymentMethod) {
        case 'datafast':
          await _goToDatafastPayment(inscriptionData, token);
          break;

        case 'deuna':
          await _goToDeUnaPayment(inscriptionData);
          break;

        case 'manual':
          await _goToBankTransferPayment(inscriptionData);
          break;

        default:
          break;
      }
    } else {
      final String message =
          result["message"] ?? result["error"] ?? "Error desconocido";
      ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _goToBankTransferPayment(
    Map<String, dynamic> inscriptionData,
  ) async {
    final comp = widget.competition;
    final bankInfo = BankTransferInfo(
      banckName: comp.banckName ?? comp.empresa.banckName ?? '',
      accountNumber: comp.accountNumber ?? comp.empresa.accountNumber ?? '',
      accountType: comp.accountType ?? comp.empresa.accountType ?? '',
      accountHoldersName:
          comp.accountHoldersName ?? comp.empresa.accountHoldersName ?? '',
      documentNumber: comp.documentNumber ?? comp.empresa.documentNumber ?? '',
    );

    final inscriptionId = inscriptionData['_id']?.toString() ?? '';
    final navigatorState = Navigator.of(context);
    final result = await navigatorState.push(
      MaterialPageRoute(
        builder: (context) => BankTransferPaymentScreen(
          bankInfo: bankInfo,
          total: (inscriptionData['total'] as num).toDouble(),
          orderId: inscriptionId,
        ),
      ),
    );

    if (result != null && (result['response'] ?? false)) {
      setState(() {
        _success = true;
      });
    }
  }

  Future<void> _goToDatafastPayment(
    Map<String, dynamic> inscriptionData,
    String token,
  ) async {
    final inscriptionId = inscriptionData['_id'];
    if (inscriptionId == null) {
      ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
        const SnackBar(
          content: Text('Error: ID de inscripción no disponible'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final navigatorState = Navigator.of(context);
    final result = await navigatorState.push(
      MaterialPageRoute(
        builder: (context) => DatafastPaymentScreen(
          serviceLabel: 'id_order',
          total: double.parse(inscriptionData['total'].toString()).toMoney(),
          serviceId: inscriptionId.toString(),
          token: token,
        ),
      ),
    );
    if (result != null) {
      if (result['response'] ?? false) {
        setState(() {
          _success = true;
        });
      } else {
        final String error =
            result['message'] ?? result['error'] ?? 'Ha ocurrido un error';
        final Map<String, dynamic> datafastData = Map<String, dynamic>.from(
          result['data'] ?? {},
        );
        final Map<String, dynamic> datafastResult = Map<String, dynamic>.from(
          datafastData['result'] ??
              {'description': 'Error desconocido, por favor intente más tarde'},
        );
        final String description = datafastResult['description']!;

        await GlobalWidgets.showBasicAlert(error, description, "Aceptar");
      }
    } else {
      ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.orange,
          content: Text(
            "El pago ha sido cancelado. Por favor, intente nuevamente.",
            style: nunitoSansStyle(400, 14, color: Colors.white),
          ),
        ),
      );
    }
  }

  Future<void> _goToDeUnaPayment(Map<String, dynamic> inscriptionData) async {
    final inscriptionId = inscriptionData['_id'];
    if (inscriptionId == null) {
      ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
        const SnackBar(
          content: Text('Error: ID de inscripción no disponible'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final navigatorState = Navigator.of(context);
    final result = await InscriptionsApiService.requestDeUnaPayment(
      'id_order',
      inscriptionId.toString(),
    );
    if (result['response'] ?? false) {
      final Map<String, dynamic> data = Map<String, dynamic>.from(
        result['data'] ?? {},
      );

      final deUnaResult = await navigatorState.push(
        MaterialPageRoute(
          builder: (context) => DeUnaPaymentScreen(
            data: data,
            total: double.parse(inscriptionData['total'].toString()).toMoney(),
          ),
        ),
      );
      if (deUnaResult != null) {
        final String status = deUnaResult['status'] ?? 'unknown';
        if (status == 'APPROVED') {
          setState(() {
            _success = true;
          });
        } else {
          await GlobalWidgets.showBasicAlert(
            'Estado: $status',
            'El pago aún no ha sido verificado',
            "Aceptar",
          );
        }
      } else {
        ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.orange,
            content: Text(
              "El pago ha sido cancelado. Por favor, intente nuevamente.",
              style: nunitoSansStyle(400, 14, color: Colors.white),
            ),
          ),
        );
      }
    } else {
      final String error =
          result['message'] ??
          result['error'] ??
          'error desconocido, por favor intente más tarde';

      await GlobalWidgets.showBasicAlert(
        'Ha ocurrido un error al solicitar el pago con DeUna',
        error,
        "Aceptar",
      );
    }
  }

  List<Map<String, dynamic>> _buildProductsPayload() {
    final productsPricing = _calculateProductsPricing();

    return widget.extraProducts.map((item) {
      final lineTotal = productsPricing.lineTotalFor(item.id);
      final unitPrice = item.quantity > 0 ? (lineTotal / item.quantity) : 0.0;

      return {
        'kind': 'product',
        'product': item.product.id,
        'product_variant_id': null,
        'size': null,
        'color': null,
        'gender': null,
        'name_snapshot': item.product.name,
        'image_snapshot': item.product.imageUrl,
        'quantity': item.quantity,
        'unit_price': unitPrice.toStringAsFixed(2),
        'total_price': lineTotal.toStringAsFixed(2),
      };
    }).toList();
  }

  TapGestureRecognizer get tapTermsRecognizer => TapGestureRecognizer()
    ..onTap = () {
      try {
        UrlLauncherUtils.launch(
          "https://registrate.magdata.com.ec/terminosycondiciones",
        );
      } catch (e) {
        GlobalWidgets.showBasicAlert(
          "Error",
          "No se pudo abrir el enlace de términos y condiciones. Por favor, inténtalo más tarde",
          "Aceptar",
        );
      }
    };

  TapGestureRecognizer get tapPoliticsRecognizer => TapGestureRecognizer()
    ..onTap = () {
      try {
        UrlLauncherUtils.launch(
          "https://registrate.magdata.com.ec/politicasdeprotecciondedatos",
        );
      } catch (e) {
        GlobalWidgets.showBasicAlert(
          "Error",
          "No se pudo abrir el enlace de términos y condiciones. Por favor, inténtalo más tarde",
          "Aceptar",
        );
      }
    };

  @override
  Widget build(BuildContext context) {
    final productsPricing = _calculateProductsPricing();
    final discountedSubtotal = _calculateDiscountedSubtotal();
    final iva = _calculateIVA();
    final total = _calculateTotal();
    final userProvider = ref.watch(userProfileProvider);
    final responsive = Responsive(context);

    return userProvider.when(
      skipLoadingOnRefresh: false,
      data: (user) {
        SharedService.email = user.email;
        SharedService.photoUrl = user.foto;
        SharedService.uuid = user.id;
        SharedService.nombres = user.nombres;
        SharedService.apellidos = user.apellidos;
        SharedService.userUpdatedAt = user.updatedAt.toString();
        return PopScope(
          canPop: !_success,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop && _success) {
              // No permitir retroceso cuando está en pantalla de éxito
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Usa los botones para navegar'),
                  duration: Duration(seconds: 1),
                ),
              );
            }
          },
          child: Scaffold(
            backgroundColor: AppTheme.inscriptionsBackground,
            appBar: !_success
                ? AppBar(
                    elevation: 0,
                    leading: IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color: AppTheme.lightModeBlack,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    title: Text(
                      '3. Resumen de compra',
                      style: nunitoSansStyle(
                        600,
                        18,
                        color: AppTheme.lightModeBlack,
                      ),
                    ),
                  )
                : null,
            body: Column(
              children: !_success
                  ? [
                      // Progress bar
                      Container(
                        width: double.infinity,
                        height: 4,
                        color: AppTheme.grey.withValues(alpha: 0.2),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: 1.0,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppTheme.primary, AppTheme.secondary],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Competition card
                              SizedBox(
                                height: 200,
                                child: CompetitionCard(
                                  competition: widget.competition,
                                  responsive: responsive,
                                  detailsOnPressedAvailable: false,
                                ),
                              ),
                              const SizedBox(height: 24),

                              if (widget.competition.isApplyCodeDiscount ??
                                  false) ...[
                                // Detalle de compra
                                Text(
                                  'Detalle de compra',
                                  style: nunitoSansTitleSmallStyle(
                                    context,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _couponController,
                                        enabled: _appliedDiscountCode == null,
                                        style: nunitoSansStyle(
                                          400,
                                          14,
                                          color: AppTheme.lightModeBlack,
                                        ),
                                        decoration: InputDecoration(
                                          hintText: 'Código de descuento',
                                          hintStyle: nunitoSansBodyMediumStyle(
                                            context,
                                            color: AppTheme.grey,
                                          ),
                                          filled: true,
                                          fillColor: Colors.white,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 16,
                                              ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            borderSide: BorderSide.none,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    InkWell(
                                      onTap:
                                          _appliedDiscountCode == null &&
                                              !_isApplyingCoupon
                                          ? _applyCoupon
                                          : null,
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 16,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              AppTheme.primary,
                                              AppTheme.secondary,
                                            ],
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: _isApplyingCoupon
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                        Color
                                                      >(Colors.white),
                                                ),
                                              )
                                            : Text(
                                                'Aplicar',
                                                style: nunitoSansStyle(
                                                  600,
                                                  14,
                                                  color: Colors.white,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                              ],

                              // Resumen de compra
                              Text(
                                'Resumen de compra',
                                style: nunitoSansTitleSmallStyle(
                                  context,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 16),

                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    // Lista de participantes
                                    ...widget.participants.map((participant) {
                                      final basePrice =
                                          participant['base_price'] as double;
                                      final tshirtPrice =
                                          (participant['tshirt_price'] ?? 0.0)
                                              as double;
                                      final totalPrice =
                                          basePrice + tshirtPrice;

                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 4,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                '${participant['category']} ${participant['distance_km']}',
                                                style: nunitoSansBodySmallStyle(
                                                  context,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              '\$${totalPrice.toStringAsFixed(2)}',
                                              style: nunitoSansBodySmallStyle(
                                                context,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                    ...widget.extraProducts.map((item) {
                                      final totalPrice = productsPricing
                                          .lineTotalFor(item.id);

                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 4,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                '${item.product.name} x${item.quantity}',
                                                style: nunitoSansBodySmallStyle(
                                                  context,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              '\$${totalPrice.toStringAsFixed(2)}',
                                              style: nunitoSansBodySmallStyle(
                                                context,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),

                                    // Cupón aplicado
                                    if (_appliedCoupon != null) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Cupón $_appliedCoupon',
                                            style: nunitoSansBodySmallStyle(
                                              context,
                                              color: Colors.green,
                                            ),
                                          ),
                                          Text(
                                            '-\$${_discount.toStringAsFixed(2)}',
                                            style: nunitoSansBodySmallStyle(
                                              context,
                                              color: Colors.green,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],

                                    const SizedBox(height: 8),

                                    // Subtotal
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Subtotal',
                                          style: nunitoSansBodySmallStyle(
                                            context,
                                          ),
                                        ),
                                        Text(
                                          '\$${discountedSubtotal.toStringAsFixed(2)}',
                                          style: nunitoSansBodySmallStyle(
                                            context,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),

                                    // IVA - solo mostrar si isApplyInvoice es true
                                    if (widget.competition.isApplyInvoice ??
                                        false) ...[
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'IVA 15%',
                                            style: nunitoSansBodySmallStyle(
                                              context,
                                            ),
                                          ),
                                          Text(
                                            '\$${iva.toStringAsFixed(2)}',
                                            style: nunitoSansBodySmallStyle(
                                              context,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                    ],

                                    const SizedBox(height: 8),

                                    // Total
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Total',
                                          style: nunitoSansBodySmallStyle(
                                            context,
                                          ),
                                        ),
                                        Text(
                                          '\$${total.toStringAsFixed(2)}',
                                          style: nunitoSansBodySmallStyle(
                                            context,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Método de pago
                              Text(
                                'Método de pago',
                                style: nunitoSansTitleSmallStyle(
                                  context,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Tarjeta de crédito o débito
                              if (widget.competition.isApplyTC ?? true) ...[
                                _buildPaymentMethod(
                                  icon: Icon(
                                    Icons.credit_card,
                                    color: AppTheme.lightModeBlack,
                                  ),
                                  title: 'Tarjeta de crédito o débito',
                                  subtitle: 'Todas las entidades bancarias',
                                  value: 'datafast',
                                ),
                                const SizedBox(height: 12),
                              ],

                              // DeUna
                              if (widget.competition.isApplyDeuna ?? true) ...[
                                _buildPaymentMethod(
                                  icon: Image.asset(
                                    'assets/images/deuna.png',
                                    width: 20,
                                    height: 20,
                                  ),
                                  title: 'DeUna',
                                  subtitle: 'App de pagos',
                                  value: 'deuna',
                                ),
                                const SizedBox(height: 12),
                              ],

                              // Transferencia bancaria
                              if (widget.competition.isApplyManual ??
                                  false) ...[
                                _buildPaymentMethod(
                                  icon: Icon(
                                    Icons.account_balance_outlined,
                                    color: AppTheme.lightModeBlack,
                                  ),
                                  title: 'Transferencia bancaria',
                                  subtitle: 'Sube tu comprobante de pago',
                                  value: 'manual',
                                ),
                                const SizedBox(height: 12),
                              ],

                              const SizedBox(height: 4),
                            ],
                          ),
                        ),
                      ),
                    ]
                  : [
                      // Success screen with confetti animation
                      Expanded(
                        child: Stack(
                          children: [
                            // Background confetti
                            const Positioned.fill(child: ConfettiWidget()),
                            // Success content
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(40),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Animated check icon
                                    TweenAnimationBuilder<double>(
                                      duration: const Duration(
                                        milliseconds: 800,
                                      ),
                                      tween: Tween(begin: 0.0, end: 1.0),
                                      curve: Curves.elasticOut,
                                      builder: (context, value, child) {
                                        return Transform.scale(
                                          scale: value,
                                          child: Container(
                                            width: 120,
                                            height: 120,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF14B8A6),
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: const Color(
                                                    0xFF14B8A6,
                                                  ).withValues(alpha: 0.3),
                                                  blurRadius: 20,
                                                  spreadRadius: 5,
                                                ),
                                              ],
                                            ),
                                            child: const Icon(
                                              Icons.check,
                                              color: Colors.white,
                                              size: 70,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 32),
                                    // Success title with fade animation
                                    TweenAnimationBuilder<double>(
                                      duration: const Duration(
                                        milliseconds: 600,
                                      ),
                                      tween: Tween(begin: 0.0, end: 1.0),
                                      curve: Curves.easeOut,
                                      builder: (context, value, child) {
                                        return Opacity(
                                          opacity: value,
                                          child: Transform.translate(
                                            offset: Offset(0, 20 * (1 - value)),
                                            child: child,
                                          ),
                                        );
                                      },
                                      child: Text(
                                        'Inscripción confirmada',
                                        style: nunitoSansStyle(
                                          700,
                                          28,
                                          color: const Color(0xFF14B8A6),
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    // Success message
                                    TweenAnimationBuilder<double>(
                                      duration: const Duration(
                                        milliseconds: 800,
                                      ),
                                      tween: Tween(begin: 0.0, end: 1.0),
                                      curve: Curves.easeOut,
                                      builder: (context, value, child) {
                                        return Opacity(
                                          opacity: value,
                                          child: Transform.translate(
                                            offset: Offset(0, 20 * (1 - value)),
                                            child: child,
                                          ),
                                        );
                                      },
                                      child: Text(
                                        'Gracias por unirte a esta aventura.\nNos vemos en la línea de partida. ¡A correr!',
                                        style: nunitoSansStyle(
                                          400,
                                          16,
                                          color: AppTheme.grey,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    const SizedBox(height: 48),
                                    // Button with animation
                                    TweenAnimationBuilder<double>(
                                      duration: const Duration(
                                        milliseconds: 1000,
                                      ),
                                      tween: Tween(begin: 0.0, end: 1.0),
                                      curve: Curves.easeOut,
                                      builder: (context, value, child) {
                                        return Opacity(
                                          opacity: value,
                                          child: Transform.translate(
                                            offset: Offset(0, 30 * (1 - value)),
                                            child: child,
                                          ),
                                        );
                                      },
                                      child: InkWell(
                                        onTap: () {
                                          if (_inscriptionResult != null) {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    InscriptionDetailScreen(
                                                      inscriptionData:
                                                          _inscriptionResult!,
                                                      competition:
                                                          widget.competition,
                                                    ),
                                              ),
                                            );
                                          }
                                        },
                                        borderRadius: BorderRadius.circular(16),
                                        child: Container(
                                          width: double.infinity,
                                          height: 56,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                AppTheme.primary,
                                                AppTheme.secondary,
                                              ],
                                              begin: Alignment.centerLeft,
                                              end: Alignment.centerRight,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              'Ver inscripción',
                                              style: nunitoSansStyle(
                                                600,
                                                16,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    // Botón regresar al inicio
                                    TweenAnimationBuilder<double>(
                                      duration: const Duration(
                                        milliseconds: 1200,
                                      ),
                                      tween: Tween(begin: 0.0, end: 1.0),
                                      curve: Curves.easeOut,
                                      builder: (context, value, child) {
                                        return Opacity(
                                          opacity: value,
                                          child: Transform.translate(
                                            offset: Offset(0, 30 * (1 - value)),
                                            child: child,
                                          ),
                                        );
                                      },
                                      child: InkWell(
                                        onTap: () {
                                          ref.invalidate(
                                            inscriptionsFilterProvider,
                                          );
                                          Navigator.of(
                                            context,
                                          ).popUntil((route) => route.isFirst);
                                        },
                                        borderRadius: BorderRadius.circular(16),
                                        child: Container(
                                          width: double.infinity,
                                          height: 56,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            border: Border.all(
                                              color: AppTheme.primary,
                                              width: 2,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              'Regresar al inicio',
                                              style: nunitoSansStyle(
                                                600,
                                                16,
                                                color: AppTheme.primary,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
            ),
            bottomNavigationBar: !_success
                ? Container(
                    height: 150,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Términos y condiciones
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _acceptedTerms = !_acceptedTerms;
                                });
                              },
                              child: Container(
                                width: 20,
                                height: 20,
                                margin: const EdgeInsets.only(top: 2),
                                decoration: BoxDecoration(
                                  color: _acceptedTerms
                                      ? AppTheme.primary
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: _acceptedTerms
                                        ? AppTheme.primary
                                        : AppTheme.grey,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: _acceptedTerms
                                    ? const Icon(
                                        Icons.check,
                                        size: 14,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: RichText(
                                textAlign: TextAlign.justify,
                                text: TextSpan(
                                  style: nunitoSansBodySmallStyle(context),
                                  children: [
                                    const TextSpan(
                                      text: 'Al continuar, acepta los ',
                                    ),
                                    TextSpan(
                                      text: 'Términos y condiciones',
                                      style: nunitoSansBodySmallStyle(
                                        context,
                                        color: AppTheme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      recognizer: tapTermsRecognizer,
                                    ),
                                    const TextSpan(text: ' y '),
                                    TextSpan(
                                      text: 'Políticas de privacidad',
                                      style: nunitoSansBodySmallStyle(
                                        context,
                                        color: AppTheme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      recognizer: tapPoliticsRecognizer,
                                    ),
                                    const TextSpan(text: '.'),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        InkWell(
                          onTap:
                              _selectedPaymentMethod != null &&
                                  _acceptedTerms &&
                                  !_isProcessingPayment
                              ? _processPayment
                              : null,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: double.infinity,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient:
                                  _selectedPaymentMethod != null &&
                                      _acceptedTerms &&
                                      !_isProcessingPayment
                                  ? LinearGradient(
                                      colors: [
                                        AppTheme.primary,
                                        AppTheme.secondary,
                                      ],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    )
                                  : null,
                              color:
                                  _selectedPaymentMethod == null ||
                                      !_acceptedTerms ||
                                      _isProcessingPayment
                                  ? AppTheme.grey.withValues(alpha: 0.3)
                                  : null,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: _isProcessingPayment
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 3,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : Text(
                                      'Pagar',
                                      style: nunitoSansTitleSmallStyle(
                                        context,
                                        fontWeight: FontWeight.w700,
                                        color:
                                            _selectedPaymentMethod != null &&
                                                _acceptedTerms
                                            ? Colors.white
                                            : AppTheme.grey,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  )
                : null,
          ),
        );
      },
      loading: () => Scaffold(
        body: Center(
          child: GlobalWidgets.circularProgressIndicator(
            radius: 50,
            color: AppTheme.lightModeBlue,
          ),
        ),
      ),
      error: (error, _) {
        final String errorMessage = error.toString().replaceFirst(
          'Exception: ',
          '',
        );
        if (errorMessage.contains('Unauthorized') ||
            errorMessage.contains('Authorization header missing')) {
          return LoginView();
        } else {
          return Scaffold(
            body: Center(
              child: Text(errorMessage, textAlign: TextAlign.center),
            ),
          );
        }
      },
    );
  }

  Widget _buildPaymentMethod({
    required Widget icon,
    required String title,
    required String subtitle,
    required String value,
  }) {
    final isSelected = _selectedPaymentMethod == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppTheme.primary
                : AppTheme.grey.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            icon,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: nunitoSansStyle(
                      600,
                      14,
                      color: AppTheme.lightModeBlack,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: nunitoSansStyle(400, 12, color: AppTheme.grey),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primary, AppTheme.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 16),
              ),
          ],
        ),
      ),
    );
  }

  void _addParticipantInscriptionFinalValues() {
    final isApplyInvoice = widget.competition.isApplyInvoice ?? false;
    final participantsSubtotal = _calculateParticipantsSubtotal();
    final appliedDiscount = _calculateParticipantsDiscountPool();
    final orderDiscountPct = _appliedCoupon != null && participantsSubtotal > 0
        ? (appliedDiscount / participantsSubtotal * 100)
        : 0.0;

    for (var participant in widget.participants) {
      final basePrice = participant['base_price'] as double;
      final tshirtPrice = (participant['tshirt_price'] ?? 0.0) as double;
      final participantSubtotal = basePrice + tshirtPrice;

      // Calculate proportional discount for this participant
      final participantDiscount =
          _appliedCoupon != null && participantsSubtotal > 0
          ? math.min(
              participantSubtotal,
              participantSubtotal / participantsSubtotal * appliedDiscount,
            )
          : 0.0;

      final participantSubtotalAfterDiscount = math.max(
        0.0,
        participantSubtotal - participantDiscount,
      );

      // Aplicar IVA solo si isApplyInvoice es true
      final participantIva = isApplyInvoice
          ? participantSubtotalAfterDiscount * 0.15
          : 0.0;
      final participantTotal =
          participantSubtotalAfterDiscount + participantIva;

      participant['discount_pct'] = orderDiscountPct.toStringAsFixed(2);
      participant['discount_code'] = _appliedCoupon;
      participant['sub_total'] = participantSubtotalAfterDiscount
          .toStringAsFixed(2);
      participant['iva_pct'] = isApplyInvoice ? "15" : "0";
      participant['iva_value'] = participantIva.toStringAsFixed(2);
      participant['total'] = participantTotal.toStringAsFixed(2);
    }
  }
}

class _AppliedDiscountCode {
  const _AppliedDiscountCode({required this.codigo, required this.descuento});

  final String codigo;
  final double descuento;

  Map<String, dynamic> toJson() {
    return {'codigo': codigo, 'descuento': descuento};
  }
}
