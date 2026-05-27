import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:running_app/src/data/api/competitions/competitions_api_service.dart';
import 'package:running_app/src/domain/models/running_competition.dart';

final competitionsProvider = FutureProvider.autoDispose((ref) async {
  final result = await CompetitionsApiService.fetchRuns();
  List<RunningCompetition> competitions = [];
  if (result["response"] ?? false) {
    competitions = RunningCompetition.parseCompetitions(jsonEncode(result));
    // sort competitions by date from newest to oldest
    // competitions.sort((a, b) => b.date.compareTo(a.date));

    // Opcional: guardar información de la empresa del primer resultado
    // if (competitions.isNotEmpty) {
    //   final company = competitions.first.empresa;
    //   ref.read(companyIdProvider.notifier).state = company.id;
    //   ref.read(companyNameProvider.notifier).state = company.nombreComercial;
    //   ref.read(companyLogoUrlProvider.notifier).state = company.logo;
    // }

    return competitions;
  } else {
    final String message =
        result["message"] ?? result["error"] ?? "Error desconocido";
    throw Exception(message);
  }
});

// Provider para obtener una competencia por ID
final competitionByIdProvider = FutureProvider.autoDispose
    .family<RunningCompetition, String>((ref, competitionId) async {
      final result = await CompetitionsApiService.fetchRunDetails(
        competitionId,
      );
      if (result["response"] ?? false) {
        final data = result["data"];
        if (data != null) {
          return RunningCompetition.fromJson(data);
        } else {
          throw Exception("No se encontró la competencia");
        }
      } else {
        final String message =
            result["message"] ??
            result["error"] ??
            "Error al cargar la competencia";
        throw Exception(message);
      }
    });
