import 'package:flutter_test/flutter_test.dart';
import 'package:mini_sudoku/app.dart';
import 'package:mini_sudoku/core/storage/local_store.dart';
import 'package:mini_sudoku/features/settings/settings_controller.dart';
import 'package:mini_sudoku/features/sudoku/board_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<LocalStore> freshStore() async {
    SharedPreferences.setMockInitialValues({});
    return LocalStore(await SharedPreferences.getInstance());
  }

  testWidgets('home starts a new game and then offers to continue it', (
    tester,
  ) async {
    final store = await freshStore();
    await tester.pumpWidget(
      MiniSudokuApp(store: store, settings: SettingsController(store)),
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
    final store = await freshStore();
    await tester.pumpWidget(
      MiniSudokuApp(store: store, settings: SettingsController(store)),
    );
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
    final store = await freshStore();
    final settings = SettingsController(store);
    await tester.pumpWidget(MiniSudokuApp(store: store, settings: settings));
    await tester.pumpAndSettle();
    await settings.setLocale('pt');
    await tester.pumpAndSettle();
    expect(find.text('Nova partida'), findsOneWidget);
  });
}
