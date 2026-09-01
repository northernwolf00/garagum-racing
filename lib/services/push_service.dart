import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Handles messages that arrive while the app is fully in the background or
/// terminated. This MUST be a top-level (or static) function annotated with
/// [pragma('vm:entry-point')] because Firebase runs it in a separate isolate.
///
/// Keep it lightweight — there's no UI here. Firebase itself shows the system
/// notification tray entry for "notification" messages; this callback is only
/// for extra work on "data" messages (analytics, local storage, etc.).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[push] background message: ${message.messageId}');
}

/// Wraps Firebase Cloud Messaging (push notifications).
///
/// Same singleton shape as the other services: private constructor, static
/// [instance], [init] awaited once from `main()` (after `Firebase.initializeApp`).
class PushService {
  static PushService? _instance;
  static PushService get instance {
    _instance ??= PushService._();
    return _instance!;
  }

  PushService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  bool _initialized = false;

  /// The current device's FCM registration token, once known. Send this to
  /// your backend if you want to target this specific device.
  String? get token => _token;
  String? _token;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      // Register the background/terminated-state handler before anything else.
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // Ask the user for notification permission (iOS + Android 13+). On older
      // Android this is granted automatically.
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('[push] permission: ${settings.authorizationStatus}');

      // Show notifications while the app is in the foreground on iOS too.
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Fetch (and keep in sync) the device token.
      _token = await _messaging.getToken();
      debugPrint('[push] token: $_token');
      _messaging.onTokenRefresh.listen((t) {
        _token = t;
        debugPrint('[push] token refreshed: $t');
      });

      // Everyone gets broadcast announcements sent to the "all" topic.
      await _messaging.subscribeToTopic('all');

      // Foreground messages arrive here (the OS won't show a tray entry itself).
      FirebaseMessaging.onMessage.listen((message) {
        debugPrint('[push] foreground message: ${message.notification?.title}');
      });

      // Fired when the user taps a notification and the app was in background.
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        debugPrint('[push] opened from notification: ${message.messageId}');
      });
    } catch (e) {
      debugPrint('[push] init failed: $e');
    }
  }

  /// Subscribe/unsubscribe to a topic (e.g. 'promo', 'news').
  Future<void> subscribe(String topic) => _messaging.subscribeToTopic(topic);
  Future<void> unsubscribe(String topic) =>
      _messaging.unsubscribeFromTopic(topic);
}
