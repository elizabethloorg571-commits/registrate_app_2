// import 'package:badges/badges.dart' as badges;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:running_app/app_localizations_context.dart';
import 'package:running_app/src/domain/models/running_competition.dart';
import 'package:running_app/src/presentation/providers/modes/modes_provider.dart';
// import 'package:running_app/src/presentation/providers/notifications/notifications_provider.dart';
import 'package:running_app/src/presentation/ui/home/views/competitions_view.dart';
import 'package:running_app/src/presentation/widgets/competition_card.dart';
import 'package:running_app/src/presentation/widgets/custom_icon_button.dart';
import 'package:running_app/src/presentation/widgets/global_widgets.dart';
import 'package:running_app/config/theme/app_theme.dart';
import 'package:running_app/config/theme/fonts.dart';
import 'package:running_app/src/utils/date_handler.dart';
import 'package:running_app/src/utils/responsive.dart';
import 'package:running_app/src/utils/url_launcher_utils.dart';

class CalendarView extends ConsumerStatefulWidget {
  const CalendarView({super.key, required this.competitions});

  final List<RunningCompetition> competitions;

  @override
  CalendarViewState createState() => CalendarViewState();
}

class CalendarViewState extends ConsumerState<CalendarView> {
  late DateTime referenceDate;
  RunningCompetition? foundCompetition;
  late int daysInMonth;
  late int startWeekday;
  String? supportNumber;
  DateTime now = DateTime.now();
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85);
    _selectDate(DateTime(now.year, now.month, now.day));
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _showMonthYearPicker(Responsive responsive) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final currentYear = now.year;
        final years = List.generate(11, (index) => currentYear - 0 + index);

        int selectedYear = referenceDate.year;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return SizedBox(
              height: responsive.hPercent(60),
              // height: MediaQuery.of(context).size.height * 0.6,
              child: Column(
                children: [
                  SizedBox(height: responsive.hp(16)),
                  Text(
                    context.l1on.selectMonthAndYear,
                    style: nunitoSansStyle(
                      600,
                      responsive.sp(18),
                      color: AppTheme.lightModeBlack,
                    ),
                  ),
                  SizedBox(height: responsive.hp(16)),
                  SizedBox(
                    height: responsive.hPercent(6),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: years.length,
                      itemBuilder: (context, index) {
                        final year = years[index];
                        return Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: responsive.wp(8),
                          ),
                          child: ChoiceChip(
                            label: Text(
                              "$year",
                              style: nunitoSansStyle(
                                500,
                                responsive.sp(16),
                                color: selectedYear == year
                                    ? AppTheme.white950
                                    : AppTheme.lightModeBlack,
                              ),
                            ),
                            selectedShadowColor: AppTheme.cardsBackground,
                            selectedColor: AppTheme.lightModeBlue,
                            checkmarkColor: AppTheme.white950,
                            selected: selectedYear == year,
                            onSelected: (_) {
                              setModalState(() {
                                selectedYear = year;
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView.builder(
                      itemCount: 12,
                      itemBuilder: (context, index) {
                        final monthDate = DateTime(0, index + 1);
                        final monthName = monthDate.monthName(context);
                        return ListTile(
                          title: Text(
                            monthName,
                            style: nunitoSansStyle(
                              500,
                              responsive.sp(16),
                              color: AppTheme.lightModeBlack,
                            ),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            setState(() {
                              foundCompetition = null;
                              referenceDate = DateTime(
                                selectedYear,
                                index + 1,
                                1,
                              );
                              daysInMonth = DateTime(
                                referenceDate.year,
                                referenceDate.month + 1,
                                0,
                              ).day;
                              startWeekday = DateTime(
                                referenceDate.year,
                                referenceDate.month,
                                1,
                              ).weekday;
                            });
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _selectDate(DateTime date) {
    referenceDate = date;
    daysInMonth = DateTime(referenceDate.year, referenceDate.month + 1, 0).day;
    startWeekday = DateTime(referenceDate.year, referenceDate.month, 1).weekday;
    foundCompetition = null;

    // Buscar la competencia en la fecha seleccionada
    int competitionIndex = -1;
    for (int i = 0; i < widget.competitions.length; i++) {
      final competition = widget.competitions[i];
      final competitionDate = competition.date;
      if (DateTime(
            competitionDate.year,
            competitionDate.month,
            competitionDate.day,
          ) ==
          date) {
        foundCompetition = competition;
        competitionIndex = i;
        break;
      }
    }

    // Si se encontró una competencia, animar el carrusel a esa tarjeta
    if (competitionIndex != -1 && _pageController.hasClients) {
      _pageController.animateToPage(
        competitionIndex,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final responsive = Responsive(context);
    // final userNotificacions = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () =>
                  UrlLauncherUtils.launchWhatsAppUri(context, supportNumber),
              child: SvgPicture.asset(
                'assets/images/whatsapp_icon.svg',
                width: 32,
                height: 32,
              ),

              // child: userNotificacions.when(
              //   data: (data) {
              //     final unreadCount = data
              //         .where((element) => !element.read)
              //         .length;

              //     return Container(
              //       decoration: BoxDecoration(
              //         shape: BoxShape.circle,
              //         color: AppTheme.primary50,
              //       ),
              //       padding: const EdgeInsets.all(8.0),
              //       child: badges.Badge(
              //         showBadge: unreadCount > 0,
              //         position: badges.BadgePosition.topEnd(top: 0, end: 0),
              //         onTap: null,
              //         badgeAnimation: const badges.BadgeAnimation.fade(),
              //         badgeContent: Text(
              //           "$unreadCount",
              //           style: nunitoSansLabelSmallStyle(
              //             context,
              //             color: Colors.white,
              //             fontWeight: FontWeight.w700,
              //           ),
              //         ),
              //         child: const Icon(CupertinoIcons.bell_fill),
              //       ),
              //     );
              //   },
              //   error: (error, stackTrace) {
              //     return Container(
              //       decoration: BoxDecoration(
              //         shape: BoxShape.circle,
              //         color: AppTheme.cardsBackground,
              //       ),
              //       padding: const EdgeInsets.all(8.0),
              //       child: Icon(CupertinoIcons.bell),
              //     );
              //   },
              //   loading: () {
              //     return GlobalWidgets.circularProgressIndicator(
              //       color: AppTheme.grey,
              //     );
              //   },
              // ),
            ),
          ),
        ],
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.center,

          children: [
            Image.asset(
              'assets/images/registraTe-logo-horizontal.png',
              height: 40,
              fit: BoxFit.contain,
            ),
          ],
        ),
      ),
      body: Padding(
        padding: GlobalWidgets.pagePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppTheme.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.l1on.calendar,
                        style: nunitoSansTitleSmallStyle(
                          context,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Row(
                        children: [
                          CustomIconButton(
                            icon: Icon(
                              CupertinoIcons.back,
                              color: AppTheme.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                foundCompetition = null;
                                referenceDate = DateTime(
                                  referenceDate.year,
                                  referenceDate.month - 1,
                                );
                                if (referenceDate.year == now.year &&
                                    referenceDate.month == now.month) {
                                  referenceDate = DateTime(
                                    now.year,
                                    now.month,
                                    now.day,
                                  );
                                }
                                daysInMonth = DateTime(
                                  referenceDate.year,
                                  referenceDate.month + 1,
                                  0,
                                ).day;
                                startWeekday = DateTime(
                                  referenceDate.year,
                                  referenceDate.month,
                                  1,
                                ).weekday;
                              });
                            },
                          ),
                          GestureDetector(
                            onTap: () => _showMonthYearPicker(responsive),
                            child: Text(
                              fixedDateTimeMonth(referenceDate),
                              style: nunitoSansLabelLargeStyle(
                                context,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.grey,
                              ),
                            ),
                          ),
                          CustomIconButton(
                            icon: Icon(
                              CupertinoIcons.forward,
                              color: AppTheme.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                foundCompetition = null;
                                referenceDate = DateTime(
                                  referenceDate.year,
                                  referenceDate.month + 1,
                                );
                                final now = DateTime.now();
                                if (referenceDate.year == now.year &&
                                    referenceDate.month == now.month) {
                                  referenceDate = DateTime(
                                    now.year,
                                    now.month,
                                    now.day,
                                  );
                                }

                                daysInMonth = DateTime(
                                  referenceDate.year,
                                  referenceDate.month + 1,
                                  0,
                                ).day;
                                startWeekday = DateTime(
                                  referenceDate.year,
                                  referenceDate.month,
                                  1,
                                ).weekday;
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  GridView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      childAspectRatio:
                          responsive.wp(50.86) / responsive.hp(45), // = ~ 1.06
                    ),
                    itemCount: 7,
                    itemBuilder: (BuildContext context, int index) {
                      return Center(
                        child: Text(
                          [
                            context.l1on.mon,
                            context.l1on.tue,
                            context.l1on.wed,
                            context.l1on.thu,
                            context.l1on.fri,
                            context.l1on.sat,
                            context.l1on.sun,
                          ][index],
                          style: nunitoSansLabelMediumStyle(
                            context,
                            color: Colors.black.withValues(alpha: 0.5),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    },
                  ),
                  GridView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      childAspectRatio:
                          responsive.wp(53) / responsive.hp(45), // = ~ 1.06
                    ),
                    itemCount: daysInMonth + startWeekday - 1,
                    itemBuilder: (BuildContext context, int index) {
                      if (index < startWeekday - 1) {
                        return Container();
                      } else {
                        final int day = index - startWeekday + 2;
                        final int month = referenceDate.month;
                        final int year = referenceDate.year;

                        final DateTime date = DateTime(year, month, day);
                        bool isSelected = false;

                        isSelected =
                            referenceDate.year == year &&
                            referenceDate.month == month &&
                            referenceDate.day == day;

                        bool hasFixture = false;
                        bool isToday = false;
                        if (date.year == now.year &&
                            date.month == now.month &&
                            date.day == now.day) {
                          isToday = true;
                        }

                        for (var competition in widget.competitions) {
                          final competitionDate = competition.date;
                          final fixtureDay = competitionDate.day;
                          final fixtureMonth = competitionDate.month;
                          final fixtureYear = competitionDate.year;
                          final fixtureDateMin = DateTime(
                            fixtureYear,
                            fixtureMonth,
                            fixtureDay,
                          );
                          final dateTime = DateTime(year, month, day);
                          if (fixtureDateMin == dateTime) {
                            hasFixture = true;
                          }
                        }

                        return GestureDetector(
                          onTap: () => _selectDate(date),
                          child: Center(
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: size.height * 0.045,
                                  height: size.height * 0.045,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _cardColor(
                                      isSelected,
                                      hasFixture,
                                      isToday,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      "$day",
                                      style: TextStyle(
                                        fontFamily: 'nunitoSans',
                                        fontSize: responsive.sp(14),
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        decoration: TextDecoration.none,
                                        color: _textColor(
                                          isSelected,
                                          hasFixture,
                                          isToday,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                // Indicador de evento (punto debajo del número)
                                if (hasFixture && !isSelected)
                                  Positioned(
                                    bottom: 2,
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppTheme.secondary,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Sección de Próximas carreras
            if (widget.competitions.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.l1on.upcomingRaces,
                    style: nunitoSansTitleMediumStyle(
                      context,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // Navegar a ver todas las carreras (cambiar al tab de Partidos)
                      ref.read(bottomNavigationIndexProvider.notifier).state =
                          1;
                    },
                    child: Text(
                      context.l1on.viewAll,
                      style: nunitoSansTitleSmallStyle(
                        context,
                        color: AppTheme.primary900,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: widget.competitions.length,
                  onPageChanged: (index) {
                    // Opcional: actualizar la fecha seleccionada cuando se desliza
                    final competition = widget.competitions[index];
                    _selectDate(competition.date);
                  },
                  itemBuilder: (context, index) {
                    final competition = widget.competitions[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: CompetitionCard(
                        competition: competition,
                        responsive: responsive,
                        detailsOnPressedAvailable: true,
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Color _cardColor(bool isSelected, bool hasFixture, bool isToday) {
    if (isSelected) {
      return AppTheme.cardsBackground;
    } else if (isToday) {
      return AppTheme.primary50;
    } else {
      return Colors.transparent;
    }
  }

  Color _textColor(bool isSelected, bool hasFixture, bool isToday) {
    return AppTheme.lightModeBlack;
  }
}
