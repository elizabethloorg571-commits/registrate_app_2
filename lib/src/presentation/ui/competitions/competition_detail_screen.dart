import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:running_app/app_localizations_context.dart';
import 'package:running_app/extensions/string_extensions.dart';
import 'package:running_app/src/domain/models/running_competition.dart';
import 'package:running_app/src/presentation/ui/home/views/competitions_view.dart';
import 'package:running_app/src/presentation/ui/inscriptions/inscription_screen.dart';
import 'package:running_app/src/presentation/widgets/global_widgets.dart';
import 'package:running_app/config/theme/app_theme.dart';
import 'package:running_app/config/theme/fonts.dart';
import 'package:running_app/src/utils/responsive.dart';
import 'package:url_launcher/url_launcher.dart';

class CompetitionDetailScreen extends ConsumerStatefulWidget {
  const CompetitionDetailScreen({super.key, required this.competition});

  final RunningCompetition competition;

  @override
  CompetitionDetailScreenState createState() => CompetitionDetailScreenState();
}

class CompetitionDetailScreenState
    extends ConsumerState<CompetitionDetailScreen> {
  bool _showFullDescription = false;
  bool _isOpeningMap = false;

  final MapController _mapController = MapController();
  final double _zoom = 12;

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    final competition = widget.competition;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Imagen superior con app bar
          _buildSliverAppBar(competition, responsive),
          // Contenido
          SliverToBoxAdapter(
            child: Padding(
              padding: GlobalWidgets.pagePadding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 12,
                children: [
                  // Título y detalles principales
                  _buildHeaderSection(competition, responsive),
                  // Auspiciantes
                  _buildSponsorsSection(responsive),
                  // Descripción
                  _buildDescriptionSection(competition, responsive),
                  // Ubicación
                  _buildLocationSection(competition, responsive),
                  // Botón de inscripción
                  _buildRegistrationButton(responsive),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(
    RunningCompetition competition,
    Responsive responsive,
  ) {
    return SliverAppBar(
      expandedHeight: responsive.hPercent(20),
      pinned: true,
      backgroundColor: AppTheme.white950,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
              ),
            ],
          ),
          child: Icon(Icons.chevron_left, color: Colors.grey[800]),
        ),
        onPressed: () {
          // Usar GoRouter para manejar deep links correctamente
          if (context.canPop()) {
            context.pop();
          } else {
            // Si no hay historial (deep link), ir al home
            context.go('/');
          }
        },
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: competition.image.isNotEmpty
            ? Image.network(
                competition.image,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildImagePlaceholder(responsive);
                },
              )
            : _buildImagePlaceholder(responsive),
      ),
    );
  }

  Widget _buildImagePlaceholder(Responsive responsive) {
    return Container(
      color: AppTheme.lightModeLightBlue,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.directions_run,
              size: 80,
              color: AppTheme.lightModeBlue.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              context.l1on.imagePlaceholder,
              style: nunitoSansStyle(400, 16, color: AppTheme.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection(
    RunningCompetition competition,
    Responsive responsive,
  ) {
    final day = competition.date.day.toString();
    final month = competition.date.monthNameShort(context).capitalize();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          competition.title,
          style: nunitoSansStyle(700, 24, color: AppTheme.lightModeBlack),
        ),
        const SizedBox(height: 16),
        // Container con información de fecha y ciudad
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Fecha
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.lightModeLightBlue,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.calendar_today_outlined,
                        size: 20,
                        color: AppTheme.lightModeBlue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l1on.date,
                          style: nunitoSansStyle(400, 12, color: AppTheme.grey),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$month $day',
                          style: nunitoSansStyle(
                            600,
                            14,
                            color: AppTheme.lightModeBlue,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Divider vertical
              Container(
                height: 40,
                width: 1,
                color: AppTheme.grey.withValues(alpha: 0.2),
              ),
              const SizedBox(width: 16),
              // Ciudad
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.lightModeLightBlue,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.location_on_outlined,
                        size: 20,
                        color: AppTheme.lightModeBlue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l1on.location,
                            style: nunitoSansStyle(
                              400,
                              12,
                              color: AppTheme.grey,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            competition.venueCity,
                            style: nunitoSansStyle(
                              600,
                              14,
                              color: AppTheme.lightModeBlue,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Chips de información rápida
        // _buildInfoChips(competition, responsive),
      ],
    );
  }

  // Widget _buildInfoChips(
  //   RunningCompetition competition,
  //   Responsive responsive,
  // ) {
  //   // Obtener todas las distancias disponibles
  //   final distances = <String>[];
  //   for (final setting in competition.settings) {
  //     for (final distance in setting.distance) {
  //       if (!distances.contains(distance.km)) {
  //         distances.add(distance.km);
  //       }
  //     }
  //   }

  //   return Wrap(
  //     spacing: 8,
  //     runSpacing: 8,
  //     children: [
  //       // Chips de distancias
  //       ...distances.map((distance) {
  //         return Container(
  //           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  //           decoration: BoxDecoration(
  //             gradient: LinearGradient(
  //               colors: [AppTheme.primary, AppTheme.secondary],
  //             ),
  //             borderRadius: BorderRadius.circular(20),
  //           ),
  //           child: Row(
  //             mainAxisSize: MainAxisSize.min,
  //             children: [
  //               const Icon(Icons.directions_run, size: 16, color: Colors.white),
  //               const SizedBox(width: 4),
  //               Text(
  //                 distance,
  //                 style: nunitoSansStyle(600, 12, color: Colors.white),
  //               ),
  //             ],
  //           ),
  //         );
  //       }),
  //     ],
  //   );
  // }

  Widget _buildDescriptionSection(
    RunningCompetition competition,
    Responsive responsive,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${context.l1on.aboutTheCompetition}:',
          style: nunitoSansTitleSmallStyle(
            context,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          competition.venueDetails,
          style: nunitoSansBodySmallStyle(context, color: AppTheme.dark700),
          maxLines: _showFullDescription ? null : 3,
          overflow: _showFullDescription
              ? TextOverflow.visible
              : TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () {
            setState(() {
              _showFullDescription = !_showFullDescription;
            });
          },
          child: Text(
            _showFullDescription
                ? context.l1on.readLess
                : context.l1on.readMore,
            style: nunitoSansStyle(600, 14, color: AppTheme.lightModeBlue),
          ),
        ),
      ],
    );
  }

  Widget _buildSponsorsSection(Responsive responsive) {
    final competition = widget.competition;

    // Si no hay sponsors, no mostrar nada
    if (competition.sponsors.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l1on.sponsors,
          style: nunitoSansTitleSmallStyle(
            context,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: competition.sponsors.length,
            itemBuilder: (context, index) {
              final sponsor = competition.sponsors[index];
              return GestureDetector(
                onTap: () => _showSponsorBottomSheet(sponsor),
                child: Container(
                  width: 60,
                  height: 60,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: sponsor.logo.isNotEmpty
                        ? Image.network(
                            sponsor.logo,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.business,
                                color: AppTheme.grey.withValues(alpha: 0.5),
                                size: 30,
                              );
                            },
                          )
                        : Icon(
                            Icons.business,
                            color: AppTheme.grey.withValues(alpha: 0.5),
                            size: 30,
                          ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSection(
    RunningCompetition competition,
    Responsive responsive,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${context.l1on.location}:',
          style: nunitoSansTitleSmallStyle(
            context,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          competition.venueCity,
          style: nunitoSansStyle(400, 14, color: AppTheme.grey),
        ),
        const SizedBox(height: 12),
        // Mapa con ubicación
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isOpeningMap
                  ? null
                  : () => _openNativeMap(
                      competition.latitude,
                      competition.longitude,
                    ),
              child: Ink(
                height: responsive.hPercent(18),
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppTheme.grey.withValues(alpha: .3),
                    width: 1,
                  ),
                ),
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: LatLng(
                          competition.latitude,
                          competition.longitude,
                        ),
                        initialZoom: _zoom,
                        interactionOptions: const InteractionOptions(
                          flags:
                              InteractiveFlag.none, // Deshabilitar interacción
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key=IFKmcfDiLxVQTsl7buR9',
                          userAgentPackageName: 'com.magdata.tenorioApp',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: LatLng(
                                competition.latitude,
                                competition.longitude,
                              ),
                              width: 50.0,
                              height: 50.0,
                              child: Icon(
                                Icons.location_on,
                                color: AppTheme.lightModeBlue,
                                size: 40,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    // Overlay para indicar que es clickeable
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: _isOpeningMap
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        AppTheme.lightModeBlue,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${context.l1on.loading}...',
                                    style: nunitoSansStyle(
                                      600,
                                      12,
                                      color: AppTheme.lightModeBlue,
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.directions,
                                    size: 18,
                                    color: AppTheme.lightModeBlue,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    context.l1on.openInMaps,
                                    style: nunitoSansStyle(
                                      600,
                                      12,
                                      color: AppTheme.lightModeBlue,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegistrationButton(Responsive responsive) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    InscriptionScreen(competition: widget.competition),
              ),
            );
          },
          child: Ink(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [AppTheme.primary, AppTheme.secondary],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.lightModeBlue.withValues(alpha: 0.7),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                context.l1on.register,
                style: nunitoSansTitleMediumStyle(
                  context,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Abrir ubicación en la app de mapas nativa
  Future<void> _openNativeMap(double latitude, double longitude) async {
    if (_isOpeningMap) return; // Prevenir múltiples llamadas

    setState(() {
      _isOpeningMap = true;
    });

    final Uri androidUrl = Uri.parse(
      'https://www.google.com/maps?q=$latitude,$longitude',
    );

    try {
      if (await canLaunchUrl(androidUrl)) {
        await launchUrl(androidUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l1on.couldNotOpenMapsApp)),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isOpeningMap = false;
        });
      }
    }
  }

  // Mostrar bottom sheet con información del sponsor
  void _showSponsorBottomSheet(Sponsor sponsor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppTheme.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Logo del sponsor
            if (sponsor.logo.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  sponsor.logo,
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppTheme.lightModeLightBlue,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.business,
                        size: 60,
                        color: AppTheme.grey.withValues(alpha: 0.5),
                      ),
                    );
                  },
                ),
              )
            else
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppTheme.lightModeLightBlue,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.business,
                  size: 60,
                  color: AppTheme.grey.withValues(alpha: 0.5),
                ),
              ),
            const SizedBox(height: 20),
            // Título del sponsor
            Text(
              sponsor.title,
              style: nunitoSansStyle(700, 20, color: AppTheme.lightModeBlack),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            // Texto informativo
            Text(
              'Auspiciante Oficial',
              style: nunitoSansStyle(400, 14, color: AppTheme.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Botón de cerrar
            InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primary, AppTheme.secondary],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    'Cerrar',
                    style: nunitoSansStyle(600, 16, color: Colors.white),
                  ),
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
          ],
        ),
      ),
    );
  }
}
