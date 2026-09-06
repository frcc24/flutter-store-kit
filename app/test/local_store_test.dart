import 'package:flutter_test/flutter_test.dart';
import 'package:mini_sudoku/core/storage/local_store.dart';
import 'package:mini_sudoku/features/stats/player_stats.dart';
import 'package:mini_sudoku/features/sudoku/engine.dart';
import 'package:mini_sudoku/features/sudoku/game_session.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<LocalStore> storeWith(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    return LocalStore(await SharedPreferences.getInstance());
  }

  test('session saves, loads and clears', () async {
    final store = await storeWith({});
    expect(store.loadSession(), isNull);
    final session = GameSession.fromPuzzle(
      SudokuEngine().generate(Difficulty.easy, seed: 2),
    );
    await store.saveSession(session);
    expect(store.loadSession()?.puzzleId, 'easy-2');
    await store.clearSession();
    expect(store.loadSession(), isNull);
  });

  test('a corrupt session is dropped instead of thrown', () async {
    final store = await storeWith({'session': '{not json'});
    expect(store.loadSession(), isNull);
  });

  test('stats default to zero and round-trip', () async {
    final store = await storeWith({});
    expect(store.loadStats().completedGames, 0);
    await store.saveStats(const PlayerStats(hintBalance: 3));
    expect(store.loadStats().hintBalance, 3);
  });

  test('locale saves and null removes it', () async {
    final store = await storeWith({});
    expect(store.loadLocale(), isNull);
    await store.saveLocale('pt');
    expect(store.loadLocale(), 'pt');
    await store.saveLocale(null);
    expect(store.loadLocale(), isNull);
  });
}
