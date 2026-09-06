import 'package:flutter_test/flutter_test.dart';
import 'package:mini_sudoku/app.dart';
import 'package:mini_sudoku/features/sudoku/board_widget.dart';

import 'support/test_services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('home starts a new game and then offers to continue it', (
    tester,
  ) async {
    final store = await freshStore();
    await tester.pumpWidget(
      MiniSudokuApp(services: await testServices(store: store)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Mini Sudoku'), findsOneWidget);
    expect(find.text('Continue'), findsNothing);

    await tester.tap(find.text('New game'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Easy'));
    await tester.pumpAndSettle();
    expect(find.byType(BoardWidget), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Continue'), findsOneWidget);
    expect(store.loadSession(), isNotNull);
  });

  testWidgets('statistics, rules and settings screens open', (tester) async {
    await tester.pumpWidget(MiniSudokuApp(services: await testServices()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Statistics'));
    await tester.pumpAndSettle();
    expect(find.text('Completed games'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Rules'));
    await tester.pumpAndSettle();
    expect(find.textContaining('every row'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('System language'), findsOneWidget);
  });

  testWidgets('switching language re-labels the home screen', (tester) async {
    final services = await testServices();
    await tester.pumpWidget(MiniSudokuApp(services: services));
    await tester.pumpAndSettle();
    await services.settings.setLocale('pt');
    await tester.pumpAndSettle();
    expect(find.text('Nova partida'), findsOneWidget);
  });
}
