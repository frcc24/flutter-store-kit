import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_sudoku/core/api/kit_api.dart';
import 'package:mini_sudoku/core/storage/local_store.dart';
import 'package:mini_sudoku/features/stats/player_stats.dart';
import 'package:mini_sudoku/features/sudoku/engine.dart';
import 'package:mini_sudoku/features/sudoku/game_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<({LocalStore store, GameController controller})> make({
    PlayerStats? stats,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final store = LocalStore(await SharedPreferences.getInstance());
    if (stats != null) await store.saveStats(stats);
    final controller = GameController(store: store);
    addTearDown(controller.dispose);
    return (store: store, controller: controller);
  }

  List<(int, int)> emptyCells(GameController controller) {
    final grid = controller.session!.grid;
    return [
      for (var r = 0; r < 9; r++)
        for (var c = 0; c < 9; c++)
          if (grid[r][c] == 0) (r, c),
    ];
  }

  /// Fills every empty cell with the solution except the last [leave].
  Future<void> fillAllBut(GameController controller, int leave) async {
    final cells = emptyCells(controller);
    final solution = controller.session!.solution;
    for (final (r, c) in cells.take(cells.length - leave)) {
      controller.select(r, c);
      await controller.input(solution[r][c]);
    }
  }

  test('startNew saves a session that resume loads', () async {
    final (:store, :controller) = await make();
    controller.startNew(Difficulty.easy, seed: 5);
    expect(store.loadSession()?.puzzleId, 'easy-5');

    final second = GameController(store: store);
    addTearDown(second.dispose);
    expect(second.resume(), isTrue);
    expect(second.session?.puzzleId, 'easy-5');
  });

  test('resume is false when nothing was saved', () async {
    final (:controller, store: _) = await make();
    expect(controller.resume(), isFalse);
    expect(controller.session, isNull);
  });

  test('input ignores given cells and counts a conflicting value', () async {
    final (:controller, store: _) = await make();
    controller.startNew(Difficulty.easy, seed: 5);
    final session = controller.session!;

    final (gr, gc) = [
      for (var r = 0; r < 9; r++)
        for (var c = 0; c < 9; c++)
          if (session.isGiven(r, c)) (r, c),
    ].first;
    final givenValue = session.grid[gr][gc];
    controller.select(gr, gc);
    await controller.input(givenValue % 9 + 1);
    expect(controller.session!.grid[gr][gc], givenValue);
    expect(controller.session!.mistakes, 0);

    final (er, ec) = emptyCells(controller).first;
    final clashing = session.grid[er].firstWhere((v) => v != 0);
    controller.select(er, ec);
    await controller.input(clashing);
    expect(controller.session!.grid[er][ec], clashing);
    expect(controller.session!.mistakes, 1);
    expect(controller.conflicts, contains((er, ec)));

    await controller.erase();
    expect(controller.session!.grid[er][ec], 0);
    expect(controller.conflicts, isEmpty);
  });

  test('one free hint per game, then hints need balance', () async {
    final (:store, :controller) = await make();
    controller.startNew(Difficulty.easy, seed: 5);
    final (r, c) = emptyCells(controller).first;
    controller.select(r, c);

    expect(controller.hasFreeHint, isTrue);
    expect(await controller.useHint(), HintResult.applied);
    expect(controller.session!.grid[r][c], controller.session!.solution[r][c]);
    expect(controller.session!.freeHintUsed, isTrue);
    expect(controller.session!.hintsUsed, 1);
    expect(controller.hasFreeHint, isFalse);

    expect(await controller.useHint(), HintResult.noHintsLeft);
    expect(store.loadSession()?.hintsUsed, 1);
  });

  test('a paid hint consumes the balance', () async {
    final (:store, :controller) = await make(
      stats: const PlayerStats(hintBalance: 1),
    );
    controller.startNew(Difficulty.easy, seed: 5);
    expect(await controller.useHint(), HintResult.applied); // free
    expect(await controller.useHint(), HintResult.applied); // paid
    expect(controller.hintBalance, 0);
    expect(store.loadStats().hintBalance, 0);
    expect(await controller.useHint(), HintResult.noHintsLeft);
  });

  test('completing the puzzle updates stats and clears the session', () async {
    final (:store, :controller) = await make();
    controller.startNew(Difficulty.easy, seed: 11);
    await fillAllBut(controller, 0);
    expect(controller.session!.isCompleted, isTrue);
    expect(store.loadSession(), isNull);
    expect(store.loadStats().completedGames, 1);
    expect(store.loadStats().bestTimeFor(Difficulty.easy), 0);
    expect(await controller.useHint(), HintResult.nothingToReveal);
  });

  test('ticker counts seconds and pause stops it', () async {
    final (:controller, store: _) = await make();
    controller.startNew(Difficulty.medium, seed: 8);
    fakeAsync((async) {
      controller.startTicker();
      async.elapse(const Duration(seconds: 3));
      expect(controller.session!.elapsedMs, 3000);
      controller.pause();
      async.elapse(const Duration(seconds: 3));
      expect(controller.session!.elapsedMs, 3000);
    });
  });

  test('a paid hint goes through the server when one is configured', () async {
    SharedPreferences.setMockInitialValues({});
    final store = LocalStore(await SharedPreferences.getInstance());
    final spent = <String>[];
    final controller = GameController(
      store: store,
      remoteSpend: (operationId) async {
        spent.add(operationId);
        return const SpendBalance(4);
      },
    );
    addTearDown(controller.dispose);
    controller.startNew(Difficulty.easy, seed: 5);
    expect(await controller.useHint(), HintResult.applied); // free, no call
    expect(spent, isEmpty);
    expect(await controller.useHint(), HintResult.applied); // paid
    expect(spent, hasLength(1));
    expect(controller.hintBalance, 4);
    expect(store.loadStats().hintBalance, 4);
  });

  test('server answers decide noHintsLeft and unavailable', () async {
    SharedPreferences.setMockInitialValues({});
    final store = LocalStore(await SharedPreferences.getInstance());
    SpendResult next = const SpendNoHints();
    final controller = GameController(
      store: store,
      remoteSpend: (_) async => next,
    );
    addTearDown(controller.dispose);
    controller.startNew(Difficulty.easy, seed: 5);
    await controller.useHint(); // free
    final before = controller.session!.grid.map((r) => [...r]).toList();
    expect(await controller.useHint(), HintResult.noHintsLeft);
    next = const SpendUnavailable();
    expect(await controller.useHint(), HintResult.unavailable);
    expect(controller.session!.grid, before);
    controller.setHintBalance(2);
    expect(store.loadStats().hintBalance, 2);
  });
}
