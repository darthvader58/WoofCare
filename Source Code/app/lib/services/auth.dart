import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '/config/constants.dart';
import '/models/profile.dart';

class Auth {
  static void _showUnexpectedError(BuildContext context, Object error) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Authentication failed: ${error.toString()}")),
    );
  }

  static Future<void> launch(
    BuildContext context,
    void Function() onLoggedIn,
  ) async {
    try {
      profile = await Profile.fromID(AUTH.currentUser!.uid);
    } catch (error, _) {
      if (error.toString().contains(
            "does not exist within the DocumentSnapshotPlatform",
          ) ||
          error.toString().contains(
            "on a DocumentSnapshotPlatform which does not exist",
          )) {
        if (context.mounted) {
          Navigator.popAndPushNamed(context, "/login");
        }
      } else {
        // TODO: Error Dialog
      }
      return;
    }

    onLoggedIn();
  }

  static Future<void> signup({
    required String email,
    required String password,
    required Map<String, String> data,
    required BuildContext context,
    required void Function(FirebaseAuthException e) error,
  }) async {
    User? createdUser;

    try {
      final credential = await AUTH.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      createdUser = credential.user;

      String uid = AUTH.currentUser!.uid;
      await FIRESTORE.collection("users").doc(uid).set(data);

      profile = await Profile.fromID(uid);

      if (context.mounted) {
        Navigator.pushNamed(context, "/");
      }
    } on FirebaseAuthException catch (e) {
      error(e);
    } catch (e) {
      if (createdUser != null) {
        try {
          await createdUser.delete();
        } catch (_) {
          await AUTH.signOut();
        }
      }

      if (!context.mounted) return;
      _showUnexpectedError(context, e);
    }
  }

  static Future<void> login({
    required String email,
    required String password,
    required BuildContext context,
    required void Function(FirebaseAuthException e) error,
  }) async {
    try {
      await AUTH.signInWithEmailAndPassword(email: email, password: password);

      String uid = AUTH.currentUser!.uid;

      profile = await Profile.fromID(uid);

      if (context.mounted) {
        Navigator.pushNamed(context, "/");
      }
    } on FirebaseAuthException catch (e) {
      error(e);
    } catch (e) {
      await AUTH.signOut();
      if (!context.mounted) return;
      _showUnexpectedError(context, e);
    }
  }

  static Future<void> logOut(BuildContext context) async {
    await AUTH.signOut();

    if (context.mounted) {
      Navigator.pushNamed(context, "/login");
    }
  }

  static Future<void> passwordReset({
    required String email,
    required BuildContext context,
    required void Function() success,
    required void Function(FirebaseAuthException e) error,
  }) async {
    try {
      await AUTH.sendPasswordResetEmail(email: email);
      success();
    } on FirebaseAuthException catch (e) {
      error(e);
    }
  }
}
