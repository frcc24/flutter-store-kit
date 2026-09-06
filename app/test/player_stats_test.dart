import 'package:flutter_test/flutter_test.dart';
import 'package:mini_sudoku/features/stats/player_stats.dart';
import 'package:mini_sudoku/features/sudoku/engine.dart';

void main() {
  test('defaults are zero', () {
    const stats = PlayerStats();
    expect(stats.completedGames, 0);
    expect(stats.bestTimeFor(Difficulty.easy), isNull);
    expect(stats.hintBalance, 0);
    expect(stats.adFree, isFalse);
  });

  test('recordCompletion counts games and keeps the best time', () {
    var stats = const PlayerStats().recordCompletion(Difficulty.easy, 90000);
    stats = stats.recordCompletion(Difficulty.easy, 120000);
    stats = stats.recordCompletion(Difficulty.hard, 300000);
    expect(stats.completedGames, 3);
    expect(stats.bestTimeFor(Difficulty.easy), 90000);
    expect(stats.bestTimeFor(Difficulty.hard), 300000);
    expect(stats.bestTimeFor(Difficulty.medium), isNull);
  });

  test('round-trips through JSON and tolerates missing fields', () {
    final stats = const PlayerStats(
      hintBalance: 2,
      adFree: true,
    ).recordCompletion(Difficulty.medium, 45000);
    final decoded = PlayerStats.fromJson(stats.toJson());
    expect(decoded.completedGames, 1);
    expect(decoded.bestTimeFor(Difficulty.medium), 45000);
    expect(decoded.hintBalance, 2);
    expect(decoded.adFree, isTrue);

    final partial = PlayerStats.fromJson({'completedGames': 4});
    expect(partial.completedGames, 4);
    expect(partial.bestTimeMs, isEmpty);
  });
}
