import 'dart:io';

import 'package:mini_sudoku/features/sudoku/engine.dart';

/// Proves the property the test suite cannot: every generated puzzle has
/// exactly one solution. The solver below is deliberately naive and
/// independent of the engine — checking the generator with the generator's own
/// solver proves nothing. Run it after touching generation:
/// `dart run tool/check_unique.dart`
void main() {
  const seedsPerDifficulty = 30;
  final engine = SudokuEngine();
  var checked = 0;
  final broken = <String>[];

  for (final difficulty in Difficulty.values) {
    for (var seed = 1; seed <= seedsPerDifficulty; seed++) {
      final puzzle = engine.generate(difficulty, seed: seed);
      final grid = puzzle.givens.map((row) => [...row]).toList();
      final solutions = _countSolutions(grid, limit: 2);
      checked++;
      if (solutions != 1) {
        broken.add('${difficulty.name} seed $seed: $solutions solutions');
      }
    }
  }

  stdout.writeln(
    '$checked puzzles, ${broken.length} with more than one '
    'solution',
  );
  for (final line in broken) {
    stderr.writeln('FAIL $line');
  }
  if (broken.isNotEmpty) exit(1);
}

/// Plain backtracking, first empty cell first. Stops at [limit] solutions.
int _countSolutions(List<List<int>> grid, {required int limit}) {
  for (var row = 0; row < 9; row++) {
    for (var col = 0; col < 9; col++) {
      if (grid[row][col] != 0) continue;
      var found = 0;
      for (var value = 1; value <= 9; value++) {
        if (!_fits(grid, row, col, value)) continue;
        grid[row][col] = value;
        found += _countSolutions(grid, limit: limit - found);
        grid[row][col] = 0;
        if (found >= limit) return found;
      }
      return found;
    }
  }
  return 1;
}

bool _fits(List<List<int>> grid, int row, int col, int value) {
  for (var i = 0; i < 9; i++) {
    if (grid[row][i] == value || grid[i][col] == value) return false;
  }
  final r0 = (row ~/ 3) * 3;
  final c0 = (col ~/ 3) * 3;
  for (var r = r0; r < r0 + 3; r++) {
    for (var c = c0; c < c0 + 3; c++) {
      if (grid[r][c] == value) return false;
    }
  }
  return true;
}
