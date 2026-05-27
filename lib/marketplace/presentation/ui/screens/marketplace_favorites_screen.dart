import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme/marketplace_theme.dart';
import '../../../domain/models/marketplace_product.dart';
import 'product_detail_screen.dart';
import '../../../services/favorites_service.dart';
import '../../widgets/marketplace_button.dart';
import '../../widgets/marketplace_card.dart';
import '../../widgets/product_card.dart';
import '../../../../src/presentation/providers/profile/profile_provider.dart';
import '../../../../src/presentation/ui/auth/views/login_view.dart';

class MarketplaceFavoritesScreen extends ConsumerStatefulWidget {
  const MarketplaceFavoritesScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  ConsumerState<MarketplaceFavoritesScreen> createState() =>
      _MarketplaceFavoritesScreenState();
}

class _MarketplaceFavoritesScreenState
    extends ConsumerState<MarketplaceFavoritesScreen> {
  Future<List<MarketplaceProduct>>? _favoritesFuture;
  String? _loadedPersona;
  final Set<String> _updatingProductIds = <String>{};

  Future<List<MarketplaceProduct>> _fetchFavorites(String persona) async {
    return FavoritesService.getFavoriteProducts(
      forceRefresh: true,
      personaId: persona,
    );
  }

  void _ensureFavoritesLoaded(String persona) {
    if (_loadedPersona == persona && _favoritesFuture != null) {
      return;
    }

    _loadedPersona = persona;
    _favoritesFuture = _fetchFavorites(persona);
  }

  Future<void> _refreshFavorites(String persona) async {
    setState(() {
      _loadedPersona = persona;
      _favoritesFuture = _fetchFavorites(persona);
    });
    await _favoritesFuture;
  }

  Future<void> _removeFavorite(String persona, String productId) async {
    if (_updatingProductIds.contains(productId)) {
      return;
    }

    setState(() {
      _updatingProductIds.add(productId);
    });

    final result = await FavoritesService.removeFromFavorites(productId);
    if (!mounted) {
      return;
    }

    setState(() {
      _updatingProductIds.remove(productId);
    });

    if (!result.success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));
      return;
    }

    await _refreshFavorites(persona);
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProfileProvider);
    final content = userAsync.when(
      data: (user) {
        _ensureFavoritesLoaded(user.id);

        return FutureBuilder<List<MarketplaceProduct>>(
          future: _favoritesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return _buildMessageState(
                icon: Icons.favorite_border_rounded,
                title: 'No se pudieron cargar tus favoritos',
                message: snapshot.error.toString().replaceFirst(
                  'Exception: ',
                  '',
                ),
                actionLabel: 'Reintentar',
                onAction: () => _refreshFavorites(user.id),
              );
            }

            final favorites = snapshot.data ?? const <MarketplaceProduct>[];
            if (favorites.isEmpty) {
              return RefreshIndicator(
                onRefresh: () => _refreshFavorites(user.id),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  children: const [
                    SizedBox(height: 80),
                    _FavoritesEmptyState(),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () => _refreshFavorites(user.id),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: _FavoritesHeader(count: favorites.length),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.68,
                          ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final product = favorites[index];
                        final isUpdating = _updatingProductIds.contains(
                          product.id,
                        );

                        return Opacity(
                          opacity: isUpdating ? 0.6 : 1,
                          child: ProductCard(
                            product: product,
                            isFavorite: true,
                            onFavorite: () =>
                                _removeFavorite(user.id, product.id),
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ProductDetailScreen(
                                    productId: product.id,
                                    product: product,
                                  ),
                                ),
                              );

                              if (!mounted) {
                                return;
                              }
                              await _refreshFavorites(user.id);
                            },
                          ),
                        );
                      }, childCount: favorites.length),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => _buildMessageState(
        icon: Icons.lock_outline_rounded,
        title: 'Inicia sesión para ver tus favoritos',
        message:
            'Necesitas una cuenta activa para consultar los productos que guardaste.',
        actionLabel: 'Iniciar sesión',
        onAction: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LoginView()),
          );
        },
      ),
    );

    if (widget.embedded) {
      return ColoredBox(color: Colors.grey.shade50, child: content);
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(title: const Text('Mis favoritos')),
      body: content,
    );
  }

  Widget _buildMessageState({
    required IconData icon,
    required String title,
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 72, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: MarketplaceTheme.titleMediumTextStyle(
                context,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: MarketplaceTheme.bodyMediumTextStyle(
                context,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 16),
            MarketplaceButton(text: actionLabel, onPressed: onAction),
          ],
        ),
      ),
    );
  }
}

class _FavoritesHeader extends StatelessWidget {
  const _FavoritesHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tus favoritos',
          style: MarketplaceTheme.titleLargeTextStyle(
            context,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '$count ${count == 1 ? "producto guardado" : "productos guardados"}',
          style: MarketplaceTheme.bodyMediumTextStyle(
            context,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}

class _FavoritesEmptyState extends StatelessWidget {
  const _FavoritesEmptyState();

  @override
  Widget build(BuildContext context) {
    return MarketplaceCard(
      elevated: false,
      borderRadius: 24,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 36),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: MarketplaceTheme.primary50,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite_border_rounded,
                color: MarketplaceTheme.primary,
                size: 34,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Aún no has guardado favoritos',
              textAlign: TextAlign.center,
              style: MarketplaceTheme.titleMediumTextStyle(
                context,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Marca con el corazón los productos que quieras revisar más tarde.',
              textAlign: TextAlign.center,
              style: MarketplaceTheme.bodyMediumTextStyle(
                context,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
