import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../config/theme/app_theme.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../../data/api/marketplace_api_service.dart';
import '../../../domain/models/marketplace_delivery_data.dart';
import 'marketplace_checkout_screen.dart';

class DeliveryAddressScreen extends StatefulWidget {
  final Map<String, dynamic>? initialAddress;

  const DeliveryAddressScreen({super.key, this.initialAddress});

  @override
  State<DeliveryAddressScreen> createState() => _DeliveryAddressScreenState();
}

class _DeliveryAddressScreenState extends State<DeliveryAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mapController = MapController();

  static const LatLng _defaultCenter = LatLng(-0.180653, -78.467834);
  static const double _minZoom = 6;
  static const double _maxZoom = 18;

  final _mainAddressController = TextEditingController();
  final _secondaryAddressController = TextEditingController();
  final _referenceController = TextEditingController();
  final _cellphoneController = TextEditingController();

  String? _lastAutofilledSecondaryAddress;
  String? _lastAutofilledReference;
  Timer? _addressDebounce;

  List<_EcuadorProvince> _provinces = const [];
  String? _selectedProvince;
  String? _selectedCanton;
  String? _selectedParish;

  LatLng _selectedPoint = _defaultCenter;
  double _currentZoom = 15;

  bool _isLoadingGeoData = true;
  bool _isLoadingLocation = false;
  bool _isResolvingAddress = false;
  bool _isValidatingCoverage = false;
  double _deliveryCost = 0;

  static const Color _primaryGreen = Color(0xFFC0FF00);
  static const Color _screenBg = Color.fromARGB(255, 253, 253, 253);
  static const Color _textDark = Colors.black87;
  static const Color _titleColor = Color.fromARGB(255, 0, 0, 0);

  List<_EcuadorCanton> get _availableCantons {
    if (_selectedProvince == null) return const [];

    final matches = _provinces.where((p) => p.name == _selectedProvince);
    if (matches.isEmpty) return const [];
    return matches.first.cantons;
  }

  List<String> get _availableParishes {
    if (_selectedCanton == null) return const [];

    final matches = _availableCantons.where((c) => c.name == _selectedCanton);
    if (matches.isEmpty) return const [];
    return matches.first.parishes;
  }

  Future<void> _calculateDeliveryCost() async {
    try {
      final result = await MarketplaceApiService.validateCoverageZone(
        lat: _selectedPoint.latitude,
        lng: _selectedPoint.longitude,
      );

      if (!mounted) return;

      final covered = result['covered'] == true;
      final data = result['data'];
      final hasZones = data is List && data.isNotEmpty;

      if (covered && hasZones) {
        final zone = data.first as Map<String, dynamic>;
        final value = zone['value'];
        setState(() {
          _deliveryCost = value is num ? value.toDouble() : 0.0;
        });
      } else {
        setState(() => _deliveryCost = 0);
      }
    } catch (_) {
      if (mounted) setState(() => _deliveryCost = 0);
    }
  }

  void _showNoCoverageDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    // ignore: deprecated_member_use
                    color: AppTheme.primary600.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.location_off_outlined,
                    color: AppTheme.gbDark600,
                    size: 35,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Sin cobertura",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.gbDark600,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Lo sentimos, no tenemos cobertura en esta zona. Intenta con otra ubicación.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.3,
                    color: AppTheme.primary900,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary600,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      "Entendido",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _initScreen();
  }

  Future<void> _initScreen() async {
    await _loadEcuadorGeography();

    if (!mounted) return;

    if (widget.initialAddress != null) {
      _loadInitialAddress(widget.initialAddress!);
    } else {
      _bootstrapUserLocation();
    }
  }

  @override
  void dispose() {
    _addressDebounce?.cancel();
    _mainAddressController.dispose();
    _secondaryAddressController.dispose();
    _referenceController.dispose();
    _cellphoneController.dispose();
    super.dispose();
  }

  void _loadInitialAddress(Map<String, dynamic> address) {
    final lat = _toDouble(address['latitud']) ?? _defaultCenter.latitude;
    final lng = _toDouble(address['longitud']) ?? _defaultCenter.longitude;

    final direccion = address['direccion']?.toString() ?? '';
    final ciudad = address['ciudad']?.toString() ?? '';
    final detalle = address['detalle']?.toString() ?? '';
    final referencia = address['referencia']?.toString() ?? '';

    final provincia = _extractDetailValue(detalle, 'Provincia');
    final canton = _extractDetailValue(detalle, 'Cantón');
    final parroquia = _extractDetailValue(detalle, 'Parroquia');
    final calleSecundaria =
        _extractDetailValue(detalle, 'Calle secundaria') ?? '';

    setState(() {
      _selectedPoint = LatLng(lat, lng);
      _currentZoom = 16;

      _mainAddressController.text = direccion;
      _secondaryAddressController.text = calleSecundaria;
      _referenceController.text = referencia;

      _selectedProvince = provincia;
      _selectedCanton = canton;
      _selectedParish = parroquia;
    });

    _calculateDeliveryCost();

    _normalizeInitialAdministrativeData();

    if (_selectedProvince == null ||
        _selectedCanton == null ||
        _selectedParish == null) {
      _autoSelectFromCity('$direccion $ciudad $detalle');
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _mapController.move(_selectedPoint, _currentZoom);
    });
  }

  ////////////////
  void _autoSelectFromCity(String ciudad) {
    final normalizedCity = _normalize(ciudad);

    for (final province in _provinces) {
      for (final canton in province.cantons) {
        if (_normalize(canton.name).contains(normalizedCity) ||
            normalizedCity.contains(_normalize(canton.name))) {
          setState(() {
            _selectedProvince = province.name;
            _selectedCanton = canton.name;
            _selectedParish = null;
          });
          return;
        }

        for (final parish in canton.parishes) {
          if (_normalize(parish).contains(normalizedCity) ||
              normalizedCity.contains(_normalize(parish))) {
            setState(() {
              _selectedProvince = province.name;
              _selectedCanton = canton.name;
              _selectedParish = parish;
            });
            return;
          }
        }
      }
    }
  }

  //////////////////
  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString());
  }

  String? _extractDetailValue(dynamic detail, String key) {
    if (detail == null) return null;

    final parts = detail.toString().split('|');

    for (final part in parts) {
      final clean = part.trim();

      if (clean.toLowerCase().startsWith(key.toLowerCase())) {
        return clean.split(':').skip(1).join(':').trim();
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _screenBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Dirección de Entrega',
          style: TextStyle(color: _titleColor, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: _isLoadingGeoData
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  Text(
                    'Completa la información para recibir tu pedido de forma rápida y segura.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildMapCard(),
                  const SizedBox(height: 12),
                  _buildMapCoordinates(),
                  const SizedBox(height: 16),
                  _buildSelectorField(
                    label: 'Provincia',
                    value: _selectedProvince,
                    hint: 'Seleccione una provincia',
                    items: _provinces.map((p) => p.name).toList(),
                    onChanged: (value) async {
                      setState(() {
                        _selectedProvince = value;
                        _selectedCanton = null;
                        _selectedParish = null;
                      });

                      await _movePinToSelectedAddress();
                    },
                    validator: (value) =>
                        value == null ? 'Selecciona una provincia' : null,
                  ),
                  const SizedBox(height: 12),
                  _buildSelectorField(
                    label: 'Cantón',
                    value: _selectedCanton,
                    hint: 'Seleccione un cantón',
                    items: _availableCantons.map((c) => c.name).toList(),
                    onChanged: (value) async {
                      setState(() {
                        _selectedCanton = value;
                        _selectedParish = null;
                      });

                      await _movePinToSelectedAddress();
                    },
                    validator: (value) =>
                        value == null ? 'Selecciona un cantón' : null,
                  ),
                  const SizedBox(height: 12),
                  _buildSelectorField(
                    label: 'Parroquia',
                    value: _selectedParish,
                    hint: 'Seleccione una parroquia',
                    items: _availableParishes,
                    onChanged: (value) async {
                      setState(() {
                        _selectedParish = value;
                      });

                      await _movePinToSelectedAddress();
                    },
                    validator: (value) =>
                        value == null ? 'Selecciona una parroquia' : null,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _mainAddressController,
                    label: 'Calle principal y numeración',
                    hintText: 'Ej. Av. Amazonas N32-121',
                    onChanged: (_) => _scheduleAddressSearch(),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Ingresa la dirección principal';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _secondaryAddressController,
                    label: 'Calle secundaria (opcional)',
                    hintText: 'Ej. Juan de Dios Morales',
                    onChanged: (_) => _scheduleAddressSearch(),
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _referenceController,
                    label: 'Referencia',
                    hintText:
                        'Ej. Casa blanca de dos pisos junto a la panadería',
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  _buildPhoneRow(),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isValidatingCoverage
                          ? null
                          : _continueToCheckout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryGreen,
                        foregroundColor: Colors.black,
                        elevation: 0,
                        minimumSize: const Size.fromHeight(54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isValidatingCoverage
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.black,
                              ),
                            )
                          : const Text(
                              'Continuar',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildMapCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 190,
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _selectedPoint,
                initialZoom: _currentZoom,
                onTap: (_, point) => _onMapPointSelected(point),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key=IFKmcfDiLxVQTsl7buR9',
                  userAgentPackageName: 'com.hoor.app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedPoint,
                      width: 70,
                      height: 70,
                      child: Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.black,
                                  width: 1.5,
                                ),
                              ),
                            ),

                            const Icon(
                              Icons.location_on,
                              size: 38,
                              color: Color.fromARGB(255, 3, 15, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Positioned(
              left: 12,
              top: 12,
              right: 12,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Toca el mapa para seleccionar la ubicación exacta',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          height: 1.20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  ElevatedButton.icon(
                    onPressed: _isLoadingLocation
                        ? null
                        : _bootstrapUserLocation,
                    icon: _isLoadingLocation
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : const Icon(Icons.my_location, size: 16),
                    label: const Text(
                      'Mi ubicación',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryGreen,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 12,
              bottom: 12,
              child: Column(
                children: [
                  _buildMapActionButton(icon: Icons.add, onTap: _zoomIn),
                  const SizedBox(height: 8),
                  _buildMapActionButton(icon: Icons.remove, onTap: _zoomOut),
                ],
              ),
            ),
            if (_isResolvingAddress)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.10),
                  alignment: Alignment.center,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Autocompletando dirección...',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: _textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapActionButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: _textDark),
        ),
      ),
    );
  }

  Widget _buildMapCoordinates() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.pin_drop_outlined, color: _primaryGreen),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Lat: ${_selectedPoint.latitude.toStringAsFixed(6)} | Lng: ${_selectedPoint.longitude.toStringAsFixed(6)}',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectorField({
    required String label,
    required String? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required String? Function(String?) validator,
  }) {
    return DropdownButtonFormField<String>(
      // ignore: deprecated_member_use
      value: items.contains(value) ? value : null,
      isExpanded: true,
      menuMaxHeight: 250,

      icon: Icon(
        Icons.keyboard_arrow_down_rounded,
        color: Colors.grey.shade600,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: _textDark,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        floatingLabelStyle: const TextStyle(
          color: _textDark,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(color: _primaryGreen, width: 1.5),
        ),
      ),
      hint: Text(
        hint,
        style: TextStyle(
          color: Colors.grey.shade500,
          fontWeight: FontWeight.w400,
        ),
      ),
      items: items
          .map(
            (item) => DropdownMenuItem<String>(
              value: item,
              child: Text(item, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: onChanged,
      validator: validator,
    );
  }

  Widget _buildPhoneRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'CONTACTO DE ENTREGA',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: _textDark,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Text(
                '+593',
                style: TextStyle(color: _textDark, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: _cellphoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(9),
                ],
                autovalidateMode: AutovalidateMode.onUserInteraction,
                decoration: InputDecoration(
                  hintText: '099888777',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w400,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(14)),
                    borderSide: BorderSide(color: _primaryGreen, width: 1.5),
                  ),
                ),
                validator: (value) {
                  final digits = (value ?? '').trim();
                  if (digits.isEmpty) {
                    return 'Ingresa el número de contacto';
                  }
                  if (digits.length != 9) {
                    return 'Ingresa 9 dígitos';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        labelStyle: const TextStyle(
          color: _textDark,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        floatingLabelStyle: const TextStyle(
          color: _textDark,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        hintStyle: TextStyle(
          color: Colors.grey.shade500,
          fontWeight: FontWeight.w400,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(color: _primaryGreen, width: 1.5),
        ),
      ),
      validator: validator,
    );
  }

  Future<void> _continueToCheckout() async {
    FocusManager.instance.primaryFocus?.unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final phoneDigits = _cellphoneController.text.trim();
    final deliveryData = MarketplaceDeliveryData.fromForm(
      province: _selectedProvince ?? '',
      canton: _selectedCanton ?? '',
      parish: _selectedParish ?? '',
      mainAddress: _mainAddressController.text,
      secondaryAddress: _secondaryAddressController.text,
      reference: _referenceController.text,
      cellphone: '+593$phoneDigits',
      lat: _selectedPoint.latitude.toStringAsFixed(6),
      lng: _selectedPoint.longitude.toStringAsFixed(6),
    );

    setState(() => _isValidatingCoverage = true);
    try {
      await _calculateDeliveryCost();
    } finally {
      if (mounted) setState(() => _isValidatingCoverage = false);
    }

    if (!mounted) return;

    if (_deliveryCost <= 0) {
      _showNoCoverageDialog();
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MarketplaceCheckoutScreen(
          deliveryData: deliveryData,
          deliveryFee: _deliveryCost,
        ),
      ),
    );
  }

  Future<void> _loadEcuadorGeography() async {
    try {
      final raw = await rootBundle.loadString(
        'assets/json/ecuador/provincias.json',
      );

      final List<dynamic> decoded = json.decode(raw) as List<dynamic>;

      final provinces = decoded
          .whereType<Map>()
          .map(
            (rawProvince) => _EcuadorProvince.fromJson(
              Map<String, dynamic>.from(rawProvince),
            ),
          )
          .toList();

      if (!mounted) return;

      setState(() {
        _provinces = provinces;
        _isLoadingGeoData = false;
      });

      // if (widget.initialAddress != null) {
      //   _normalizeInitialAdministrativeData();
      // }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoadingGeoData = false;
      });

      _showSnackBar(
        'No se pudo cargar el catálogo de ubicaciones de Ecuador',
        isError: true,
      );
    }
  }

  void _normalizeInitialAdministrativeData() {
    final matchedProvince = _matchName(
      _provinces.map((p) => p.name).toList(),
      _selectedProvince ?? '',
    );

    if (matchedProvince == null) return;

    final province = _provinces.firstWhere((p) => p.name == matchedProvince);

    final matchedCanton = _matchName(
      province.cantons.map((c) => c.name).toList(),
      _selectedCanton ?? '',
    );

    String? matchedParish;

    if (matchedCanton != null) {
      final canton = province.cantons.firstWhere(
        (c) => c.name == matchedCanton,
      );

      matchedParish = _matchName(canton.parishes, _selectedParish ?? '');
    }

    setState(() {
      _selectedProvince = matchedProvince;
      _selectedCanton = matchedCanton;
      _selectedParish = matchedParish;
    });
  }

  Future<void> _bootstrapUserLocation() async {
    if (_isLoadingLocation) return;

    setState(() => _isLoadingLocation = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        _showSnackBar(
          'Activa la ubicación para seleccionar la dirección exacta',
          isError: true,
        );
        return;
      }

      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showSnackBar('No se concedió permiso de ubicación', isError: true);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final point = LatLng(position.latitude, position.longitude);

      await _onMapPointSelected(point, moveMap: true);
    } catch (_) {
      _showSnackBar(
        'No se pudo obtener tu ubicación. Puedes seleccionarla en el mapa.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  Future<void> _onMapPointSelected(LatLng point, {bool moveMap = true}) async {
    setState(() {
      _selectedPoint = point;
    });

    if (moveMap) {
      _currentZoom = 16;
      _mapController.move(point, _currentZoom);
    }

    await _reverseGeocodeAndAutofill(point);

    await _calculateDeliveryCost();
  }

  void _zoomIn() {
    _currentZoom = (_currentZoom + 1).clamp(_minZoom, _maxZoom);
    _mapController.move(_selectedPoint, _currentZoom);
    setState(() {});
  }

  void _zoomOut() {
    _currentZoom = (_currentZoom - 1).clamp(_minZoom, _maxZoom);
    _mapController.move(_selectedPoint, _currentZoom);
    setState(() {});
  }

  Future<void> _movePinToSelectedAddress() async {
    final attempts = <String>[];

    final mainAddress = _mainAddressController.text.trim();
    final secondaryAddress = _secondaryAddressController.text.trim();

    final province = _selectedProvince?.trim() ?? '';
    final canton = _selectedCanton?.trim() ?? '';
    final parish = _selectedParish?.trim() ?? '';

    if (province.isEmpty) return;

    final fullAddressParts = <String>[
      if (mainAddress.isNotEmpty) mainAddress,
      if (secondaryAddress.isNotEmpty) secondaryAddress,
      if (parish.isNotEmpty) parish,
      if (canton.isNotEmpty) canton,
      if (province.isNotEmpty) province,
      'Ecuador',
    ];

    attempts.add(fullAddressParts.join(', '));

    if (mainAddress.isNotEmpty) {
      attempts.add(
        [
          mainAddress,
          if (parish.isNotEmpty) parish,
          if (canton.isNotEmpty) canton,
          province,
          'Ecuador',
        ].join(', '),
      );
    }

    if (parish.isNotEmpty && canton.isNotEmpty) {
      attempts.add('$parish, $canton, $province, Ecuador');
    }

    if (canton.isNotEmpty) {
      attempts.add('$canton, $province, Ecuador');
    }

    attempts.add('$province, Ecuador');

    final uniqueAttempts = attempts.toSet().toList();

    for (final query in uniqueAttempts) {
      final point = await _searchPointWithNominatim(query);

      if (point != null) {
        if (!mounted) return;

        setState(() {
          _selectedPoint = point;
          _currentZoom = mainAddress.isNotEmpty
              ? 16
              : parish.isNotEmpty
              ? 15
              : canton.isNotEmpty
              ? 13
              : 9;
        });

        _mapController.move(point, _currentZoom);
        return;
      }
    }

    _showSnackBar('No se pudo ubicar esa dirección en el mapa', isError: true);
  }

  Future<LatLng?> _searchPointWithNominatim(String query) async {
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': query,
        'format': 'jsonv2',
        'limit': '1',
        'countrycodes': 'ec',
        'accept-language': 'es',
      });

      final response = await http
          .get(
            uri,
            headers: {'User-Agent': 'hoor_app/1.0 (delivery-screen-search)'},
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      final decoded = json.decode(response.body);

      if (decoded is! List || decoded.isEmpty) {
        return null;
      }

      final first = decoded.first;

      if (first is! Map<String, dynamic>) {
        return null;
      }

      final lat = double.tryParse(first['lat']?.toString() ?? '');
      final lon = double.tryParse(first['lon']?.toString() ?? '');

      if (lat == null || lon == null) return null;

      return LatLng(lat, lon);
    } catch (_) {
      return null;
    }
  }

  void _scheduleAddressSearch() {
    _addressDebounce?.cancel();
    _addressDebounce = Timer(const Duration(milliseconds: 700), () async {
      await _movePinToSelectedAddress();
    });
  }

  Future<void> _reverseGeocodeAndAutofill(LatLng point) async {
    if (_isResolvingAddress) return;

    setState(() => _isResolvingAddress = true);

    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
        'format': 'jsonv2',
        'lat': point.latitude.toString(),
        'lon': point.longitude.toString(),
        'zoom': '18',
        'addressdetails': '1',
        'accept-language': 'es',
      });

      final response = await http
          .get(uri, headers: {'User-Agent': 'hoor_app/1.0 (delivery-screen)'})
          .timeout(const Duration(seconds: 12));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return;
      }

      final decoded = json.decode(response.body);

      if (decoded is! Map<String, dynamic>) {
        return;
      }

      final address = decoded['address'];

      if (address is! Map<String, dynamic>) {
        return;
      }

      final mainAddress = _buildMainAddress(address);

      if (mainAddress.isNotEmpty) {
        _mainAddressController.text = mainAddress;
      }

      final secondaryAddress =
          address['neighbourhood']?.toString() ??
          address['suburb']?.toString() ??
          '';

      _applyAutofillValue(
        controller: _secondaryAddressController,
        nextValue: secondaryAddress,
        lastAutofilledValue: _lastAutofilledSecondaryAddress,
        onValueApplied: (value) => _lastAutofilledSecondaryAddress = value,
      );

      final displayName = decoded['display_name']?.toString() ?? '';

      _applyAutofillValue(
        controller: _referenceController,
        nextValue: displayName,
        lastAutofilledValue: _lastAutofilledReference,
        onValueApplied: (value) => _lastAutofilledReference = value,
      );

      final provinceCandidate =
          address['state']?.toString() ?? address['region']?.toString() ?? '';
      final cantonCandidate =
          address['county']?.toString() ??
          address['city']?.toString() ??
          address['town']?.toString() ??
          '';
      final parishCandidate =
          address['city_district']?.toString() ??
          address['suburb']?.toString() ??
          address['village']?.toString() ??
          '';

      _tryAutoSelectAdministrativeData(
        provinceCandidate: provinceCandidate,
        cantonCandidate: cantonCandidate,
        parishCandidate: parishCandidate,
      );
    } catch (_) {
      // El usuario puede completar manualmente.
    } finally {
      if (mounted) {
        setState(() => _isResolvingAddress = false);
      }
    }
  }

  String _buildMainAddress(Map<String, dynamic> address) {
    final road = address['road']?.toString() ?? '';
    final houseNumber = address['house_number']?.toString() ?? '';
    final combined = '$road ${houseNumber.trim()}'.trim();

    if (combined.isNotEmpty) {
      return combined;
    }

    return address['pedestrian']?.toString() ??
        address['residential']?.toString() ??
        '';
  }

  void _applyAutofillValue({
    required TextEditingController controller,
    required String nextValue,
    required String? lastAutofilledValue,
    required ValueChanged<String?> onValueApplied,
  }) {
    final currentValue = controller.text.trim();
    final normalizedNextValue = nextValue.trim();

    final canReplaceCurrentValue =
        currentValue.isEmpty || currentValue == (lastAutofilledValue ?? '');

    if (!canReplaceCurrentValue) return;

    controller.text = normalizedNextValue;
    onValueApplied(normalizedNextValue.isEmpty ? null : normalizedNextValue);
  }

  void _tryAutoSelectAdministrativeData({
    required String provinceCandidate,
    required String cantonCandidate,
    required String parishCandidate,
  }) {
    String? matchedProvince = _matchName(
      _provinces.map((p) => p.name).toList(),
      provinceCandidate,
    );

    if (matchedProvince == null && _provinces.isNotEmpty) {
      matchedProvince = _matchName(
        _provinces.map((p) => p.name).toList(),
        cantonCandidate,
      );
    }

    if (matchedProvince == null) return;

    final provinceMatches = _provinces.where((p) => p.name == matchedProvince);
    if (provinceMatches.isEmpty) return;

    final province = provinceMatches.first;

    final matchedCanton = _matchName(
      province.cantons.map((c) => c.name).toList(),
      cantonCandidate,
    );

    String? matchedParish;

    if (matchedCanton != null) {
      final cantonMatches = province.cantons.where(
        (c) => c.name == matchedCanton,
      );

      if (cantonMatches.isNotEmpty) {
        matchedParish = _matchName(
          cantonMatches.first.parishes,
          parishCandidate,
        );
      }
    }

    setState(() {
      _selectedProvince = matchedProvince;
      _selectedCanton = matchedCanton;
      _selectedParish = matchedParish;
    });
  }

  String? _matchName(List<String> candidates, String rawValue) {
    if (rawValue.trim().isEmpty) return null;

    final normalizedRaw = _normalize(rawValue);

    if (normalizedRaw.isEmpty) return null;

    for (final candidate in candidates) {
      if (_normalize(candidate) == normalizedRaw) {
        return candidate;
      }
    }

    for (final candidate in candidates) {
      final normalizedCandidate = _normalize(candidate);

      if (normalizedCandidate.contains(normalizedRaw) ||
          normalizedRaw.contains(normalizedCandidate)) {
        return candidate;
      }
    }

    return null;
  }

  String _normalize(String value) {
    final lower = value.toLowerCase().trim();

    const accentsMap = {
      'á': 'a',
      'é': 'e',
      'í': 'i',
      'ó': 'o',
      'ú': 'u',
      'ä': 'a',
      'ë': 'e',
      'ï': 'i',
      'ö': 'o',
      'ü': 'u',
      'à': 'a',
      'è': 'e',
      'ì': 'i',
      'ò': 'o',
      'ù': 'u',
      'â': 'a',
      'ê': 'e',
      'î': 'i',
      'ô': 'o',
      'û': 'u',
      'ñ': 'n',
    };

    var normalized = lower;

    accentsMap.forEach((key, value) {
      normalized = normalized.replaceAll(key, value);
    });

    return normalized
        .replaceAll(RegExp(r'[^a-z0-9 ]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
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
}

class _EcuadorProvince {
  const _EcuadorProvince({required this.name, required this.cantons});

  final String name;
  final List<_EcuadorCanton> cantons;

  factory _EcuadorProvince.fromJson(Map<String, dynamic> json) {
    final rawCantons = json['cantones'];

    final cantons = rawCantons is List
        ? rawCantons
              .whereType<Map>()
              .map(
                (raw) =>
                    _EcuadorCanton.fromJson(Map<String, dynamic>.from(raw)),
              )
              .toList()
        : const <_EcuadorCanton>[];

    return _EcuadorProvince(
      name: json['nombre']?.toString() ?? '',
      cantons: cantons,
    );
  }
}

class _EcuadorCanton {
  const _EcuadorCanton({required this.name, required this.parishes});

  final String name;
  final List<String> parishes;

  factory _EcuadorCanton.fromJson(Map<String, dynamic> json) {
    final rawParishes = json['parroquias'];

    final parishes = rawParishes is List
        ? rawParishes.map((e) => e.toString()).toList()
        : const <String>[];

    return _EcuadorCanton(
      name: json['nombre']?.toString() ?? '',
      parishes: parishes,
    );
  }
}
