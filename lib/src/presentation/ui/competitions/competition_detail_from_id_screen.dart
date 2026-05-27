import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:running_app/app_localizations_context.dart';
import 'package:running_app/src/presentation/providers/competitions/competitions_provider.dart';
import 'package:running_app/src/presentation/ui/competitions/competition_detail_screen.dart';
import 'package:running_app/src/presentation/widgets/global_widgets.dart';
import 'package:running_app/config/theme/app_theme.dart';
import 'package:running_app/config/theme/fonts.dart';

/// Pantalla que carga y muestra el detalle de una competencia desde un ID
/// Esta pantalla es útil para deep linking y acceso directo a competencias
class CompetitionDetailFromIdScreen extends ConsumerWidget {
  const CompetitionDetailFromIdScreen({super.key, required this.competitionId});

  final String competitionId;

  static const name = '/competition';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final competitionAsync = ref.watch(competitionByIdProvider(competitionId));

    return competitionAsync.when(
      data: (competition) {
        // Una vez cargada la competencia, mostramos la pantalla de detalle
        return CompetitionDetailScreen(competition: competition);
      },
      loading: () => Scaffold(
        backgroundColor: AppTheme.white950,
        appBar: AppBar(
          backgroundColor: AppTheme.white950,
          elevation: 0,
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
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.lightModeBlue,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                context.l1on.loading,
                style: nunitoSansStyle(600, 16, color: AppTheme.grey),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  context.l1on.loadingCompetitionDetails,
                  style: nunitoSansStyle(400, 14, color: AppTheme.grey),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
      error: (error, stackTrace) => Scaffold(
        backgroundColor: AppTheme.white950,
        appBar: AppBar(
          backgroundColor: AppTheme.white950,
          elevation: 0,
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
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
          ),
        ),
        body: Center(
          child: Padding(
            padding: GlobalWidgets.pagePadding(context),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 80,
                  color: AppTheme.lightModeBlue.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 24),
                Text(
                  context.l1on.error,
                  style: nunitoSansStyle(
                    700,
                    20,
                    color: AppTheme.lightModeBlack,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  _getErrorMessage(context, error),
                  style: nunitoSansStyle(400, 14, color: AppTheme.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                // Botón de reintentar
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        // Invalidar el provider para volver a intentar
                        ref.invalidate(competitionByIdProvider(competitionId));
                      },
                      child: Ink(
                        height: 56,
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            colors: [AppTheme.primary, AppTheme.secondary],
                          ),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.refresh,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                context.l1on.retry,
                                style: nunitoSansStyle(
                                  600,
                                  16,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Botón de volver
                TextButton(
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/');
                    }
                  },
                  child: Text(
                    context.l1on.goBack,
                    style: nunitoSansStyle(
                      600,
                      14,
                      color: AppTheme.lightModeBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getErrorMessage(BuildContext context, Object error) {
    final errorMessage = error.toString();

    // Si el error contiene el mensaje de la API, mostrarlo
    if (errorMessage.contains('Exception: ')) {
      return errorMessage.replaceFirst('Exception: ', '');
    }

    // Mensajes específicos según el tipo de error
    if (errorMessage.contains('SocketException') ||
        errorMessage.contains('Connection') ||
        errorMessage.contains('Network')) {
      return context.l1on.noInternetConnection;
    }

    if (errorMessage.contains('No se encontró') ||
        errorMessage.contains('not found')) {
      return context.l1on.competitionNotFound;
    }

    // Mensaje genérico
    return context.l1on.errorLoadingCompetition;
  }
}
