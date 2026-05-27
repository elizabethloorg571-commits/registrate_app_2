import 'dart:convert';
import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:running_app/marketplace/domain/models/cart_item.dart';
import 'package:running_app/marketplace/domain/models/marketplace_order.dart';
import 'package:running_app/marketplace/domain/models/marketplace_product.dart';
import 'package:running_app/app_localizations_context.dart';
import 'package:running_app/src/domain/models/running_competition.dart';
import 'package:running_app/src/presentation/ui/inscriptions/inscription_checkout_screen.dart';
import 'package:running_app/src/presentation/ui/inscriptions/invoice_data_screen.dart';
import 'package:running_app/src/presentation/widgets/competition_card.dart';
import 'package:running_app/src/presentation/widgets/custom_text_field.dart';
import 'package:running_app/src/presentation/widgets/global_widgets.dart';
import 'package:running_app/config/theme/app_theme.dart';
import 'package:running_app/config/theme/fonts.dart';
import 'package:running_app/config/theme/helpers/hex_color.dart';
import 'package:running_app/src/utils/navigator_key.dart';
import 'package:running_app/src/utils/responsive.dart';

import '../../../../marketplace/data/api/marketplace_api_service.dart';
import '../home/utils/home_svg_files.dart';
import 'utils/inscription_svg_files.dart';

class InscriptionScreen extends ConsumerStatefulWidget {
  const InscriptionScreen({super.key, required this.competition});

  final RunningCompetition competition;

  @override
  InscriptionScreenState createState() => InscriptionScreenState();
}

class InscriptionScreenState extends ConsumerState<InscriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // Step 1: Categoría
  CompetitionSetting? _selectedSetting;

  // Step 2: Datos personales + distancia + género
  final _nombreController = TextEditingController();
  String _tipoDocumento = 'Cedula';
  final _cedulaController = TextEditingController();
  final _celularController = TextEditingController();
  final _emailController = TextEditingController();
  final _birthDateController = TextEditingController();
  DateTime? _selectedBirthDate;
  Distance? _selectedDistance;
  String? _selectedGender;

  // FocusNode para controlar el foco
  final FocusNode _dummyFocusNode = FocusNode();

  // Country selection
  Map<String, String> _selectedCountry = {
    'name': 'Ecuador',
    'code': '+593',
    'flag': '🇪🇨',
    'iso': 'EC',
  };

  // Lista de países disponibles
  final List<Map<String, String>> _countries = [
    {'name': 'Ecuador', 'code': '+593', 'flag': '🇪🇨', 'iso': 'EC'},
    {'name': 'Estados Unidos', 'code': '+1', 'flag': '🇺🇸', 'iso': 'US'},
    {'name': 'México', 'code': '+52', 'flag': '🇲🇽', 'iso': 'MX'},
    {'name': 'Colombia', 'code': '+57', 'flag': '🇨🇴', 'iso': 'CO'},
    {'name': 'Perú', 'code': '+51', 'flag': '🇵🇪', 'iso': 'PE'},
    {'name': 'Argentina', 'code': '+54', 'flag': '🇦🇷', 'iso': 'AR'},
    {'name': 'Chile', 'code': '+56', 'flag': '🇨🇱', 'iso': 'CL'},
    {'name': 'España', 'code': '+34', 'flag': '🇪🇸', 'iso': 'ES'},
    {'name': 'Brasil', 'code': '+55', 'flag': '🇧🇷', 'iso': 'BR'},
    {'name': 'Venezuela', 'code': '+58', 'flag': '🇻🇪', 'iso': 'VE'},
  ];

  // Tipos de documento
  final List<String> _tiposDocumento = ['Cedula', 'Pasaporte', 'RUC'];

  // Step 3: Talla de camiseta (solo si aplica)
  TshirtDetail? _selectedTshirtSize;

  // Lista de inscritos
  final List<Map<String, dynamic>> _registeredParticipants = [];
  final List<MarketplaceProduct> _crossSellProducts = [];
  final Map<String, int> _selectedCrossSellQuantities = {};

  // Variable para rastrear si estamos editando un participante
  int? _editingParticipantIndex;
  bool _isLoadingCrossSellProducts = false;
  String? _crossSellError;

  @override
  void initState() {
    super.initState();
    _loadCrossSellProducts();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nombreController.dispose();
    _cedulaController.dispose();
    _celularController.dispose();
    _emailController.dispose();
    _dummyFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadCrossSellProducts() async {
    setState(() {
      _isLoadingCrossSellProducts = true;
      _crossSellError = null;
    });

    final result = await MarketplaceApiService.getMarketplaceProducts(
      limit: 12,
    );

    if (!mounted) return;

    if (result['response'] == true && result['data'] is List) {
      final products = (result['data'] as List)
          .whereType<MarketplaceProduct>()
          .toList();

      setState(() {
        _crossSellProducts
          ..clear()
          ..addAll(products);
        _isLoadingCrossSellProducts = false;
      });
      return;
    }

    setState(() {
      _isLoadingCrossSellProducts = false;
      _crossSellError =
          result['message']?.toString() ??
          'No se pudieron cargar los productos extra';
    });
  }

  void _nextStep() {
    _currentStep++;
    _pageController.animateToPage(
      _currentStep,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0: // Categoría
        if (_selectedSetting == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l1on.pleaseSelectACategory)),
          );
          return false;
        }
        return true;
      case 1: // Inscripción (datos personales + distancia + género)

        if (!(_formKey.currentState?.validate() ?? false)) {
          return false;
        }
        if (_selectedDistance == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l1on.pleaseSelectADistance)),
          );
          return false;
        }
        if (_selectedSetting?.gender == true && _selectedGender == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l1on.pleaseSelectGender)),
          );
          return false;
        }
        if (_selectedSetting?.isTshirt == true && _selectedTshirtSize == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l1on.pleaseSelectASize)),
          );
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.inscriptionsBackground,
      appBar: GlobalWidgets.customAppBar(
        context,
        title: '1. ${context.l1on.inscription}',
        onBackButtonPressed: () {
          switch (_currentStep) {
            case 0:
              if (_registeredParticipants.isNotEmpty) {
                setState(() {
                  _editingParticipantIndex = null;
                  _currentStep = 2;
                  _pageController.jumpToPage(2);
                });
              } else {
                Navigator.of(context).pop();
              }

              break;
            case 1:
              setState(() {
                _currentStep = 0;
              });
              _pageController.jumpToPage(0);
              break;
            case 2:
              if (_registeredParticipants.isNotEmpty) {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text(
                        context.l1on.exitWithoutSaving,
                        style: nunitoSansStyle(
                          700,
                          18,
                          color: AppTheme.lightModeBlack,
                        ),
                      ),
                      content: Text(
                        '${context.l1on.youHave} ${_registeredParticipants.length} ${context.l1on.registeredParticipantPlural(_registeredParticipants.length)}. ${context.l1on.ifYouLeaveNowYouWillLoseChanges}',
                        style: nunitoSansStyle(
                          400,
                          14,
                          color: AppTheme.dark700,
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            context.l1on.cancel,
                            style: nunitoSansStyle(
                              600,
                              14,
                              color: AppTheme.grey,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(); // Cerrar diálogo
                            Navigator.of(context).pop(); // Salir de la pantalla
                          },
                          child: Text(
                            context.l1on.exit,
                            style: nunitoSansStyle(600, 14, color: Colors.red),
                          ),
                        ),
                      ],
                    );
                  },
                );
              } else {
                Navigator.of(context).pop();
              }
              break;
            default:
              break;
          }
        },
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Indicador de progreso
          _buildProgressIndicator(),
          // Contenido del paso
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildCategoryStep(),
                _buildPersonalDataStep(),
                _buildFinalSummaryStep(),
              ],
            ),
          ),
          // Botón de continuar o inscribirme
          _currentStep != 0 ? _buildBottomButton() : SizedBox(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    // 2 pasos totales: Inscripción (0) y Resumen de Compra (1)
    // Paso 0 (inscripción) = 50%
    // Paso 1 (resumen de compra) = 100%
    final progressPercentage = (_currentStep == 0 || _currentStep == 1)
        ? 0.5
        : 1.0;

    return ClipRRect(
      child: Container(
        height: 6,
        decoration: BoxDecoration(color: hexOrRGBToColor('#EDE8FD')),
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: progressPercentage,
            child: Container(
              decoration: BoxDecoration(color: AppTheme.primary),
            ),
          ),
        ),
      ),
    );
  }

  // STEP 1: Categoría
  Widget _buildCategoryStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l1on.category,
            style: nunitoSansTitleMediumStyle(
              context,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          ...widget.competition.settings.map((setting) {
            final isSelected = _selectedSetting?.id == setting.id;
            return GestureDetector(
              onTap: () {
                if (!isSelected) {
                  _selectedSetting = setting;
                  // Reset selections when category changes
                  _selectedDistance = null;
                  _selectedGender = null;
                  _selectedTshirtSize = null;
                }

                _nextStep();
                setState(() {});
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppTheme.primary : Colors.transparent,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    SvgPicture.string(kCategoryIconSvg),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        setting.category,
                        style: nunitoSansTitleSmallStyle(
                          context,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right, color: AppTheme.grey, size: 24),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // STEP 2: Datos personales + Distancia + Género
  Widget _buildPersonalDataStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l1on.fullName,
              style: nunitoSansStyle(700, 24, color: AppTheme.lightModeBlack),
            ),
            const SizedBox(height: 24),
            CustomTextField(
              label: context.l1on.fullName,
              controller: _nombreController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return context.l1on.pleaseEnterYourFullName;
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            // Campo de Cédula de identidad con selector de tipo
            _buildDocumentField(),
            const SizedBox(height: 20),
            // Campo de Celular con selector de país
            _buildPhoneField(),
            const SizedBox(height: 20),

            _buildBirthDateField(),
            const SizedBox(height: 20),

            CustomTextField(
              label: context.l1on.email,
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return context.l1on.pleaseEnterYourEmail;
                }
                final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                if (!emailRegex.hasMatch(value)) {
                  return context.l1on.invalidEmail;
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            // Campo de Fecha de nacimiento

            // Campo de Distancia con BottomSheet
            _buildDistanceSelector(),
            if (_selectedSetting?.gender == true) ...[
              const SizedBox(height: 20),
              // Campo de Género con BottomSheet
              _buildGenderSelector(),
            ],
          ],
        ),
      ),
    );
  }

  // STEP 3: Pantalla final de resumen con opción de agregar más participantes
  Widget _buildFinalSummaryStep() {
    final responsive = Responsive(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 200,
            child: CompetitionCard(
              competition: widget.competition,
              responsive: responsive,
              detailsOnPressedAvailable: false,
            ),
          ),
          const SizedBox(height: 16),

          // Categoría seleccionada
          Text(
            context.l1on.category,
            style: nunitoSansTitleSmallStyle(
              context,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ListView.separated(
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _registeredParticipants.length,
            itemBuilder: (context, index) {
              final participant = _registeredParticipants[index];
              return Dismissible(
                key: Key('participant_$index'),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.delete,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                confirmDismiss: (direction) async {
                  return await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text(context.l1on.confirmDeletion),
                        content: Text(
                          context.l1on.areYouSureToDeleteParticipant(
                            participant['fullName'],
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: Text(context.l1on.cancel),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            child: Text(context.l1on.delete),
                          ),
                        ],
                      );
                    },
                  );
                },
                onDismissed: (direction) {
                  setState(() {
                    _registeredParticipants.removeAt(index);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${participant['fullName']} ${context.l1on.deleted}',
                      ),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      SvgPicture.string(kCategoryIconSvg),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              participant['category'] ??
                                  context.l1on.notSelected,
                              style: nunitoSansTitleSmallStyle(
                                context,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              participant['fullName'] ??
                                  context.l1on.notRegistered,
                              style: nunitoSansBodySmallStyle(
                                context,
                                color: AppTheme.dark700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _editingParticipantIndex = index;
                            _setEditionData(participant);
                            _currentStep = 0;
                          });
                          _pageController.jumpToPage(_currentStep);
                        },
                        child: Text(
                          context.l1on.change,
                          style: nunitoSansLabelLargeStyle(
                            context,
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),

          // Botón para inscribir a otra persona
          GestureDetector(
            onTap: () {
              setState(() {
                _editingParticipantIndex = null;
                _clean();
                _currentStep = 0;
              });
              _pageController.jumpToPage(_currentStep);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.l1on.registerAnotherPerson,
                    style: nunitoSansLabelLargeStyle(
                      context,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),

                  Icon(Icons.chevron_right, color: AppTheme.dark700),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildCrossSellSection(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  List<CartItem> _selectedCrossSellItems() {
    return _crossSellProducts
        .where((product) => (_selectedCrossSellQuantities[product.id] ?? 0) > 0)
        .map(
          (product) => CartItem(
            id: product.id,
            product: product,
            quantity: _selectedCrossSellQuantities[product.id] ?? 0,
            addedAt: DateTime.now(),
          ),
        )
        .toList();
  }

  int _crossSellQuantityFor(String productId) {
    return _selectedCrossSellQuantities[productId] ?? 0;
  }

  void _updateCrossSellQuantity(MarketplaceProduct product, int delta) {
    final currentQuantity = _crossSellQuantityFor(product.id);
    final nextQuantity = currentQuantity + delta;

    if (nextQuantity < 0) return;
    if (product.stockQuantity < 999999 &&
        nextQuantity > product.stockQuantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay suficiente stock disponible'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      if (nextQuantity == 0) {
        _selectedCrossSellQuantities.remove(product.id);
      } else {
        _selectedCrossSellQuantities[product.id] = nextQuantity;
      }
    });
  }

  double _calculateParticipantsSubtotal() {
    double subtotal = 0.0;
    for (final participant in _registeredParticipants) {
      subtotal +=
          (participant['base_price'] as double) +
          ((participant['tshirt_price'] ?? 0.0) as double);
    }
    return subtotal;
  }

  MarketplaceOrderPricing _calculateCrossSellPricing() {
    return MarketplaceOrderPricing.fromCart(
      items: _selectedCrossSellItems(),
      discountAmount: 0.0,
      taxRate: widget.competition.isApplyInvoice ?? false ? 0.15 : 0.0,
    );
  }

  double _calculateFinalSummaryTotal() {
    final participantsSubtotal = _calculateParticipantsSubtotal();
    final participantsIva = widget.competition.isApplyInvoice ?? false
        ? participantsSubtotal * 0.15
        : 0.0;
    final crossSellPricing = _calculateCrossSellPricing();

    return participantsSubtotal + participantsIva + crossSellPricing.total;
  }

  Widget _buildCrossSellSection() {
    if (_isLoadingCrossSellProducts) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '¿Deseas algo adicional?',
            style: nunitoSansTitleSmallStyle(
              context,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          const Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (_crossSellError != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '¿Deseas algo adicional?',
            style: nunitoSansTitleSmallStyle(
              context,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _crossSellError!,
              style: nunitoSansBodySmallStyle(context, color: AppTheme.dark700),
            ),
          ),
        ],
      );
    }

    if (_crossSellProducts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '¿Deseas algo adicional?',
          style: nunitoSansTitleSmallStyle(
            context,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _crossSellProducts.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final product = _crossSellProducts[index];
              final quantity = _crossSellQuantityFor(product.id);
              final isAdded = quantity > 0;

              return Container(
                width: 145,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isAdded
                        ? AppTheme.primary
                        : AppTheme.grey.withValues(alpha: 0.15),
                    width: isAdded ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppTheme.white950,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: product.imageUrl != null
                              ? Image.network(
                                  product.imageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => const Icon(
                                    Icons.inventory_2_outlined,
                                    size: 32,
                                    color: Colors.grey,
                                  ),
                                )
                              : const Icon(
                                  Icons.inventory_2_outlined,
                                  size: 32,
                                  color: Colors.grey,
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: nunitoSansBodySmallStyle(
                        context,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${product.effectivePrice.toStringAsFixed(2)}',
                      style: nunitoSansBodySmallStyle(
                        context,
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (isAdded)
                      Row(
                        children: [
                          _buildCrossSellQtyButton(
                            icon: Icons.remove,
                            onTap: () => _updateCrossSellQuantity(product, -1),
                          ),
                          Expanded(
                            child: Text(
                              '$quantity',
                              textAlign: TextAlign.center,
                              style: nunitoSansBodySmallStyle(
                                context,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          _buildCrossSellQtyButton(
                            icon: Icons.add,
                            onTap: () => _updateCrossSellQuantity(product, 1),
                          ),
                        ],
                      )
                    else
                      InkWell(
                        onTap: product.inStock
                            ? () => _updateCrossSellQuantity(product, 1)
                            : null,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.primary),
                          ),
                          child: Center(
                            child: Text(
                              product.inStock ? 'Añadir' : 'Sin stock',
                              style: nunitoSansBodySmallStyle(
                                context,
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCrossSellQtyButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: AppTheme.primary,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(icon, size: 16, color: Colors.white),
      ),
    );
  }

  void _clean() {
    _nombreController.clear();
    _cedulaController.clear();
    _celularController.clear();
    _emailController.clear();
    _birthDateController.clear();
    _selectedBirthDate = null;
    _tipoDocumento = 'Cedula';
    _selectedDistance = null;
    _selectedGender = null;
    _selectedTshirtSize = null;
    _selectedSetting = null;
  }

  void _setEditionData(Map<String, dynamic> participant) {
    _nombreController.text = participant['fullName'] ?? '';
    _tipoDocumento = participant['document_type'] ?? 'Cedula';
    _cedulaController.text = participant['dni'] ?? '';
    _celularController.text = participant['phone'] ?? '';
    _emailController.text = participant['email'] ?? '';
    if (participant['birth_date'] != null) {
      _selectedBirthDate = DateTime.parse(participant['birth_date']);
      _birthDateController.text =
          '${_selectedBirthDate!.day.toString().padLeft(2, '0')}/${_selectedBirthDate!.month.toString().padLeft(2, '0')}/${_selectedBirthDate!.year}';
    }
    _selectedDistance = Distance(
      id: participant['distance_id'],
      km: participant['distance_km'],
      price: participant['base_price'],
      availableSlots: participant['distance_available_slots'],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _selectedGender = participant['gender'];
    _selectedTshirtSize = participant['tshirt_id'] != null
        ? TshirtDetail(
            id: participant['tshirt_id'],
            size: participant['tshirt_size'],
            price: participant['tshirt_price'],
          )
        : null;
  }

  // Construir campo de documento con selector de tipo
  Widget _buildDocumentField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _tipoDocumento,
          style: nunitoSansTitleSmallStyle(
            context,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.grey.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              // Botón de tipo de documento
              GestureDetector(
                onTap: () {
                  FocusManager.instance.primaryFocus?.unfocus();
                  _dummyFocusNode.requestFocus();
                  Future.microtask(() {
                    _dummyFocusNode.unfocus();
                    _showDocumentTypeBottomSheet();
                  });
                },
                child: Container(
                  width: 95,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(
                        color: AppTheme.grey.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        context.l1on.type,
                        style: nunitoSansStyle(
                          400,
                          14,
                          color: AppTheme.lightModeBlack,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.keyboard_arrow_down,
                        color: AppTheme.grey,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              // Campo de texto para número
              Expanded(
                child: TextFormField(
                  controller: _cedulaController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: nunitoSansStyle(
                    400,
                    14,
                    color: AppTheme.lightModeBlack,
                  ),
                  decoration: InputDecoration(
                    hintText: context.l1on.number,
                    hintStyle: nunitoSansStyle(400, 14, color: AppTheme.grey),
                    filled: false,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    errorStyle: const TextStyle(height: 0),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return context.l1on.requiredField;
                    }
                    // Validación según tipo de documento
                    if (_tipoDocumento == 'Cedula') {
                      if (value.length != 10) {
                        return context.l1on.mustHave10Digits;
                      }
                    } else if (_tipoDocumento == 'Pasaporte') {
                      if (value.length < 6) {
                        return context.l1on.minimum6Characters;
                      }
                    } else if (_tipoDocumento == 'RUC') {
                      if (value.length != 13) {
                        return context.l1on.mustHave13Digits;
                      }
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Construir campo de celular con selector de país
  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l1on.cellPhone,
          style: nunitoSansStyle(600, 14, color: AppTheme.lightModeBlack),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.grey.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              // Botón de país
              GestureDetector(
                onTap: () {
                  FocusManager.instance.primaryFocus?.unfocus();
                  _dummyFocusNode.requestFocus();
                  Future.microtask(() {
                    _dummyFocusNode.unfocus();
                    _showCountryBottomSheet();
                  });
                },
                child: Container(
                  width: 95,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(
                        color: AppTheme.grey.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _selectedCountry['flag']!,
                        style: nunitoSansStyle(400, 20),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.keyboard_arrow_down,
                        color: AppTheme.grey,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              // Campo de texto para número
              Expanded(
                child: TextFormField(
                  controller: _celularController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: nunitoSansStyle(
                    400,
                    14,
                    color: AppTheme.lightModeBlack,
                  ),
                  decoration: InputDecoration(
                    hintText: context.l1on.number,
                    hintStyle: nunitoSansStyle(400, 14, color: AppTheme.grey),
                    filled: false,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    errorStyle: const TextStyle(height: 0),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return context.l1on.requiredField;
                    }
                    if (value.length < 7) {
                      return context.l1on.invalidNumber;
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Bottom sheet para seleccionar tipo de documento
  void _showDocumentTypeBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppTheme.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              context.l1on.documentType(_tipoDocumento),
              style: nunitoSansStyle(700, 20, color: AppTheme.lightModeBlack),
            ),
            const SizedBox(height: 20),
            ..._tiposDocumento.map((tipo) {
              final isSelected = _tipoDocumento == tipo;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _tipoDocumento = tipo;
                    _cedulaController.clear();
                  });
                  Navigator.pop(context);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.lightModeBlue
                          : AppTheme.grey.withValues(alpha: 0.3),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          tipo,
                          style: nunitoSansStyle(
                            600,
                            16,
                            color: AppTheme.lightModeBlack,
                          ),
                        ),
                      ),
                      if (isSelected)
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [
                              AppTheme.lightModeBlue,
                              const Color(0xFF8B5CF6),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(bounds),
                          child: const Icon(
                            Icons.check_circle,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Bottom sheet para seleccionar país
  void _showCountryBottomSheet() {
    final TextEditingController searchController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          List<Map<String, String>> filteredCountries = _countries.where((
            country,
          ) {
            final searchLower = searchController.text.toLowerCase();
            return country['name']!.toLowerCase().contains(searchLower) ||
                country['code']!.contains(searchLower);
          }).toList();

          return Container(
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: AppTheme.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  context.l1on.selectYourCountry,
                  style: nunitoSansStyle(
                    700,
                    20,
                    color: AppTheme.lightModeBlack,
                  ),
                ),
                const SizedBox(height: 20),
                // Buscador
                TextField(
                  controller: searchController,
                  onChanged: (value) {
                    setModalState(() {});
                  },
                  style: nunitoSansStyle(
                    400,
                    14,
                    color: AppTheme.lightModeBlack,
                  ),
                  decoration: InputDecoration(
                    hintText: context.l1on.searchCountry,
                    hintStyle: nunitoSansStyle(400, 14, color: AppTheme.grey),
                    prefixIcon: Icon(Icons.search, color: AppTheme.grey),
                    filled: true,
                    fillColor: AppTheme.white950,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Lista de países
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredCountries.length,
                    itemBuilder: (context, index) {
                      final country = filteredCountries[index];
                      final isSelected =
                          _selectedCountry['iso'] == country['iso'];
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCountry = country;
                          });
                          Navigator.pop(context);
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.lightModeBlue
                                  : AppTheme.grey.withValues(alpha: 0.3),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                country['flag']!,
                                style: nunitoSansStyle(400, 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      country['name']!,
                                      style: nunitoSansStyle(
                                        600,
                                        16,
                                        color: AppTheme.lightModeBlack,
                                      ),
                                    ),
                                    Text(
                                      country['code']!,
                                      style: nunitoSansStyle(
                                        400,
                                        14,
                                        color: AppTheme.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                ShaderMask(
                                  shaderCallback: (bounds) => LinearGradient(
                                    colors: [
                                      AppTheme.lightModeBlue,
                                      const Color(0xFF8B5CF6),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ).createShader(bounds),
                                  child: const Icon(
                                    Icons.check_circle,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDistanceSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l1on.selectDistance,
          style: nunitoSansStyle(600, 14, color: AppTheme.lightModeBlack),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            // Forzar eliminación completa del foco
            FocusManager.instance.primaryFocus?.unfocus();
            _dummyFocusNode.requestFocus();
            Future.microtask(() {
              _dummyFocusNode.unfocus();
              _showDistanceBottomSheet();
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.grey.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedDistance?.km ?? context.l1on.select,
                  style: nunitoSansStyle(
                    400,
                    14,
                    color: _selectedDistance != null
                        ? AppTheme.lightModeBlack
                        : AppTheme.grey,
                  ),
                ),
                Icon(Icons.keyboard_arrow_down, color: AppTheme.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l1on.gender,
          style: nunitoSansStyle(600, 14, color: AppTheme.lightModeBlack),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            // Forzar eliminación completa del foco
            FocusManager.instance.primaryFocus?.unfocus();
            _dummyFocusNode.requestFocus();
            Future.microtask(() {
              _dummyFocusNode.unfocus();
              _showGenderBottomSheet();
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.grey.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedGender ?? context.l1on.select,
                  style: nunitoSansStyle(
                    400,
                    14,
                    color: _selectedGender != null
                        ? AppTheme.lightModeBlack
                        : AppTheme.grey,
                  ),
                ),
                Icon(Icons.keyboard_arrow_down, color: AppTheme.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showDistanceBottomSheet() async {
    if (_selectedSetting == null) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppTheme.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              context.l1on.selectDistance,
              style: nunitoSansTitleSmallStyle(
                context,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            ..._selectedSetting!.distance.map((distance) {
              final isSelected = _selectedDistance?.id == distance.id;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDistance = distance;
                  });
                  Navigator.pop(context);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.secondary
                          : AppTheme.grey.withValues(alpha: 0.3),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      SvgPicture.string(kRunsIconFullSvg),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              distance.km,
                              style: nunitoSansStyle(
                                600,
                                16,
                                color: AppTheme.lightModeBlack,
                              ),
                            ),
                            Text(
                              '\$${distance.price.toStringAsFixed(2)}',
                              style: nunitoSansStyle(
                                400,
                                14,
                                color: AppTheme.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [AppTheme.primary, AppTheme.secondary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(bounds),
                          child: const Icon(
                            Icons.check_circle,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 20),
            InkWell(
              onTap: () => Navigator.pop(context),
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
                    context.l1on.save,
                    style: nunitoSansStyle(600, 16, color: Colors.white),
                  ),
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
          ],
        ),
      ),
    );
  }

  void _showGenderBottomSheet() {
    String? tempSelectedGender = _selectedGender;
    TshirtDetail? tempSelectedTshirtSize = _selectedTshirtSize;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: AppTheme.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  context.l1on.chooseGender,
                  style: nunitoSansTitleSmallStyle(
                    context,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 20),
                // Opciones de género - Diseño vertical como distancia
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setModalState(() {
                            tempSelectedGender = context.l1on.male;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: tempSelectedGender == context.l1on.male
                                  ? AppTheme.primary
                                  : AppTheme.grey.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  context.l1on.male,
                                  style: nunitoSansBodySmallStyle(
                                    context,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              if (tempSelectedGender == context.l1on.male)
                                ShaderMask(
                                  shaderCallback: (bounds) => LinearGradient(
                                    colors: [
                                      AppTheme.primary,
                                      AppTheme.secondary,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ).createShader(bounds),
                                  child: const Icon(
                                    Icons.check_circle,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setModalState(() {
                            tempSelectedGender = context.l1on.female;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: tempSelectedGender == context.l1on.female
                                  ? AppTheme.primary
                                  : AppTheme.grey.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  context.l1on.female,
                                  style: nunitoSansBodySmallStyle(
                                    context,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              if (tempSelectedGender == context.l1on.female)
                                ShaderMask(
                                  shaderCallback: (bounds) => LinearGradient(
                                    colors: [
                                      AppTheme.primary,
                                      AppTheme.secondary,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ).createShader(bounds),
                                  child: const Icon(
                                    Icons.check_circle,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_selectedSetting?.isTshirt == true) ...[
                  const SizedBox(height: 24),
                  Text(
                    context.l1on.selectTshirtSize,
                    style: nunitoSansTitleSmallStyle(
                      context,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.grey.withValues(alpha: 0.2),
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: _selectedSetting!.detailsTshirt.map((tshirt) {
                        final isSelected =
                            tempSelectedTshirtSize?.id == tshirt.id;
                        return GestureDetector(
                          onTap: () {
                            setModalState(() {
                              tempSelectedTshirtSize = tshirt;
                            });
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primary
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.primary,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                tshirt.size,
                                style: nunitoSansBodySmallStyle(
                                  context,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : AppTheme.lightModeBlack,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                InkWell(
                  onTap: () {
                    setState(() {
                      _selectedGender = tempSelectedGender;
                      _selectedTshirtSize = tempSelectedTshirtSize;
                    });
                    Navigator.pop(context);
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
                        context.l1on.save,
                        style: nunitoSansStyle(600, 16, color: Colors.white),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomButton() {
    final bool isFinalizingInscription =
        _currentStep == 2 && _registeredParticipants.isNotEmpty;
    final selectedCrossSellItems = _selectedCrossSellItems();
    final finalSummaryTotal = _calculateFinalSummaryTotal();

    // Agrupar participantes por categoría y distancia
    Map<String, Map<String, dynamic>> groupedParticipants = {};

    for (var participant in _registeredParticipants) {
      final key = '${participant['category']} ${participant['distance_km']}';
      final subtotal =
          (participant['base_price'] as double) +
          (participant['tshirt_price'] as double);

      if (groupedParticipants.containsKey(key)) {
        groupedParticipants[key]!['count'] += 1;
        groupedParticipants[key]!['total'] += subtotal;
      } else {
        groupedParticipants[key] = {'count': 1, 'total': subtotal};
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mostrar resumen agrupado solo en paso 2 (resumen final)
          if (_currentStep == 2 && _registeredParticipants.isNotEmpty) ...[
            ...groupedParticipants.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${entry.key} (x${entry.value['count']})',
                      style: nunitoSansStyle(
                        400,
                        14,
                        color: AppTheme.lightModeBlack,
                      ),
                    ),
                    Text(
                      '\$${entry.value['total'].toStringAsFixed(2)}',
                      style: nunitoSansStyle(
                        600,
                        14,
                        color: AppTheme.lightModeBlack,
                      ),
                    ),
                  ],
                ),
              );
            }),
            ...selectedCrossSellItems.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${item.product.name} (x${item.quantity})',
                        style: nunitoSansStyle(
                          400,
                          14,
                          color: AppTheme.lightModeBlack,
                        ),
                      ),
                    ),
                    Text(
                      '\$${item.totalPrice.toStringAsFixed(2)}',
                      style: nunitoSansStyle(
                        600,
                        14,
                        color: AppTheme.lightModeBlack,
                      ),
                    ),
                  ],
                ),
              );
            }),

            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.l1on.totalIncludingVAT,
                    style: nunitoSansStyle(
                      700,
                      16,
                      color: AppTheme.lightModeBlack,
                    ),
                  ),
                  Text(
                    '\$${finalSummaryTotal.toStringAsFixed(2)}',
                    style: nunitoSansStyle(
                      700,
                      16,
                      color: AppTheme.lightModeBlack,
                    ),
                  ),
                ],
              ),
            ),
          ],
          // Botón
          InkWell(
            onTap: () {
              // Forzar eliminación completa del foco
              FocusManager.instance.primaryFocus?.unfocus();
              _dummyFocusNode.requestFocus();
              Future.microtask(() {
                _dummyFocusNode.unfocus();
                if (isFinalizingInscription) {
                  _finalizeInscription();
                } else {
                  _handleInscription();
                }
              });
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
                  _editingParticipantIndex != null
                      ? context.l1on.update
                      : context.l1on.register,
                  style: nunitoSansStyle(600, 16, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _finalizeInscription() {
    // Verificar si la carrera requiere facturación
    log(jsonEncode(widget.competition.toJson()));

    final isApplyInvoice = widget.competition.isApplyInvoice ?? false;

    if (isApplyInvoice) {
      // Navegar a la pantalla de datos de facturación
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => InvoiceDataScreen(
            competition: widget.competition,
            participants: _registeredParticipants,
            extraProducts: _selectedCrossSellItems(),
          ),
        ),
      );
    } else {
      // Ir directamente al checkout sin datos de facturación
      final emptyBillingData = BillingData(
        numeroDocumento: '',
        nombres: '',
        email: '',
        celular: '',
        direccion: '',
        id: '',
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => InscriptionCheckoutScreen(
            competition: widget.competition,
            participants: _registeredParticipants,
            extraProducts: _selectedCrossSellItems(),
            billingData: emptyBillingData,
          ),
        ),
      );
    }
  }

  void _handleInscription() {
    // Asegurar que el foco esté eliminado
    FocusManager.instance.primaryFocus?.unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_validateCurrentStep()) {
      // Guardar los datos del participante con el prefijo del país
      final fullPhoneNumber =
          '${_selectedCountry['code']}${_celularController.text}';

      final participantData = {
        'document_type': _tipoDocumento,
        'dni': _cedulaController.text,
        'fullName': _nombreController.text,
        'email': _emailController.text,
        'phone_full': fullPhoneNumber, // Número completo con prefijo de país
        'phone': _celularController.text, // Número sin prefijo
        'birth_date': _selectedBirthDate?.toIso8601String(),
        'setting_id': _selectedSetting!.id,
        'category': _selectedSetting!.category,
        'distance_id': _selectedDistance!.id,
        'distance_km': _selectedDistance!.km,
        'distance_available_slots': _selectedDistance!.availableSlots,
        'gender': _selectedGender == context.l1on.male ? 'M' : 'F',
        'base_price': _selectedDistance!.price,
        'is_tshirt': _selectedSetting!.isTshirt,
        'tshirt_id': _selectedTshirtSize?.id,
        'tshirt_size': _selectedTshirtSize?.size,
        'tshirt_price': _selectedTshirtSize?.price ?? 0.0,
      };

      if (_editingParticipantIndex != null) {
        // Actualizar participante existente
        _registeredParticipants[_editingParticipantIndex!] = participantData;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Participante actualizado'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        // Agregar nuevo participante
        _registeredParticipants.add(participantData);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${context.l1on.participantAdded} (${_registeredParticipants.length})',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      setState(() {
        _editingParticipantIndex = null;
        _clean();
        _nextStep();
      });
    }
  }

  Widget _buildBirthDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fecha de nacimiento',
          style: nunitoSansStyle(600, 14, color: AppTheme.lightModeBlack),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            FocusManager.instance.primaryFocus?.unfocus();
            _dummyFocusNode.requestFocus();
            Future.microtask(() {
              _dummyFocusNode.unfocus();
              _selectBirthDate(navigatorKey.currentContext!);
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.grey.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _birthDateController.text.isEmpty
                      ? 'Selecciona tu fecha de nacimiento'
                      : _birthDateController.text,
                  style: nunitoSansStyle(
                    400,
                    14,
                    color: _birthDateController.text.isEmpty
                        ? AppTheme.grey
                        : AppTheme.lightModeBlack,
                  ),
                ),
                Icon(Icons.calendar_today, color: AppTheme.grey, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectBirthDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime initialDate =
        _selectedBirthDate ?? DateTime(now.year - 18, now.month, now.day);
    final DateTime firstDate = DateTime(1900);
    final DateTime lastDate = now;

    final DateTime? picked = await showPlatformDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      material: (_, _) => MaterialDatePickerData(
        helpText: 'Selecciona tu fecha de nacimiento',
        cancelText: 'Cancelar',
        confirmText: 'Aceptar',
      ),
      cupertino: (_, _) =>
          CupertinoDatePickerData(mode: CupertinoDatePickerMode.date),
    );

    if (picked != null && picked != _selectedBirthDate) {
      setState(() {
        _selectedBirthDate = picked;
        _birthDateController.text =
            '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }
}
