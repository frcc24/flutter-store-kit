import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// The player's identity for the Worker: a Firebase anonymous user created
/// on first use. No screen, no e-mail. Every answer is null when Firebase is
/// not configured, and every caller treats null as "not available".
///
/// Not final: screen tests subclass it to hand out a fixed uid and token.
class AnonymousSession {
  AnonymousSession({this._auth});

  final FirebaseAuth? _auth;

  Future<User?> _user() async {
    final auth = _auth;
    if (auth == null) return null;
    try {
      return auth.currentUser ?? (await auth.signInAnonymously()).user;
    } catch (error) {
      debugPrint('[AnonymousSession] sign-in failed: $error');
      return null;
    }
  }

  Future<String?> uid() async => (await _user())?.uid;

  Future<String?> idToken({bool forceRefresh = false}) async {
    try {
      return await (await _user())?.getIdToken(forceRefresh);
    } catch (_) {
      // The exception can embed the credential; the fixed message is enough.
      debugPrint('[AnonymousSession] no ID token available');
      return null;
    }
  }

  /// Removes the Firebase user. Only after the Worker confirmed the deletion:
  /// the token is what authorises that call.
  Future<void> deleteUser() async {
    try {
      await _auth?.currentUser?.delete();
    } catch (error) {
      debugPrint('[AnonymousSession] delete failed: $error');
    }
  }
}
