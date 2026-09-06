import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';

/// Boots Firebase and routes uncaught errors to Crashlytics. If Firebase is
/// not configured (placeholder options, emulator without Play services, a
/// reader who has not run `flutterfire configure` yet) the app still starts:
/// a crash reporter that crashes the app is worse than none.
class CrashReporter {
  CrashReporter._();

  static bool _ready = false;

  static bool get firebaseReady => _ready;

  static Future<void> init() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
        !kDebugMode,
      );
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        recordError(error, stack, reason: 'PlatformDispatcher', fatal: true);
        return true;
      };
      _ready = true;
    } catch (error) {
      debugPrint('[CrashReporter] Firebase unavailable: $error');
    }
  }

  /// [reason] is a fixed identifier of the code path, never user data.
  static void recordError(
    Object error,
    StackTrace stack, {
    required String reason,
    bool fatal = false,
  }) {
    if (kDebugMode) debugPrint('[CrashReporter] $reason: $error');
    if (!_ready) return;
    FirebaseCrashlytics.instance.recordError(
      error,
      stack,
      reason: reason,
      fatal: fatal,
    );
  }
}
