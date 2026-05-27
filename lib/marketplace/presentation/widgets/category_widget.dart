import 'package:flutter/material.dart';

import '../../domain/models/marketplace_category.dart';
import '../ui/screens/categories_screen.dart';
import '/config/theme/app_theme.dart';
import 'marketplace_card.dart';

/// Widget de categoría para el Marketplace
/// Diseño inspirado en Apple Store y Amazon categorías
class CategoryWidget extends StatelessWidget {
  const CategoryWidget({
    super.key,
    required this.category,
    this.onTap,
    this.compact = false,
  });
  final MarketplaceCategory category;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _CompactCategoryWidget(category: category, onTap: onTap);
    }
    return _FullCategoryWidget(category: category, onTap: onTap);
  }
}

/// Versión compacta para grid horizontal
class _CompactCategoryWidget extends StatelessWidget {
  const _CompactCategoryWidget({required this.category, this.onTap});
  final MarketplaceCategory category;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 85,
        child: Column(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: category.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: category.color.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Icon(category.icon, size: 32, color: category.color),
            ),
            const SizedBox(height: 8),
            Text(
              category.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Versión completa para listados
class _FullCategoryWidget extends StatelessWidget {
  const _FullCategoryWidget({required this.category, this.onTap});
  final MarketplaceCategory category;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return MarketplaceCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Icono
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: category.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(category.icon, size: 28, color: category.color),
          ),
          const SizedBox(width: 16),
          // Información
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      category.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (category.isPopular) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLowestShade,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'POPULAR',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  category.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 6),
                if (category.productCount > 0)
                  Text(
                    '${category.productCount} productos',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          // Icono de flecha
          Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
        ],
      ),
    );
  }
}

/// Grid horizontal de categorías populares
class PopularCategoriesWidget extends StatelessWidget {
  const PopularCategoriesWidget({
    super.key,
    required this.categories,
    this.onCategoryTap,
    this.onViewAllCategorySelected,
  });
  final List<MarketplaceCategory> categories;
  final Function(MarketplaceCategory)? onCategoryTap;
  final Function(String)? onViewAllCategorySelected;

  @override
  Widget build(BuildContext context) {
    final popularCategories = categories.where((c) => c.isPopular).toList();
    final visibleCategories = popularCategories.isNotEmpty
        ? popularCategories
        : categories.take(4).toList();

    if (visibleCategories.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Categorías Populares',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              TextButton(
                onPressed: () async {
                  final selectedCategory = await Navigator.push<String>(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          CategoriesScreen(categories: categories),
                    ),
                  );
                  if (selectedCategory != null) {
                    onViewAllCategorySelected?.call(selectedCategory);
                  }
                },
                child: const Text(
                  'Ver todas',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: visibleCategories.length,
            itemBuilder: (context, index) {
              final category = visibleCategories[index];
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: CategoryWidget(
                  category: category,
                  compact: true,
                  onTap: () => onCategoryTap?.call(category),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
