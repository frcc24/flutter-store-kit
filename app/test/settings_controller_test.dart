import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_sudoku/core/storage/local_store.dart';
import 'package:mini_sudoku/features/settings/settings_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('locale persists and null means system', () async {
    SharedPreferences.setMockInitialValues({});
    final store = LocalStore(await SharedPreferences.getInstance());
    final settings = SettingsController(store);
    expect(settings.locale, isNull);

    var notified = 0;
    settings.addListener(() => notified++);
    await settings.setLocale('es');
    expect(settings.locale, const Locale('es'));
    expect(notified, 1);
    expect(SettingsController(store).locale, const Locale('es'));

    await settings.setLocale(null);
    expect(settings.locale, isNull);
    expect(store.loadLocale(), isNull);
  });
}
