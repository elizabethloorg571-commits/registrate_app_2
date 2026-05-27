import 'package:flutter/material.dart';

import '../../domain/models/marketplace_category.dart';
import '/config/theme/app_theme.dart';
import 'marketplace_button.dart';

/// Modelo para los filtros del marketplace
class MarketplaceFilters {
  MarketplaceFilters({
    this.category,
    this.subCategory,
    this.minPrice,
    this.maxPrice,
    this.sortBy,
    this.inStockOnly,
    this.onSaleOnly,
    this.tags,
  });
  final String? category;
  final String? subCategory;
  final double? minPrice;
  final double? maxPrice;
  final String? sortBy;
  final bool? inStockOnly;
  final bool? onSaleOnly;
  final List<String>? tags;

  MarketplaceFilters copyWith({
    String? category,
    bool clearCategory = false,
    String? subCategory,
    bool clearSubCategory = false,
    double? minPrice,
    double? maxPrice,
    String? sortBy,
    bool? inStockOnly,
    bool? onSaleOnly,
    List<String>? tags,
  }) {
    return MarketplaceFilters(
      category: clearCategory ? null : (category ?? this.category),
      subCategory: clearSubCategory ? null : (subCategory ?? this.subCategory),
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      sortBy: sortBy ?? this.sortBy,
      inStockOnly: inStockOnly ?? this.inStockOnly,
      onSaleOnly: onSaleOnly ?? this.onSaleOnly,
      tags: tags ?? this.tags,
    );
  }

  /// Verificar si hay filtros activos
  bool get hasActiveFilters {
    return category != null ||
        subCategory != null ||
        minPrice != null ||
        maxPrice != null ||
        (inStockOnly ?? false) ||
        (onSaleOnly ?? false) ||
        (tags != null && tags!.isNotEmpty);
  }

  /// Contar filtros activos
  int get activeFiltersCount {
    int count = 0;
    if (category != null) count++;
    if (subCategory != null) count++;
    if (minPrice != null || maxPrice != null) count++;
    if (inStockOnly ?? false) count++;
    if (onSaleOnly ?? false) count++;
    if (tags != null && tags!.isNotEmpty) count += tags!.length;
    return count;
  }

  /// Limpiar todos los filtros
  MarketplaceFilters clear() {
    return MarketplaceFilters();
  }
}

/// Bottom Sheet para filtros avanzados del marketplace
class FiltersBottomSheet extends StatefulWidget {
  const FiltersBottomSheet({
    super.key,
    required this.initialFilters,
    required this.categories,
    this.hideOnSaleFilter = false,
  });
  final MarketplaceFilters initialFilters;
  final List<MarketplaceCategory> categories;
  final bool hideOnSaleFilter;

  @override
  State<FiltersBottomSheet> createState() => _FiltersBottomSheetState();
}

class _FiltersBottomSheetState extends State<FiltersBottomSheet> {
  late MarketplaceFilters _filters;
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();

  final List<String> _availableTags = [
    'Nuevo',
    'Destacado',
    'Mejor vendido',
    'Oferta',
  ];

  @override
  void initState() {
    super.initState();
    _filters = widget.initialFilters;
    _minPriceController.text = _filters.minPrice != null
        ? _filters.minPrice.toString()
        : '';
    _maxPriceController.text = _filters.maxPrice != null
        ? _filters.maxPrice.toString()
        : '';
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    // Actualizar precios desde los controladores
    final minPrice = double.tryParse(_minPriceController.text);
    final maxPrice = double.tryParse(_maxPriceController.text);

    _filters = _filters.copyWith(minPrice: minPrice, maxPrice: maxPrice);

    Navigator.pop(context, _filters);
  }

  void _clearFilters() {
    setState(() {
      _filters = MarketplaceFilters();
      _minPriceController.clear();
      _maxPriceController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filtros',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                TextButton(
                  onPressed: _clearFilters,
                  child: const Text(
                    'Limpiar todo',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCategorySection(),
                  const SizedBox(height: 24),
                  _buildPriceRangeSection(),
                  const SizedBox(height: 24),
                  _buildSortSection(),
                  const SizedBox(height: 24),
                  _buildAvailabilitySection(),
                  const SizedBox(height: 24),
                  _buildTagsSection(),
                ],
              ),
            ),
          ),

          // Footer con botones
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: MarketplaceButton(
                      text: 'Cancelar',
                      variant: MarketplaceButtonVariant.outline,
                      size: MarketplaceButtonSize.large,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: MarketplaceButton(
                      text: _filters.hasActiveFilters
                          ? 'Aplicar (${_filters.activeFiltersCount})'
                          : 'Aplicar',
                      variant: MarketplaceButtonVariant.primary,
                      size: MarketplaceButtonSize.large,
                      onPressed: _applyFilters,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Categoría',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildFilterChip(
              'Todas',
              _filters.category == null,
              () => setState(
                () => _filters = _filters.copyWith(clearCategory: true),
              ),
            ),
            ...widget.categories.map((category) {
              return _buildFilterChip(
                category.name,
                _filters.category == category.id,
                () => setState(() {
                  _filters = _filters.copyWith(category: category.id);
                }),
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildPriceRangeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rango de precio',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _minPriceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Mínimo',
                  prefixText: '\$ ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: _maxPriceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Máximo',
                  prefixText: '\$ ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSortSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ordenar por',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildFilterChip(
              'Relevancia',
              _filters.sortBy == null || _filters.sortBy == 'none',
              () =>
                  setState(() => _filters = _filters.copyWith(sortBy: 'none')),
            ),
            _buildFilterChip(
              'Precio: Menor',
              _filters.sortBy == 'price_asc',
              () => setState(
                () => _filters = _filters.copyWith(sortBy: 'price_asc'),
              ),
            ),
            _buildFilterChip(
              'Precio: Mayor',
              _filters.sortBy == 'price_desc',
              () => setState(
                () => _filters = _filters.copyWith(sortBy: 'price_desc'),
              ),
            ),
            _buildFilterChip(
              'Nombre: A-Z',
              _filters.sortBy == 'name_asc',
              () => setState(
                () => _filters = _filters.copyWith(sortBy: 'name_asc'),
              ),
            ),
            _buildFilterChip(
              'Nombre: Z-A',
              _filters.sortBy == 'name_desc',
              () => setState(
                () => _filters = _filters.copyWith(sortBy: 'name_desc'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAvailabilitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Disponibilidad',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        CheckboxListTile(
          title: const Text('Solo productos en stock'),
          value: _filters.inStockOnly ?? false,
          onChanged: (value) {
            setState(() {
              _filters = _filters.copyWith(inStockOnly: value);
            });
          },
          activeColor: AppTheme.gbYellow500,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
        ),
        if (!widget.hideOnSaleFilter)
          CheckboxListTile(
            title: const Text('Solo productos en oferta'),
            value: _filters.onSaleOnly ?? false,
            onChanged: (value) {
              setState(() {
                _filters = _filters.copyWith(onSaleOnly: value);
              });
            },
            activeColor: AppTheme.gbYellow500,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
          ),
      ],
    );
  }

  Widget _buildTagsSection() {
    final selectedTags = _filters.tags ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Etiquetas',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableTags.map((tag) {
            final isSelected = selectedTags.contains(tag);
            return _buildFilterChip(tag, isSelected, () {
              setState(() {
                final newTags = List<String>.from(selectedTags);
                if (isSelected) {
                  newTags.remove(tag);
                } else {
                  newTags.add(tag);
                }
                _filters = _filters.copyWith(tags: newTags);
              });
            });
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: AppTheme.gbYellow200,
      checkmarkColor: AppTheme.gbDark600,
      backgroundColor: Colors.grey.shade100,
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: isSelected ? AppTheme.gbDark600 : Colors.grey.shade700,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }
}
