import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../data/api/constants.dart';
import '../data/api/marketplace_api_service.dart';
import '../domain/models/marketplace_product.dart';

class FavoriteToggleResult {
  const FavoriteToggleResult({
    required this.success,
    required this.isFavorite,
    required this.message,
  });

  final bool success;
  final bool isFavorite;
  final String message;
}

/// Servicio para gestionar favoritos del marketplace
/// Incluye persistencia local y sincronización con backend
class FavoritesService {
  static const String _favoritesKey = 'marketplace_favorites';

  // ==================== MÉTODOS PÚBLICOS ====================

  /// Obtener lista de IDs de favoritos desde el backend
  static Future<List<String>> getFavoriteIds({
    bool forceRefresh = false,
    String? personaId,
  }) async {
    final session = await _readSession(personaId: personaId);
    if (!session.canUseBackend) {
      return [];
    }

    try {
      if (!forceRefresh) {
        final cachedFavorites = await _getLocalFavorites(session.personaId);
        if (cachedFavorites.isNotEmpty) {
          return cachedFavorites;
        }
      }

      final favorites = await _fetchFavoriteRecordsFromBackend(session);
      final favoriteIds = favorites
          .map((favorite) => favorite.productId)
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();

      await _saveFavorites(favoriteIds, session.personaId);

      return favoriteIds;
    } catch (e) {
      log('Error getting favorites from backend, using cache: $e');
      return await _getLocalFavorites(session.personaId);
    }
  }

  /// Obtener los productos completos que el usuario ha marcado como favorito.
  static Future<List<MarketplaceProduct>> getFavoriteProducts({
    bool forceRefresh = false,
    String? personaId,
  }) async {
    final favoriteIds = await getFavoriteIds(
      forceRefresh: forceRefresh,
      personaId: personaId,
    );
    if (favoriteIds.isEmpty) {
      return [];
    }

    return MarketplaceApiService.getMarketplaceProductsByIds(favoriteIds);
  }

  /// Agregar producto a favoritos (local + backend)
  static Future<FavoriteToggleResult> addToFavorites(String productId) async {
    final validation = await _validateFavoriteAction(productId);
    if (!validation.success || validation.session == null) {
      return FavoriteToggleResult(
        success: false,
        isFavorite: false,
        message: validation.message,
      );
    }

    final session = validation.session!;

    try {
      final favorites = await _getLocalFavorites(session.personaId);
      if (favorites.contains(productId)) {
        return const FavoriteToggleResult(
          success: true,
          isFavorite: true,
          message: 'Este producto ya estaba en tus favoritos.',
        );
      }

      final existingFavorite = await _getFavoriteRecordFromBackend(
        session,
        productId,
      );
      if (existingFavorite != null) {
        favorites.add(productId);
        await _saveFavorites(favorites, session.personaId);
        return const FavoriteToggleResult(
          success: true,
          isFavorite: true,
          message: 'Producto agregado a favoritos.',
        );
      }

      final backendResult = await _addFavoriteToBackend(session, productId);

      if (backendResult.success) {
        favorites.add(productId);
        await _saveFavorites(favorites, session.personaId);
        log('Product added to favorites: $productId');
        return FavoriteToggleResult(
          success: true,
          isFavorite: true,
          message: backendResult.message,
        );
      }
    } catch (e) {
      log('Error adding to favorites: $e');
    }

    return const FavoriteToggleResult(
      success: false,
      isFavorite: false,
      message: 'No se pudo agregar el producto a favoritos.',
    );
  }

  /// Eliminar producto de favoritos (local + backend)
  static Future<FavoriteToggleResult> removeFromFavorites(
    String productId,
  ) async {
    final validation = await _validateFavoriteAction(productId);
    if (!validation.success || validation.session == null) {
      return FavoriteToggleResult(
        success: false,
        isFavorite: false,
        message: validation.message,
      );
    }

    final session = validation.session!;

    try {
      final favoriteId = await _getFavoriteIdFromBackend(session, productId);
      final favorites = await _getLocalFavorites(session.personaId);

      if (favoriteId == null) {
        favorites.remove(productId);
        await _saveFavorites(favorites, session.personaId);
        return const FavoriteToggleResult(
          success: true,
          isFavorite: false,
          message: 'Producto eliminado de favoritos.',
        );
      }

      final backendResult = await _removeFavoriteFromBackend(
        session,
        favoriteId,
      );
      if (backendResult.success) {
        favorites.remove(productId);
        await _saveFavorites(favorites, session.personaId);
        log('Product removed from favorites: $productId');
        return FavoriteToggleResult(
          success: true,
          isFavorite: false,
          message: backendResult.message,
        );
      }
    } catch (e) {
      log('Error removing from favorites: $e');
    }

    return const FavoriteToggleResult(
      success: false,
      isFavorite: true,
      message: 'No se pudo quitar el producto de favoritos.',
    );
  }

  /// Toggle favorite (agregar o quitar)
  static Future<FavoriteToggleResult> toggleFavorite(String productId) async {
    final session = await _readSession();
    if (!session.canUseBackend) {
      return const FavoriteToggleResult(
        success: false,
        isFavorite: false,
        message: 'Necesitas iniciar sesión para guardar favoritos.',
      );
    }

    final favorites = await _getLocalFavorites(session.personaId);
    if (favorites.contains(productId)) {
      return removeFromFavorites(productId);
    }

    return addToFavorites(productId);
  }

  /// Verificar si un producto está en favoritos
  static Future<bool> isFavorite(String productId) async {
    final favorites = await getFavoriteIds();
    return favorites.contains(productId);
  }

  /// Obtener cantidad de favoritos
  static Future<int> getFavoritesCount() async {
    final favorites = await getFavoriteIds();
    return favorites.length;
  }

  /// Limpiar todos los favoritos (solo local, no afecta backend)
  static Future<bool> clearFavorites() async {
    try {
      final session = await _readSession();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKeyForPersona(session.personaId));
      await prefs.remove(_favoritesKey);
      log('Local favorites cleared');
      return true;
    } catch (e) {
      log('Error clearing favorites: $e');
      return false;
    }
  }

  /// Sincronizar favoritos del backend al iniciar sesión
  static Future<void> syncFavorites() async {
    try {
      final session = await _readSession();
      if (!session.canUseBackend) {
        log('No active session found, skipping favorites sync');
        return;
      }

      log('Syncing favorites for persona: ${session.personaId}');
      final favorites = await getFavoriteIds(
        forceRefresh: true,
        personaId: session.personaId,
      );
      log('Favorites synced successfully: ${favorites.length} items');
    } catch (e) {
      log('Error syncing favorites: $e');
    }
  }

  // ==================== MÉTODOS PRIVADOS ====================

  /// Obtener favoritos locales
  static Future<List<String>> _getLocalFavorites(String personaId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson =
          prefs.getStringList(_cacheKeyForPersona(personaId)) ??
          prefs.getStringList(_favoritesKey);
      return favoritesJson ?? [];
    } catch (e) {
      log('Error getting local favorites: $e');
      return [];
    }
  }

  /// Guardar favoritos en SharedPreferences
  static Future<void> _saveFavorites(
    List<String> favorites,
    String personaId,
  ) async {
    log('Saving ${favorites.length} favorites to local storage: $favorites');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_cacheKeyForPersona(personaId), favorites);
    await prefs.setStringList(_favoritesKey, favorites);
    log('Favorites saved successfully');
  }

  static String _cacheKeyForPersona(String personaId) {
    if (personaId.isEmpty) {
      return _favoritesKey;
    }
    return '${_favoritesKey}_$personaId';
  }

  static Future<_FavoriteValidationResult> _validateFavoriteAction(
    String productId,
  ) async {
    if (productId.trim().isEmpty) {
      return const _FavoriteValidationResult(
        success: false,
        message: 'No se pudo identificar el producto seleccionado.',
      );
    }

    final session = await _readSession();
    if (!session.isLoggedIn) {
      return const _FavoriteValidationResult(
        success: false,
        message: 'Necesitas iniciar sesión para guardar favoritos.',
      );
    }

    if (session.personaId.isEmpty) {
      return const _FavoriteValidationResult(
        success: false,
        message: 'No pudimos identificar tu perfil. Vuelve a iniciar sesión.',
      );
    }

    if (session.token.isEmpty) {
      return const _FavoriteValidationResult(
        success: false,
        message: 'Tu sesión expiró. Inicia sesión nuevamente.',
      );
    }

    return _FavoriteValidationResult(
      success: true,
      message: '',
      session: session,
    );
  }

  static Future<_FavoriteSession> _readSession({String? personaId}) async {
    final prefs = await SharedPreferences.getInstance();

    final resolvedPersonaId =
        personaId ??
        prefs.getString('uuid') ??
        prefs.getString('userUuid') ??
        prefs.getString('userUUID') ??
        '';

    return _FavoriteSession(
      personaId: resolvedPersonaId,
      token: prefs.getString('token') ?? '',
      isLoggedIn: prefs.getBool('isLoggedIn') ?? false,
    );
  }

  /// Obtener favoritos del usuario desde el backend
  static Future<List<_FavoriteRecord>> _fetchFavoriteRecordsFromBackend(
    _FavoriteSession session,
  ) async {
    try {
      log('Fetching favorites from backend for persona: ${session.personaId}');

      for (final endpoint in [MarketplaceConstants.favoriteFilterUrl]) {
        final body = jsonEncode(_favoriteRequestBody(session.personaId));
        log('Requesting favorites from $endpoint with body: $body');
        final response = await http.post(
          Uri.parse(endpoint),
          headers: _buildHeaders(session.token),
          body: body,
        );

        log('Favorites response ($endpoint): ${response.statusCode}');
        final data = _decodeResponse(response);

        if (response.statusCode != 200) {
          log(
            'Backend indicated failure fetching favorites at $endpoint: ${data['message'] ?? data['error']}',
          );
          continue;
        }

        if (data['response'] != true) {
          continue;
        }

        final List<dynamic> favoritesData = data['data'] ?? [];
        final favorites = favoritesData
            .whereType<Map<String, dynamic>>()
            .map(_parseFavoriteRecord)
            .whereType<_FavoriteRecord>()
            .toList();

        log('Fetched ${favorites.length} favorites from backend');
        return favorites;
      }

      return [];
    } catch (e) {
      log('Error fetching favorites from backend: $e');
      return [];
    }
  }

  /// Agregar favorito al backend
  static Future<_FavoriteBackendResult> _addFavoriteToBackend(
    _FavoriteSession session,
    String productId,
  ) async {
    try {
      for (final endpoint in [MarketplaceConstants.favoriteUrl]) {
        final body = jsonEncode(
          _favoriteRequestBody(session.personaId, productId: productId),
        );
        log('Adding favorite to backend at $endpoint with body: $body');

        final response = await http.post(
          Uri.parse(endpoint),
          headers: _buildHeaders(session.token),
          body: body,
        );

        log('Add favorite response ($endpoint): ${response.statusCode}');

        if (response.statusCode != 200 && response.statusCode != 201) {
          log('Failed to add favorite at $endpoint: ${response.body}');
          continue;
        }

        final data = _decodeResponse(response);
        final message =
            data['message']?.toString() ?? 'Producto agregado a favoritos.';
        final wasSuccessful = data['response'] == true;

        if (wasSuccessful || _looksLikeDuplicateMessage(message)) {
          return _FavoriteBackendResult(
            success: true,
            message: wasSuccessful
                ? message
                : 'Este producto ya estaba en tus favoritos.',
          );
        }
      }

      return const _FavoriteBackendResult(
        success: false,
        message: 'No se pudo agregar el producto a favoritos.',
      );
    } catch (e) {
      log('Error adding favorite to backend: $e');
      return const _FavoriteBackendResult(
        success: false,
        message: 'No se pudo agregar el producto a favoritos.',
      );
    }
  }

  /// Eliminar favorito del backend
  static Future<_FavoriteBackendResult> _removeFavoriteFromBackend(
    _FavoriteSession session,
    String favoriteId,
  ) async {
    try {
      log('Removing favorite from backend - favoriteId: $favoriteId');

      for (final endpoint in [MarketplaceConstants.favoriteUrl]) {
        final response = await http.post(
          Uri.parse('$endpoint/delete/$favoriteId'),
          headers: _buildHeaders(session.token),
        );

        log('Remove favorite response ($endpoint): ${response.statusCode}');

        if (response.statusCode == 200 || response.statusCode == 204) {
          return const _FavoriteBackendResult(
            success: true,
            message: 'Producto eliminado de favoritos.',
          );
        }
      }

      return const _FavoriteBackendResult(
        success: false,
        message: 'No se pudo quitar el producto de favoritos.',
      );
    } catch (e) {
      log('Error removing favorite from backend: $e');
      return const _FavoriteBackendResult(
        success: false,
        message: 'No se pudo quitar el producto de favoritos.',
      );
    }
  }

  /// Obtener el _id del favorito en el backend (necesario para eliminarlo)
  static Future<String?> _getFavoriteIdFromBackend(
    _FavoriteSession session,
    String productId,
  ) async {
    final favorite = await _getFavoriteRecordFromBackend(session, productId);
    return favorite?.id;
  }

  static Future<_FavoriteRecord?> _getFavoriteRecordFromBackend(
    _FavoriteSession session,
    String productId,
  ) async {
    try {
      final favorites = await _fetchFavoriteRecordsFromBackend(session);
      for (final favorite in favorites) {
        if (favorite.productId == productId) {
          return favorite;
        }
      }

      return null;
    } catch (e) {
      log('Error getting favorite ID from backend: $e');
      return null;
    }
  }

  static Map<String, String> _buildHeaders(String token) {
    return {'Content-Type': 'application/json', 'Authorization': token};
  }

  static Map<String, dynamic> _favoriteRequestBody(
    String personaId, {
    String? productId,
  }) {
    final body = <String, dynamic>{'persona': personaId};

    if (productId != null) {
      body['product'] = productId;
    }

    return body;
  }

  static Map<String, dynamic> _decodeResponse(http.Response response) {
    try {
      return jsonDecode(utf8.decode(response.bodyBytes))
          as Map<String, dynamic>;
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  static _FavoriteRecord? _parseFavoriteRecord(Map<String, dynamic> favorite) {
    final favoriteId =
        favorite['_id']?.toString() ?? favorite['id']?.toString();
    final productId = _extractProductId(favorite);

    if (favoriteId == null || favoriteId.isEmpty || productId.isEmpty) {
      return null;
    }

    return _FavoriteRecord(id: favoriteId, productId: productId);
  }

  static String _extractProductId(Map<String, dynamic> favorite) {
    final productData =
        favorite['product'] ??
        favorite['productId'] ??
        favorite['itemId'] ??
        favorite['item'];

    if (productData is String) {
      return productData;
    }

    if (productData is Map) {
      return productData['_id']?.toString() ??
          productData['id']?.toString() ??
          '';
    }

    return '';
  }

  static bool _looksLikeDuplicateMessage(String message) {
    final normalizedMessage = message.toLowerCase();
    return normalizedMessage.contains('ya existe') ||
        normalizedMessage.contains('already exists') ||
        normalizedMessage.contains('duplicate');
  }
}

class _FavoriteValidationResult {
  const _FavoriteValidationResult({
    required this.success,
    required this.message,
    this.session,
  });

  final bool success;
  final String message;
  final _FavoriteSession? session;
}

class _FavoriteSession {
  const _FavoriteSession({
    required this.personaId,
    required this.token,
    required this.isLoggedIn,
  });

  final String personaId;
  final String token;
  final bool isLoggedIn;

  bool get canUseBackend =>
      isLoggedIn && personaId.isNotEmpty && token.isNotEmpty;
}

class _FavoriteRecord {
  const _FavoriteRecord({required this.id, required this.productId});

  final String id;
  final String productId;
}

class _FavoriteBackendResult {
  const _FavoriteBackendResult({required this.success, required this.message});

  final bool success;
  final String message;
}
