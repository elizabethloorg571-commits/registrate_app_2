import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:running_app/app_localizations_context.dart';
import 'package:running_app/src/domain/models/inscription.dart';
import 'package:running_app/src/domain/models/running_competition.dart';
import 'package:running_app/src/domain/models/user.dart';
import 'package:running_app/src/presentation/providers/inscriptions/inscriptions_provider.dart';
import 'package:running_app/src/presentation/ui/inscriptions/inscription_detail_screen.dart';
import 'package:running_app/src/presentation/widgets/global_widgets.dart';
import 'package:running_app/config/theme/app_theme.dart';
import 'package:running_app/config/theme/fonts.dart';

class InscriptionsView extends ConsumerStatefulWidget {
  const InscriptionsView({
    super.key,
    required this.user,
    this.offlineView = false,
  });

  final User user;
  final bool offlineView;

  @override
  InscriptionsViewState createState() => InscriptionsViewState();
}

class InscriptionsViewState extends ConsumerState<InscriptionsView> {
  final Map<String, dynamic> inscriptionsFilter = {};

  @override
  Widget build(BuildContext context) {
    final inscriptionsAsync = ref.watch(
      inscriptionsFilterProvider(inscriptionsFilter),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.l1on.myInscriptions,
          style: nunitoSansTitleLargeStyle(
            context,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: Padding(
        padding: GlobalWidgets.pagePadding(context),
        child: inscriptionsAsync.when(
          data: (inscriptions) {
            if (inscriptions.isEmpty) {
              return Center(
                child: Text(
                  context.l1on.noInscriptionsYet,
                  style: nunitoSansBodyMediumStyle(context),
                ),
              );
            }

            return ListView.separated(
              itemCount: inscriptions.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final inscription = inscriptions[index];
                final hasFullCarreraData =
                    inscription.carrera is RunningCompetition;

                // Si tenemos datos completos, usarlos; si no, valores por defecto
                final carreraTitle = hasFullCarreraData
                    ? (inscription.carrera as RunningCompetition).title
                    : context.l1on.informationNotAvailable;
                final carreraLocation = hasFullCarreraData
                    ? '${(inscription.carrera as RunningCompetition).venueCity}, ${(inscription.carrera as RunningCompetition).venueName}'
                    : '${context.l1on.raceId}: ${inscription.carrera}';
                DateTime carreraDate = hasFullCarreraData
                    ? (inscription.carrera as RunningCompetition).date
                    : inscription.createdAt;

                final carreraHourStr = hasFullCarreraData
                    ? (inscription.carrera as RunningCompetition).hour
                    : '';

                final int hour =
                    int.tryParse(carreraHourStr.split(':')[0]) ?? 0;
                final int minute =
                    int.tryParse(carreraHourStr.split(':')[1]) ?? 0;

                if (hour != 0 || minute != 0) {
                  carreraDate = DateTime(
                    carreraDate.year,
                    carreraDate.month,
                    carreraDate.day,
                    hour,
                    minute,
                  );
                }

                final dateFormat = DateFormat('dd/MM - h:mm a', 'es_ES');
                final formattedDate = dateFormat.format(carreraDate);

                // Verificar si tiene items completos (objetos) para mostrar detalle
                final hasCompleteItems =
                    inscription.items is List<InscriptionItem>;
                final canShowDetail = hasFullCarreraData && hasCompleteItems;

                return InkWell(
                  onTap: canShowDetail
                      ? () {
                          // Navegar a la pantalla de detalle con datos completos
                          final carrera =
                              inscription.carrera as RunningCompetition;

                          // Construir el JSON de la carrera con la empresa completa
                          final carreraJson = carrera.toJson();
                          carreraJson['empresa'] = inscription.empresa.toJson();

                          // Crear RunningCompetition desde el JSON modificado
                          final competition = RunningCompetition.fromJson(
                            carreraJson,
                          );

                          // Crear estructura compatible con InscriptionDetailScreen
                          final inscriptionData = {
                            'data': {
                              'participantes':
                                  (inscription.items as List<InscriptionItem>)
                                      .map((item) => item.toJson())
                                      .toList(),
                              'orderId': inscription.id,
                            },
                          };

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => InscriptionDetailScreen(
                                inscriptionData: inscriptionData,
                                competition: competition,
                              ),
                            ),
                          );
                        }
                      : !canShowDetail && hasFullCarreraData
                      ? () {
                          // Mostrar diálogo con información básica cuando no hay items completos
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(
                                carreraTitle,
                                style: nunitoSansStyle(
                                  600,
                                  18,
                                  color: AppTheme.lightModeBlack,
                                ),
                              ),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Fecha: $formattedDate',
                                    style: nunitoSansStyle(
                                      400,
                                      14,
                                      color: AppTheme.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Estado: ${inscription.status}',
                                    style: nunitoSansStyle(
                                      400,
                                      14,
                                      color: AppTheme.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Total: \$${inscription.total.toStringAsFixed(2)}',
                                    style: nunitoSansStyle(
                                      600,
                                      16,
                                      color: AppTheme.lightModeBlack,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'ID de inscripción:',
                                    style: nunitoSansStyle(
                                      400,
                                      12,
                                      color: AppTheme.grey,
                                    ),
                                  ),
                                  Text(
                                    inscription.id,
                                    style: nunitoSansStyle(
                                      400,
                                      10,
                                      color: AppTheme.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Número de participantes: ${(inscription.items is List) ? (inscription.items as List).length : 0}',
                                    style: nunitoSansStyle(
                                      400,
                                      14,
                                      color: AppTheme.grey,
                                    ),
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(
                                    'Cerrar',
                                    style: nunitoSansStyle(
                                      600,
                                      14,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                      : null,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Imagen placeholder con ícono
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: hasFullCarreraData
                                ? const Color(0xFFE8E5F5)
                                : Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            hasFullCarreraData
                                ? Icons.directions_run
                                : Icons.info_outline,
                            size: 40,
                            color: hasFullCarreraData
                                ? const Color(0xFF9C8FE0)
                                : Colors.orange.shade700,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Contenido de la inscripción
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                carreraTitle,
                                style: nunitoSansTitleSmallStyle(
                                  context,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                formattedDate,
                                style: nunitoSansBodyMediumStyle(
                                  context,
                                  color: AppTheme.primary900,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                carreraLocation,
                                style: nunitoSansBodySmallStyle(context),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        // Ícono de ticket
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.grey900,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.confirmation_number_outlined),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: Text(
              context.l1on.errorLoadingInscriptions,
              style: nunitoSansBodyMediumStyle(context),
            ),
          ),
        ),
      ),
    );
  }
}
