import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:running_app/app_localizations_context.dart';
import 'package:running_app/marketplace/presentation/ui/screens/marketplace_landing_screen.dart';
import 'package:running_app/services/shared_service.dart';
import 'package:running_app/src/domain/models/running_competition.dart';
import 'package:running_app/src/domain/models/user.dart';
import 'package:running_app/src/presentation/providers/competitions/competitions_provider.dart';
import 'package:running_app/src/presentation/providers/connectivity/connectivity_provider.dart';
import 'package:running_app/src/presentation/providers/modes/modes_provider.dart';
import 'package:running_app/src/presentation/providers/profile/profile_provider.dart';
import 'package:running_app/src/presentation/ui/auth/views/login_view.dart';
import 'package:running_app/src/presentation/ui/home/views/calendar_view.dart';
import 'package:running_app/src/presentation/ui/home/views/competitions_view.dart';
import 'package:running_app/src/presentation/ui/home/views/inscriptions_view.dart';
import 'package:running_app/src/presentation/ui/home/views/profile_view.dart';
import 'package:running_app/src/presentation/widgets/global_widgets.dart';
import 'package:running_app/src/presentation/widgets/skeleton_box.dart';
import 'package:running_app/config/theme/app_theme.dart';
import 'package:running_app/config/theme/fonts.dart';
import 'package:running_app/src/utils/responsive.dart';

import '../utils/home_svg_files.dart';

enum SignedView { inscriptions, profile }

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  static const name = '/';

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends ConsumerState<HomeScreen> {
  // bool _calendarViewEnabled = false;
  bool _didRefreshCompetitionsAfterOnline = false;
  bool isProfileViewUnseen = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(bottomNavigationIndexProvider);
    // Cachear el provider de competiciones para evitar múltiples llamadas
    final competitionAsync = ref.watch(competitionsProvider);

    // Escucha conectividad para refrescar partidos cuando vuelva la conexión
    ref.listen<AsyncValue<bool>>(connectivityStatusProvider, (prev, next) {
      if (prev == null) return; // Ignorar la primera vez
      final online = next.value == true;
      final offline = next.value == false;

      if (offline) {
        _didRefreshCompetitionsAfterOnline = false;
      }
      if (online && !_didRefreshCompetitionsAfterOnline) {
        _didRefreshCompetitionsAfterOnline = true;
        ref.invalidate(competitionsProvider);
        if (mounted && currentIndex == 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l1on.connectionEstablishedUpdatingRaces),
            ),
          );
        }
      }
    });

    final responsive = Responsive(context);
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        landscapeLayout: BottomNavigationBarLandscapeLayout.centered,
        selectedItemColor: AppTheme.secondary,
        unselectedItemColor: AppTheme.bottomNavigationIconUnselectedColor,
        selectedLabelStyle: nunitoSansStyle(600, 11, color: AppTheme.secondary),
        unselectedLabelStyle: nunitoSansStyle(
          400,
          11,
          color: AppTheme.bottomNavigationIconUnselectedColor,
        ),
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppTheme.white,
        elevation: 10,
        onTap: (index) async {
          ref.read(bottomNavigationIndexProvider.notifier).state = index;
        },
        items: [
          BottomNavigationBarItem(
            icon: _SvgNavIcon(
              svgString: currentIndex == 0
                  ? kHomeIconFullSvg
                  : kHomeIconOutlinedSvg,
              // unselectedColor: Colors.white,
            ),
            label: context.l1on.home,
          ),
          BottomNavigationBarItem(
            icon: _SvgNavIcon(
              svgString: currentIndex == 1
                  ? kRunsIconFullSvg
                  : kRunsIconOutlinedSvg,
            ),
            label: context.l1on.runs,
          ),
          BottomNavigationBarItem(
            icon: _SvgNavIcon(
              svgString: currentIndex == 2
                  ? kInscriptionsIconFullSvg
                  : kInscriptionsIconOutlinedSvg,
            ),
            label: context.l1on.myInscriptions,
          ),
          BottomNavigationBarItem(
            icon: _SvgNavIcon(
              svgString: currentIndex == 3
                  ? kStoreIconFullSvg
                  : kStoreIconOutlinedSvg,
            ),
            label: 'Tienda',
          ),
          BottomNavigationBarItem(
            icon: _SvgNavIcon(
              svgString: currentIndex == 4
                  ? kProfileIconFullSvg
                  : kProfileIconOutlinedSvg,
            ),
            label: context.l1on.profile,
          ),
        ],
      ),

      body: IndexedStack(
        index: currentIndex,
        children: [
          _calendarView(responsive, competitionAsync),
          _competitionsView(responsive, competitionAsync),
          _signedView(view: SignedView.inscriptions),
          MarketplaceLandingScreen(),
          _signedView(view: SignedView.profile),
        ],
      ),
    );
  }

  Widget _calendarView(
    Responsive responsive,
    AsyncValue<List<RunningCompetition>> competitionAsync,
  ) {
    return competitionAsync.when(
      data: (competitions) {
        return CalendarView(competitions: competitions);
      },
      loading: () => _buildCalendarSkeleton(responsive),
      error: (error, stackTrace) {
        final String errorMessage = error.toString().replaceFirst(
          'Exception: ',
          '',
        );
        return Center(child: Text(errorMessage, textAlign: TextAlign.center));
      },
    );
  }

  Widget _competitionsView(
    Responsive responsive,
    AsyncValue<List<RunningCompetition>> competitionAsync,
  ) {
    return competitionAsync.when(
      data: (competitions) {
        return CompetitionsView(
          user: User(
            id: '',
            rol: '',
            nombres: '',
            apellidos: '',
            tipoDocumento: '',
            numDocumento: '',
            celular: '',
            email: '',
            tipo: '',
            estado: 0,
            facebookId: '',
            appleId: '',
            googleId: '',
            datosFacturacion: {},
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
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
        return Center(child: Text(errorMessage, textAlign: TextAlign.center));
      },
    );
  }

  Widget _signedView({required SignedView view}) {
    final userProvider = ref.watch(userProfileProvider);
    return userProvider.when(
      skipLoadingOnRefresh: false,
      data: (user) {
        SharedService.email = user.email;
        SharedService.photoUrl = user.foto;
        SharedService.uuid = user.id;
        SharedService.nombres = user.nombres;
        SharedService.apellidos = user.apellidos;
        SharedService.userUpdatedAt = user.updatedAt.toString();
        return view == SignedView.inscriptions
            ? InscriptionsView(user: user)
            : ProfileView(user: user);
      },
      loading: () => Center(
        child: GlobalWidgets.circularProgressIndicator(
          radius: 50,
          color: AppTheme.lightModeBlue,
        ),
      ),
      error: (error, _) {
        final String errorMessage = error.toString().replaceFirst(
          'Exception: ',
          '',
        );
        if (errorMessage.contains('Unauthorized') ||
            errorMessage.contains('Authorization header missing')) {
          return LoginView();
        } else {
          return Center(child: Text(errorMessage, textAlign: TextAlign.center));
        }
      },
    );
  }

  Widget _buildCalendarSkeleton(Responsive responsive) {
    final referenceDate = DateTime.now();
    final daysInMonth = DateTime(
      referenceDate.year,
      referenceDate.month + 1,
      0,
    ).day;
    final startWeekday = DateTime(
      referenceDate.year,
      referenceDate.month,
      1,
    ).weekday;

    return Scaffold(
      appBar: AppBar(centerTitle: false),
      body: Padding(
        padding: GlobalWidgets.pagePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SkeletonBox(
                  width: responsive.wPercent(30),
                  height: responsive.hPercent(4),
                  borderRadius: BorderRadius.circular(responsive.hp(25)),
                ),
                Row(
                  children: [
                    SkeletonBox(
                      width: responsive.hPercent(4),
                      height: responsive.hPercent(4),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    SizedBox(width: 8),
                    SkeletonBox(
                      width: responsive.hPercent(4),
                      height: responsive.hPercent(4),
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 16),
            GridView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1,
              ),
              itemCount: 7,
              itemBuilder: (context, index) => Center(
                child: SkeletonBox(
                  width: responsive.hPercent(3),
                  height: responsive.hPercent(2),
                ),
              ),
            ),
            GridView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1,
              ),
              itemCount: daysInMonth + startWeekday - 1,
              itemBuilder: (context, index) => Center(
                child: SkeletonBox(
                  width: responsive.hPercent(4),
                  height: responsive.hPercent(3.5),
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
            ),

            Expanded(
              child: SkeletonBox(
                width: double.infinity,
                height: double.infinity,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            SizedBox(height: responsive.hp(2)),
          ],
        ),
      ),
    );
  }
}

class _SvgNavIcon extends StatelessWidget {
  const _SvgNavIcon({required this.svgString});

  final String svgString;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: SvgPicture.string(svgString),
    );
  }
}
