import 'package:flutter/widgets.dart';

import '../../core/storage/local_store.dart';

/// The user's language choice. `null` means "follow the system".
class SettingsController extends ChangeNotifier {
  SettingsController(this._store) : _locale = _parse(_store.loadLocale());

  final LocalStore _store;
  Locale? _locale;

  Locale? get locale => _locale;

  Future<void> setLocale(String? code) async {
    _locale = _parse(code);
    await _store.saveLocale(code);
    notifyListeners();
  }

  static Locale? _parse(String? code) => code == null ? null : Locale(code);
}
