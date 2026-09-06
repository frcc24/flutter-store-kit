import 'dart:convert';

import 'engine.dart';

/// One game, in progress or just finished. Immutable: every change is a copy,
/// so the controller can save "the session as it was" without races.
class GameSession {
  const GameSession({
    required this.puzzleId,
    required this.difficulty,
    required this.givens,
    required this.solution,
    required this.grid,
    this.elapsedMs = 0,
    this.mistakes = 0,
    this.hintsUsed = 0,
    this.freeHintUsed = false,
    this.isCompleted = false,
  });

  factory GameSession.fromPuzzle(Puzzle puzzle) => GameSession(
    puzzleId: puzzle.id,
    difficulty: puzzle.difficulty,
    givens: puzzle.givens,
    solution: puzzle.solution,
    grid: puzzle.givens.map((row) => [...row]).toList(),
  );

  factory GameSession.fromJson(Map<String, dynamic> json) {
    List<List<int>> grid(Object? value) => (value as List)
        .map((row) => (row as List).cast<int>().toList())
        .toList();
    return GameSession(
      puzzleId: json['puzzleId'] as String,
      difficulty: Difficulty.values.byName(json['difficulty'] as String),
      givens: grid(json['givens']),
      solution: grid(json['solution']),
      grid: grid(json['grid']),
      elapsedMs: json['elapsedMs'] as int? ?? 0,
      mistakes: json['mistakes'] as int? ?? 0,
      hintsUsed: json['hintsUsed'] as int? ?? 0,
      freeHintUsed: json['freeHintUsed'] as bool? ?? false,
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }

  final String puzzleId;
  final Difficulty difficulty;
  final List<List<int>> givens;
  final List<List<int>> solution;
  final List<List<int>> grid;
  final int elapsedMs;
  final int mistakes;
  final int hintsUsed;
  final bool freeHintUsed;
  final bool isCompleted;

  bool isGiven(int row, int col) => givens[row][col] != 0;

  GameSession copyWith({
    List<List<int>>? grid,
    int? elapsedMs,
    int? mistakes,
    int? hintsUsed,
    bool? freeHintUsed,
    bool? isCompleted,
  }) => GameSession(
    puzzleId: puzzleId,
    difficulty: difficulty,
    givens: givens,
    solution: solution,
    grid: grid ?? this.grid,
    elapsedMs: elapsedMs ?? this.elapsedMs,
    mistakes: mistakes ?? this.mistakes,
    hintsUsed: hintsUsed ?? this.hintsUsed,
    freeHintUsed: freeHintUsed ?? this.freeHintUsed,
    isCompleted: isCompleted ?? this.isCompleted,
  );

  Map<String, dynamic> toJson() => {
    'puzzleId': puzzleId,
    'difficulty': difficulty.name,
    'givens': givens,
    'solution': solution,
    'grid': grid,
    'elapsedMs': elapsedMs,
    'mistakes': mistakes,
    'hintsUsed': hintsUsed,
    'freeHintUsed': freeHintUsed,
    'isCompleted': isCompleted,
  };

  String encode() => jsonEncode(toJson());

  static GameSession decode(String raw) =>
      GameSession.fromJson(jsonDecode(raw) as Map<String, dynamic>);
}
