import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

import '../crash/crash_reporter.dart';

/// The three switches operations needs after launch, read once at boot.
/// Defaults are the "everything on, nothing forced" state, and they are what
/// the app runs with when Firebase is missing or the fetch times out — a
/// switch that fails closed would take the game down with the network.
class RemoteFlags {
  const RemoteFlags({
    this.minSupportedBuild = 0,
    this.adsEnabled = true,
    this.iapEnabled = true,
  });

  /// Builds below this must update before playing. 0 = never.
  final int minSupportedBuild;
  final bool adsEnabled;
  final bool iapEnabled;

  static const _defaults = <String, Object>{
    'min_supported_build': 0,
    'ads_enabled': true,
    'iap_enabled': true,
  };

  static Future<RemoteFlags> fetch({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    if (!CrashReporter.firebaseReady) return const RemoteFlags();
    try {
      final config = FirebaseRemoteConfig.instance;
      await config.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: timeout,
          minimumFetchInterval: const Duration(hours: 1),
        ),
      );
      await config.setDefaults(_defaults);
      await config.fetchAndActivate().timeout(timeout);
      return RemoteFlags(
        minSupportedBuild: config.getInt('min_supported_build'),
        adsEnabled: config.getBool('ads_enabled'),
        iapEnabled: config.getBool('iap_enabled'),
      );
    } catch (error) {
      debugPrint('[RemoteFlags] using defaults: $error');
      return const RemoteFlags();
    }
  }

  bool requiresUpdate(int currentBuild) => currentBuild < minSupportedBuild;
}
