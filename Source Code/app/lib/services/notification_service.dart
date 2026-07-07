import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '/config/constants.dart';

class NotificationService {
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
