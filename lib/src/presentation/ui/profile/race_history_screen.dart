import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:running_app/app_localizations_context.dart';
import 'package:running_app/src/domain/models/inscription.dart';
import 'package:running_app/src/domain/models/running_competition.dart';
import 'package:running_app/src/presentation/providers/inscriptions/inscriptions_provider.dart';
import 'package:running_app/src/presentation/ui/inscriptions/inscription_detail_screen.dart';
import 'package:running_app/config/theme/fonts.dart';

class RaceHistoryScreen extends ConsumerWidget {
  const RaceHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inscriptionsAsync = ref.watch(inscriptionsFilterProvider({}));

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          context.l1on.raceHistory,
          style: nunitoSansTitleLargeStyle(
            context,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: inscriptionsAsync.when(
        data: (inscriptions) {
          if (inscriptions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    context.l1on.noRaceHistory,
                    style: nunitoSansBodyLargeStyle(
                      context,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            itemCount: inscriptions.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final inscription = inscriptions[index];
              final hasFullCarreraData = inscription.carrera is InscriptionRace;

              // Si tenemos datos completos, usarlos; si no, valores por defecto
              final carreraTitle = hasFullCarreraData
                  ? (inscription.carrera as InscriptionRace).title
                  : context.l1on.informationNotAvailable;
              final carreraLocation = hasFullCarreraData
                  ? '${(inscription.carrera as InscriptionRace).venueCity}, ${(inscription.carrera as InscriptionRace).venueName}'
                  : '${context.l1on.raceId}: ${inscription.carrera}';
              final carreraDate = hasFullCarreraData
                  ? (inscription.carrera as InscriptionRace).date
                  : inscription.createdAt;

              final dateFormat = DateFormat('dd/MM - h:mm a', 'es_ES');
              final formattedDate = dateFormat.format(carreraDate);

              return InkWell(
                onTap: hasFullCarreraData
                    ? () {
                        final inscriptionData = inscription.toJson();
                        final carrera = inscription.carrera as InscriptionRace;
                        final carreraJson = carrera.toJson();
                        carreraJson['empresa'] = inscription.empresa.toJson();
                        final competition = RunningCompetition.fromJson(
                          carreraJson,
                        );

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
                    : null,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: hasFullCarreraData
                        ? Colors.white
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: hasFullCarreraData
                        ? null
                        : Border.all(color: Colors.orange.shade200, width: 1),
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
                              ? Icons.image_outlined
                              : Icons.info_outline,
                          size: 35,
                          color: hasFullCarreraData
                              ? const Color(0xFF9C8FE0)
                              : Colors.orange.shade700,
                        ),
                      ),
                      const SizedBox(width: 16),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              carreraTitle,
                              style:
                                  nunitoSansTitleSmallStyle(
                                    context,
                                    fontWeight: FontWeight.w700,
                                  ).copyWith(
                                    color: hasFullCarreraData
                                        ? null
                                        : Colors.grey.shade700,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formattedDate,
                              style: nunitoSansBodyMediumStyle(
                                context,
                                color: hasFullCarreraData
                                    ? const Color(0xFF6366F1)
                                    : Colors.orange.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              carreraLocation,
                              style: nunitoSansBodySmallStyle(
                                context,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      Icon(
                        Icons.confirmation_number_outlined,
                        color: hasFullCarreraData
                            ? const Color(0xFF6366F1)
                            : Colors.orange.shade600,
                        size: 24,
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 80, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(
                context.l1on.errorLoadingHistory,
                style: nunitoSansBodyLargeStyle(
                  context,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
