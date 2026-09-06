import 'package:firebase_auth/firebase_auth.dart';

import 'core/api/kit_api.dart';
import 'core/auth/anonymous_session.dart';
import 'core/crash/crash_reporter.dart';
import 'core/storage/local_store.dart';
import 'features/settings/settings_controller.dart';
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
  });

  /// Production wiring. Each piece answers "unavailable" when its backing
  /// service is not configured, so the app boots on a fresh clone.
  factory Services.production(LocalStore store) {
    final session = AnonymousSession(
      auth: CrashReporter.firebaseReady ? FirebaseAuth.instance : null,
    );
    return Services(
      store: store,
      settings: SettingsController(store),
      session: session,
      api: KitApi.fromEnvironment(session.idToken),
    );
  }

  final LocalStore store;
  final SettingsController settings;
  final AnonymousSession session;
  final KitApi? api;

  /// The controller for a new or resumed game, wired to the server when
  /// there is one.
  GameController newGameController() =>
      GameController(store: store, remoteSpend: api?.spendHint);
}
