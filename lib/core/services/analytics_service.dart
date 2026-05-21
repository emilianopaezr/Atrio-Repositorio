import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';

import '../utils/app_logger.dart';

/// Thin wrapper over Firebase Analytics with a small, opinionated event
/// vocabulary so we don't sprinkle string literals all over the app.
///
/// Every method is non-fatal: if Firebase isn't initialized (no
/// google-services.json), or analytics is disabled at runtime, the calls
/// silently no-op.
class AnalyticsService {
  AnalyticsService._();

  static FirebaseAnalytics? _instance;
  static bool _ready = false;

  /// Returns true if Firebase Core is initialized and analytics can be
  /// used. Cached after first check.
  static bool get _available {
    if (_ready) return _instance != null;
    try {
      // Will throw if Firebase isn't initialized.
      Firebase.app();
      _instance = FirebaseAnalytics.instance;
      _ready = true;
      return true;
    } catch (_) {
      _ready = true;
      _instance = null;
      return false;
    }
  }

  /// Wrap with this on a navigation root so screen views are reported.
  /// Pass to a `Navigator.observers` list.
  static FirebaseAnalyticsObserver? observer() {
    if (!_available) return null;
    return FirebaseAnalyticsObserver(analytics: _instance!);
  }

  static Future<void> setUserId(String? id) async {
    if (!_available) return;
    try {
      await _instance!.setUserId(id: id);
    } catch (e, st) {
      AppLogger.w('analytics.setUserId failed', tag: 'analytics');
      AppLogger.d('$e\n$st');
    }
  }

  /// Set the user role (guest/host/admin) so we can segment funnels.
  static Future<void> setUserRole(String role) async {
    if (!_available) return;
    try {
      await _instance!.setUserProperty(name: 'role', value: role);
    } catch (_) {}
  }

  /// Free-form event. Prefer the typed helpers below when available so
  /// event names stay consistent.
  static Future<void> log(String name, {Map<String, Object>? params}) async {
    if (!_available) return;
    try {
      await _instance!.logEvent(name: name, parameters: params);
    } catch (_) {}
  }

  // ─── Typed events (the vocabulary) ─────────────────────────────

  static Future<void> logScreenView(String name) async {
    if (!_available) return;
    try {
      await _instance!.logScreenView(screenName: name);
    } catch (_) {}
  }

  /// Auth events
  static Future<void> logSignUp(String method) =>
      log('sign_up', params: {'method': method});

  static Future<void> logLogin(String method) =>
      log('login', params: {'method': method});

  /// Listing browsing
  static Future<void> logViewListing(String listingId, String type) => log(
        'view_listing',
        params: {'listing_id': listingId, 'type': type},
      );

  static Future<void> logSearch(String term) =>
      log('search', params: {'search_term': term});

  /// Booking funnel
  static Future<void> logBeginCheckout({
    required String listingId,
    required double amount,
    required String currency,
  }) =>
      log('begin_checkout', params: {
        'listing_id': listingId,
        'value': amount,
        'currency': currency,
      });

  static Future<void> logPurchase({
    required String bookingId,
    required double amount,
    required String currency,
  }) =>
      log('purchase', params: {
        'transaction_id': bookingId,
        'value': amount,
        'currency': currency,
      });

  static Future<void> logBookingCancelled(String bookingId) =>
      log('booking_cancelled', params: {'booking_id': bookingId});

  /// Host events
  static Future<void> logListingPublished(String listingId, String type) =>
      log('listing_published',
          params: {'listing_id': listingId, 'type': type});

  static Future<void> logBecomeHost() => log('become_host');

  /// KYC funnel
  static Future<void> logKycStarted() => log('kyc_started');
  static Future<void> logKycSubmitted() => log('kyc_submitted');
  static Future<void> logKycApproved() => log('kyc_approved');
  static Future<void> logKycRejected() => log('kyc_rejected');
}
