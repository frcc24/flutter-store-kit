import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:mini_sudoku/core/ads/ads_config.dart';
import 'package:mini_sudoku/core/ads/ads_service.dart';
import 'package:mini_sudoku/features/review/review_prompt.dart';
import 'package:mini_sudoku/features/stats/player_stats.dart';
import 'package:mini_sudoku/features/sudoku/engine.dart';
import 'package:mini_sudoku/features/sudoku/game_controller.dart';
import 'package:mini_sudoku/features/sudoku/game_screen.dart';
import 'package:mini_sudoku/l10n/app_localizations.dart';

import 'support/test_services.dart';

class FakeReview implements InAppReview {
  int requested = 0;
  @override
  Future<bool> isAvailable() async => true;
  @override
  Future<void> requestReview() async => requested++;
  @override
  Future<void> openStoreListing({
    String? appStoreId,
    String? microsoftStoreId,
  }) async {}
}

class CountingAds extends AdsService {
  CountingAds() : super(config: const AdsConfig(androidGameId: 'x'));
  int interstitials = 0;
  @override
  bool get isInitialized => true;
  @override
  Future<void> showInterstitial() async => interstitials++;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'prompts at 3, then every 5, stops after accept or three refusals',
    () async {
      final store = await freshStore();
      final review = FakeReview();
      final prompt = ReviewPrompt(store, review: review);
      expect(await prompt.shouldPrompt(1), isFalse);
      expect(await prompt.shouldPrompt(3), isTrue);
      expect(await prompt.shouldPrompt(3), isFalse, reason: 'once per count');
      await prompt.decline();
      expect(await prompt.shouldPrompt(4), isFalse);
      expect(await prompt.shouldPrompt(8), isTrue);
      await prompt.decline();
      expect(await prompt.shouldPrompt(13), isTrue);
      await prompt.decline();
      expect(await prompt.shouldPrompt(18), isFalse, reason: 'three refusals');

      final fresh = ReviewPrompt(await freshStore(), review: review);
      expect(await fresh.shouldPrompt(3), isTrue);
      await fresh.accept();
      expect(review.requested, 1);
      expect(await fresh.shouldPrompt(8), isFalse);
    },
  );

  Future<void> finishGame(
    WidgetTester tester,
    GameController controller,
  ) async {
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
    await tester.tap(find.byKey(Key('cell-$lr-$lc')));
    await tester.pump();
    await tester.tap(find.byKey(Key('key-${session.solution[lr][lc]}')));
    await tester.pumpAndSettle();
  }

  Future<(CountingAds, GameController)> game(
    WidgetTester tester, {
    required int completedBefore,
    bool adFree = false,
  }) async {
    final store = await freshStore();
    await store.saveStats(
      PlayerStats(completedGames: completedBefore, adFree: adFree),
    );
    final ads = CountingAds();
    final services = await testServices(
      store: store,
      ads: ads,
      review: ReviewPrompt(store, review: FakeReview()),
    );
    final controller = GameController(store: store)
      ..startNew(Difficulty.easy, seed: 7);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: GameScreen(controller: controller, services: services),
      ),
    );
    await tester.pumpAndSettle();
    return (ads, controller);
  }

  testWidgets(
    'the second completed game shows an interstitial after the dialog',
    (tester) async {
      final (ads, controller) = await game(tester, completedBefore: 1);
      await finishGame(tester, controller);
      expect(find.text('Puzzle solved!'), findsOneWidget);
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      expect(ads.interstitials, 1);
    },
  );

  testWidgets('the third completed game asks for a review instead', (
    tester,
  ) async {
    final (ads, controller) = await game(tester, completedBefore: 2);
    await finishGame(tester, controller);
    await tester.tap(find.text('Play again'));
    await tester.pumpAndSettle();
    expect(find.text('Enjoying Mini Sudoku?'), findsOneWidget);
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    expect(ads.interstitials, 0);
    expect(
      controller.session!.isCompleted,
      isFalse,
      reason: 'play again started a new game',
    );
    await controller.pause();
  });

  testWidgets('no interstitial after the purchase', (tester) async {
    final (ads, controller) = await game(
      tester,
      completedBefore: 1,
      adFree: true,
    );
    await finishGame(tester, controller);
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(ads.interstitials, 0);
  });
}
