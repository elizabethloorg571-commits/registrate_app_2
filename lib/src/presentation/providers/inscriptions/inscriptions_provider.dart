import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:running_app/src/data/api/inscriptions/inscriptions_api_service.dart';
import 'package:running_app/src/domain/models/inscription.dart';

final inscriptionsFilterProvider =
    FutureProvider.family<List<Inscription>, Map<String, dynamic>>((
      ref,
      filter,
    ) async {
      try {
        final result = await InscriptionsApiService.getInscriptionFilter(
          filter,
          self: true,
        );

        if (result["response"] ?? false) {
          final inscriptionResponse = InscriptionResponse.fromJson(result);

          return inscriptionResponse.data;
        } else {
          final String message =
              result["message"] ?? result["error"] ?? "Error desconocido";

          throw Exception(message);
        }
      } catch (e, _) {
        throw Exception(e);
      }
    });
