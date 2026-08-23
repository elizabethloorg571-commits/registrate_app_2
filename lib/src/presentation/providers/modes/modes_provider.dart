import 'package:flutter_riverpod/legacy.dart';
import 'package:running_app/src/domain/models/bank_transfer_info.dart';

final bottomNavigationIndexProvider = StateProvider<int>((ref) => 1);

final ticketBuyingModeEnabledProvider = StateProvider<bool>((ref) => false);

enum MarketplaceSection { home, offers, cart, orders }

final marketplaceSectionProvider = StateProvider<MarketplaceSection>(
  (ref) => MarketplaceSection.home,
);

final marketplaceOrdersRefreshProvider = StateProvider<int>((ref) => 0);

/// Almacena la configuración de métodos de pago del catálogo activo.
final marketplacePaymentSettingsProvider =
    StateProvider<MarketplacePaymentSettings>((ref) {
      return const MarketplacePaymentSettings();
    });

class MarketplacePaymentSettings {
  final bool isApplyTC;
  final bool isApplyDeuna;
  final bool isApplyManual;
  final BankTransferInfo? bankInfo;

  const MarketplacePaymentSettings({
    this.isApplyTC = true,
    this.isApplyDeuna = true,
    this.isApplyManual = false,
    this.bankInfo,
  });
}
