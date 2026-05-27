import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:running_app/src/domain/models/bank_transfer_info.dart';

import '../../../../src/presentation/ui/auth/views/login_view.dart';
import '../../../../src/presentation/providers/modes/modes_provider.dart';
import '../../../data/api/marketplace_api_service.dart';
import '../../../domain/models/marketplace_category.dart';
import '../../../domain/models/marketplace_product.dart';
import '../../../services/favorites_service.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/category_widget.dart';
import '../../widgets/filters_bottom_sheet.dart';
import '../../widgets/marketplace_dialog.dart';
import '../../widgets/product_card.dart';
import '../../widgets/product_card_skeleton.dart';
import '/config/theme/app_theme.dart';
import 'cart_screen.dart';
import 'marketplace_favorites_screen.dart';
import 'marketplace_search_screen.dart';
import 'marketplace_orders_screen.dart';
import 'product_detail_screen.dart';

class MarketplaceLandingScreen extends ConsumerStatefulWidget {
  const MarketplaceLandingScreen({super.key});

  @override
  ConsumerState<MarketplaceLandingScreen> createState() =>
      _MarketplaceLandingScreenState();
}

class _MarketplaceLandingScreenState
    extends ConsumerState<MarketplaceLandingScreen> {
  static const bool _offersEnabled = false;

  bool _isLoggedIn = false;
  bool _isLoadingProducts = false;
  List<MarketplaceProduct> _products = [];
  List<MarketplaceProduct> _featuredProducts = [];
  List<MarketplaceCategory> _categories = [];
  final Set<String> _favoriteProductIds = {};
  final Set<String> _favoriteLoadingProductIds = {};
  MarketplaceFilters _activeFilters = MarketplaceFilters();

  // Ofertas - se mantiene desactivado temporalmente, pero listo para retomarlo.
  List<MarketplaceProduct> _offerProducts = [];
  bool _isLoadingOffers = false;
  bool _isLoadingMoreOffers = false;
  int _offersCurrentPage = 1;
  bool _offersHasMorePages = true;
  String _offersSortBy = 'none';
  String _offersAvailabilityFilter = 'all';
  String? _offersSelectedCategory;
  int _offersMinDiscountFilter = 0;
  MarketplaceFilters _offersActiveFilters = MarketplaceFilters();
  final ScrollController _offersScrollController = ScrollController();

  // Filtros y ordenamiento
  String? _selectedCategory;
  String _sortBy =
      'none'; // 'none', 'price_asc', 'price_desc', 'name_asc', 'name_desc'
  final String _searchQuery = '';
  String _availabilityFilter = 'all'; // 'all', 'in_stock', 'low_stock'

  // Paginación infinita
  int _currentPage = 1;
  int _totalPages = 1;
  bool _isLoadingMore = false;
  bool _hasMorePages = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _loadCategories();
    _loadProducts();
    if (_offersEnabled) {
      _loadOffers();
      _offersScrollController.addListener(_onOffersScroll);
    }
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _offersScrollController.dispose();
    super.dispose();
  }

  /// Detectar cuando el usuario llega al final del scroll
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && !_isLoadingProducts && _hasMorePages) {
        _loadMoreProducts();
      }
    }
  }

  void _onOffersScroll() {
    if (_offersScrollController.position.pixels >=
        _offersScrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMoreOffers && !_isLoadingOffers && _offersHasMorePages) {
        _loadMoreOffers();
      }
    }
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    if (!mounted) return;
    setState(() {
      _isLoggedIn = isLoggedIn;
    });

    // Si el usuario está logueado, sincronizar favoritos con backend
    if (isLoggedIn) {
      await FavoritesService.syncFavorites();
      await _loadFavorites();
      return;
    }

    if (!mounted) return;
    setState(() {
      _favoriteProductIds.clear();
    });
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await MarketplaceApiService.getMarketplaceCategories();
      if (!mounted) return;

      setState(() {
        _categories = categories;
      });
    } catch (e) {
      debugPrint('Error loading categories: $e');
    }
  }

  Future<void> _loadOffers({bool forceRefresh = false}) async {
    setState(() {
      _isLoadingOffers = true;
      _offersCurrentPage = 1;
    });

    try {
      final response = await MarketplaceApiService.getMarketplaceProducts(
        page: 1,
        limit: 20,
        onSaleOnly: true,
        category: _offersSelectedCategory,
        categoryIds: _resolveBackendCategoryIds(_offersSelectedCategory),
        minPrice: _offersActiveFilters.minPrice,
        maxPrice: _offersActiveFilters.maxPrice,
        inStockOnly: _offersActiveFilters.inStockOnly,
        sortBy: _offersSortBy == 'none' ? null : _offersSortBy,
        forceRefresh: forceRefresh,
      );

      if (response['response'] == true) {
        final allProducts = List<MarketplaceProduct>.from(
          response['data'] ?? [],
        );

        final pagination = response['pagination'];
        final newTotalPages = pagination?['totalPages'] ?? 1;
        final newCurrentPage = pagination?['currentPage'] ?? 1;

        _sortOfferProducts(allProducts);

        setState(() {
          _offerProducts = allProducts.where((p) => p.hasDiscount).toList();
          _offersCurrentPage = newCurrentPage;
          _offersHasMorePages = newCurrentPage < newTotalPages;
        });
      }
    } catch (e) {
      debugPrint('Error loading offers: $e');
    } finally {
      setState(() => _isLoadingOffers = false);
    }
  }

  Future<void> _loadMoreOffers() async {
    if (_isLoadingMoreOffers || !_offersHasMorePages) return;

    setState(() => _isLoadingMoreOffers = true);

    try {
      final nextPage = _offersCurrentPage + 1;

      final response = await MarketplaceApiService.getMarketplaceProducts(
        page: nextPage,
        limit: 20,
        onSaleOnly: true,
        category: _offersSelectedCategory,
        categoryIds: _resolveBackendCategoryIds(_offersSelectedCategory),
        minPrice: _offersActiveFilters.minPrice,
        maxPrice: _offersActiveFilters.maxPrice,
        inStockOnly: _offersActiveFilters.inStockOnly,
        sortBy: _offersSortBy == 'none' ? null : _offersSortBy,
      );

      if (response['response'] == true) {
        final newProducts = List<MarketplaceProduct>.from(
          response['data'] ?? [],
        );

        _sortOfferProducts(newProducts);

        final pagination = response['pagination'];
        final newTotalPages = pagination?['totalPages'] ?? 1;
        final newCurrentPage = pagination?['currentPage'] ?? nextPage;

        setState(() {
          _offerProducts.addAll(
            newProducts.where((p) => p.hasDiscount).toList(),
          );
          _offersCurrentPage = newCurrentPage;
          _offersHasMorePages = newCurrentPage < newTotalPages;
          _isLoadingMoreOffers = false;
        });
      } else {
        setState(() => _isLoadingMoreOffers = false);
      }
    } catch (e) {
      debugPrint('Error loading more offers: $e');
      setState(() => _isLoadingMoreOffers = false);
    }
  }

  void _sortOfferProducts(List<MarketplaceProduct> products) {
    switch (_offersSortBy) {
      case 'price_asc':
        products.sort((a, b) => a.effectivePrice.compareTo(b.effectivePrice));
        break;
      case 'price_desc':
        products.sort((a, b) => b.effectivePrice.compareTo(a.effectivePrice));
        break;
      case 'discount_desc':
        products.sort(
          (a, b) =>
              (b.discountPercentage ?? 0).compareTo(a.discountPercentage ?? 0),
        );
        break;
      case 'name_asc':
        products.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'name_desc':
        products.sort((a, b) => b.name.compareTo(a.name));
        break;
      case 'none':
      default:
        break;
    }
  }

  List<MarketplaceProduct> get _filteredOfferProducts {
    var filtered = _offerProducts.toList();

    switch (_offersAvailabilityFilter) {
      case 'in_stock':
        filtered = filtered.where((p) => p.inStock).toList();
        break;
      case 'low_stock':
        filtered = filtered.where((p) => p.isLowStock).toList();
        break;
    }

    if (_offersMinDiscountFilter > 0) {
      filtered = filtered
          .where((p) => (p.discountPercentage ?? 0) >= _offersMinDiscountFilter)
          .toList();
    }

    return filtered;
  }

  MarketplaceCategory? _findCategoryById(String? categoryId) {
    if (categoryId == null || categoryId.isEmpty) return null;
    for (final category in _categories) {
      if (category.id == categoryId) return category;
    }
    return null;
  }

  List<String>? _resolveBackendCategoryIds(String? categoryId) {
    final category = _findCategoryById(categoryId);
    if (category == null) {
      return categoryId == null ? null : [categoryId];
    }
    return category.backendIds.isEmpty ? [category.id] : category.backendIds;
  }

  String _categoryLabel(String? categoryId) {
    return _findCategoryById(categoryId)?.name ?? categoryId ?? '';
  }

  void _onOffersCategorySelected(String? categoryId) {
    setState(() {
      _offersSelectedCategory = categoryId;
      _offersActiveFilters = _offersActiveFilters.copyWith(
        category: categoryId,
        clearCategory: categoryId == null,
      );
    });
    _loadOffers(forceRefresh: true);
  }

  Future<void> _loadFavorites() async {
    final favoriteIds = await FavoritesService.getFavoriteIds();
    if (!mounted) return;
    setState(() {
      _favoriteProductIds.clear();
      _favoriteProductIds.addAll(favoriteIds);
    });
  }

  void _syncPaymentSettings() {
    final empresaData = MarketplaceApiService.catalogEmpresaInfo;
    if (empresaData == null) return;

    final bankInfo = BankTransferInfo.fromMap(empresaData);
    final settings = MarketplacePaymentSettings(
      isApplyTC: empresaData['isApplyTC'] as bool? ?? true,
      isApplyDeuna: empresaData['isApplyDeuna'] as bool? ?? true,
      isApplyManual: empresaData['isApplyManual'] as bool? ?? false,
      bankInfo: bankInfo,
    );
    ref.read(marketplacePaymentSettingsProvider.notifier).state = settings;
  }

  Future<void> _loadProducts({bool forceRefresh = false}) async {
    debugPrint('🔄 _loadProducts called (forceRefresh: $forceRefresh)');
    debugPrint('📊 Before reset: page $_currentPage of $_totalPages');

    setState(() {
      _isLoadingProducts = true;
      _currentPage = 1; // Reset a primera página
    });

    debugPrint('🔄 Reset to page 1');

    try {
      // Cargar productos con filtros
      final response = await MarketplaceApiService.getMarketplaceProducts(
        page: _currentPage,
        limit: 20,
        category: _selectedCategory,
        categoryIds: _resolveBackendCategoryIds(_selectedCategory),
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
        minPrice: _activeFilters.minPrice,
        maxPrice: _activeFilters.maxPrice,
        inStockOnly: _activeFilters.inStockOnly,
        onSaleOnly: _activeFilters.onSaleOnly,
        sortBy: _sortBy == 'none' ? null : _sortBy,
        availability: _availabilityFilter == 'all' ? null : _availabilityFilter,
        forceRefresh: forceRefresh,
      );

      debugPrint('Response: ${response['response']}');
      debugPrint('Data length: ${response['data']?.length ?? 0}');
      debugPrint('Pagination in response: ${response['pagination']}');

      if (response['response'] == true) {
        final List<MarketplaceProduct> allProducts =
            List<MarketplaceProduct>.from(response['data'] ?? []);

        // Obtener info de paginación
        final pagination = response['pagination'];
        final newTotalPages = pagination?['totalPages'] ?? 1;
        final newCurrentPage = pagination?['currentPage'] ?? 1;
        final newHasMore = newCurrentPage < newTotalPages;

        debugPrint(
          '📊 Pagination from response: totalPages=$newTotalPages, currentPage=$newCurrentPage',
        );
        debugPrint('Loaded ${allProducts.length} products');

        // Aplicar ordenamiento
        _sortProducts(allProducts);

        setState(() {
          _products = allProducts;
          _featuredProducts = allProducts
              .where((p) => p.isFeatured || p.isBestseller)
              .take(5)
              .toList();
          _totalPages = newTotalPages;
          _currentPage = newCurrentPage;
          _hasMorePages = newHasMore;
        });

        debugPrint(
          '✓ State updated: Page $_currentPage of $_totalPages (hasMore: $_hasMorePages)',
        );

        // Update marketplace payment settings from cached empresa info
        _syncPaymentSettings();
      } else {
        debugPrint('Response error: ${response['message']}');
      }
    } catch (e) {
      debugPrint('Error loading products: $e');
    } finally {
      setState(() {
        _isLoadingProducts = false;
      });
    }
  }

  /// Cargar más productos (scroll infinito)
  Future<void> _loadMoreProducts() async {
    if (_isLoadingMore || !_hasMorePages) {
      debugPrint(
        '⚠️ Load more cancelled: loading=$_isLoadingMore, hasMore=$_hasMorePages',
      );
      return;
    }

    debugPrint(
      '🔄 Starting load more: currentPage=$_currentPage, totalPages=$_totalPages',
    );

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final nextPage = _currentPage + 1;
      debugPrint('📄 Loading page $nextPage...');

      final response = await MarketplaceApiService.getMarketplaceProducts(
        page: nextPage,
        limit: 20,
        category: _selectedCategory,
        categoryIds: _resolveBackendCategoryIds(_selectedCategory),
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
        minPrice: _activeFilters.minPrice,
        maxPrice: _activeFilters.maxPrice,
        inStockOnly: _activeFilters.inStockOnly,
        onSaleOnly: _activeFilters.onSaleOnly,
        sortBy: _sortBy == 'none' ? null : _sortBy,
        availability: _availabilityFilter == 'all' ? null : _availabilityFilter,
      );

      if (response['response'] == true) {
        final List<MarketplaceProduct> newProducts =
            List<MarketplaceProduct>.from(response['data'] ?? []);

        // Aplicar ordenamiento a los nuevos productos ANTES de actualizar el estado
        _sortProducts(newProducts);

        // Obtener info de paginación
        final pagination = response['pagination'];
        final newTotalPages = pagination?['totalPages'] ?? 1;
        final newCurrentPage = pagination?['currentPage'] ?? nextPage;
        final newHasMore = newCurrentPage < newTotalPages;

        debugPrint('✅ Loaded ${newProducts.length} products');
        debugPrint(
          '📊 Pagination from API: page $newCurrentPage of $newTotalPages',
        );

        // Actualizar estado en un solo setState
        setState(() {
          _products.addAll(newProducts);
          _totalPages = newTotalPages;
          _currentPage = newCurrentPage;
          _hasMorePages = newHasMore;
          _isLoadingMore = false;
        });

        debugPrint(
          '✓ State updated: now on page $_currentPage of $_totalPages (hasMore: $_hasMorePages)',
        );
      } else {
        setState(() {
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading more products: $e');
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _toggleFavorite(String productId) async {
    // Verificar si el usuario ha iniciado sesión
    if (!_isLoggedIn) {
      MarketplaceDialog.show(
        context: context,
        icon: Icons.favorite_border,
        iconColor: Colors.red.shade400,
        title: 'Inicio de sesión requerido',
        message:
            'Para agregar productos a favoritos necesitas iniciar sesión primero.',
        primaryButtonText: 'Iniciar sesión',
        secondaryButtonText: 'Cancelar',
        onPrimaryPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const LoginView(needsSafeArea: false),
            ),
          ).then((_) => _checkLoginStatus());
        },
        onSecondaryPressed: () {
          // El diálogo se cierra automáticamente
        },
      );
      return;
    }

    if (_favoriteLoadingProductIds.contains(productId)) {
      return;
    }

    setState(() {
      _favoriteLoadingProductIds.add(productId);
    });

    final result = await FavoritesService.toggleFavorite(productId);
    if (!mounted) return;

    setState(() {
      _favoriteLoadingProductIds.remove(productId);
      if (result.success) {
        if (result.isFavorite) {
          _favoriteProductIds.add(productId);
        } else {
          _favoriteProductIds.remove(productId);
        }
      }
    });

    if (!result.success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));
    }
  }

  /// Ordenar productos según el criterio seleccionado
  void _sortProducts(List<MarketplaceProduct> products) {
    switch (_sortBy) {
      case 'price_asc':
        products.sort((a, b) => a.effectivePrice.compareTo(b.effectivePrice));
        break;
      case 'price_desc':
        products.sort((a, b) => b.effectivePrice.compareTo(a.effectivePrice));
        break;
      case 'name_asc':
        products.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'name_desc':
        products.sort((a, b) => b.name.compareTo(a.name));
        break;
      case 'none':
      default:
        // No ordenar, dejar orden por defecto del API
        break;
    }
  }

  /// Obtener productos filtrados por disponibilidad
  List<MarketplaceProduct> get _filteredProducts {
    switch (_availabilityFilter) {
      case 'in_stock':
        return _products.where((p) => p.inStock).toList();
      case 'low_stock':
        return _products.where((p) => p.isLowStock).toList();
      case 'all':
      default:
        return _products;
    }
  }

  /// Cambiar categoría seleccionada
  void _onCategorySelected(String? categoryId) {
    setState(() {
      _selectedCategory = categoryId;
      _activeFilters = _activeFilters.copyWith(
        category: categoryId,
        clearCategory: categoryId == null,
      );
    });
    _loadProducts(forceRefresh: true);
  }

  /// Cambiar ordenamiento
  void _onSortChanged(String sortBy) {
    setState(() {
      _sortBy = sortBy;
    });
    // Re-aplicar ordenamiento a productos existentes
    _sortProducts(_products);
    setState(() {});
  }

  void _onOffersSortChanged(String sortBy) {
    setState(() => _offersSortBy = sortBy);
    _sortOfferProducts(_offerProducts);
    setState(() {});
  }

  /// Cambiar filtro de disponibilidad
  void _onAvailabilityFilterChanged(String filter) {
    setState(() {
      _availabilityFilter = filter;
    });
  }

  @override
  Widget build(BuildContext context) {
    final section = ref.watch(marketplaceSectionProvider);
    final effectiveSection =
        !_offersEnabled && section == MarketplaceSection.offers
        ? MarketplaceSection.home
        : section;
    final cartCount = ref.watch(cartProvider).itemCount;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Row(
          children: [
            Icon(Icons.store, color: AppTheme.primary, size: 28),
            const SizedBox(width: 8),
            Text(
              'Marketplace',
              style: AppTheme.titleMediumTextStyle(
                context,
                fontWeight: FontWeight.w700,
                color: AppTheme.secondayBlack,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppTheme.gbDark600),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MarketplaceSearchScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.favorite_border, color: AppTheme.gbDark600),
            tooltip: 'Favoritos',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MarketplaceFavoritesScreen(),
                ),
              );
              if (!mounted) return;
              await _checkLoginStatus();
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline, color: AppTheme.gbDark600),
            tooltip: 'Perfil',
            onPressed: () {
              ref.read(bottomNavigationIndexProvider.notifier).state = 4;
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: _buildSectionTabs(
              selectedSection: effectiveSection,
              cartCount: cartCount,
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: switch (effectiveSection) {
                MarketplaceSection.home => 0,
                MarketplaceSection.offers => 1,
                MarketplaceSection.cart => _offersEnabled ? 2 : 1,
                MarketplaceSection.orders => _offersEnabled ? 3 : 2,
              },
              children: [
                _buildHomeTab(),
                if (_offersEnabled) _buildOffersTab(),
                CartScreen(
                  embedded: true,
                  onExploreProducts: () {
                    ref.read(marketplaceSectionProvider.notifier).state =
                        MarketplaceSection.home;
                  },
                ),
                const MarketplaceOrdersScreen(embedded: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTabs({
    required MarketplaceSection selectedSection,
    required int cartCount,
  }) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, AppTheme.primaryLowestShade],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppTheme.primaryLowShade.withValues(alpha: 0.9),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildSectionTab(
            section: MarketplaceSection.home,
            selectedSection: selectedSection,
            icon: Icons.home_rounded,
            label: 'Inicio',
          ),
          if (_offersEnabled)
            _buildSectionTab(
              section: MarketplaceSection.offers,
              selectedSection: selectedSection,
              icon: Icons.local_offer_rounded,
              label: 'Ofertas',
            ),
          _buildSectionTab(
            section: MarketplaceSection.cart,
            selectedSection: selectedSection,
            icon: Icons.shopping_bag_rounded,
            label: 'Carrito',
            badgeCount: cartCount,
          ),
          _buildSectionTab(
            section: MarketplaceSection.orders,
            selectedSection: selectedSection,
            icon: Icons.receipt_long_rounded,
            label: 'Órdenes',
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTab({
    required MarketplaceSection section,
    required MarketplaceSection selectedSection,
    required IconData icon,
    required String label,
    int badgeCount = 0,
  }) {
    final isSelected = section == selectedSection;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            ref.read(marketplaceSectionProvider.notifier).state = section;
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(18),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.28),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected ? Colors.white : AppTheme.gbDark400,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.labelLargeTextStyle(
                      context,
                      color: isSelected ? Colors.white : AppTheme.gbDark400,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w600,
                    ),
                  ),
                ),
                if (badgeCount > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : AppTheme.red,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      badgeCount > 99 ? '99+' : '$badgeCount',
                      style: AppTheme.labelSmallTextStyle(
                        context,
                        color: isSelected ? AppTheme.primary : Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHomeTab() {
    return RefreshIndicator(
      onRefresh: _loadProducts,
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Categorías populares usando el widget creado
            PopularCategoriesWidget(
              categories: _categories,
              onCategoryTap: (category) {
                _onCategorySelected(category.id);
                debugPrint('Category selected: ${category.name}');
              },
              onViewAllCategorySelected: (categoryId) {
                _onCategorySelected(categoryId);
              },
            ),

            // Chip para mostrar filtro activo
            if (_selectedCategory != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Chip(
                  avatar: const Icon(Icons.filter_list, size: 18),
                  label: Text(
                    'Categoría: ${_categoryLabel(_selectedCategory)}',
                  ),
                  deleteIcon: const Icon(Icons.close, size: 18),
                  onDeleted: () => _onCategorySelected(null),
                  backgroundColor: AppTheme.gbYellow50,
                  labelStyle: const TextStyle(
                    color: AppTheme.gbDark600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Productos destacados
            if (_featuredProducts.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Productos Destacados',
                      style: AppTheme.titleMediumTextStyle(
                        context,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // TODO: Ver todos los productos
                      },
                      child: Text(
                        'Ver todos',
                        style: AppTheme.bodyMediumTextStyle(
                          context,
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Featured product cards
              SizedBox(
                height: 340,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _featuredProducts.length,
                  itemBuilder: (context, index) {
                    final product = _featuredProducts[index];
                    return Container(
                      width: 280,
                      margin: const EdgeInsets.only(right: 16),
                      child: ProductCard(
                        product: product,
                        variant: ProductCardVariant.featured,
                        isFavorite: _favoriteProductIds.contains(product.id),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProductDetailScreen(
                                productId: product.id,
                                product: product,
                              ),
                            ),
                          );
                        },
                        onFavorite: () => _toggleFavorite(product.id),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Grid de productos con filtros y ordenamiento
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    'Todos los Productos',
                    style: AppTheme.titleMediumTextStyle(
                      context,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  // Botón de filtros
                  IconButton(
                    icon: Stack(
                      children: [
                        const Icon(
                          Icons.tune,
                          size: 22,
                          color: AppTheme.primary,
                        ),
                        if (_activeFilters.hasActiveFilters)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                    onPressed: () async {
                      final filters =
                          await showModalBottomSheet<MarketplaceFilters>(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => FiltersBottomSheet(
                              initialFilters: _activeFilters,
                              categories: _categories,
                            ),
                          );
                      if (filters != null) {
                        setState(() {
                          _activeFilters = filters;
                          _selectedCategory = filters.category;
                          _sortBy = filters.sortBy ?? 'none';
                        });
                        _loadProducts(forceRefresh: true);
                      }
                    },
                  ),
                  const Spacer(),
                  PopupMenuButton<String>(
                    icon: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.sort, size: 18, color: AppTheme.primary),
                        SizedBox(width: 4),
                        Text(
                          'Ordenar',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    onSelected: _onSortChanged,
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'none',
                        child: Text('Por defecto'),
                      ),
                      const PopupMenuItem(
                        value: 'price_asc',
                        child: Text('Precio: Menor a Mayor'),
                      ),
                      const PopupMenuItem(
                        value: 'price_desc',
                        child: Text('Precio: Mayor a Menor'),
                      ),
                      const PopupMenuItem(
                        value: 'name_asc',
                        child: Text('Nombre: A-Z'),
                      ),
                      const PopupMenuItem(
                        value: 'name_desc',
                        child: Text('Nombre: Z-A'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Filtros de disponibilidad
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('Todos'),
                      selected: _availabilityFilter == 'all',
                      onSelected: (selected) {
                        if (selected) _onAvailabilityFilterChanged('all');
                      },
                      selectedColor: AppTheme.gbYellow200,
                      checkmarkColor: AppTheme.gbDark600,
                      side: BorderSide(
                        color: _availabilityFilter == 'all'
                            ? AppTheme.gbYellow200
                            : AppTheme.gbDark200,
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('En Stock'),
                      selected: _availabilityFilter == 'in_stock',
                      onSelected: (selected) {
                        if (selected) _onAvailabilityFilterChanged('in_stock');
                      },
                      selectedColor: Colors.green.shade100,
                      checkmarkColor: Colors.green.shade700,
                      side: BorderSide(
                        color: _availabilityFilter == 'in_stock'
                            ? Colors.green.shade200
                            : AppTheme.gbDark200,
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Pocas Unidades'),
                      selected: _availabilityFilter == 'low_stock',
                      onSelected: (selected) {
                        if (selected) _onAvailabilityFilterChanged('low_stock');
                      },
                      selectedColor: AppTheme.primary50,
                      checkmarkColor: AppTheme.primary,
                      side: BorderSide(
                        color: _availabilityFilter == 'low_stock'
                            ? AppTheme.primaryLowShade
                            : AppTheme.gbDark200,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Loading o productos
            if (_isLoadingProducts)
              const ProductGridSkeleton(itemCount: 6)
            else if (_products.isEmpty)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.gbYellow50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.gbYellow200),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 60,
                      color: AppTheme.gbYellow500,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No hay productos disponibles',
                      style: AppTheme.titleMediumTextStyle(
                        context,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.secondayBlack,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Estamos trabajando en traerte los mejores productos. ¡Vuelve pronto!',
                      textAlign: TextAlign.center,
                      style: AppTheme.bodyMediumTextStyle(
                        context,
                        color: AppTheme.gbDark600,
                      ),
                    ),
                  ],
                ),
              )
            else if (_filteredProducts.isEmpty)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.filter_list_off,
                      size: 60,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _availabilityFilter == 'low_stock'
                          ? 'No hay productos con pocas unidades'
                          : _availabilityFilter == 'in_stock'
                          ? 'No hay productos en stock'
                          : 'No hay productos para este filtro',
                      style: AppTheme.titleMediumTextStyle(
                        context,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.secondayBlack,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _availabilityFilter == 'low_stock'
                          ? 'Todos los productos tienen suficiente stock disponible en este momento'
                          : 'Prueba cambiando el filtro de disponibilidad para ver más productos',
                      textAlign: TextAlign.center,
                      style: AppTheme.bodyMediumTextStyle(
                        context,
                        color: AppTheme.gbDark600,
                      ),
                    ),
                  ],
                ),
              )
            else
              GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.68,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _filteredProducts.length,
                itemBuilder: (context, index) {
                  final product = _filteredProducts[index];
                  return ProductCard(
                    product: product,
                    variant: ProductCardVariant.grid,
                    isFavorite: _favoriteProductIds.contains(product.id),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductDetailScreen(
                            productId: product.id,
                            product: product,
                          ),
                        ),
                      );
                    },
                    onFavorite: () => _toggleFavorite(product.id),
                  );
                },
              ),

            // Indicador de carga al hacer scroll infinito
            if (_isLoadingMore)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.gbYellow500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Cargando más productos...',
                      style: TextStyle(color: AppTheme.gbDark400, fontSize: 13),
                    ),
                  ],
                ),
              ),

            // Mensaje de fin de resultados
            if (!_isLoadingProducts &&
                !_isLoadingMore &&
                _products.isNotEmpty &&
                !_hasMorePages)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    'Has visto todos los productos',
                    style: TextStyle(color: AppTheme.gbDark400, fontSize: 13),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOffersTab() {
    return RefreshIndicator(
      onRefresh: () => _loadOffers(forceRefresh: true),
      child: SingleChildScrollView(
        controller: _offersScrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 180,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red.shade600, Colors.red.shade400],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Icon(
                      Icons.local_offer,
                      size: 140,
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Ofertas y',
                          style: AppTheme.bodyLargeTextStyle(
                            context,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Descuentos',
                          style: AppTheme.displaySmallTextStyle(
                            context,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Los mejores precios en productos seleccionados',
                          style: AppTheme.bodyMediumTextStyle(
                            context,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildDiscountChip('Todos', 0),
                    const SizedBox(width: 8),
                    _buildDiscountChip('10%+', 10),
                    const SizedBox(width: 8),
                    _buildDiscountChip('20%+', 20),
                    const SizedBox(width: 8),
                    _buildDiscountChip('30%+', 30),
                    const SizedBox(width: 8),
                    _buildDiscountChip('50%+', 50),
                  ],
                ),
              ),
            ),
            if (_offersSelectedCategory != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Chip(
                  avatar: const Icon(Icons.filter_list, size: 18),
                  label: Text(
                    'Categoría: ${_categoryLabel(_offersSelectedCategory)}',
                  ),
                  deleteIcon: const Icon(Icons.close, size: 18),
                  onDeleted: () => _onOffersCategorySelected(null),
                  backgroundColor: AppTheme.gbYellow50,
                  labelStyle: const TextStyle(
                    color: AppTheme.gbDark600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    'Productos en Oferta',
                    style: AppTheme.titleMediumTextStyle(
                      context,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  IconButton(
                    icon: Stack(
                      children: [
                        const Icon(
                          Icons.tune,
                          size: 22,
                          color: AppTheme.primary,
                        ),
                        if (_offersActiveFilters.hasActiveFilters)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                    onPressed: () async {
                      final filters =
                          await showModalBottomSheet<MarketplaceFilters>(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => FiltersBottomSheet(
                              initialFilters: _offersActiveFilters,
                              categories: _categories,
                              hideOnSaleFilter: true,
                            ),
                          );
                      if (filters != null) {
                        setState(() {
                          _offersActiveFilters = filters;
                          _offersSelectedCategory = filters.category;
                          _offersSortBy = filters.sortBy ?? 'none';
                        });
                        _loadOffers(forceRefresh: true);
                      }
                    },
                  ),
                  const Spacer(),
                  PopupMenuButton<String>(
                    icon: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.sort, size: 18, color: AppTheme.primary),
                        SizedBox(width: 4),
                        Text(
                          'Ordenar',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    onSelected: _onOffersSortChanged,
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'none',
                        child: Text('Por defecto'),
                      ),
                      const PopupMenuItem(
                        value: 'discount_desc',
                        child: Text('Mayor descuento'),
                      ),
                      const PopupMenuItem(
                        value: 'price_asc',
                        child: Text('Precio: Menor a Mayor'),
                      ),
                      const PopupMenuItem(
                        value: 'price_desc',
                        child: Text('Precio: Mayor a Menor'),
                      ),
                      const PopupMenuItem(
                        value: 'name_asc',
                        child: Text('Nombre: A-Z'),
                      ),
                      const PopupMenuItem(
                        value: 'name_desc',
                        child: Text('Nombre: Z-A'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('Todos'),
                      selected: _offersAvailabilityFilter == 'all',
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _offersAvailabilityFilter = 'all');
                        }
                      },
                      selectedColor: AppTheme.gbYellow200,
                      checkmarkColor: AppTheme.gbDark600,
                      side: BorderSide(
                        color: _offersAvailabilityFilter == 'all'
                            ? AppTheme.gbYellow200
                            : AppTheme.gbDark200,
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('En Stock'),
                      selected: _offersAvailabilityFilter == 'in_stock',
                      onSelected: (selected) {
                        if (selected) {
                          setState(
                            () => _offersAvailabilityFilter = 'in_stock',
                          );
                        }
                      },
                      selectedColor: Colors.green.shade100,
                      checkmarkColor: Colors.green.shade700,
                      side: BorderSide(
                        color: _offersAvailabilityFilter == 'in_stock'
                            ? Colors.green.shade200
                            : AppTheme.gbDark200,
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Pocas Unidades'),
                      selected: _offersAvailabilityFilter == 'low_stock',
                      onSelected: (selected) {
                        if (selected) {
                          setState(
                            () => _offersAvailabilityFilter = 'low_stock',
                          );
                        }
                      },
                      selectedColor: AppTheme.primary50,
                      checkmarkColor: AppTheme.primary,
                      side: BorderSide(
                        color: _offersAvailabilityFilter == 'low_stock'
                            ? AppTheme.primaryLowShade
                            : AppTheme.gbDark200,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_isLoadingOffers)
              const ProductGridSkeleton(itemCount: 6)
            else if (_offerProducts.isEmpty)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red.shade100),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.local_offer_outlined,
                      size: 60,
                      color: Colors.red.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No hay ofertas disponibles',
                      style: AppTheme.titleMediumTextStyle(
                        context,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.secondayBlack,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Vuelve pronto, estamos preparando ofertas especiales para ti',
                      textAlign: TextAlign.center,
                      style: AppTheme.bodyMediumTextStyle(
                        context,
                        color: AppTheme.gbDark600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        ref.read(marketplaceSectionProvider.notifier).state =
                            MarketplaceSection.home;
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Explorar productos',
                        style: AppTheme.bodyLargeTextStyle(
                          context,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else if (_filteredOfferProducts.isEmpty)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.filter_list_off,
                      size: 60,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No hay ofertas para este filtro',
                      style: AppTheme.titleMediumTextStyle(
                        context,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.secondayBlack,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Prueba ajustando los filtros para ver más ofertas',
                      textAlign: TextAlign.center,
                      style: AppTheme.bodyMediumTextStyle(
                        context,
                        color: AppTheme.gbDark600,
                      ),
                    ),
                  ],
                ),
              )
            else
              GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.68,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _filteredOfferProducts.length,
                itemBuilder: (context, index) {
                  final product = _filteredOfferProducts[index];
                  return ProductCard(
                    product: product,
                    variant: ProductCardVariant.grid,
                    isFavorite: _favoriteProductIds.contains(product.id),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductDetailScreen(
                            productId: product.id,
                            product: product,
                          ),
                        ),
                      );
                    },
                    onFavorite: () => _toggleFavorite(product.id),
                  );
                },
              ),
            if (_isLoadingMoreOffers)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.red.shade400,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Cargando más ofertas...',
                      style: TextStyle(color: AppTheme.gbDark400, fontSize: 13),
                    ),
                  ],
                ),
              ),
            if (!_isLoadingOffers &&
                !_isLoadingMoreOffers &&
                _offerProducts.isNotEmpty &&
                !_offersHasMorePages)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    'Has visto todas las ofertas',
                    style: TextStyle(color: AppTheme.gbDark400, fontSize: 13),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscountChip(String label, int minDiscount) {
    final isSelected = _offersMinDiscountFilter == minDiscount;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _offersMinDiscountFilter = selected ? minDiscount : 0);
      },
      selectedColor: Colors.red.shade100,
      checkmarkColor: Colors.red.shade700,
      backgroundColor: Colors.grey.shade100,
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: isSelected ? Colors.red.shade700 : Colors.grey.shade700,
      ),
    );
  }
}
