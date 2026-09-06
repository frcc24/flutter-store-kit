import '../sudoku/engine.dart';

/// Lifetime numbers for one device. Persisted by LocalStore.
class PlayerStats {
  const PlayerStats({
    this.completedGames = 0,
    this.bestTimeMs = const {},
    this.hintBalance = 0,
    this.adFree = false,
  });

  factory PlayerStats.fromJson(Map<String, dynamic> json) => PlayerStats(
    completedGames: json['completedGames'] as int? ?? 0,
    bestTimeMs: Map<String, int>.from(json['bestTimeMs'] as Map? ?? const {}),
    hintBalance: json['hintBalance'] as int? ?? 0,
    adFree: json['adFree'] as bool? ?? false,
  );

  final int completedGames;

  /// Best time per [Difficulty.name].
  final Map<String, int> bestTimeMs;

  /// Hints beyond the free one per game. Credited by rewarded ads and
  /// purchases (chapters 7 and 8); only spent here.
  final int hintBalance;

  /// True once "remove ads" was bought (chapter 8).
  final bool adFree;

  int? bestTimeFor(Difficulty difficulty) => bestTimeMs[difficulty.name];

  PlayerStats recordCompletion(Difficulty difficulty, int elapsedMs) {
    final best = bestTimeFor(difficulty);
    return copyWith(
      completedGames: completedGames + 1,
      bestTimeMs: {
        ...bestTimeMs,
        difficulty.name: best == null || elapsedMs < best ? elapsedMs : best,
      },
    );
  }

  PlayerStats copyWith({
    int? completedGames,
    Map<String, int>? bestTimeMs,
    int? hintBalance,
    bool? adFree,
  }) => PlayerStats(
    completedGames: completedGames ?? this.completedGames,
    bestTimeMs: bestTimeMs ?? this.bestTimeMs,
    hintBalance: hintBalance ?? this.hintBalance,
    adFree: adFree ?? this.adFree,
  );

  Map<String, dynamic> toJson() => {
    'completedGames': completedGames,
    'bestTimeMs': bestTimeMs,
    'hintBalance': hintBalance,
    'adFree': adFree,
  };
}
