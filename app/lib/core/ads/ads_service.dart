import 'dart:async';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/foundation.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';

import '../crash/crash_reporter.dart';
import 'ads_config.dart';

enum RewardedOutcome { finished, skipped, unavailable }

/// Thin wrapper over the Unity Ads SDK. Isolates the SDK from the app, never
/// throws, and treats "not configured" as "no ads". Not final: screen tests
/// subclass it and answer without a platform.
class AdsService {
  AdsService({this.config = kitAds});

  final AdsConfig config;

  bool _initialized = false;
  bool _rewardedReady = false;

  bool get isInitialized => _initialized;
  bool get isRewardedReady => _rewardedReady;

  /// [consent] is the player's answer to the consent dialog. On iOS the ATT
  /// prompt comes first, because the SDK reads the IDFA at init.
  Future<void> init({required bool consent}) async {
    final gameId = config.gameId;
    if (kIsWeb || _initialized || gameId == null) return;
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await AppTrackingTransparency.requestTrackingAuthorization();
      }
      await setConsent(consent);
      final done = Completer<void>();
      await UnityAds.init(
        gameId: gameId,
        // Test ads in debug builds; real ads only in release. Unity bans
        // accounts that click their own live ads.
        testMode: kDebugMode,
        onComplete: () {
          _initialized = true;
          _loadRewarded();
          if (!done.isCompleted) done.complete();
        },
        onFailed: (error, message) {
          debugPrint('[Ads] init failed: $error $message');
          if (!done.isCompleted) done.complete();
        },
      );
      await done.future.timeout(const Duration(seconds: 15), onTimeout: () {});
    } catch (error, stack) {
      CrashReporter.recordError(error, stack, reason: 'Ads.init');
    }
  }

  Future<void> setConsent(bool consent) async {
    if (kIsWeb || config.gameId == null) return;
    try {
      await UnityAds.setPrivacyConsent(PrivacyConsentType.gdpr, consent);
      await UnityAds.setPrivacyConsent(PrivacyConsentType.ccpa, consent);
    } catch (error, stack) {
      CrashReporter.recordError(error, stack, reason: 'Ads.setConsent');
    }
  }

  void _loadRewarded() {
    UnityAds.load(
      placementId: config.rewardedPlacement,
      onComplete: (_) => _rewardedReady = true,
      onFailed: (_, error, message) {
        _rewardedReady = false;
        debugPrint('[Ads] rewarded load failed: $error $message');
      },
    );
  }

  /// [serverId] is the player's uid: Unity passes it back as `sid` in the
  /// server-to-server callback, which is what pays the hint. Never logged.
  Future<RewardedOutcome> showRewarded({required String serverId}) async {
    if (!_initialized || !_rewardedReady) return RewardedOutcome.unavailable;
    _rewardedReady = false;
    final result = Completer<RewardedOutcome>();
    void finish(RewardedOutcome outcome) {
      if (!result.isCompleted) result.complete(outcome);
      _loadRewarded();
    }

    try {
      await UnityAds.showVideoAd(
        placementId: config.rewardedPlacement,
        serverId: serverId,
        onComplete: (_) => finish(RewardedOutcome.finished),
        onSkipped: (_) => finish(RewardedOutcome.skipped),
        onFailed: (_, error, message) {
          debugPrint('[Ads] rewarded show failed: $error $message');
          finish(RewardedOutcome.unavailable);
        },
      );
    } catch (error, stack) {
      CrashReporter.recordError(error, stack, reason: 'Ads.showRewarded');
      finish(RewardedOutcome.unavailable);
    }
    return result.future;
  }

  /// Load-then-show, bounded by a timeout so a slow network never holds the
  /// game screen hostage.
  Future<void> showInterstitial() async {
    if (!_initialized) return;
    final done = Completer<void>();
    void finish() {
      if (!done.isCompleted) done.complete();
    }

    try {
      await UnityAds.load(
        placementId: config.interstitialPlacement,
        onComplete: (placementId) => UnityAds.showVideoAd(
          placementId: placementId,
          onComplete: (_) => finish(),
          onSkipped: (_) => finish(),
          onFailed: (_, _, _) => finish(),
        ),
        onFailed: (_, _, _) => finish(),
      );
    } catch (error, stack) {
      CrashReporter.recordError(error, stack, reason: 'Ads.showInterstitial');
      finish();
    }
    await done.future.timeout(const Duration(seconds: 20), onTimeout: () {});
  }
}
