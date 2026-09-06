import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

import '../crash/crash_reporter.dart';

/// The events the app reports. One method per event keeps names and
/// parameters in a single place, which is what chapter 13 reads.
class AppAnalytics {
  AppAnalytics._();

  static Future<void> logGameCompleted({
    required String difficulty,
    required int elapsedMs,
    required int mistakes,
    required int hintsUsed,
  }) async {
    if (!CrashReporter.firebaseReady) return;
    try {
      await FirebaseAnalytics.instance.logEvent(
        name: 'game_completed',
        parameters: {
          'difficulty': difficulty,
          'elapsed_ms': elapsedMs,
          'mistakes': mistakes,
          'hints_used': hintsUsed,
        },
      );
    } catch (error) {
      debugPrint('[AppAnalytics] logEvent failed: $error');
    }
  }
}
