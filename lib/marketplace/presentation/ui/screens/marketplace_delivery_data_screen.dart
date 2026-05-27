import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../../config/theme/marketplace_theme.dart';
import '../../../data/api/marketplace_api_service.dart';
import '../../../domain/models/marketplace_delivery_data.dart';
import 'marketplace_checkout_screen.dart';

class MarketplaceDeliveryDataScreen extends StatefulWidget {
  const MarketplaceDeliveryDataScreen({super.key});

  @override
  State<MarketplaceDeliveryDataScreen> createState() =>
      _MarketplaceDeliveryDataScreenState();
}

class _MarketplaceDeliveryDataScreenState
    extends State<MarketplaceDeliveryDataScreen> {
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

  List<_EcuadorCanton> get _availableCantons {
    if (_selectedProvince == null) return const [];

    final province = _provinces
        .where((p) => p.name == _selectedProvince)
        .firstOrNull;
    return province?.cantons ?? const [];
  }

  List<String> get _availableParishes {
    if (_selectedCanton == null) return const [];

    final canton = _availableCantons
        .where((c) => c.name == _selectedCanton)
        .firstOrNull;
    return canton?.parishes ?? const [];
  }

  @override
  void initState() {
    super.initState();
    _loadEcuadorGeography();
    _bootstrapUserLocation();
  }

  @override
  void dispose() {
    _mainAddressController.dispose();
    _secondaryAddressController.dispose();
    _referenceController.dispose();
    _cellphoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MarketplaceTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Dirección de entrega',
          style: MarketplaceTheme.titleLargeTextStyle(
            context,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: _isLoadingGeoData
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Completa la información para recibir tu pedido de forma rápida y segura.',
                    style: MarketplaceTheme.bodyMediumTextStyle(
                      context,
                      color: MarketplaceTheme.gbDark600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildMapCard(context),
                  const SizedBox(height: 12),
                  _buildMapCoordinates(context),
                  const SizedBox(height: 16),
                  _buildSelectorField(
                    label: 'Provincia',
                    value: _selectedProvince,
                    hint: 'Seleccione una provincia',
                    items: _provinces.map((p) => p.name).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedProvince = value;
                        _selectedCanton = null;
                        _selectedParish = null;
                      });
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
                    onChanged: (value) {
                      setState(() {
                        _selectedCanton = value;
                        _selectedParish = null;
                      });
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
                    onChanged: (value) {
                      setState(() {
                        _selectedParish = value;
                      });
                    },
                    validator: (value) =>
                        value == null ? 'Selecciona una parroquia' : null,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _mainAddressController,
                    label: 'Calle principal y numeración',
                    hintText: 'Ej. Av. Amazonas N32-121',
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
                  _buildPhoneRow(context),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _isValidatingCoverage
                        ? null
                        : _continueToCheckout,
                    style: FilledButton.styleFrom(
                      backgroundColor: MarketplaceTheme.primary,
                      foregroundColor: Colors.white,
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
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Continuar',
                            style: MarketplaceTheme.bodyMediumTextStyle(
                              context,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  Widget _buildMapCard(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 210,
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
                  userAgentPackageName: 'com.magdata.tenorioApp',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedPoint,
                      width: 48,
                      height: 48,
                      child: const Icon(
                        Icons.location_on,
                        size: 42,
                        color: MarketplaceTheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Positioned(
              left: 12,
              right: 12,
              top: 12,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.58),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Toca el mapa para seleccionar la ubicación exacta',
                        style: MarketplaceTheme.bodySmallTextStyle(
                          context,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _isLoadingLocation
                        ? null
                        : _bootstrapUserLocation,
                    icon: _isLoadingLocation
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.my_location, size: 16),
                    label: Text(
                      'Mi ubicación',
                      style: MarketplaceTheme.bodySmallTextStyle(
                        context,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: MarketplaceTheme.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
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
                  _buildZoomButton(
                    context: context,
                    icon: Icons.add,
                    onPressed: _zoomIn,
                  ),
                  const SizedBox(height: 8),
                  _buildZoomButton(
                    context: context,
                    icon: Icons.remove,
                    onPressed: _zoomOut,
                  ),
                ],
              ),
            ),
            if (_isResolvingAddress)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.12),
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Autocompletando dirección...',
                          style: MarketplaceTheme.bodySmallTextStyle(
                            context,
                            fontWeight: FontWeight.w700,
                            color: MarketplaceTheme.secondayBlack,
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

  Widget _buildZoomButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onPressed,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: MarketplaceTheme.secondayBlack),
        ),
      ),
    );
  }

  Widget _buildMapCoordinates(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.pin_drop_outlined, color: MarketplaceTheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Lat: ${_selectedPoint.latitude.toStringAsFixed(6)} | Lng: ${_selectedPoint.longitude.toStringAsFixed(6)}',
              style: MarketplaceTheme.bodySmallTextStyle(
                context,
                color: MarketplaceTheme.gbDark600,
                fontWeight: FontWeight.w600,
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
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: MarketplaceTheme.bodyMediumTextStyle(
          context,
          color: MarketplaceTheme.gbDark600,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: Colors.white,
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
      hint: Text(
        hint,
        style: MarketplaceTheme.bodyMediumTextStyle(
          context,
          color: MarketplaceTheme.gbDark600.withValues(alpha: 0.7),
          fontWeight: FontWeight.w400,
        ),
      ),
      items: [
        for (final item in items)
          DropdownMenuItem<String>(
            value: item,
            child: Text(item, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: onChanged,
      validator: validator,
    );
  }

  Widget _buildPhoneRow(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contacto de entrega',
          style: MarketplaceTheme.bodySmallTextStyle(
            context,
            color: MarketplaceTheme.gbDark600,
            fontWeight: FontWeight.w700,
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
              child: Text(
                '+593',
                style: MarketplaceTheme.bodyMediumTextStyle(
                  context,
                  color: MarketplaceTheme.secondayBlack,
                  fontWeight: FontWeight.w700,
                ),
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
                  hintStyle: MarketplaceTheme.bodyMediumTextStyle(
                    context,
                    color: MarketplaceTheme.gbDark600.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w400,
                  ),
                  filled: true,
                  fillColor: Colors.white,
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
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        labelStyle: MarketplaceTheme.bodyMediumTextStyle(
          context,
          color: MarketplaceTheme.gbDark600,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: MarketplaceTheme.bodyMediumTextStyle(
          context,
          color: MarketplaceTheme.gbDark600.withValues(alpha: 0.7),
          fontWeight: FontWeight.w400,
        ),
        filled: true,
        fillColor: Colors.white,
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
    double deliveryFee = 0;
    try {
      final result = await MarketplaceApiService.validateCoverageZone(
        lat: _selectedPoint.latitude,
        lng: _selectedPoint.longitude,
      );
      if (!mounted) return;

      final covered = result['covered'] == true;
      final data = result['data'];
      final hasZones = data is List && data.isNotEmpty;

      if (!covered || !hasZones) {
        _showNoCoverageDialog();
        return;
      }

      final zone = data.first as Map<String, dynamic>;
      final value = zone['value'];
      deliveryFee = value is num ? value.toDouble() : 0.0;
    } catch (_) {
      // Si falla la validación dejamos pasar con fee 0
    } finally {
      if (mounted) setState(() => _isValidatingCoverage = false);
    }

    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MarketplaceCheckoutScreen(
          deliveryData: deliveryData,
          deliveryFee: deliveryFee,
        ),
      ),
    );
  }

  void _showNoCoverageDialog() {
    showDialog<void>(
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
                  color: Colors.orange.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.location_off_outlined,
                  size: 38,
                  color: Colors.orange.shade700,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Sin cobertura',
                textAlign: TextAlign.center,
                style: MarketplaceTheme.titleMediumTextStyle(
                  context,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Lo sentimos, no tenemos cobertura en esta zona. Intenta con otra ubicación.',
                textAlign: TextAlign.center,
                style: MarketplaceTheme.bodyMediumTextStyle(context),
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
                    'Entendido',
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
          .get(
            uri,
            headers: {'User-Agent': 'running_app/1.0 (marketplace-delivery)'},
          )
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
      // Ignora fallos de red: el usuario puede completar manualmente.
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

    if (!canReplaceCurrentValue) {
      return;
    }

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

    if (matchedProvince == null) {
      return;
    }

    final province = _provinces
        .where((p) => p.name == matchedProvince)
        .firstOrNull;
    if (province == null) {
      return;
    }

    final matchedCanton = _matchName(
      province.cantons.map((c) => c.name).toList(),
      cantonCandidate,
    );

    String? matchedParish;
    if (matchedCanton != null) {
      final canton = province.cantons
          .where((c) => c.name == matchedCanton)
          .firstOrNull;
      matchedParish = _matchName(canton?.parishes ?? const [], parishCandidate);
    }

    setState(() {
      _selectedProvince = matchedProvince;
      _selectedCanton = matchedCanton;
      _selectedParish = matchedParish;
    });
  }

  String? _matchName(List<String> candidates, String rawValue) {
    if (rawValue.trim().isEmpty) {
      return null;
    }

    final normalizedRaw = _normalize(rawValue);
    if (normalizedRaw.isEmpty) {
      return null;
    }

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
    const withAccents = 'áéíóúäëïöüàèìòùâêîôûñ';
    const withoutAccents = 'aeiouaeiouaeiouaeioun';

    var normalized = lower;
    for (var i = 0; i < withAccents.length; i++) {
      normalized = normalized.replaceAll(withAccents[i], withoutAccents[i]);
    }

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
