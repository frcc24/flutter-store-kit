import 'dart:io';

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

  test('asks at 3, then every 5, at most three times', () async {
    final store = await freshStore();
    final review = FakeReview();
    final prompt = ReviewPrompt(store, review: review);
    final asked = <int>[];
    for (var game = 1; game <= 25; game++) {
      final before = review.requested;
      await prompt.maybeAsk(game);
      if (review.requested > before) asked.add(game);
    }
    expect(asked, [3, 8, 13]);
  });

  test('the same completed count never asks twice', () async {
    final store = await freshStore();
    final review = FakeReview();
    final prompt = ReviewPrompt(store, review: review);
    await prompt.maybeAsk(3);
    await prompt.maybeAsk(3);
    expect(review.requested, 1);
  });

  test('willAsk answers without asking', () async {
    final store = await freshStore();
    final review = FakeReview();
    final prompt = ReviewPrompt(store, review: review);
    expect(prompt.willAsk(2), isFalse);
    expect(prompt.willAsk(3), isTrue);
    expect(review.requested, 0, reason: 'willAsk has no side effect');
  });

  test('the kit ships no dialog of its own for the review flow', () {
    // The Play in-app review policy forbids asking the user anything before or
    // while the rating card is shown, including "are you enjoying it?".
    // https://developer.android.com/guide/playcore/in-app-review
    expect(
      File('lib/features/review/review_dialog.dart').existsSync(),
      isFalse,
    );
  });

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

  Future<(CountingAds, FakeReview, GameController)> game(
    WidgetTester tester, {
    required int completedBefore,
    bool adFree = false,
  }) async {
    final store = await freshStore();
    await store.saveStats(
      PlayerStats(completedGames: completedBefore, adFree: adFree),
    );
    final ads = CountingAds();
    final review = FakeReview();
    final services = await testServices(
      store: store,
      ads: ads,
      review: ReviewPrompt(store, review: review),
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
    return (ads, review, controller);
  }

  testWidgets('the second completed game shows an interstitial', (
    tester,
  ) async {
    final (ads, review, controller) = await game(tester, completedBefore: 1);
    await finishGame(tester, controller);
    expect(find.text('Puzzle solved!'), findsOneWidget);
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(ads.interstitials, 1);
    expect(review.requested, 0);
  });

  testWidgets(
    'the third completed game asks for a review, with no question and no '
    'interstitial',
    (tester) async {
      final (ads, review, controller) = await game(tester, completedBefore: 2);
      await finishGame(tester, controller);
      await tester.tap(find.text('Play again'));
      await tester.pumpAndSettle();
      expect(review.requested, 1);
      expect(ads.interstitials, 0);
      expect(
        find.textContaining('Enjoying'),
        findsNothing,
        reason: 'the policy forbids a question before the card',
      );
      await controller.pause();
    },
  );

  testWidgets('no interstitial after the purchase', (tester) async {
    final (ads, _, controller) = await game(
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
