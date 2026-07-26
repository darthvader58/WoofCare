import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
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

  static const int _apnsTokenAttempts = 10;
  static const Duration _apnsTokenRetryDelay = Duration(milliseconds: 200);
  static const String _webVapidKey = String.fromEnvironment(
    'FIREBASE_WEB_VAPID_KEY',
  );

  static String? _pendingReportId;
  static StreamSubscription<String>? _tokenRefreshSubscription;
  static String? _registeredUserId;
  static String? _registeredToken;
  static bool _localNotificationsReady = false;

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
    // These paths are deliberately isolated. Browser local-notification
    // service-worker setup can fail (for example in an unsupported/private
    // browser), but that must not prevent Firebase Messaging listeners from
    // being attached.
    await _initializeLocalNotifications();
    await _initializeFirebaseMessaging();
  }

  static Future<void> _initializeLocalNotifications() async {
    try {
      if (!kIsWeb) {
        await _localNotifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.createNotificationChannel(_reportChannel);
      }

      _localNotificationsReady =
          await _localNotifications.initialize(
            settings: const InitializationSettings(
              android: AndroidInitializationSettings('@mipmap/ic_launcher'),
              iOS: DarwinInitializationSettings(
                requestAlertPermission: false,
                requestBadgePermission: false,
                requestSoundPermission: false,
              ),
            ),
            onDidReceiveNotificationResponse: (response) =>
                _openReportOnMap(response.payload),
          ) ??
          false;

      if (!_localNotificationsReady) {
        debugPrint(
          '[NotificationService] Local notifications are unavailable on this '
          'platform/browser.',
        );
        return;
      }

      final localLaunchDetails = await _localNotifications
          .getNotificationAppLaunchDetails();
      if (localLaunchDetails?.didNotificationLaunchApp ?? false) {
        _openReportOnMap(localLaunchDetails?.notificationResponse?.payload);
      }
    } catch (error, stackTrace) {
      _localNotificationsReady = false;
      _logFailure(
        'Local notification initialization failed',
        error,
        stackTrace,
      );
      // Best-effort: Firebase Messaging startup continues independently.
    }
  }

  static Future<void> _initializeFirebaseMessaging() async {
    try {
      FirebaseMessaging.onMessage.listen(_showForegroundNotification);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      final initialMessage = await FirebaseMessaging.instance
          .getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }
    } catch (error, stackTrace) {
      _logFailure(
        'Firebase Messaging initialization failed',
        error,
        stackTrace,
      );
      // Best-effort: notification plumbing must never block app startup.
    }
  }

  static Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null || !_localNotificationsReady) return;

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
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBanner: true,
            presentList: true,
            presentSound: true,
            threadIdentifier: 'new_report_alerts',
          ),
          web: const WebNotificationDetails(),
        ),
        payload: message.data['reportId']?.toString(),
      );
    } catch (error, stackTrace) {
      _logFailure('Foreground notification failed', error, stackTrace);
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
    await _cancelTokenRefreshSubscription();

    if (profile.accountType != 'organization') return;

    try {
      final messaging = FirebaseMessaging.instance;
      final userId = profile.id;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        debugPrint(
          '[NotificationService] Notification permission was not granted.',
        );
        return;
      }

      _registeredUserId = userId;
      _tokenRefreshSubscription = messaging.onTokenRefresh.listen(
        (token) => _storeToken(userId, token),
        onError: (Object error, StackTrace stackTrace) {
          _logFailure('FCM token refresh failed', error, stackTrace);
        },
      );

      if (_isIOS && !await _waitForApnsToken(messaging)) {
        debugPrint(
          '[NotificationService] APNs token was not ready; waiting for the '
          'FCM token refresh callback.',
        );
        return;
      }

      if (kIsWeb && _webVapidKey.isEmpty) {
        debugPrint(
          '[NotificationService] FIREBASE_WEB_VAPID_KEY is not configured; '
          'trying Firebase Messaging\'s default web-push key.',
        );
      }

      final token = await messaging.getToken(
        vapidKey: kIsWeb && _webVapidKey.isNotEmpty ? _webVapidKey : null,
      );
      if (token != null) {
        await _storeToken(userId, token);
      }
    } catch (error, stackTrace) {
      _logFailure('FCM token registration failed', error, stackTrace);
      // Best-effort: a failed token registration should never block login.
    }
  }

  /// Stops token refreshes for the signed-in account, removes this app
  /// instance from its notification recipients, and invalidates the local FCM
  /// token. This must run before Firebase Auth signs the user out.
  static Future<void> unregisterCurrentUser() async {
    final userId = AUTH.currentUser?.uid ?? _registeredUserId;
    final token = _registeredToken;

    await _cancelTokenRefreshSubscription();

    if (userId != null && token != null) {
      try {
        await FIRESTORE.collection('users').doc(userId).update({
          'fcmTokens': FieldValue.arrayRemove([token]),
        });
      } catch (error, stackTrace) {
        _logFailure('FCM token removal failed', error, stackTrace);
      }
    }

    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (error, stackTrace) {
      _logFailure('Local FCM token invalidation failed', error, stackTrace);
    } finally {
      _registeredUserId = null;
      _registeredToken = null;
    }
  }

  static Future<void> _storeToken(String userId, String token) async {
    if (AUTH.currentUser?.uid != userId) return;

    try {
      await FIRESTORE.collection('users').doc(userId).update({
        'fcmTokens': FieldValue.arrayUnion([token]),
      });
      _registeredUserId = userId;
      _registeredToken = token;
    } catch (error, stackTrace) {
      _logFailure('FCM token storage failed', error, stackTrace);
      // A token refresh can fire after logout, when writing the previous
      // user's doc is no longer permitted. Never surface that as an error.
    }
  }

  static Future<bool> _waitForApnsToken(FirebaseMessaging messaging) async {
    for (var attempt = 0; attempt < _apnsTokenAttempts; attempt++) {
      if (await messaging.getAPNSToken() != null) return true;
      if (attempt < _apnsTokenAttempts - 1) {
        await Future<void>.delayed(_apnsTokenRetryDelay);
      }
    }
    return false;
  }

  static Future<void> _cancelTokenRefreshSubscription() async {
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
  }

  static bool get _isIOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  static void _logFailure(String message, Object error, StackTrace stackTrace) {
    debugPrint('[NotificationService] $message: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}
