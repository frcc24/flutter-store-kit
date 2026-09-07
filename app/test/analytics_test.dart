import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:mini_sudoku/core/analytics/app_analytics.dart';
import 'package:mini_sudoku/core/iap/products.dart';
import 'package:mini_sudoku/features/shop/purchase_deliveries.dart';
import 'package:mini_sudoku/features/sudoku/engine.dart';
import 'package:mini_sudoku/features/sudoku/game_controller.dart';
import 'package:mini_sudoku/features/sudoku/game_screen.dart';
import 'package:mini_sudoku/l10n/app_localizations.dart';

import 'support/test_services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final events = <(String, Map<String, Object>)>[];
  // Records compare maps by identity; the matcher compares them by content.
  Map<String, Object>? paramsOf(String name) =>
      events.where((event) => event.$1 == name).map((e) => e.$2).firstOrNull;

  setUp(() {
    events.clear();
    AppAnalytics.observer = (name, params) => events.add((name, params));
  });
  tearDown(() => AppAnalytics.observer = null);

  test('every event reaches the observer, with or without Firebase', () async {
    await AppAnalytics.logGameStarted(difficulty: 'easy');
    await AppAnalytics.logHintUsed(source: 'free');
    await AppAnalytics.logAdRewarded();
    await AppAnalytics.logPurchaseDelivered(productId: removeAdsId);
    await AppAnalytics.logGameCompleted(
      difficulty: 'easy',
      elapsedMs: 1000,
      mistakes: 0,
      hintsUsed: 1,
    );
    expect(events.map((event) => event.$1).toList(), [
      'game_started',
      'hint_used',
      'ad_rewarded',
      'purchase_delivered',
      'game_completed',
    ]);
    expect(events[1].$2, {'source': 'free'});
    expect(events[3].$2, {'product_id': removeAdsId});
    expect(events[4].$2['hints_used'], 1);
  });

  testWidgets('the game screen logs the free hint', (tester) async {
    final store = await freshStore();
    final services = await testServices(store: store);
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
    await tester.tap(find.text('Hint'));
    await tester.pumpAndSettle();
    expect(paramsOf('hint_used'), {'source': 'free'});
    await controller.pause();
  });

  test('a delivery logs the product', () async {
    final store = await freshStore();
    final deliveries = PurchaseDeliveries(
      store: store,
      api: null,
      finish: (_, {required consumable}) async {},
    );
    await deliveries.deliver(
      PurchaseDetails(
        purchaseID: 'p1',
        productID: removeAdsId,
        verificationData: PurchaseVerificationData(
          localVerificationData: 'l',
          serverVerificationData: 's',
          source: 'test',
        ),
        transactionDate: '0',
        status: PurchaseStatus.purchased,
      ),
    );
    expect(paramsOf('purchase_delivered'), {'product_id': removeAdsId});
  });
}
