import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:running_app/src/data/api/users/users_api_service.dart';
import 'package:running_app/src/domain/models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

final userProfileProvider = FutureProvider.autoDispose<User>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final uuid = prefs.getString('uuid') ?? '';

  if (uuid.isEmpty) {
    return Future.error(Exception("Unauthorized"));
  }

  final result = await UsersApiService.getUser();
  if (result['response'] ?? false) {
    final user = User.fromJson(result['data']);
    // if (user.isAbonado) {
    //   await _updateUserMembership(user.abonado!);
    // }

    return user;
  } else {
    final String message =
        result["message"] ?? result["error"] ?? "Error desconocido";
    return Future.error(Exception(message));
  }
});

// Future<void> _updateUserMembership(Abonado abonadoDetails) async {
//   await SharedPreferencesManager.setFields(
//     stringFields: {
//       "fecha_inicio_abonado": abonadoDetails.dateStartSuscriber
//           .toIso8601String(),
//       "fecha_fin_abonado": abonadoDetails.dateEndSuscriber.toIso8601String(),
//       "numero_abonado": abonadoDetails.numberSubscriber ?? "",
//     },
//     intFields: {
//       "descuento_abonado": abonadoDetails.suscriberDiscount,
//       "cantidad_descuento_abonado": abonadoDetails.suscriberQuantityDiscount,
//     },
//   );
// }
