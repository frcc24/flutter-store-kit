import 'package:flutter_test/flutter_test.dart';
import 'package:mini_sudoku/features/sudoku/engine.dart';

int countHoles(List<List<int>> grid) =>
    grid.expand((row) => row).where((value) => value == 0).length;

void main() {
  final engine = SudokuEngine();

  test('solution is a solved grid and givens agree with it', () {
    final puzzle = engine.generate(Difficulty.easy, seed: 42);
    expect(engine.isSolved(puzzle.solution), isTrue);
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        final given = puzzle.givens[r][c];
        expect(given == 0 || given == puzzle.solution[r][c], isTrue);
      }
    }
    expect(countHoles(puzzle.givens), greaterThanOrEqualTo(25));
  });

  test('same seed produces the same puzzle', () {
    final a = engine.generate(Difficulty.medium, seed: 123);
    final b = engine.generate(Difficulty.medium, seed: 123);
    expect(a.givens, b.givens);
    expect(a.solution, b.solution);
    expect(a.id, 'medium-123');
  });

  test('hard removes more cells than easy', () {
    final easy = engine.generate(Difficulty.easy, seed: 9);
    final hard = engine.generate(Difficulty.hard, seed: 9);
    expect(countHoles(hard.givens), greaterThan(countHoles(easy.givens)));
  });

  test('conflicts finds duplicates in row, column and box', () {
    final grid = List.generate(9, (_) => List<int>.filled(9, 0));
    grid[0][0] = 5;
    expect(engine.conflicts(grid, 0, 8, 5), {(0, 0)});
    expect(engine.conflicts(grid, 8, 0, 5), {(0, 0)});
    expect(engine.conflicts(grid, 1, 1, 5), {(0, 0)});
    expect(engine.conflicts(grid, 4, 4, 5), isEmpty);
    expect(engine.conflicts(grid, 0, 8, 0), isEmpty);
  });

  test('isSolved is false while a cell is empty or duplicated', () {
    final puzzle = engine.generate(Difficulty.easy, seed: 1);
    final grid = puzzle.solution.map((row) => [...row]).toList();
    grid[3][3] = 0;
    expect(engine.isSolved(grid), isFalse);
    grid[3][3] = grid[3][4];
    expect(engine.isSolved(grid), isFalse);
  });
}
