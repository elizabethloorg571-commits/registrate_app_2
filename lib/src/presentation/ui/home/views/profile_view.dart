import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:running_app/app_localizations_context.dart';
import 'package:running_app/services/shared_service.dart';
import 'package:running_app/src/domain/models/user.dart';
import 'package:running_app/src/presentation/providers/modes/modes_provider.dart';
import 'package:running_app/src/presentation/providers/profile/profile_provider.dart';
import 'package:running_app/src/presentation/ui/home/utils/home_svg_files.dart';
import 'package:running_app/src/presentation/ui/profile/account_screen.dart';
import 'package:running_app/src/presentation/widgets/global_widgets.dart';
import 'package:running_app/config/theme/app_theme.dart';
import 'package:running_app/config/theme/fonts.dart';

class ProfileView extends ConsumerStatefulWidget {
  const ProfileView({super.key, required this.user, this.offlineView = false});

  final User user;
  final bool offlineView;

  @override
  ProfileViewState createState() => ProfileViewState();
}

class ProfileViewState extends ConsumerState<ProfileView> {
  // final bool _notificationsEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.l1on.profile,
          style: nunitoSansTitleLargeStyle(
            context,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: GlobalWidgets.pagePadding(context),
          child: Column(
            children: [
              const SizedBox(height: 24),

              // Avatar y datos del usuario
              Column(
                children: [
                  // Avatar circular
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage: widget.user.foto.isNotEmpty
                        ? NetworkImage(widget.user.foto)
                        : null,
                    child: widget.user.foto.isEmpty
                        ? Icon(
                            Icons.person,
                            size: 50,
                            color: Colors.grey.shade600,
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // Nombre completo
                  Text(
                    '${widget.user.nombres} ${widget.user.apellidos}',
                    style: nunitoSansTitleLargeStyle(
                      context,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),

                  // Email
                  Text(
                    widget.user.email,
                    style: nunitoSansBodyMediumStyle(
                      context,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // Opciones del menú
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _buildMenuOption(
                      icon: SvgPicture.string(
                        kAccountIconSvg,
                        width: 25,
                        height: 25,
                      ),
                      title: context.l1on.account,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                AccountScreen(user: widget.user),
                          ),
                        );
                      },
                    ),
                    _buildMenuOption(
                      icon: SvgPicture.string(
                        kCompetitionsHistoryIconSvg,
                        width: 25,
                        height: 25,
                      ),
                      title: context.l1on.raceHistory,
                      onTap: () {
                        ref.read(bottomNavigationIndexProvider.notifier).state =
                            2;
                      },
                    ),

                    // _buildMenuOption(
                    //   icon: SvgPicture.string(
                    //     kLanguageIconSvg,
                    //     width: 25,
                    //     height: 25,
                    //   ),
                    //   title: context.l1on.language,
                    //   onTap: () {
                    //     Navigator.push(
                    //       context,
                    //       MaterialPageRoute(
                    //         builder: (context) => const LanguageScreen(),
                    //       ),
                    //     );
                    //   },
                    // ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Container(
                decoration: BoxDecoration(
                  color: AppTheme.primaryLowestShade,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.primaryLowShade.withValues(alpha: 0.9),
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Marketplace',
                      style: nunitoSansTitleSmallStyle(
                        context,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.secondayBlack,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Accesos rápidos para la tienda y tu carrito.',
                      style: nunitoSansBodySmallStyle(
                        context,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildMarketplaceOption(
                      icon: Icons.storefront_outlined,
                      title: 'Abrir tienda',
                      subtitle: 'Explora productos disponibles',
                      onTap: () {
                        ref.read(marketplaceSectionProvider.notifier).state =
                            MarketplaceSection.home;
                        ref.read(bottomNavigationIndexProvider.notifier).state =
                            3;
                      },
                    ),
                    Divider(
                      color: AppTheme.primaryLowShade.withValues(alpha: 0.9),
                    ),
                    _buildMarketplaceOption(
                      icon: Icons.shopping_bag_outlined,
                      title: 'Mi carrito',
                      subtitle: 'Revisa tus productos antes de pagar',
                      onTap: () {
                        ref.read(marketplaceSectionProvider.notifier).state =
                            MarketplaceSection.cart;
                        ref.read(bottomNavigationIndexProvider.notifier).state =
                            3;
                      },
                    ),
                    Divider(
                      color: AppTheme.primaryLowShade.withValues(alpha: 0.9),
                    ),
                    _buildMarketplaceOption(
                      icon: Icons.receipt_long_outlined,
                      title: 'Mis órdenes',
                      subtitle: 'Consulta el estado de tus pedidos',
                      onTap: () {
                        ref.read(marketplaceSectionProvider.notifier).state =
                            MarketplaceSection.orders;
                        ref.read(bottomNavigationIndexProvider.notifier).state =
                            3;
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Notificaciones con switch
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // _buildNotificationOption(
                    //   icon: SvgPicture.string(
                    //     kNotificationsIconSvg,
                    //     width: 25,
                    //     height: 25,
                    //   ),
                    //   title: context.l1on.notifications,
                    //   value: false,
                    //   onChanged: (value) {
                    //     setState(() {
                    //       _notificationsEnabled = value;
                    //     });
                    //     // TODO: Actualizar preferencias de notificaciones
                    //   },
                    // ),
                    // _buildMenuOption(
                    //   icon: SvgPicture.string(
                    //     kTermsAndConditionsIconSvg,
                    //     width: 25,
                    //     height: 25,
                    //   ),
                    //   title: context.l1on.termsAndConditions,
                    //   onTap: () {
                    //     Navigator.push(
                    //       context,
                    //       MaterialPageRoute(
                    //         builder: (context) => const TermsScreen(),
                    //       ),
                    //     );
                    //   },
                    // ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Botón de cerrar sesión
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: InkWell(
                  onTap: () {
                    _showLogoutDialog(context);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      children: [
                        SvgPicture.string(
                          kLogoutIconSvg,
                          width: 25,
                          height: 25,
                        ),
                        const SizedBox(width: 16),
                        Text(
                          context.l1on.logout,
                          style: nunitoSansBodyLargeStyle(
                            context,
                            color: const Color(0xFF6366F1),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuOption({
    required Widget icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            icon,
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: nunitoSansBodyLargeStyle(
                  context,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildMarketplaceOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppTheme.gbDark600),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: nunitoSansBodyLargeStyle(
                      context,
                      color: AppTheme.secondayBlack,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: nunitoSansBodySmallStyle(
                      context,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade500, size: 24),
          ],
        ),
      ),
    );
  }

  // Widget _buildNotificationOption({
  //   required Widget icon,
  //   required String title,
  //   required bool value,
  //   required ValueChanged<bool> onChanged,
  // }) {
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(vertical: 8),
  //     child: Row(
  //       children: [
  //         icon,
  //         const SizedBox(width: 16),
  //         Expanded(
  //           child: Text(
  //             title,
  //             style: nunitoSansBodyLargeStyle(
  //               context,
  //               color: AppTheme.bottomNavigationIconUnselectedColor,
  //             ),
  //           ),
  //         ),
  //         Switch(
  //           value: value,
  //           onChanged: onChanged,
  //           activeThumbColor: AppTheme.primary900,
  //         ),
  //       ],
  //     ),
  //   );
  // }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            '${context.l1on.logout}?',
            style: nunitoSansTitleMediumStyle(
              context,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            context.l1on.areYouSureYouWantToLogOut,
            style: nunitoSansBodyMediumStyle(context),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                context.l1on.cancel,
                style: nunitoSansBodyMediumStyle(
                  context,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _logout();
              },
              child: Text(
                context.l1on.logout,
                style: nunitoSansBodyMediumStyle(
                  context,
                  color: const Color(0xFF6366F1),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout() async {
    await SharedService.logOut();
    ref.invalidate(userProfileProvider);
  }
}
