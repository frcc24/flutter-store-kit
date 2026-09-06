import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/storage/local_store.dart';
import '../stats/player_stats.dart';
import 'engine.dart';
import 'game_session.dart';

enum HintResult { applied, noHintsLeft, nothingToReveal }

/// Drives one game. Owns the session, the selection, the conflicts shown on
/// the board and the one-second ticker. The screen starts and pauses the
/// ticker; the controller never starts it on its own so tests stay timer-free.
class GameController extends ChangeNotifier {
  GameController({required LocalStore store, SudokuEngine? engine})
    : _store = store,
      _engine = engine ?? SudokuEngine(),
      _stats = store.loadStats();

  final LocalStore _store;
  final SudokuEngine _engine;

  GameSession? _session;
  (int, int)? _selected;
  Set<(int, int)> _conflicts = const {};
  PlayerStats _stats;
  Timer? _ticker;

  GameSession? get session => _session;
  (int, int)? get selected => _selected;
  Set<(int, int)> get conflicts => _conflicts;
  PlayerStats get stats => _stats;
  bool get hasFreeHint => !(_session?.freeHintUsed ?? true);
  int get hintBalance => _stats.hintBalance;

  void startNew(Difficulty difficulty, {int? seed}) {
    _stopTicker();
    _session = GameSession.fromPuzzle(_engine.generate(difficulty, seed: seed));
    _selected = null;
    _conflicts = const {};
    _stats = _store.loadStats();
    _store.saveSession(_session!);
    notifyListeners();
  }

  /// Loads the saved session. False when there is none or it was finished.
  bool resume() {
    final saved = _store.loadSession();
    if (saved == null || saved.isCompleted) return false;
    _stopTicker();
    _session = saved;
    _selected = null;
    _conflicts = const {};
    _stats = _store.loadStats();
    notifyListeners();
    return true;
  }

  void select(int row, int col) {
    final session = _session;
    if (session == null || session.isCompleted) return;
    _selected = (row, col);
    notifyListeners();
  }

  Future<void> input(int value) async {
    final session = _session;
    final selected = _selected;
    if (session == null || selected == null || session.isCompleted) return;
    final (row, col) = selected;
    if (session.isGiven(row, col) || session.grid[row][col] == value) return;

    final grid = session.grid.map((r) => [...r]).toList();
    grid[row][col] = value;
    final conflicts = _engine.conflicts(grid, row, col, value);
    _conflicts = conflicts.isEmpty ? const {} : {(row, col), ...conflicts};
    await _commit(
      session.copyWith(
        grid: grid,
        mistakes: conflicts.isEmpty ? session.mistakes : session.mistakes + 1,
      ),
    );
  }

  Future<void> erase() => input(0);

  /// Reveals the selected cell, or the first wrong one. The first hint of a
  /// game is free; the rest come out of [PlayerStats.hintBalance].
  Future<HintResult> useHint() async {
    final session = _session;
    if (session == null || session.isCompleted) {
      return HintResult.nothingToReveal;
    }
    final target = _hintTarget(session);
    if (target == null) return HintResult.nothingToReveal;
    final free = !session.freeHintUsed;
    if (!free && _stats.hintBalance <= 0) return HintResult.noHintsLeft;

    final (row, col) = target;
    final grid = session.grid.map((r) => [...r]).toList();
    grid[row][col] = session.solution[row][col];
    if (!free) {
      _stats = _stats.copyWith(hintBalance: _stats.hintBalance - 1);
      await _store.saveStats(_stats);
    }
    _selected = (row, col);
    _conflicts = const {};
    await _commit(
      session.copyWith(
        grid: grid,
        hintsUsed: session.hintsUsed + 1,
        freeHintUsed: true,
      ),
    );
    return HintResult.applied;
  }

  void startTicker() {
    final session = _session;
    if (session == null || session.isCompleted) return;
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final current = _session;
      if (current == null || current.isCompleted) return;
      _session = current.copyWith(elapsedMs: current.elapsedMs + 1000);
      notifyListeners();
    });
  }

  /// Stops the clock and saves the elapsed time. Called by the screen when it
  /// leaves the foreground or is disposed.
  Future<void> pause() async {
    _stopTicker();
    final session = _session;
    if (session != null && !session.isCompleted) {
      await _store.saveSession(session);
    }
  }

  (int, int)? _hintTarget(GameSession session) {
    bool wrong(int r, int c) =>
        !session.isGiven(r, c) && session.grid[r][c] != session.solution[r][c];
    final selected = _selected;
    if (selected != null && wrong(selected.$1, selected.$2)) return selected;
    for (var r = 0; r < SudokuEngine.size; r++) {
      for (var c = 0; c < SudokuEngine.size; c++) {
        if (wrong(r, c)) return (r, c);
      }
    }
    return null;
  }

  Future<void> _commit(GameSession next) async {
    if (_engine.isSolved(next.grid)) {
      _stopTicker();
      _session = next.copyWith(isCompleted: true);
      _stats = _stats.recordCompletion(next.difficulty, next.elapsedMs);
      await _store.saveStats(_stats);
      await _store.clearSession();
    } else {
      _session = next;
      await _store.saveSession(next);
    }
    notifyListeners();
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  @override
  void dispose() {
    _stopTicker();
    super.dispose();
  }
}
