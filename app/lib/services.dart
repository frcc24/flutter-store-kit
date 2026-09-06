import 'package:firebase_auth/firebase_auth.dart';

import 'core/ads/ads_service.dart';
import 'core/api/kit_api.dart';
import 'core/auth/anonymous_session.dart';
import 'core/crash/crash_reporter.dart';
import 'core/iap/iap_service.dart';
import 'core/storage/local_store.dart';
import 'features/settings/settings_controller.dart';
import 'features/shop/purchase_deliveries.dart';
import 'features/sudoku/game_controller.dart';

/// Everything the screens need, built once in main() and handed down. A plain
/// container, not a locator: every field is a constructor argument, so a test
/// builds one with fakes and nothing global exists.
class Services {
  const Services({
    required this.store,
    required this.settings,
    required this.session,
    required this.api,
    required this.ads,
    required this.iap,
  });

  /// Production wiring. Each piece answers "unavailable" when its backing
  /// service is not configured, so the app boots on a fresh clone.
  factory Services.production(LocalStore store) {
    final session = AnonymousSession(
      auth: CrashReporter.firebaseReady ? FirebaseAuth.instance : null,
    );
    final api = KitApi.fromEnvironment(session.idToken);
    // The store hands purchases to the deliveries, and the deliveries close
    // them with the store: two objects that need each other, tied here.
    late final PurchaseDeliveries deliveries;
    final iap = IapService(
      onPurchase: (purchase) => deliveries.deliver(purchase),
    );
    deliveries = PurchaseDeliveries(store: store, api: api, finish: iap.finish);
    return Services(
      store: store,
      settings: SettingsController(store),
      session: session,
      api: api,
      ads: AdsService(),
      iap: iap,
    );
  }

  final LocalStore store;
  final SettingsController settings;
  final AnonymousSession session;
  final KitApi? api;
  final AdsService ads;
  final IapService iap;

  /// The controller for a new or resumed game, wired to the server when
  /// there is one.
  GameController newGameController() =>
      GameController(store: store, remoteSpend: api?.spendHint);
}
