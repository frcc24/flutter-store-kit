import 'package:flutter_test/flutter_test.dart';
import 'package:mini_sudoku/features/sudoku/engine.dart';
import 'package:mini_sudoku/features/sudoku/game_session.dart';

void main() {
  final puzzle = SudokuEngine().generate(Difficulty.easy, seed: 3);

  test('fromPuzzle copies the givens into a separate grid', () {
    final session = GameSession.fromPuzzle(puzzle);
    expect(session.grid, puzzle.givens);
    expect(identical(session.grid, puzzle.givens), isFalse);
    expect(session.puzzleId, 'easy-3');
    expect(session.elapsedMs, 0);
    expect(session.freeHintUsed, isFalse);
    expect(session.isCompleted, isFalse);
  });

  test('round-trips through JSON', () {
    final session = GameSession.fromPuzzle(
      puzzle,
    ).copyWith(elapsedMs: 5000, mistakes: 2, hintsUsed: 1, freeHintUsed: true);
    final decoded = GameSession.decode(session.encode());
    expect(decoded.puzzleId, session.puzzleId);
    expect(decoded.difficulty, Difficulty.easy);
    expect(decoded.givens, puzzle.givens);
    expect(decoded.solution, puzzle.solution);
    expect(decoded.grid, session.grid);
    expect(decoded.elapsedMs, 5000);
    expect(decoded.mistakes, 2);
    expect(decoded.hintsUsed, 1);
    expect(decoded.freeHintUsed, isTrue);
    expect(decoded.isCompleted, isFalse);
  });

  test('isGiven reads the givens, not the grid', () {
    final session = GameSession.fromPuzzle(puzzle);
    var checked = false;
    for (var r = 0; r < 9 && !checked; r++) {
      for (var c = 0; c < 9; c++) {
        if (puzzle.givens[r][c] != 0) {
          expect(session.isGiven(r, c), isTrue);
          checked = true;
          break;
        }
      }
    }
    expect(checked, isTrue);
  });
}
