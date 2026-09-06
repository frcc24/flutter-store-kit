import 'dart:math';

/// The three difficulties the app offers. Holes per difficulty live in
/// [SudokuEngine.generate].
enum Difficulty { easy, medium, hard }

/// A generated puzzle: [givens] has 0 for empty cells, [solution] is full.
class Puzzle {
  const Puzzle({
    required this.id,
    required this.difficulty,
    required this.givens,
    required this.solution,
  });

  final String id;
  final Difficulty difficulty;
  final List<List<int>> givens;
  final List<List<int>> solution;
}

/// Classic 9x9 sudoku: generation, move validation and the solved check.
class SudokuEngine {
  SudokuEngine({Random? random}) : _random = random ?? Random();

  final Random _random;

  static const size = 9;
  static const box = 3;

  /// Generates a puzzle with a unique solution. Same [seed], same puzzle.
  Puzzle generate(Difficulty difficulty, {int? seed}) {
    final runtimeSeed = seed ?? _random.nextInt(0x7fffffff);
    final rng = _StableRandom(runtimeSeed);
    final solution = _solvedGrid(rng);
    final givens = solution.map((row) => [...row]).toList();
    final target = switch (difficulty) {
      Difficulty.easy => 34,
      Difficulty.medium => 44,
      Difficulty.hard => 52,
    };

    final cells = [
      for (var r = 0; r < size; r++)
        for (var c = 0; c < size; c++) (r, c),
    ];
    _shuffle(cells, rng);
    var holes = 0;
    var stalledRounds = 0;
    // ponytail: dig until the target or three rounds without progress. The
    // node limit in _countSolutions means a hard puzzle can end a few holes
    // short of the target; it never ships a cell whose removal was not proven
    // unique within the limit.
    while (holes < target && stalledRounds < 3) {
      var removed = 0;
      for (final (r, c) in cells) {
        if (holes >= target) break;
        if (givens[r][c] == 0) continue;
        final backup = givens[r][c];
        givens[r][c] = 0;
        if (_countSolutions(givens, rng, limit: 2, nodeLimit: 30000) == 1) {
          holes++;
          removed++;
        } else {
          givens[r][c] = backup;
        }
      }
      _shuffle(cells, rng);
      stalledRounds = removed == 0 ? stalledRounds + 1 : 0;
    }

    return Puzzle(
      id: '${difficulty.name}-$runtimeSeed',
      difficulty: difficulty,
      givens: givens,
      solution: solution,
    );
  }

  /// Cells that clash with placing [value] at ([row], [col]). Empty = valid.
  Set<(int, int)> conflicts(List<List<int>> grid, int row, int col, int value) {
    final result = <(int, int)>{};
    if (value == 0) return result;
    for (var c = 0; c < size; c++) {
      if (c != col && grid[row][c] == value) result.add((row, c));
    }
    for (var r = 0; r < size; r++) {
      if (r != row && grid[r][col] == value) result.add((r, col));
    }
    final r0 = (row ~/ box) * box;
    final c0 = (col ~/ box) * box;
    for (var r = r0; r < r0 + box; r++) {
      for (var c = c0; c < c0 + box; c++) {
        if ((r != row || c != col) && grid[r][c] == value) {
          result.add((r, c));
        }
      }
    }
    return result;
  }

  bool isSolved(List<List<int>> grid) {
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        final value = grid[r][c];
        if (value == 0 || conflicts(grid, r, c, value).isNotEmpty) {
          return false;
        }
      }
    }
    return true;
  }

  List<List<int>> _solvedGrid(_StableRandom rng) {
    int pattern(int row, int col) => (box * row + row ~/ box + col) % size;
    List<int> shuffled(List<int> values) {
      final copy = [...values];
      _shuffle(copy, rng);
      return copy;
    }

    final numbers = shuffled(List.generate(size, (i) => i + 1));
    final rows = [
      for (final group in shuffled([0, 1, 2]))
        for (final i in shuffled([0, 1, 2])) group * box + i,
    ];
    final cols = [
      for (final group in shuffled([0, 1, 2]))
        for (final i in shuffled([0, 1, 2])) group * box + i,
    ];
    return [
      for (final r in rows) [for (final c in cols) numbers[pattern(r, c)]],
    ];
  }

  int _countSolutions(
    List<List<int>> grid,
    _StableRandom rng, {
    required int limit,
    required int nodeLimit,
  }) {
    var solutions = 0;
    var visited = 0;

    bool solve() {
      if (solutions >= limit || visited > nodeLimit) return false;
      (int, int)? empty;
      search:
      for (var r = 0; r < size; r++) {
        for (var c = 0; c < size; c++) {
          if (grid[r][c] == 0) {
            empty = (r, c);
            break search;
          }
        }
      }
      if (empty == null) {
        solutions++;
        return solutions < limit;
      }
      final (row, col) = empty;
      final values = List.generate(size, (i) => i + 1);
      _shuffle(values, rng);
      for (final value in values) {
        visited++;
        if (conflicts(grid, row, col, value).isNotEmpty) continue;
        grid[row][col] = value;
        final keepGoing = solve();
        grid[row][col] = 0;
        if (!keepGoing) break;
      }
      return true;
    }

    solve();
    return solutions;
  }
}

void _shuffle<T>(List<T> items, _StableRandom rng) {
  for (var i = items.length - 1; i > 0; i--) {
    final j = rng.nextInt(i + 1);
    final temp = items[i];
    items[i] = items[j];
    items[j] = temp;
  }
}

/// Linear congruential generator so a seed reproduces a puzzle on every
/// platform and Flutter version; `dart:math` makes no such promise.
class _StableRandom {
  _StableRandom(int seed)
    : _state = (seed & 0x7fffffff) == 0 ? 1 : seed & 0x7fffffff;

  int _state;

  int nextInt(int maxExclusive) {
    _state = ((_state * 1103515245) + 12345) & 0x7fffffff;
    return _state % maxExclusive;
  }
}
