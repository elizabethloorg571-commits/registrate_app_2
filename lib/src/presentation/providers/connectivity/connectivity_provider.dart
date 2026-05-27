import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Emite true si hay conexión (al menos un resultado distinto de 'none'), false si no hay.
final connectivityStatusProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();
  final initial = await connectivity
      .checkConnectivity(); // List<ConnectivityResult>
  bool initialOnline = initial.any((r) => r != ConnectivityResult.none);
  yield initialOnline;
  yield* connectivity.onConnectivityChanged.map(
    (results) => results.any((r) => r != ConnectivityResult.none),
  );
});
