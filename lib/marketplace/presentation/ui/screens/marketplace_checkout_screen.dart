import 'dart:developer';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../src/presentation/providers/modes/modes_provider.dart';
import '../../../../src/presentation/providers/profile/profile_provider.dart';
import '../../../../src/presentation/ui/auth/views/login_view.dart';
import '../../../../src/utils/url_launcher_utils.dart';
import '../../../../src/utils/validator.dart';
import '../../../config/theme/marketplace_theme.dart';
import '../../../data/api/marketplace_api_service.dart';
import '../../../domain/models/user.dart';
import '../../../domain/models/marketplace_billing_data.dart';
import '../../../domain/models/marketplace_delivery_data.dart';
import '../../../domain/models/marketplace_order.dart';
import '../../../presentation/providers/cart_provider.dart';
import '../../../services/marketplace_order_service.dart';
import '../../widgets/global.dart';
import '../../../../src/presentation/ui/inscriptions/bank_transfer_screen.dart';
import 'datafast/marketplace_datafast_payment_screen.dart';
import 'deuna/marketplace_deuna_payment_screen.dart';

class MarketplaceCheckoutScreen extends ConsumerStatefulWidget {
  const MarketplaceCheckoutScreen({
    super.key,
    required this.deliveryData,
    this.deliveryFee = 0,
  });

  final MarketplaceDeliveryData deliveryData;
  final double deliveryFee;

  @override
  ConsumerState<MarketplaceCheckoutScreen> createState() =>
      _MarketplaceCheckoutScreenState();
}

class _MarketplaceCheckoutScreenState
    extends ConsumerState<MarketplaceCheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _dniController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _didPrefill = false;
  bool _isSubmitting = false;
  String? _selectedPaymentMethod;
  bool _acceptedTerms = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _dniController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final orderRequiresBilling = _orderRequiresBilling(cart);
    final pricing = MarketplaceOrderPricing.fromCart(
      items: cart.items,
      discountAmount: cart.discountAmount,
      taxRate: MarketplaceOrderService.ivaRate,
      deliveryFee: widget.deliveryFee,
    );
    final userAsync = ref.watch(userProfileProvider);
    final user = userAsync.asData?.value;
    final paymentSettings = ref.watch(marketplacePaymentSettingsProvider);

    if (user != null && !_didPrefill) {
      _didPrefill = true;
      final billingData = MarketplaceBillingData.fromUserBillingData(
        user.datosFacturacion,
      );
      _fullNameController.text = billingData.fullName.isNotEmpty
          ? billingData.fullName
          : '${user.nombres} ${user.apellidos}'.trim();
      _dniController.text = billingData.dni.isNotEmpty
          ? billingData.dni
          : user.numDocumento;
      _emailController.text = billingData.email.isNotEmpty
          ? billingData.email
          : user.email;
      _addressController.text = billingData.address;
      _phoneController.text = billingData.phone.isNotEmpty
          ? billingData.phone
          : user.celular;
    }

    return Scaffold(
      backgroundColor: MarketplaceTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Confirmar orden',
          style: MarketplaceTheme.titleLargeTextStyle(
            context,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: cart.items.isEmpty
          ? _buildEmptyState(context)
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildOrderStatusCard(context),
                  const SizedBox(height: 16),
                  _buildSavedDeliveryLocationCard(context),
                  const SizedBox(height: 16),
                  if (orderRequiresBilling) ...[
                    _buildSectionTitle(context, 'Datos de facturación'),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _fullNameController,
                      label: 'Nombre completo',
                      keyboardType: TextInputType.name,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Ingresa el nombre para la factura';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _dniController,
                      label: 'Cédula, RUC o pasaporte',
                      keyboardType: TextInputType.number,
                      maxLength: 13,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Ingresa el documento';
                        }
                        if (!Validator.validate(
                          ValidatorType.document,
                          value.trim(),
                        )) {
                          return 'Documento inválido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _emailController,
                      label: 'Correo electrónico',
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Ingresa el correo electrónico';
                        }
                        if (!Validator.validate(
                          ValidatorType.email,
                          value.trim(),
                        )) {
                          return 'Correo electrónico inválido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _addressController,
                      label: 'Dirección',
                      keyboardType: TextInputType.streetAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Ingresa la dirección';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _phoneController,
                      label: 'Teléfono',
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value != null &&
                            value.trim().isNotEmpty &&
                            !Validator.validate(
                              ValidatorType.phone,
                              value.trim(),
                            )) {
                          return 'Teléfono inválido';
                        }
                        return null;
                      },
                    ),
                  ] else ...[
                    _buildBillingNotRequiredCard(context),
                  ],
                  const SizedBox(height: 20),
                  _buildSectionTitle(context, 'Resumen'),
                  const SizedBox(height: 12),
                  _buildSummaryCard(context, cart, pricing),
                  const SizedBox(height: 20),
                  _buildSectionTitle(context, 'Método de pago'),
                  const SizedBox(height: 12),
                  if (paymentSettings.isApplyTC) ...[
                    _buildPaymentMethod(
                      icon: Icon(
                        Icons.credit_card,
                        color: MarketplaceTheme.secondayBlack,
                      ),
                      title: 'Tarjeta de crédito o débito',
                      subtitle: 'Todas las entidades bancarias',
                      value: 'datafast',
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (paymentSettings.isApplyDeuna) ...[
                    _buildPaymentMethod(
                      icon: Image.asset(
                        'assets/images/deuna.png',
                        width: 22,
                        height: 22,
                      ),
                      title: 'DeUna',
                      subtitle: 'App de pagos',
                      value: 'deuna',
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (paymentSettings.isApplyManual) ...[
                    _buildPaymentMethod(
                      icon: Icon(
                        Icons.account_balance_outlined,
                        color: MarketplaceTheme.secondayBlack,
                      ),
                      title: 'Transferencia bancaria',
                      subtitle: 'Sube tu comprobante de pago',
                      value: 'manual',
                    ),
                    const SizedBox(height: 12),
                  ],
                  const SizedBox(height: 12),
                ],
              ),
            ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
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
            mainAxisSize: MainAxisSize.min,
            children: [
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
                            ? MarketplaceTheme.primary
                            : Colors.transparent,
                        border: Border.all(
                          color: _acceptedTerms
                              ? MarketplaceTheme.primary
                              : MarketplaceTheme.gbDark600,
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
                        style: MarketplaceTheme.bodySmallTextStyle(context),
                        children: [
                          const TextSpan(text: 'Al continuar, acepta los '),
                          TextSpan(
                            text: 'Términos y condiciones',
                            style: MarketplaceTheme.bodySmallTextStyle(
                              context,
                              color: MarketplaceTheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                            recognizer: tapTermsRecognizer,
                          ),
                          const TextSpan(text: ' y '),
                          TextSpan(
                            text: 'Políticas de privacidad',
                            style: MarketplaceTheme.bodySmallTextStyle(
                              context,
                              color: MarketplaceTheme.primary,
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
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _isSubmitting || cart.items.isEmpty
                    ? null
                    : () => _submit(cart),
                style: FilledButton.styleFrom(
                  backgroundColor:
                      _selectedPaymentMethod != null && _acceptedTerms
                      ? MarketplaceTheme.primary
                      : MarketplaceTheme.gbDark600.withValues(alpha: 0.35),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Pagar',
                        style: MarketplaceTheme.bodyMediumTextStyle(
                          context,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 84,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No hay productos para generar una orden',
              textAlign: TextAlign.center,
              style: MarketplaceTheme.titleMediumTextStyle(
                context,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderStatusCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MarketplaceTheme.gbBlue50,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.receipt_long_outlined),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selecciona tu método de pago',
                  style: MarketplaceTheme.bodyMediumTextStyle(
                    context,
                    fontWeight: FontWeight.w700,
                    color: MarketplaceTheme.secondayBlack,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'La orden se registrará y el pago se procesará con la pasarela seleccionada.',
                  style: MarketplaceTheme.bodySmallTextStyle(
                    context,
                    color: MarketplaceTheme.gbDark600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedDeliveryLocationCard(BuildContext context) {
    final addressLine = _buildDeliveryAddressLine();
    final detailLine = _buildDeliveryDetailLine();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: MarketplaceTheme.primary.withValues(alpha: 0.14),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: MarketplaceTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.location_on_outlined,
              color: MarketplaceTheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ubicación de entrega guardada',
                  style: MarketplaceTheme.bodyMediumTextStyle(
                    context,
                    fontWeight: FontWeight.w700,
                    color: MarketplaceTheme.secondayBlack,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  addressLine,
                  style: MarketplaceTheme.bodySmallTextStyle(
                    context,
                    color: MarketplaceTheme.secondayBlack,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (detailLine != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    detailLine,
                    style: MarketplaceTheme.bodySmallTextStyle(
                      context,
                      color: MarketplaceTheme.gbDark600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: MarketplaceTheme.titleSmallTextStyle(
        context,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  String _buildDeliveryAddressLine() {
    final parts =
        [widget.deliveryData.mainAddress, widget.deliveryData.secondaryAddress]
            .whereType<String>()
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty)
            .toList();

    if (parts.isNotEmpty) {
      return parts.join(' y ');
    }

    return 'Ubicación seleccionada en el mapa';
  }

  String? _buildDeliveryDetailLine() {
    final parts =
        [
              widget.deliveryData.parish,
              widget.deliveryData.canton,
              widget.deliveryData.province,
            ]
            .whereType<String>()
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty)
            .toList();

    final locationLabel = parts.isEmpty ? null : parts.join(', ');
    final reference = widget.deliveryData.reference?.trim();

    if (reference != null && reference.isNotEmpty) {
      if (locationLabel == null) {
        return reference;
      }
      return '$locationLabel. Ref: $reference';
    }

    return locationLabel;
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required TextInputType keyboardType,
    String? Function(String?)? validator,
    int? maxLength,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        counterText: '',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: MarketplaceTheme.primary,
            width: 1.5,
          ),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    CartState cart,
    MarketplaceOrderPricing pricing,
  ) {
    final orderRequiresBilling = _orderRequiresBilling(cart);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          for (final item in cart.items) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    '${item.quantity} x ${item.product.name}',
                    style: MarketplaceTheme.bodyMediumTextStyle(
                      context,
                      color: MarketplaceTheme.secondayBlack,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '\$${pricing.lineTotalFor(item.id).toStringAsFixed(2)}',
                  style: MarketplaceTheme.bodyMediumTextStyle(
                    context,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          const Divider(),
          _buildSummaryRow(
            context,
            label: 'Subtotal',
            value: '\$${pricing.subtotalBeforeDiscount.toStringAsFixed(2)}',
          ),
          if (pricing.discountAmount > 0) ...[
            const SizedBox(height: 8),
            _buildSummaryRow(
              context,
              label: 'Descuento cupón',
              value: '- \$${pricing.discountAmount.toStringAsFixed(2)}',
              valueColor: Colors.green.shade700,
            ),
          ],
          if (orderRequiresBilling) ...[
            const SizedBox(height: 8),
            _buildSummaryRow(
              context,
              label:
                  'IVA ${(MarketplaceOrderService.ivaRate * 100).toStringAsFixed(0)}% (ítems gravados)',
              value: '\$${pricing.iva.toStringAsFixed(2)}',
            ),
          ],
          if (pricing.deliveryFee > 0) ...[
            const SizedBox(height: 8),
            _buildSummaryRow(
              context,
              label: 'Costo de envío',
              value: '\$${pricing.deliveryFee.toStringAsFixed(2)}',
            ),
          ],
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          _buildSummaryRow(
            context,
            label: 'Total',
            value: '\$${pricing.total.toStringAsFixed(2)}',
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildBillingNotRequiredCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MarketplaceTheme.gbBlue50,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: MarketplaceTheme.primary.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.info_outline,
              color: MarketplaceTheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Facturación no requerida',
                  style: MarketplaceTheme.bodyMediumTextStyle(
                    context,
                    fontWeight: FontWeight.w700,
                    color: MarketplaceTheme.secondayBlack,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Esta orden no incluye ítems gravados con IVA, por lo que no es necesario completar datos de facturación.',
                  style: MarketplaceTheme.bodySmallTextStyle(
                    context,
                    color: MarketplaceTheme.gbDark600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    BuildContext context, {
    required String label,
    required String value,
    bool isTotal = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: MarketplaceTheme.bodyMediumTextStyle(
            context,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
            color: isTotal
                ? MarketplaceTheme.secondayBlack
                : MarketplaceTheme.gbDark600,
          ),
        ),
        Text(
          value,
          style: MarketplaceTheme.bodyMediumTextStyle(
            context,
            fontWeight: FontWeight.w700,
            color: valueColor ?? MarketplaceTheme.secondayBlack,
          ),
        ),
      ],
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
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? MarketplaceTheme.primary
                : MarketplaceTheme.gbDark600.withValues(alpha: 0.18),
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
                    style: MarketplaceTheme.bodyMediumTextStyle(
                      context,
                      fontWeight: FontWeight.w700,
                      color: MarketplaceTheme.secondayBlack,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: MarketplaceTheme.bodySmallTextStyle(
                      context,
                      color: MarketplaceTheme.gbDark600,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: MarketplaceTheme.primary,
                ),
                child: const Icon(Icons.check, size: 16, color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }

  TapGestureRecognizer get tapTermsRecognizer => TapGestureRecognizer()
    ..onTap = () {
      try {
        UrlLauncherUtils.launch(
          'https://registrate.magdata.com.ec/terminosycondiciones',
        );
      } catch (_) {
        Global.showBasicAlert(
          'Error',
          'No se pudo abrir el enlace de términos y condiciones. Por favor, inténtalo más tarde',
          'Aceptar',
        );
      }
    };

  TapGestureRecognizer get tapPoliticsRecognizer => TapGestureRecognizer()
    ..onTap = () {
      try {
        UrlLauncherUtils.launch(
          'https://registrate.magdata.com.ec/politicasdeprotecciondedatos',
        );
      } catch (_) {
        Global.showBasicAlert(
          'Error',
          'No se pudo abrir el enlace de términos y condiciones. Por favor, inténtalo más tarde',
          'Aceptar',
        );
      }
    };

  Future<void> _submit(CartState cart) async {
    final orderRequiresBilling = _orderRequiresBilling(cart);

    if (_selectedPaymentMethod == null) {
      _showSnackBar('Por favor, selecciona un método de pago', isError: true);
      return;
    }

    if (!_acceptedTerms) {
      _showSnackBar('Debes aceptar los términos y condiciones', isError: true);
      return;
    }

    final user = await _requireAuthenticatedUser();
    if (user == null) {
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    if (orderRequiresBilling && !_formKey.currentState!.validate()) {
      return;
    }

    final billingData = orderRequiresBilling
        ? MarketplaceBillingData.fromForm(
            fullName: _fullNameController.text,
            dni: _dniController.text,
            email: _emailController.text,
            address: _addressController.text,
            phone: _phoneController.text,
          )
        : MarketplaceBillingData.fromUserBillingData(user.datosFacturacion);
    final pricing = MarketplaceOrderPricing.fromCart(
      items: cart.items,
      discountAmount: cart.discountAmount,
      taxRate: MarketplaceOrderService.ivaRate,
    );

    setState(() => _isSubmitting = true);
    try {
      if (orderRequiresBilling &&
          !billingData.equalsUserBillingData(user.datosFacturacion)) {
        final updateResult = await MarketplaceApiService.updateUser({
          'datos_facturacion': billingData.toUserBillingJson(),
        });
        if (!(updateResult['response'] ?? false)) {
          _showSnackBar(
            updateResult['message']?.toString() ??
                'No se pudieron actualizar los datos de facturación',
            isError: true,
          );
          return;
        }
        ref.invalidate(userProfileProvider);
      }

      final result = await MarketplaceOrderService.createOrder(
        user: user,
        cart: cart,
        billingData: billingData,
        deliveryData: widget.deliveryData,
        gateway: _selectedPaymentMethod!,
        deliveryFee: widget.deliveryFee,
      );
      log('Marketplace create order result: $result');

      if (!(result['response'] ?? false)) {
        _showSnackBar(_resolveOrderErrorMessage(result), isError: true);
        return;
      }

      final orderId = _extractOrderId(result);
      final orderCode = _extractOrderCode(result);
      if (orderId == null || orderId.isEmpty) {
        _showSnackBar(
          'La orden fue creada pero no se recibió el identificador para procesar el pago',
          isError: true,
        );
        return;
      }

      final paymentApproved = await _startPaymentFlow(
        gateway: _selectedPaymentMethod!,
        orderId: orderId,
        total: pricing.total,
      );
      if (!paymentApproved) {
        return;
      }

      await ref.read(cartProvider.notifier).clearCart();
      if (!mounted) return;

      await _showPaymentConfirmedDialog(orderCode);
      if (!mounted) return;

      ref.read(marketplaceOrdersRefreshProvider.notifier).state++;
      ref.read(bottomNavigationIndexProvider.notifier).state = 3;
      ref.read(marketplaceSectionProvider.notifier).state =
          MarketplaceSection.home;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _showPaymentConfirmedDialog(String orderCode) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  size: 38,
                  color: Colors.green.shade700,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Pago confirmado',
                textAlign: TextAlign.center,
                style: MarketplaceTheme.titleMediumTextStyle(
                  context,
                  fontWeight: FontWeight.w800,
                  color: MarketplaceTheme.secondayBlack,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'La orden $orderCode fue pagada correctamente.',
                textAlign: TextAlign.center,
                style: MarketplaceTheme.bodyMediumTextStyle(
                  context,
                  color: MarketplaceTheme.gbDark600,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: MarketplaceTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  orderCode,
                  textAlign: TextAlign.center,
                  style: MarketplaceTheme.bodyMediumTextStyle(
                    context,
                    fontWeight: FontWeight.w800,
                    color: MarketplaceTheme.secondayBlack,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: MarketplaceTheme.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Volver al inicio',
                    style: MarketplaceTheme.bodyMediumTextStyle(
                      context,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _startPaymentFlow({
    required String gateway,
    required String orderId,
    required double total,
  }) async {
    switch (gateway) {
      case 'datafast':
        return _goToDatafastPayment(orderId: orderId, total: total);
      case 'deuna':
        return _goToDeUnaPayment(orderId: orderId, total: total);
      case 'manual':
        return _goToBankTransferPayment(orderId: orderId, total: total);
      default:
        _showSnackBar('Método de pago no soportado', isError: true);
        return false;
    }
  }

  Future<bool> _goToDatafastPayment({
    required String orderId,
    required double total,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    if (token.isEmpty) {
      _showSnackBar(
        'No se encontró la sesión para iniciar el pago',
        isError: true,
      );
      return false;
    }
    if (!mounted) return false;

    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MarketplaceDatafastPaymentScreen(
          serviceLabel: 'id_order',
          total: total,
          serviceId: orderId,
          token: token,
        ),
      ),
    );

    if (result != null) {
      if (result['response'] ?? false) {
        return true;
      }

      final String error =
          result['message']?.toString() ??
          result['error']?.toString() ??
          'Ha ocurrido un error';
      final Map<String, dynamic> datafastData = Map<String, dynamic>.from(
        result['data'] ?? {},
      );
      final Map<String, dynamic> datafastResult = Map<String, dynamic>.from(
        datafastData['result'] ??
            {'description': 'Error desconocido, por favor intente más tarde'},
      );
      final String description =
          datafastResult['description']?.toString() ??
          'Error desconocido, por favor intente más tarde';

      await Global.showBasicAlert(error, description, 'Aceptar');
      return false;
    }

    _showSnackBar(
      'El pago ha sido cancelado. Por favor, intente nuevamente.',
      isError: true,
    );
    return false;
  }

  Future<bool> _goToDeUnaPayment({
    required String orderId,
    required double total,
  }) async {
    final result = await MarketplaceApiService.requestDeUnaPayment(
      'id_order',
      orderId,
    );
    if (!(result['response'] ?? false)) {
      final String error =
          result['message']?.toString() ??
          result['error']?.toString() ??
          'Error desconocido, por favor intente más tarde';
      await Global.showBasicAlert(
        'Ha ocurrido un error al solicitar el pago con DeUna',
        error,
        'Aceptar',
      );
      return false;
    }

    final Map<String, dynamic> data = Map<String, dynamic>.from(
      result['data'] ?? {},
    );
    if (!mounted) return false;
    final deUnaResult = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            MarketplaceDeunaPaymentScreen(data: data, total: total),
      ),
    );
    if (deUnaResult != null) {
      final String status = deUnaResult['status']?.toString() ?? 'unknown';
      if (status == 'APPROVED') {
        return true;
      }

      await Global.showBasicAlert(
        'Estado: $status',
        'El pago aún no ha sido verificado',
        'Aceptar',
      );
      return false;
    }

    _showSnackBar(
      'El pago ha sido cancelado. Por favor, intente nuevamente.',
      isError: true,
    );
    return false;
  }

  Future<bool> _goToBankTransferPayment({
    required String orderId,
    required double total,
  }) async {
    final settings = ref.read(marketplacePaymentSettingsProvider);
    final bankInfo = settings.bankInfo;
    if (bankInfo == null || !bankInfo.isValid) {
      _showSnackBar(
        'No hay información bancaria configurada para transferencias',
        isError: true,
      );
      return false;
    }
    if (!mounted) return false;
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BankTransferPaymentScreen(
          bankInfo: bankInfo,
          total: total,
          orderId: orderId,
          isFromMarketplace: true,
        ),
      ),
    );
    return result != null && (result['response'] ?? false);
  }

  String _extractOrderCode(Map<String, dynamic> result) {
    final data = result['data'];
    final orderDraft = result['orderDraft'];
    final fallbackCode = orderDraft is Map<String, dynamic>
        ? orderDraft['order_code']?.toString() ?? 'sin código'
        : 'sin código';
    if (data is Map<String, dynamic>) {
      return data['order_code']?.toString() ??
          data['orderCode']?.toString() ??
          data['codigo']?.toString() ??
          fallbackCode;
    }
    return fallbackCode;
  }

  String? _extractOrderId(Map<String, dynamic> result) {
    final data = result['data'];
    if (data is Map<String, dynamic>) {
      return _readOrderIdFromMap(data);
    }
    return null;
  }

  String? _readOrderIdFromMap(Map<String, dynamic> data) {
    final direct =
        data['_id']?.toString() ??
        data['id']?.toString() ??
        data['orderId']?.toString() ??
        data['order_id']?.toString();
    if (direct != null && direct.isNotEmpty) {
      return direct;
    }

    final nestedData = data['data'];
    if (nestedData is Map<String, dynamic>) {
      final nested = _readOrderIdFromMap(nestedData);
      if (nested != null && nested.isNotEmpty) {
        return nested;
      }
    }

    final order = data['order'];
    if (order is Map<String, dynamic>) {
      final nested = _readOrderIdFromMap(order);
      if (nested != null && nested.isNotEmpty) {
        return nested;
      }
    }

    return null;
  }

  void _showSnackBar(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  String _resolveOrderErrorMessage(Map<String, dynamic> result) {
    final message =
        result['message']?.toString() ??
        result['error']?.toString() ??
        (result['data'] is Map<String, dynamic>
            ? (result['data'] as Map<String, dynamic>)['message']?.toString()
            : null);
    if (message != null && message.trim().isNotEmpty) {
      return message;
    }

    final statusCode = result['statusCode']?.toString();
    if (statusCode != null && statusCode.isNotEmpty) {
      return 'No se pudo crear la orden (HTTP $statusCode)';
    }

    return 'No se pudo crear la orden';
  }

  Future<User?> _requireAuthenticatedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final uuid = prefs.getString('uuid') ?? '';

    if (uuid.isEmpty) {
      final didLogin = await _goToLogin();
      if (!didLogin) {
        return null;
      }
    }

    final cachedUser = ref.read(userProfileProvider).asData?.value;
    if (cachedUser != null) {
      return User.fromJson(cachedUser.toJson());
    }

    try {
      ref.invalidate(userProfileProvider);
      final srcUser = await ref.read(userProfileProvider.future);
      return User.fromJson(srcUser.toJson());
    } catch (error) {
      if (_isUnauthorizedError(error)) {
        final didLogin = await _goToLogin();
        if (!didLogin) {
          return null;
        }

        try {
          ref.invalidate(userProfileProvider);
          final srcUser = await ref.read(userProfileProvider.future);
          return User.fromJson(srcUser.toJson());
        } catch (retryError) {
          if (mounted) {
            _showSnackBar(
              retryError.toString().replaceFirst('Exception: ', ''),
              isError: true,
            );
          }
          return null;
        }
      }

      if (mounted) {
        _showSnackBar(
          error.toString().replaceFirst('Exception: ', ''),
          isError: true,
        );
      }
      return null;
    }
  }

  Future<bool> _goToLogin() async {
    if (!mounted) return false;

    _showSnackBar('Inicia sesión para completar la compra', isError: true);

    final didLogin = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const LoginView(needsSafeArea: false)),
    );

    _didPrefill = false;
    ref.invalidate(userProfileProvider);
    if (mounted) {
      setState(() {});
    }

    return didLogin == true;
  }

  bool _isUnauthorizedError(Object? error) {
    final message = error?.toString().toLowerCase() ?? '';
    return message.contains('unauthorized') ||
        message.contains('authorization') ||
        message.contains('no autorizado');
  }

  bool _orderRequiresBilling(CartState cart) {
    return cart.items.any((item) => item.product.appliesIva);
  }
}
