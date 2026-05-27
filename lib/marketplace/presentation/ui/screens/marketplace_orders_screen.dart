import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../config/theme/marketplace_theme.dart';
import '../../../../src/presentation/providers/modes/modes_provider.dart';
import '../../../../src/presentation/providers/profile/profile_provider.dart';
import '../../../../src/presentation/ui/auth/views/login_view.dart';
import '../../../domain/models/marketplace_order.dart';
import '../../../services/marketplace_order_service.dart';
import '../../../presentation/widgets/marketplace_card.dart';

class MarketplaceOrdersScreen extends ConsumerStatefulWidget {
  const MarketplaceOrdersScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  ConsumerState<MarketplaceOrdersScreen> createState() =>
      _MarketplaceOrdersScreenState();
}

class _MarketplaceOrdersScreenState
    extends ConsumerState<MarketplaceOrdersScreen> {
  Future<List<MarketplaceOrderRecord>>? _ordersFuture;
  String? _loadedPersona;

  Future<List<MarketplaceOrderRecord>> _fetchOrders(String persona) async {
    final response = await MarketplaceOrderService.getOrders(
      persona: persona,
      logic: 'a',
    );

    if (response['response'] == true) {
      return List<MarketplaceOrderRecord>.from(response['data'] ?? const []);
    }

    throw Exception(
      response['message']?.toString() ?? 'No se pudieron cargar las órdenes',
    );
  }

  void _ensureOrdersLoaded(String persona) {
    if (_loadedPersona == persona && _ordersFuture != null) {
      return;
    }

    _loadedPersona = persona;
    _ordersFuture = _fetchOrders(persona);
  }

  Future<void> _refreshOrders(String persona) async {
    setState(() {
      _loadedPersona = persona;
      _ordersFuture = _fetchOrders(persona);
    });
    await _ordersFuture;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(marketplaceOrdersRefreshProvider, (_, _) {
      _loadedPersona = null;
    });

    final userAsync = ref.watch(userProfileProvider);
    final content = userAsync.when(
      data: (user) {
        _ensureOrdersLoaded(user.id);

        return FutureBuilder<List<MarketplaceOrderRecord>>(
          future: _ordersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return _buildMessageState(
                icon: Icons.receipt_long_outlined,
                title: 'No se pudieron cargar tus órdenes',
                message: snapshot.error.toString().replaceFirst(
                  'Exception: ',
                  '',
                ),
                actionLabel: 'Reintentar',
                onAction: () => _refreshOrders(user.id),
              );
            }

            final orders = snapshot.data ?? const <MarketplaceOrderRecord>[];
            if (orders.isEmpty) {
              return RefreshIndicator(
                onRefresh: () => _refreshOrders(user.id),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  children: const [SizedBox(height: 80), _OrdersEmptyState()],
                ),
              );
            }

            final currency = NumberFormat.currency(
              symbol: r'$',
              decimalDigits: 2,
            );

            return RefreshIndicator(
              onRefresh: () => _refreshOrders(user.id),
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                itemCount: orders.length + 1,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _OrdersHeader(count: orders.length);
                  }

                  final order = orders[index - 1];
                  return _OrderCard(order: order, currency: currency);
                },
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => _buildMessageState(
        icon: Icons.lock_outline_rounded,
        title: 'Inicia sesión para ver tus órdenes',
        message:
            'Necesitas una cuenta activa para consultar el estado de tus pedidos.',
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
      appBar: AppBar(title: const Text('Mis órdenes')),
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
            ElevatedButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}

class _OrdersHeader extends StatelessWidget {
  const _OrdersHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tus pedidos',
            style: MarketplaceTheme.titleLargeTextStyle(
              context,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$count ${count == 1 ? "orden registrada" : "órdenes registradas"}',
            style: MarketplaceTheme.bodyMediumTextStyle(
              context,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.currency});

  final MarketplaceOrderRecord order;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    final dateLabel = order.createdAt != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt!.toLocal())
        : 'Fecha no disponible';

    return MarketplaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.displayCode.isNotEmpty
                          ? order.displayCode
                          : 'Orden sin código',
                      style: MarketplaceTheme.titleSmallTextStyle(
                        context,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateLabel,
                      style: MarketplaceTheme.bodySmallTextStyle(
                        context,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                currency.format(order.total),
                style: MarketplaceTheme.titleSmallTextStyle(
                  context,
                  fontWeight: FontWeight.w800,
                  color: MarketplaceTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatusChip(
                icon: Icons.payments_outlined,
                label: _paymentStatusLabel(order.paymentStatus),
                color: _paymentStatusColor(order.paymentStatus),
              ),
              _StatusChip(
                icon: Icons.local_shipping_outlined,
                label: _deliveryStatusLabel(order.deliveryStatus),
                color: _deliveryStatusColor(order.deliveryStatus),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            order.itemsPreview,
            style: MarketplaceTheme.bodyMediumTextStyle(
              context,
              fontWeight: FontWeight.w600,
              color: MarketplaceTheme.secondayBlack,
            ),
          ),
          if (order.itemCount > 2) ...[
            const SizedBox(height: 4),
            Text(
              '+${order.itemCount - 2} producto${order.itemCount - 2 == 1 ? "" : "s"} más',
              style: MarketplaceTheme.bodySmallTextStyle(
                context,
                color: Colors.grey.shade600,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.shopping_bag_outlined,
                  size: 18,
                  color: Colors.grey.shade700,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${order.itemCount} producto${order.itemCount == 1 ? "" : "s"}',
                    style: MarketplaceTheme.bodyMediumTextStyle(
                      context,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
                Text(
                  'IVA ${currency.format(order.iva)}',
                  style: MarketplaceTheme.bodySmallTextStyle(
                    context,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: MarketplaceTheme.labelMediumTextStyle(
              context,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrdersEmptyState extends StatelessWidget {
  const _OrdersEmptyState();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(Icons.inventory_2_outlined, size: 88, color: Colors.grey.shade300),
        const SizedBox(height: 20),
        Text(
          'Aún no tienes órdenes',
          textAlign: TextAlign.center,
          style: MarketplaceTheme.titleMediumTextStyle(
            context,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Cuando realices una compra podrás revisar aquí el estado de pago y entrega.',
          textAlign: TextAlign.center,
          style: MarketplaceTheme.bodyMediumTextStyle(
            context,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}

String _paymentStatusLabel(String status) {
  switch (status.toLowerCase()) {
    case 'paid':
    case 'approved':
    case 'completed':
      return 'Pago aprobado';
    case 'rejected':
    case 'failed':
      return 'Pago rechazado';
    case 'cancelled':
    case 'canceled':
      return 'Pago cancelado';
    case 'pending':
    default:
      return 'Pago pendiente';
  }
}

Color _paymentStatusColor(String status) {
  switch (status.toLowerCase()) {
    case 'paid':
    case 'approved':
    case 'completed':
      return Colors.green.shade700;
    case 'rejected':
    case 'failed':
    case 'cancelled':
    case 'canceled':
      return Colors.red.shade700;
    case 'pending':
    default:
      return MarketplaceTheme.primary;
  }
}

String _deliveryStatusLabel(String status) {
  switch (status.toLowerCase()) {
    case 'delivered':
      return 'Entregado';
    case 'shipped':
      return 'Enviado';
    case 'processing':
    case 'preparing':
      return 'En preparación';
    case 'cancelled':
    case 'canceled':
      return 'Cancelado';
    case 'pending':
    default:
      return 'Pendiente';
  }
}

Color _deliveryStatusColor(String status) {
  switch (status.toLowerCase()) {
    case 'delivered':
      return Colors.green.shade700;
    case 'shipped':
      return Colors.blue.shade700;
    case 'processing':
    case 'preparing':
      return Colors.deepPurple.shade400;
    case 'cancelled':
    case 'canceled':
      return Colors.red.shade700;
    case 'pending':
    default:
      return MarketplaceTheme.primary;
  }
}
