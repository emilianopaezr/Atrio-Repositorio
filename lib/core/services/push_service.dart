import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../config/supabase/supabase_config.dart';
import 'notification_prefs.dart';

/// Background handler must be a top-level function annotated with `@pragma`.
/// We keep it minimal; the system already shows the notification from the
/// `notification` payload when the app is backgrounded/terminated.
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  // No-op: Android displays the FCM notification payload automatically.
  // Data-only pushes can be processed here if we need app-side logic.
}

/// Push notification bootstrap. Safe to call even if Firebase isn't configured
/// — every entry point wraps failures so a missing `google-services.json`
/// cannot take the whole app down.
class PushService {
  PushService._();

  static const String _androidChannelId = 'atrio_default';
  static const String _androidChannelName = 'Atrio';
  static const String _androidChannelDesc =
      'Reservas, mensajes y novedades de Atrio';

  static final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;
  static String? _cachedToken;

  /// Call once from `main()`. Idempotent and never throws.
  static Future<void> initialize() async {
    if (_initialized) return;
    try {
      // Firebase init is required before FirebaseMessaging.
      await Firebase.initializeApp();

      await _setupLocalNotifications();

      FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

      FirebaseMessaging.onMessage.listen(_onForegroundMessage);
      FirebaseMessaging.instance.onTokenRefresh.listen(_onTokenRefresh);

      _initialized = true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[PushService] initialize skipped: $e');
      }
      // Missing google-services.json, offline, etc. Silently no-op.
    }
  }

  /// Call after the user signs in. Requests permission, fetches the current
  /// FCM token, and registers it against the authenticated user.
  static Future<void> registerCurrentUser() async {
    if (!_initialized) return;
    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        return;
      }

      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      _cachedToken = token;

      await SupabaseConfig.client.rpc('register_device_token', params: {
        'p_token': token,
        'p_platform': _platformName(),
        'p_app_version': null,
      });
    } catch (e) {
      if (kDebugMode) debugPrint('[PushService] registerCurrentUser: $e');
    }
  }

  /// Call on sign-out to stop delivering pushes to this device.
  static Future<void> unregisterCurrentDevice() async {
    if (!_initialized) return;
    try {
      final token = _cachedToken ?? await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      await SupabaseConfig.client.rpc('unregister_device_token', params: {
        'p_token': token,
      });
      await FirebaseMessaging.instance.deleteToken();
      _cachedToken = null;
    } catch (e) {
      if (kDebugMode) debugPrint('[PushService] unregisterCurrentDevice: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  static Future<void> _setupLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _local.initialize(settings: initSettings);

    const channel = AndroidNotificationChannel(
      _androidChannelId,
      _androidChannelName,
      description: _androidChannelDesc,
      importance: Importance.high,
    );
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  static Future<void> _onForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    final android = message.notification?.android;
    if (notification == null) return;

    // Respect the per-category toggle from Settings. Unknown types default to
    // showing, so legacy or uncategorised pushes still reach the user.
    final type = message.data['type']?.toString();
    final allowed = await NotificationPrefs.shouldShow(type);
    if (!allowed) return;

    await _local.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannelId,
          _androidChannelName,
          channelDescription: _androidChannelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: android?.smallIcon,
        ),
      ),
      payload: message.data.isNotEmpty ? message.data.toString() : null,
    );
  }

  static Future<void> _onTokenRefresh(String token) async {
    _cachedToken = token;
    try {
      await SupabaseConfig.client.rpc('register_device_token', params: {
        'p_token': token,
        'p_platform': _platformName(),
        'p_app_version': null,
      });
    } catch (e) {
      if (kDebugMode) debugPrint('[PushService] token refresh persist: $e');
    }
  }

  static String _platformName() {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'android';
  }
}
