import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:running_app/app_localizations_context.dart';
import 'package:running_app/src/domain/models/user.dart';
import 'package:running_app/src/domain/models/running_competition.dart';
import 'package:running_app/src/presentation/providers/competitions/competitions_provider.dart';
import 'package:running_app/src/presentation/ui/competitions/competition_detail_screen.dart';
import 'package:running_app/src/presentation/widgets/global_widgets.dart';
import 'package:running_app/config/theme/app_theme.dart';
import 'package:running_app/config/theme/fonts.dart';
import 'package:running_app/src/utils/responsive.dart';

class CompetitionsView extends ConsumerStatefulWidget {
  const CompetitionsView({
    super.key,
    required this.user,
    this.offlineView = false,
  });

  final User user;
  final bool offlineView;

  @override
  CompetitionsViewState createState() => CompetitionsViewState();
}

class CompetitionsViewState extends ConsumerState<CompetitionsView> {
  String? selectedDistance; // null significa "Todas"
  List<String> availableDistances = [];

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    final competitionsAsync = ref.watch(competitionsProvider);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        // leading: IconButton(
        //   icon: const Icon(Icons.arrow_back),
        //   onPressed: () => Navigator.of(context).pop(),
        // ),
        title: Text(
          context.l1on.runs,
          style: nunitoSansTitleLargeStyle(
            context,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: competitionsAsync.when(
        data: (competitions) {
          // Extraer todas las distancias únicas de todas las competencias

          _extractAvailableDistances(competitions);

          // Filtrar competencias según la distancia seleccionada
          final filteredCompetitions = _filterCompetitions(competitions);

          return Padding(
            padding: GlobalWidgets.pagePadding(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Filtros de distancia
                _buildDistanceFilters(responsive),
                const SizedBox(height: 20),
                // Lista de carreras
                Expanded(
                  child: filteredCompetitions.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.directions_run,
                                size: 64,
                                color: AppTheme.grey.withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                context.l1on.noRacesAvailable,
                                style: nunitoSansBodyLargeStyle(
                                  context,
                                  color: AppTheme.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: filteredCompetitions.length,
                          itemBuilder: (context, index) {
                            final competition = filteredCompetitions[index];
                            return _buildCompetitionCard(
                              competition,
                              responsive,
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
        loading: () => Center(
          child: GlobalWidgets.circularProgressIndicator(
            radius: 50,
            color: AppTheme.lightModeBlue,
          ),
        ),
        error: (error, stackTrace) {
          final String errorMessage = error.toString().replaceFirst(
            'Exception: ',
            '',
          );
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                errorMessage,
                textAlign: TextAlign.center,
                style: nunitoSansBodyLargeStyle(context),
              ),
            ),
          );
        },
      ),
    );
  }

  void _extractAvailableDistances(List<RunningCompetition> competitions) {
    final Set<String> distances = {};

    for (final competition in competitions) {
      for (final setting in competition.settings) {
        for (final distance in setting.distance) {
          distances.add(distance.km);
        }
      }
    }

    // Ordenar las distancias
    availableDistances = distances.toList()
      ..sort((a, b) {
        // Extraer el número de la distancia para ordenar correctamente
        final numA = int.tryParse(a.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        final numB = int.tryParse(b.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        return numA.compareTo(numB);
      });
  }

  List<RunningCompetition> _filterCompetitions(
    List<RunningCompetition> competitions,
  ) {
    if (selectedDistance == null) {
      return competitions; // Mostrar todas
    }

    return competitions.where((competition) {
      // Verificar si alguna de las configuraciones tiene la distancia seleccionada
      return competition.settings.any((setting) {
        return setting.distance.any((distance) {
          return distance.km == selectedDistance;
        });
      });
    }).toList();
  }

  Widget _buildDistanceFilters(Responsive responsive) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // Chip "Todas"
          _buildFilterChip(
            label: context.l1on.all,
            isSelected: selectedDistance == null,
            onTap: () {
              setState(() {
                selectedDistance = null;
              });
            },
            responsive: responsive,
          ),
          const SizedBox(width: 8),
          // Chips de distancias
          ...availableDistances.map((distance) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildFilterChip(
                label: distance,
                isSelected: selectedDistance == distance,
                onTap: () {
                  setState(() {
                    selectedDistance = distance;
                  });
                },
                responsive: responsive,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Responsive responsive,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [AppTheme.secondary, AppTheme.primary],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : AppTheme.grey.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.lightModeBlue.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            '$label${label != context.l1on.all ? 'K' : ''}',
            style: nunitoSansLabelMediumStyle(
              context,
              color: isSelected ? Colors.white : AppTheme.lightModeBlack,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompetitionCard(
    RunningCompetition competition,
    Responsive responsive,
  ) {
    final day = competition.date.day.toString();
    final month = competition.date.monthNameShort(context);

    // Obtener el precio mínimo de todas las distancias
    double minPrice = double.infinity;
    for (final setting in competition.settings) {
      for (final distance in setting.distance) {
        if (distance.price < minPrice) {
          minPrice = distance.price;
        }
      }
    }

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) =>
                CompetitionDetailScreen(competition: competition),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
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
            // Imagen/Logo de la empresa
            Container(
              width: 85,
              height: 170,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(16),
                ),
                color: AppTheme.lightModeLightBlue,
              ),
              child: competition.image.isNotEmpty
                  ? ClipRRect(
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(16),
                      ),
                      child: Image.network(
                        competition.image,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildDefaultLogo();
                        },
                      ),
                    )
                  : _buildDefaultLogo(),
            ),
            // Información de la carrera
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            competition.title,
                            style: nunitoSansStyle(
                              600,
                              16,
                              color: AppTheme.lightModeBlack,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.lightModeBlue.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Column(
                            children: [
                              Text(
                                month,
                                style: nunitoSansStyle(
                                  700,
                                  9,
                                  color: AppTheme.lightModeBlue,
                                ),
                              ),
                              Text(
                                day,
                                style: nunitoSansStyle(
                                  700,
                                  14,
                                  color: AppTheme.lightModeBlack,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${competition.venueCity}, ${competition.venueDetails}',
                      style: nunitoSansStyle(400, 12, color: Colors.grey[600]!),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Spacer(),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => CompetitionDetailScreen(
                                  competition: competition,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.primary900,
                                  AppTheme.secondary,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              context.l1on.viewMore,
                              style: nunitoSansStyle(
                                600,
                                12,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultLogo() {
    return Center(
      child: Icon(
        Icons.directions_run,
        size: 40,
        color: AppTheme.lightModeBlue.withValues(alpha: 0.5),
      ),
    );
  }
}

// Extensión para formatear fechas
extension DateFormatting on DateTime {
  String monthNameShort(BuildContext context) {
    final months = [
      context.l1on.jan,
      context.l1on.feb,
      context.l1on.mar,
      context.l1on.apr,
      context.l1on.may,
      context.l1on.jun,
      context.l1on.jul,
      context.l1on.aug,
      context.l1on.sep,
      context.l1on.oct,
      context.l1on.nov,
      context.l1on.dec,
    ];
    return months[month - 1];
  }
}

extension DateFormattingFull on DateTime {
  String monthName(BuildContext context) {
    final months = [
      context.l1on.january,
      context.l1on.february,
      context.l1on.march,
      context.l1on.april,
      context.l1on.mayFull,
      context.l1on.june,
      context.l1on.july,
      context.l1on.august,
      context.l1on.september,
      context.l1on.october,
      context.l1on.november,
      context.l1on.december,
    ];
    return months[month - 1];
  }
}
