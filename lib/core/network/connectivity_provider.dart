import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Stream of connectivity changes from connectivity_plus.
final connectivityStatusProvider = StreamProvider<ConnectivityResult>((ref) {
  final connectivity = Connectivity();
  return connectivity.onConnectivityChanged;
});

/// Simple boolean flag for whether the app is currently offline.
final isOfflineProvider = Provider<bool>((ref) {
  final asyncStatus = ref.watch(connectivityStatusProvider);
  return asyncStatus.maybeWhen(
    data: (status) => status == ConnectivityResult.none,
    orElse: () => false,
  );
});
