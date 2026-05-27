import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:running_app/marketplace/domain/models/cart_item.dart';
import 'package:running_app/app_localizations_context.dart';
import 'package:running_app/src/data/api/users/users_api_service.dart';
import 'package:running_app/src/domain/models/running_competition.dart';
import 'package:running_app/src/presentation/providers/profile/profile_provider.dart';
import 'package:running_app/src/presentation/ui/auth/views/login_view.dart';
import 'package:running_app/src/presentation/ui/inscriptions/inscription_checkout_screen.dart';
import 'package:running_app/src/presentation/widgets/global_widgets.dart';
import 'package:running_app/config/theme/app_theme.dart';
import 'package:running_app/config/theme/fonts.dart';
import 'package:running_app/src/utils/navigator_key.dart';
import 'package:running_app/src/utils/validator.dart';

class InvoiceDataScreen extends ConsumerStatefulWidget {
  const InvoiceDataScreen({
    super.key,
    required this.competition,
    required this.participants,
    this.extraProducts = const [],
  });

  final RunningCompetition competition;
  final List<Map<String, dynamic>> participants;
  final List<CartItem> extraProducts;

  @override
  InvoiceDataScreenState createState() => InvoiceDataScreenState();
}

class InvoiceDataScreenState extends ConsumerState<InvoiceDataScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _documentNumberController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _telephoneController = TextEditingController();

  bool firstTimeLoading = true;

  @override
  void dispose() {
    _nameController.dispose();
    _documentNumberController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _telephoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = ref.watch(userProfileProvider);
    final size = MediaQuery.of(context).size;

    return userProvider.when(
      data: (user) {
        final invoiceData = user.datosFacturacion;

        if (invoiceData != null && firstTimeLoading) {
          firstTimeLoading = false;
          _nameController.text = invoiceData['nombres'] ?? '';
          _documentNumberController.text = invoiceData['num_documento'] ?? '';
          _emailController.text = invoiceData['email'] ?? '';
          _addressController.text = invoiceData['direccion'] ?? '';
          _telephoneController.text =
              invoiceData['celular'] ?? invoiceData['telefono'] ?? '';
        }

        return Scaffold(
          backgroundColor: AppTheme.inscriptionsBackground,
          appBar: GlobalWidgets.customAppBar(
            context,
            title: context.l1on.billingData,
            onBackButtonPressed: () => Navigator.of(context).pop(),
            centerTitle: false,
          ),
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l1on.billingInformation,
                      style: nunitoSansStyle(
                        700,
                        24,
                        color: AppTheme.lightModeBlack,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildTextField(
                      controller: _nameController,
                      label: context.l1on.businessNameOrFullName,
                      keyboardType: TextInputType.name,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return context.l1on.pleaseEnterNameForInvoice;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _documentNumberController,
                      label: context.l1on.idRucOrPassport,
                      keyboardType: TextInputType.number,
                      maxLength: 13,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return context.l1on.pleaseEnterDocumentNumber;
                        }
                        if (!Validator.validate(
                          ValidatorType.document,
                          value,
                        )) {
                          return context.l1on.invalidDocumentNumber;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _emailController,
                      label: context.l1on.email,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return context.l1on.pleaseEnterYourEmail;
                        }
                        if (!Validator.validate(ValidatorType.email, value)) {
                          return context.l1on.invalidEmail;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _addressController,
                      label: context.l1on.address,
                      keyboardType: TextInputType.streetAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return context.l1on.pleaseEnterAddress;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _telephoneController,
                      label: context.l1on.phone,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (!Validator.validate(ValidatorType.phone, value)) {
                            return context.l1on.invalidPhoneNumber;
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    _buildSaveButton(invoiceData, user),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      error: (error, stackTrace) {
        final String errorMessage = error.toString();
        if (errorMessage.contains('Unauthorized')) {
          return const LoginView();
        } else {
          return Scaffold(
            backgroundColor: AppTheme.inscriptionsBackground,
            appBar: GlobalWidgets.customAppBar(
              context,
              title: context.l1on.billingData,
              onBackButtonPressed: () => Navigator.of(context).pop(),
              centerTitle: false,
            ),
            body: Center(child: Text(errorMessage)),
          );
        }
      },
      loading: () => Scaffold(
        backgroundColor: AppTheme.inscriptionsBackground,
        appBar: GlobalWidgets.customAppBar(
          context,
          title: context.l1on.billingData,
          onBackButtonPressed: () => Navigator.of(context).pop(),
          centerTitle: false,
        ),
        body: Center(
          child: GlobalWidgets.circularProgressIndicator(
            radius: size.width * 0.1,
            color: AppTheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required TextInputType keyboardType,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: nunitoSansStyle(600, 14, color: AppTheme.lightModeBlack),
        ),
        const SizedBox(height: 8),
        TextFormField(
          autovalidateMode: AutovalidateMode.onUserInteraction,
          keyboardType: keyboardType,
          style: nunitoSansStyle(400, 14, color: AppTheme.lightModeBlack),
          controller: controller,
          maxLength: maxLength,
          decoration: InputDecoration(
            counter: maxLength != null ? const SizedBox.shrink() : null,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppTheme.grey.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.lightModeBlue, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildSaveButton(Map<String, dynamic>? invoiceData, dynamic user) {
    return InkWell(
      onTap: () async {
        // Eliminar foco del teclado
        FocusManager.instance.primaryFocus?.unfocus();

        if (_formKey.currentState!.validate()) {
          final Map<String, dynamic> newInvoiceData = {
            'fullName': _nameController.text,
            'dni': _documentNumberController.text,
            'email': _emailController.text,
            'address': _addressController.text,
            'phone': _telephoneController.text,
          };

          final Map<String, dynamic> invoiceReferenceData = {
            'fullName': invoiceData?['nombres'] ?? '',
            'dni': invoiceData?['num_documento'] ?? '',
            'email': invoiceData?['email'] ?? '',
            'address': invoiceData?['direccion'] ?? '',
            'phone': invoiceData?['celular'] ?? invoiceData?['telefono'] ?? '',
          };

          final invoiceDataEncoded = jsonEncode(newInvoiceData);
          final invoiceReferenceDataEncoded = jsonEncode(invoiceReferenceData);
          final billingData = BillingData.fromJson(newInvoiceData);

          if (invoiceDataEncoded == invoiceReferenceDataEncoded) {
            // No hubo cambios, ir directo al checkout

            _goToCheckoutScreen(billingData);
          } else {
            // Hay cambios, actualizar datos de facturación
            SmartDialog.showLoading(
              msg: context.l1on.updatingBillingData,
              backType: SmartBackType.ignore,
              clickMaskDismiss: false,
            );

            final userData = {
              'datos_facturacion': {
                'nombres': _nameController.text,
                'apellidos': '',
                'num_documento': _documentNumberController.text,
                'email': _emailController.text,
                'direccion': _addressController.text,
                'celular': _telephoneController.text,
              },
            };
            log('User data: $userData');

            final result = await UsersApiService.updateUser(userData);
            SmartDialog.dismiss();

            if (result['response'] ?? false) {
              ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
                SnackBar(
                  content: Text(
                    navigatorKey
                        .currentContext!
                        .l1on
                        .billingDataUpdatedSuccessfully,
                  ),
                  backgroundColor: Colors.green,
                ),
              );
              ref.invalidate(userProfileProvider);
              _goToCheckoutScreen(billingData);
            } else {
              ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
                SnackBar(
                  content: Text(result['message']),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primary, AppTheme.secondary],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            context.l1on.continueToPayment,
            style: nunitoSansStyle(600, 16, color: Colors.white),
          ),
        ),
      ),
    );
  }

  void _goToCheckoutScreen(BillingData billingData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InscriptionCheckoutScreen(
          competition: widget.competition,
          participants: widget.participants,
          extraProducts: widget.extraProducts,
          billingData: billingData,
        ),
      ),
    );
  }
}
