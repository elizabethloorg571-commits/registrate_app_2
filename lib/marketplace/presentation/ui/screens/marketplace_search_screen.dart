import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../src/presentation/ui/auth/views/login_view.dart';
import '../../../config/theme/marketplace_theme.dart';
import '../../../data/api/marketplace_api_service.dart';
import '../../../domain/models/marketplace_product.dart';
import '../../../services/favorites_service.dart';
import '../../widgets/marketplace_dialog.dart';
import '../../widgets/product_card.dart';
import '../../widgets/product_card_skeleton.dart';
import 'marketplace_favorites_screen.dart';
import 'product_detail_screen.dart';

/// Pantalla dedicada de búsqueda - estilo Amazon/Mercado Libre
class MarketplaceSearchScreen extends StatefulWidget {
  const MarketplaceSearchScreen({super.key});

  @override
  State<MarketplaceSearchScreen> createState() =>
      _MarketplaceSearchScreenState();
}

class _MarketplaceSearchScreenState extends State<MarketplaceSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _debounceTimer;

  List<MarketplaceProduct> _searchResults = [];
  List<String> _searchHistory = [];
  List<String> _suggestions = [];
  bool _isSearching = false;
  bool _showHistory = true;
  String _currentQuery = '';
  bool _isLoggedIn = false;
  final Set<String> _favoriteProductIds = {};
  final Set<String> _favoriteLoadingProductIds = {};

  static const String _historyKey = 'marketplace_search_history';
  static const int _maxHistoryItems = 10;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _loadSearchHistory();
    _searchFocusNode.requestFocus();
    _searchController.addListener(_onSearchTextChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  /// Cargar historial de búsquedas
  Future<void> _loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList(_historyKey) ?? [];
    setState(() {
      _searchHistory = history;
    });
  }

  /// Verificar estado de sesión
  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    if (!mounted) return;
    setState(() {
      _isLoggedIn = isLoggedIn;
    });

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

  /// Cargar favoritos
  Future<void> _loadFavorites() async {
    final favoriteIds = await FavoritesService.getFavoriteIds();
    if (!mounted) return;
    setState(() {
      _favoriteProductIds.clear();
      _favoriteProductIds.addAll(favoriteIds);
    });
  }

  /// Toggle favorito con validación de sesión
  Future<void> _toggleFavorite(String productId) async {
    // Verificar si el usuario ha iniciado sesión
    if (!_isLoggedIn) {
      MarketplaceDialog.show(
        context: context,
        icon: Icons.favorite_border,
        iconColor: Colors.red.shade400,
        title: 'Iniciar sesión requerido',
        message:
            'Para agregar productos a favoritos necesitas iniciar sesión primero.',
        primaryButtonText: 'Iniciar sesión',
        secondaryButtonText: 'Cancelar',
        onPrimaryPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LoginView()),
          ).then((_) => _checkLoginStatus());
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

  /// Guardar búsqueda en historial
  Future<void> _saveToHistory(String query) async {
    if (query.isEmpty || query.length < 2) return;

    final prefs = await SharedPreferences.getInstance();
    final history = List<String>.from(_searchHistory);

    // Remover si ya existe
    history.remove(query);
    // Agregar al inicio
    history.insert(0, query);
    // Limitar a máximo de items
    if (history.length > _maxHistoryItems) {
      history.removeRange(_maxHistoryItems, history.length);
    }

    await prefs.setStringList(_historyKey, history);
    setState(() {
      _searchHistory = history;
    });
  }

  /// Limpiar historial
  Future<void> _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
    setState(() {
      _searchHistory = [];
    });
  }

  /// Eliminar un item del historial
  Future<void> _removeFromHistory(String query) async {
    final prefs = await SharedPreferences.getInstance();
    final history = List<String>.from(_searchHistory);
    history.remove(query);
    await prefs.setStringList(_historyKey, history);
    setState(() {
      _searchHistory = history;
    });
  }

  /// Detectar cambios en el texto de búsqueda
  void _onSearchTextChanged() {
    final query = _searchController.text;
    setState(() {
      _currentQuery = query;
      _showHistory = query.isEmpty;
    });

    // Cancelar timer anterior
    _debounceTimer?.cancel();

    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _suggestions = [];
      });
      return;
    }

    // Generar sugerencias locales del historial
    if (query.length >= 2) {
      final matchingSuggestions = _searchHistory
          .where((h) => h.toLowerCase().contains(query.toLowerCase()))
          .take(5)
          .toList();
      setState(() {
        _suggestions = matchingSuggestions;
      });
    }

    // Debounce para búsqueda real
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (query.length >= 2) {
        _performSearch(query);
      }
    });
  }

  /// Realizar búsqueda
  Future<void> _performSearch(String query) async {
    setState(() {
      _isSearching = true;
    });

    try {
      final response = await MarketplaceApiService.getMarketplaceProducts(
        page: 1,
        limit: 50,
        searchQuery: query,
      );

      if (response['response'] == true) {
        final results = List<MarketplaceProduct>.from(response['data'] ?? []);
        setState(() {
          _searchResults = results;
        });

        // Guardar en historial solo si hay resultados
        if (results.isNotEmpty) {
          await _saveToHistory(query);
        }
      }
    } catch (e) {
      debugPrint('Error searching: $e');
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  /// Seleccionar sugerencia o historial
  void _selectSuggestion(String query) {
    _searchController.text = query;
    _performSearch(query);
    _searchFocusNode.unfocus();
  }

  /// Limpiar búsqueda
  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchResults = [];
      _suggestions = [];
      _showHistory = true;
      _currentQuery = '';
    });
    _searchFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.favorite_border,
              color: MarketplaceTheme.gbDark600,
            ),
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
        ],
        title: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          decoration: InputDecoration(
            hintText: 'Buscar productos...',
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: MarketplaceTheme.primary,
                width: 2,
              ),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            suffixIcon: _currentQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: _clearSearch,
                  )
                : null,
          ),
          style: const TextStyle(fontSize: 16, color: Colors.black87),
        ),
      ),
      body: Column(
        children: [
          Divider(height: 1, color: Colors.grey.shade200),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    // Mostrar historial cuando no hay búsqueda activa
    if (_showHistory && _currentQuery.isEmpty) {
      return _buildSearchHistory();
    }

    // Mostrar sugerencias mientras escribe
    if (_currentQuery.isNotEmpty &&
        _currentQuery.length >= 2 &&
        _suggestions.isNotEmpty &&
        _searchFocusNode.hasFocus) {
      return _buildSuggestions();
    }

    // Mostrar loading
    if (_isSearching) {
      return const ProductGridSkeleton(itemCount: 6);
    }

    // Mostrar resultados
    if (_searchResults.isNotEmpty) {
      return _buildSearchResults();
    }

    // Sin resultados
    if (_currentQuery.isNotEmpty && !_isSearching) {
      return _buildNoResults();
    }

    // Estado inicial
    return _buildEmptyState();
  }

  Widget _buildSearchHistory() {
    if (_searchHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'Busca productos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Encuentra lo que necesitas',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Búsquedas recientes',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              TextButton(
                onPressed: _clearHistory,
                child: const Text(
                  'Limpiar',
                  style: TextStyle(
                    fontSize: 13,
                    color: MarketplaceTheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        ..._searchHistory.map((query) {
          return ListTile(
            leading: Icon(Icons.history, color: Colors.grey.shade400, size: 22),
            title: Text(query, style: const TextStyle(fontSize: 15)),
            trailing: IconButton(
              icon: Icon(Icons.close, color: Colors.grey.shade400, size: 20),
              onPressed: () => _removeFromHistory(query),
            ),
            onTap: () => _selectSuggestion(query),
          );
        }),
      ],
    );
  }

  Widget _buildSuggestions() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _suggestions.length,
      itemBuilder: (context, index) {
        final suggestion = _suggestions[index];
        return ListTile(
          leading: Icon(Icons.search, color: Colors.grey.shade400, size: 22),
          title: RichText(
            text: TextSpan(
              children: _highlightMatch(suggestion, _currentQuery),
              style: const TextStyle(fontSize: 15, color: Colors.black87),
            ),
          ),
          trailing: const Icon(Icons.north_west, size: 18, color: Colors.grey),
          onTap: () => _selectSuggestion(suggestion),
        );
      },
    );
  }

  Widget _buildSearchResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '${_searchResults.length} resultado${_searchResults.length == 1 ? '' : 's'} para "$_currentQuery"',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.68,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              final product = _searchResults[index];
              return ProductCard(
                product: product,
                variant: ProductCardVariant.grid,
                isFavorite: _favoriteProductIds.contains(product.id),
                onFavorite: () => _toggleFavorite(product.id),
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
                  // Notificar a la pantalla padre que actualice el carrito
                  // cerrando y reabriendo esta pantalla, o mejor, volver atrás
                  // para que el landing screen actualice su contador
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No encontramos resultados',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Intenta con otras palabras clave',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Comienza a buscar',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  /// Resaltar coincidencias en sugerencias
  List<TextSpan> _highlightMatch(String text, String query) {
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final index = lowerText.indexOf(lowerQuery);

    if (index == -1) {
      return [TextSpan(text: text)];
    }

    return [
      if (index > 0) TextSpan(text: text.substring(0, index)),
      TextSpan(
        text: text.substring(index, index + query.length),
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      if (index + query.length < text.length)
        TextSpan(text: text.substring(index + query.length)),
    ];
  }
}
