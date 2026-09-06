import 'package:flutter/foundation.dart';

/// Unity Ads identifiers. Empty game ids mean "no ads": the app runs, the
/// consent dialog never shows and every ad call answers unavailable.
/// Fill in the ids from dashboard.unity3d.com → Monetization → your project.
class AdsConfig {
  const AdsConfig({
    this.androidGameId = '',
    this.iosGameId = '',
    this.rewardedAndroid = 'Rewarded_Android',
    this.rewardedIOS = 'Rewarded_iOS',
    this.interstitialAndroid = 'Interstitial_Android',
    this.interstitialIOS = 'Interstitial_iOS',
  });

  final String androidGameId;
  final String iosGameId;
  final String rewardedAndroid;
  final String rewardedIOS;
  final String interstitialAndroid;
  final String interstitialIOS;

  bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;

  String? get gameId {
    final id = _isIOS ? iosGameId : androidGameId;
    return id.isEmpty ? null : id;
  }

  bool get isConfigured => androidGameId.isNotEmpty || iosGameId.isNotEmpty;
  String get rewardedPlacement => _isIOS ? rewardedIOS : rewardedAndroid;
  String get interstitialPlacement =>
      _isIOS ? interstitialIOS : interstitialAndroid;
}

/// The kit's own ids. Replace with yours.
const kitAds = AdsConfig();
