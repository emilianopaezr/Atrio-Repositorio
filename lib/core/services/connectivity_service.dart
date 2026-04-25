import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Reactive network status. `true` = at least one transport reports connected
/// (wifi / mobile / ethernet / vpn). Does not guarantee actual internet reach;
/// providers should still treat their network calls defensively.
class ConnectivityService {
  ConnectivityService._();

  static final Connectivity _connectivity = Connectivity();

  /// One-shot current status.
  static Future<bool> isOnline() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return _isOnline(result);
    } catch (e) {
      if (kDebugMode) debugPrint('[ConnectivityService] isOnline: $e');
      // If the plugin fails, assume online so we don't block the UI.
      return true;
    }
  }

  /// Stream of online/offline transitions. Emits initial value once subscribed.
  static Stream<bool> onStatusChange() async* {
    yield await isOnline();
    yield* _connectivity.onConnectivityChanged.map(_isOnline);
  }

  static bool _isOnline(List<ConnectivityResult> results) {
    if (results.isEmpty) return false;
    return results.any((r) => r != ConnectivityResult.none);
  }
}

/// Reactive `true`/`false` online flag for UI (banners, badges, cache hints).
final connectivityProvider = StreamProvider<bool>((ref) {
  return ConnectivityService.onStatusChange();
});

/// Convenience sync read: if we don't know yet, assume online.
final isOnlineProvider = Provider<bool>((ref) {
  final async = ref.watch(connectivityProvider);
  return async.maybeWhen(data: (v) => v, orElse: () => true);
});
