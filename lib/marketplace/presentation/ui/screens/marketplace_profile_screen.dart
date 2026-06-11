import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../widgets/marketplace_button.dart';
import '../../widgets/marketplace_card.dart';
import '/config/theme/app_theme.dart';
import 'marketplace_favorites_screen.dart';
import 'marketplace_orders_screen.dart';

/// Pantalla de perfil del marketplace - Inspirado en Amazon, Mercado Libre
class MarketplaceProfileScreen extends StatefulWidget {
  const MarketplaceProfileScreen({super.key});

  @override
  State<MarketplaceProfileScreen> createState() =>
      _MarketplaceProfileScreenState();
}

class _MarketplaceProfileScreenState extends State<MarketplaceProfileScreen> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  String _userName = '';
  String _userEmail = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName =
          _currentUser?.displayName ?? prefs.getString('userName') ?? 'Usuario';
      _userEmail = _currentUser?.email ?? prefs.getString('userEmail') ?? '';
    });
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await FirebaseAuth.instance.signOut();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isMarketplaceUser', false);
        await prefs.remove('isLoggedIn');

        if (mounted) {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/mode-selection', (route) => false);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error al cerrar sesión: $e')));
        }
      }
    }
  }

  Future<void> _switchToAdminMode() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cambiar a modo Admin'),
        content: const Text(
          '¿Deseas cambiar al modo administrador?\n\nPodrás volver al marketplace desde tu perfil de administrador.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cambiar'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isMarketplaceUser', false);

      if (mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/home', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        elevation: 0,
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // User Header
            _buildUserHeader(),

            const SizedBox(height: 16),

            // Main Menu Options
            _buildMenuSection(
              title: 'Mi Cuenta',
              items: [
                _MenuItem(
                  icon: Icons.person,
                  title: 'Información Personal',
                  subtitle: 'Editar nombre, teléfono y email',
                  onTap: _navigateToEditProfile,
                ),
                _MenuItem(
                  icon: Icons.shopping_bag,
                  title: 'Mis Pedidos',
                  subtitle: 'Ver historial de compras',
                  onTap: _navigateToOrders,
                ),
                _MenuItem(
                  icon: Icons.favorite,
                  title: 'Mis Favoritos',
                  subtitle: 'Ver productos guardados',
                  onTap: _navigateToFavorites,
                ),
                _MenuItem(
                  icon: Icons.location_on,
                  title: 'Direcciones',
                  subtitle: 'Gestionar direcciones de envío',
                  onTap: _navigateToAddresses,
                ),
                _MenuItem(
                  icon: Icons.credit_card,
                  title: 'Métodos de Pago',
                  subtitle: 'Tarjetas y métodos guardados',
                  onTap: _navigateToPaymentMethods,
                ),
              ],
            ),

            const SizedBox(height: 16),

            _buildMenuSection(
              title: 'Preferencias',
              items: [
                _MenuItem(
                  icon: Icons.notifications,
                  title: 'Notificaciones',
                  subtitle: 'Configurar alertas y notificaciones',
                  onTap: _navigateToNotifications,
                ),
                _MenuItem(
                  icon: Icons.dark_mode,
                  title: 'Modo Oscuro',
                  subtitle: 'Próximamente disponible',
                  trailing: const Switch(value: false, onChanged: null),
                  onTap: null,
                ),
              ],
            ),

            const SizedBox(height: 16),

            _buildMenuSection(
              title: 'Soporte',
              items: [
                _MenuItem(
                  icon: Icons.help_outline,
                  title: 'Centro de Ayuda',
                  subtitle: 'Preguntas frecuentes y soporte',
                  onTap: _navigateToHelp,
                ),
                _MenuItem(
                  icon: Icons.message,
                  title: 'Contáctanos',
                  subtitle: 'Chat, email o teléfono',
                  onTap: _navigateToContact,
                ),
                _MenuItem(
                  icon: Icons.description,
                  title: 'Términos y Condiciones',
                  subtitle: 'Políticas y privacidad',
                  onTap: _navigateToTerms,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Admin Mode Switch
            if (_currentUser != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: MarketplaceCard(
                  onTap: _switchToAdminMode,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.grid_on,
                            color: Colors.blue[700],
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Cambiar a Modo Admin',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Gestiona tu negocio',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: Colors.grey[400]),
                      ],
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Logout
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: MarketplaceButton(
                text: 'Cerrar Sesión',
                onPressed: _logout,
                variant: MarketplaceButtonVariant.outline,
                size: MarketplaceButtonSize.large,
                icon: Icons.logout,
              ),
            ),

            const SizedBox(height: 16),

            // Version info
            Text(
              'Versión 1.0.0',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildUserHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.primary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Avatar
              Stack(
                children: [
                  CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 43,
                      backgroundImage: _currentUser?.photoURL != null
                          ? NetworkImage(_currentUser!.photoURL!)
                          : null,
                      backgroundColor: Colors.grey[200],
                      child: _currentUser?.photoURL == null
                          ? Icon(
                              Icons.person,
                              size: 40,
                              color: Colors.grey[400],
                            )
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _navigateToEditProfile,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.primary, width: 2),
                        ),
                        child: const Icon(
                          Icons.camera,
                          size: 16,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Name
              Text(
                _userName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 4),

              // Email
              if (_userEmail.isNotEmpty)
                Text(
                  _userEmail,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuSection({
    required String title,
    required List<_MenuItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
              letterSpacing: 0.5,
            ),
          ),
        ),
        MarketplaceCard(
          child: Column(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                _buildMenuItem(items[i]),
                if (i < items.length - 1)
                  Divider(height: 1, color: Colors.grey[200]),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(_MenuItem item) {
    return InkWell(
      onTap: item.onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(item.icon, color: AppTheme.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
                  ),
                  if (item.subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle!,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ],
              ),
            ),
            if (item.trailing != null)
              item.trailing!
            else if (item.onTap != null)
              Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  // Navegación a pantallas (placeholders por ahora)
  void _navigateToEditProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Editar perfil - Próximamente')),
    );
  }

  void _navigateToOrders() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MarketplaceOrdersScreen()),
    );
  }

  void _navigateToFavorites() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MarketplaceFavoritesScreen()),
    );
  }

  void _navigateToAddresses() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Direcciones - Próximamente disponible')),
    );
  }

  void _navigateToPaymentMethods() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Métodos de pago - Próximamente disponible'),
      ),
    );
  }

  void _navigateToNotifications() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notificaciones - Próximamente disponible')),
    );
  }

  void _navigateToHelp() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Centro de ayuda - Próximamente disponible'),
      ),
    );
  }

  void _navigateToContact() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Contáctanos - Próximamente disponible')),
    );
  }

  void _navigateToTerms() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Términos y condiciones - Próximamente disponible'),
      ),
    );
  }
}

class _MenuItem {
  _MenuItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
}
