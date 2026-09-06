import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_sudoku/features/sudoku/board_widget.dart';
import 'package:mini_sudoku/features/sudoku/engine.dart';
import 'package:mini_sudoku/features/sudoku/game_controller.dart';
import 'package:mini_sudoku/features/sudoku/game_screen.dart';
import 'package:mini_sudoku/l10n/app_localizations.dart';

import 'support/test_services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget wrap(Widget child) => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );

  testWidgets('solving the last cell shows the completion dialog', (
    tester,
  ) async {
    final store = await freshStore();
    final services = await testServices(store: store);
    final controller = GameController(store: store)
      ..startNew(Difficulty.easy, seed: 7);
    addTearDown(controller.dispose);
    final session = controller.session!;
    final empties = [
      for (var r = 0; r < 9; r++)
        for (var c = 0; c < 9; c++)
          if (session.grid[r][c] == 0) (r, c),
    ];
    for (final (r, c) in empties.take(empties.length - 1)) {
      controller.select(r, c);
      await controller.input(session.solution[r][c]);
    }
    final (lr, lc) = empties.last;

    await tester.pumpWidget(
      wrap(GameScreen(controller: controller, services: services)),
    );
    await tester.pumpAndSettle();
    expect(find.byType(BoardWidget), findsOneWidget);
    expect(find.text('Easy'), findsOneWidget);
    expect(find.text('Mistakes: 0'), findsOneWidget);

    await tester.tap(find.byKey(Key('cell-$lr-$lc')));
    await tester.pump();
    await tester.tap(find.byKey(Key('key-${session.solution[lr][lc]}')));
    await tester.pumpAndSettle();

    expect(find.text('Puzzle solved!'), findsOneWidget);
    expect(store.loadStats().completedGames, 1);
  });

  testWidgets('hint reveals a cell and the second hint is refused', (
    tester,
  ) async {
    final store = await freshStore();
    final services = await testServices(store: store);
    final controller = GameController(store: store)
      ..startNew(Difficulty.easy, seed: 7);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      wrap(GameScreen(controller: controller, services: services)),
    );
    await tester.pumpAndSettle();
    expect(find.text('1 free hint'), findsOneWidget);

    await tester.tap(find.text('Hint'));
    await tester.pumpAndSettle();
    expect(controller.session!.hintsUsed, 1);
    expect(find.text('No hints left'), findsOneWidget);

    // No server in the test services: the sheet opens and only explains.
    await tester.tap(find.text('Hint'));
    await tester.pumpAndSettle();
    expect(find.text('Out of hints'), findsOneWidget);
    expect(find.textContaining('not available'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    await controller.pause();
  });
}
