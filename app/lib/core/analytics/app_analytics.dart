import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

import '../crash/crash_reporter.dart';

/// The events the app reports. One method per event keeps names and
/// parameters in a single place, which is what the growth report reads.
class AppAnalytics {
  AppAnalytics._();

  /// Tests observe events here. Production leaves it null.
  @visibleForTesting
  static void Function(String name, Map<String, Object> params)? observer;

  static Future<void> logGameStarted({required String difficulty}) =>
      _log('game_started', {'difficulty': difficulty});

  static Future<void> logGameCompleted({
    required String difficulty,
    required int elapsedMs,
    required int mistakes,
    required int hintsUsed,
  }) => _log('game_completed', {
    'difficulty': difficulty,
    'elapsed_ms': elapsedMs,
    'mistakes': mistakes,
    'hints_used': hintsUsed,
  });

  /// [source] is `free` (the one per game) or `paid` (wallet).
  static Future<void> logHintUsed({required String source}) =>
      _log('hint_used', {'source': source});

  static Future<void> logAdRewarded() => _log('ad_rewarded', const {});

  static Future<void> logPurchaseDelivered({required String productId}) =>
      _log('purchase_delivered', {'product_id': productId});

  static Future<void> _log(String name, Map<String, Object> params) async {
    observer?.call(name, params);
    if (!CrashReporter.firebaseReady) return;
    try {
      await FirebaseAnalytics.instance.logEvent(name: name, parameters: params);
    } catch (error) {
      debugPrint('[AppAnalytics] $name failed: $error');
    }
  }
}
