// Barrel file - Marketplace Module
// Exporta todos los archivos del marketplace para importación simple

// Models
export 'domain/models/cart_item.dart';
export 'domain/models/marketplace_category.dart';
export 'domain/models/marketplace_entities.dart';
export 'domain/models/marketplace_product.dart';

// Services
export 'services/cart_service.dart';
export 'services/favorites_service.dart';
export 'helpers/marketplace_helpers.dart';

// Providers
export 'presentation/providers/cart_provider.dart';

// Screens
export 'presentation/ui/screens/cart_screen.dart';
export 'presentation/ui/screens/categories_screen.dart';
export 'presentation/ui/screens/marketplace_landing_screen.dart';
export 'presentation/ui/screens/marketplace_orders_screen.dart';
export 'presentation/ui/screens/marketplace_favorites_screen.dart';
export 'presentation/ui/screens/marketplace_profile_screen.dart';
export 'presentation/ui/screens/marketplace_search_screen.dart';
export 'presentation/ui/screens/product_detail_screen.dart';

// Widgets
export 'presentation/widgets/category_widget.dart';
export 'presentation/widgets/filters_bottom_sheet.dart';
export 'presentation/widgets/marketplace_badge.dart';
export 'presentation/widgets/marketplace_button.dart';
export 'presentation/widgets/marketplace_card.dart';
export 'presentation/widgets/marketplace_dialog.dart';
export 'presentation/widgets/marketplace_loading_indicator.dart';
export 'presentation/widgets/marketplace_search_bar.dart';
export 'presentation/widgets/marketplace_widgets.dart';
export 'presentation/widgets/product_card.dart';
export 'presentation/widgets/product_card_skeleton.dart';
