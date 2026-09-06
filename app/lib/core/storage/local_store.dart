import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../features/stats/player_stats.dart';
import '../../features/sudoku/game_session.dart';

/// Everything the app persists, in one place. Keys are private so nothing
/// else can write to the preferences behind this class's back.
class LocalStore {
  LocalStore(this._prefs);

  final SharedPreferences _prefs;

  static const _sessionKey = 'session';
  static const _statsKey = 'stats';
  static const _localeKey = 'locale';

  GameSession? loadSession() {
    final raw = _prefs.getString(_sessionKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return GameSession.decode(raw);
    } catch (_) {
      // ponytail: a session written by an older build that no longer parses
      // is dropped instead of crashing the home screen.
      return null;
    }
  }

  Future<void> saveSession(GameSession session) =>
      _prefs.setString(_sessionKey, session.encode());

  Future<void> clearSession() => _prefs.remove(_sessionKey);

  PlayerStats loadStats() {
    final raw = _prefs.getString(_statsKey);
    if (raw == null || raw.isEmpty) return const PlayerStats();
    try {
      return PlayerStats.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const PlayerStats();
    }
  }

  Future<void> saveStats(PlayerStats stats) =>
      _prefs.setString(_statsKey, jsonEncode(stats.toJson()));

  static const _adsConsentKey = 'ads_consent';

  /// Null until the player answered the consent dialog.
  bool? loadAdsConsent() => _prefs.getBool(_adsConsentKey);

  Future<void> saveAdsConsent(bool consent) =>
      _prefs.setBool(_adsConsentKey, consent);

  String? loadLocale() => _prefs.getString(_localeKey);

  Future<void> saveLocale(String? code) => code == null
      ? _prefs.remove(_localeKey)
      : _prefs.setString(_localeKey, code);
}
