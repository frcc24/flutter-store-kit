import 'package:mini_sudoku/core/api/kit_api.dart';
import 'package:mini_sudoku/core/auth/anonymous_session.dart';
import 'package:mini_sudoku/core/storage/local_store.dart';
import 'package:mini_sudoku/features/settings/settings_controller.dart';
import 'package:mini_sudoku/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<LocalStore> freshStore([Map<String, Object> values = const {}]) async {
  SharedPreferences.setMockInitialValues(values);
  return LocalStore(await SharedPreferences.getInstance());
}

/// Real store and settings, no Firebase, no server unless given.
Future<Services> testServices({
  LocalStore? store,
  KitApi? api,
  AnonymousSession? session,
}) async {
  final s = store ?? await freshStore();
  return Services(
    store: s,
    settings: SettingsController(s),
    session: session ?? AnonymousSession(),
    api: api,
  );
}
