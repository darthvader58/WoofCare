import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '/config/constants.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _reportChannel =
      AndroidNotificationChannel(
        'new_report_alerts',
        'New Report Alerts',
        description: 'Alerts for nearby stray-dog reports.',
        importance: Importance.high,
      );

  static String? _pendingReportId;

  /// Returns the report id from the most recent notification tap and clears
  /// it, so a deep link is consumed at most once. The map page calls this
  /// after its report markers finish loading.
  static String? takePendingReportId() {
    final reportId = _pendingReportId;
    _pendingReportId = null;
    return reportId;
  }

  /// Sets up the local-notification channel, foreground banners, and tap
  /// routing. Safe for individual accounts (they never receive these pushes)
  /// and never requests notification permission itself.
  static Future<void> initialize() async {
    try {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(_reportChannel);

      await _localNotifications.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
        onDidReceiveNotificationResponse:
            (response) => _openReportOnMap(response.payload),
      );

      FirebaseMessaging.onMessage.listen(_showForegroundNotification);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      final initialMessage =
          await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }
    } catch (_) {
      // Best-effort: notification plumbing must never block app startup.
    }
  }

  static Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    try {
      await _localNotifications.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _reportChannel.id,
            _reportChannel.name,
            channelDescription: _reportChannel.description,
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        payload: message.data['reportId']?.toString(),
      );
    } catch (_) {
      // Best-effort: a failed banner should never crash the app.
    }
  }

  static void _handleNotificationTap(RemoteMessage message) {
    if (message.data['type'] != 'new_report') return;
    _openReportOnMap(message.data['reportId']?.toString());
  }

  static void _openReportOnMap(String? reportId) {
    if (reportId == null || reportId.isEmpty) return;
    if (AUTH.currentUser == null) return;

    _pendingReportId = reportId;

    // During a cold start the splash flow is still loading the profile and
    // will land on the map itself, which then consumes the pending report id.
    if (!_profileLoaded) return;

    NAVIGATOR_KEY.currentState?.pushNamedAndRemoveUntil(
      "/home",
      (route) => false,
    );
  }

  static bool get _profileLoaded {
    try {
      profile.id;
      return true;
    } catch (_) {
      // `profile` is a `late` global; reading it before the launch flow
      // finishes throws.
      return false;
    }
  }

  static Future<void> registerIfOrganization() async {
    if (profile.accountType != 'organization') return;

    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();

      final token = await messaging.getToken();
      if (token != null) {
        await _storeToken(token);
      }

      messaging.onTokenRefresh.listen(_storeToken);
    } catch (_) {
      // Best-effort: a failed token registration should never block login.
    }
  }

  static Future<void> _storeToken(String token) async {
    try {
      await FIRESTORE.collection('users').doc(profile.id).update({
        'fcmTokens': FieldValue.arrayUnion([token]),
      });
    } catch (_) {
      // A token refresh can fire after logout, when writing the previous
      // user's doc is no longer permitted. Never surface that as an error.
    }
  }
}
