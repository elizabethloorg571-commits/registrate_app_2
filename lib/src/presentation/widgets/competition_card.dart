import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:running_app/src/domain/models/running_competition.dart';
import 'package:running_app/src/presentation/providers/inscriptions/inscriptions_provider.dart';
import 'package:running_app/src/presentation/ui/competitions/competition_detail_screen.dart';
import 'package:running_app/src/presentation/widgets/custom_icon_button.dart';
import 'package:running_app/config/theme/app_theme.dart';
import 'package:running_app/config/theme/fonts.dart';
import 'package:running_app/src/utils/date_handler.dart';
import 'package:running_app/src/utils/responsive.dart';

class CompetitionCard extends ConsumerStatefulWidget {
  const CompetitionCard({
    super.key,
    required this.competition,
    required this.responsive,
    this.detailsOnPressedAvailable = true,
  });

  final RunningCompetition competition;
  final Responsive responsive;
  final bool detailsOnPressedAvailable;

  @override
  ConsumerState<CompetitionCard> createState() => _CompetitionCardState();
}

class _CompetitionCardState extends ConsumerState<CompetitionCard> {
  @override
  void initState() {
    _inscriptionFilter = {"carrera": widget.competition.id};
    super.initState();
  }

  late final Map<String, dynamic> _inscriptionFilter;

  @override
  Widget build(BuildContext context) {
    final day = widget.competition.date.day.toString();
    final month = widget.competition.date.monthNameShort;
    final hour =
        int.tryParse(widget.competition.hour.split(':').first) ??
        widget.competition.date.hour;
    final minute =
        int.tryParse(widget.competition.hour.split(':')[1]) ??
        widget.competition.date.minute;
    final DateTime fixedTime = DateTime(
      widget.competition.date.year,
      widget.competition.date.month,
      widget.competition.date.day,
      hour,
      minute,
    );
    final size = MediaQuery.sizeOf(context);
    final inscriptionProvider = ref.watch(
      inscriptionsFilterProvider(_inscriptionFilter),
    );
    return GestureDetector(
      onTap: widget.detailsOnPressedAvailable
          ? () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      CompetitionDetailScreen(competition: widget.competition),
                ),
              );
            }
          : null,
      child: Stack(
        children: [
          if (widget.detailsOnPressedAvailable)
            Center(
              child: Container(
                width: size.width * 0.5,
                margin: EdgeInsets.only(
                  right: widget.responsive.wp(4),
                  top: widget.responsive.hp(1),
                  bottom: widget.responsive.hp(15),
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.36),
                      blurRadius: 10,
                      spreadRadius: 4,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
            ),
          Column(
            children: [
              Expanded(
                flex: 20,
                child: Stack(
                  children: [
                    Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.all(
                              Radius.circular(12),
                            ),
                            image: widget.competition.image.isNotEmpty
                                ? DecorationImage(
                                    image: NetworkImage(
                                      widget.competition.image,
                                    ),
                                    fit: BoxFit.cover,
                                  )
                                : DecorationImage(
                                    image: AssetImage(
                                      'assets/images/competition_placeholder.png',
                                    ),
                                    fit: BoxFit.fill,
                                  ),
                            color: AppTheme.cardsFooterColor,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            width: size.width,
                            height: widget.responsive.hp(70),
                            decoration: BoxDecoration(
                              color: AppTheme.competitionCardColor,
                              borderRadius: const BorderRadius.all(
                                Radius.circular(12),
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 12,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.competition.title,
                                        overflow: TextOverflow.ellipsis,
                                        style: nunitoSansTitleSmallStyle(
                                          context,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.dark900,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${widget.competition.venueCity}, ${widget.competition.venueName} - ${fixedTimeMin(fixedTime)}',
                                        overflow: TextOverflow.ellipsis,
                                        style: nunitoSansLabelMediumStyle(
                                          context,
                                          color: AppTheme.dark700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                if (widget.detailsOnPressedAvailable)
                                  CustomIconButton(
                                    onPressed: () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            CompetitionDetailScreen(
                                              competition: widget.competition,
                                            ),
                                      ),
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    icon: Ink(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: AppTheme.white950,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Icon(
                                        Icons.chevron_right_outlined,
                                        color: AppTheme.secondary,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Text(
                              month,
                              style: nunitoSansLabelLargeStyle(context),
                            ),
                            Text(
                              day,
                              style: nunitoSansTitleSmallStyle(
                                context,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    inscriptionProvider.when(
                      data: (data) {
                        if (data.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.green,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Registrado',
                              style: nunitoSansLabelLargeStyle(
                                context,
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        );
                      },
                      error: (_, _) => const SizedBox.shrink(),
                      loading: () => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),

              // Información de la carrera
              Expanded(flex: 1, child: SizedBox()),
            ],
          ),
        ],
      ),
    );
  }
}

// Extensión para formatear fechas en español
extension DateFormatting on DateTime {
  String get monthNameShort {
    const months = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    return months[month - 1];
  }
}
