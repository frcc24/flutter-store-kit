import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mini_sudoku/core/ads/ads_config.dart';
import 'package:mini_sudoku/core/ads/ads_service.dart';
import 'package:mini_sudoku/core/api/kit_api.dart';
import 'package:mini_sudoku/core/auth/anonymous_session.dart';
import 'package:mini_sudoku/features/hints/hint_offer_sheet.dart';
import 'package:mini_sudoku/features/sudoku/engine.dart';
import 'package:mini_sudoku/features/sudoku/game_controller.dart';
import 'package:mini_sudoku/l10n/app_localizations.dart';
import 'package:mini_sudoku/services.dart';

import 'support/test_services.dart';

class FakeAds extends AdsService {
  FakeAds({this.outcome = RewardedOutcome.finished})
    : super(config: const AdsConfig(androidGameId: 'x'));
  RewardedOutcome outcome;
  int shown = 0;
  @override
  bool get isInitialized => true;
  @override
  bool get isRewardedReady => true;
  @override
  Future<RewardedOutcome> showRewarded({required String serverId}) async {
    shown++;
    return outcome;
  }
}

class FakeSession extends AnonymousSession {
  @override
  Future<String?> uid() async => 'u1';
  @override
  Future<String?> idToken({bool forceRefresh = false}) async => 'tok';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<(Services, GameController)> setup({
    required List<int> walletAnswers,
    FakeAds? ads,
  }) async {
    final store = await freshStore();
    final api = KitApi(
      baseUrl: Uri.parse('https://api.test'),
      tokenProvider: () async => 'tok',
      client: MockClient((request) async {
        final hints = walletAnswers.isEmpty ? 0 : walletAnswers.removeAt(0);
        return http.Response(
          jsonEncode({'hints': hints}),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    final services = await testServices(
      store: store,
      api: api,
      session: FakeSession(),
      ads: ads ?? FakeAds(),
    );
    final controller = GameController(store: store, remoteSpend: api.spendHint)
      ..startNew(Difficulty.easy, seed: 3);
    addTearDown(controller.dispose);
    return (services, controller);
  }

  Widget host(
    Services services,
    GameController controller,
    void Function(bool) onResult,
  ) => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Builder(
      builder: (context) => TextButton(
        onPressed: () async => onResult(
          await showHintOffer(
            context,
            services: services,
            controller: controller,
          ),
        ),
        child: const Text('open'),
      ),
    ),
  );

  testWidgets('watching the ad credits the wallet the server reports', (
    tester,
  ) async {
    final (services, controller) = await setup(walletAnswers: [0, 1]);
    bool? result;
    await tester.pumpWidget(host(services, controller, (r) => result = r));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Watch an ad · +1 hint'), findsOneWidget);
    await tester.tap(find.text('Watch an ad · +1 hint'));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 900));
    }
    await tester.pumpAndSettle();
    expect(result, isTrue);
    expect(controller.hintBalance, 1);
  });

  testWidgets('a skipped ad pays nothing', (tester) async {
    final (services, controller) = await setup(
      walletAnswers: [0, 0, 0, 0],
      ads: FakeAds(outcome: RewardedOutcome.skipped),
    );
    bool? result;
    await tester.pumpWidget(host(services, controller, (r) => result = r));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Watch an ad · +1 hint'));
    await tester.pumpAndSettle();
    expect(result, isFalse);
    expect(controller.hintBalance, 0);
  });

  testWidgets('without a server the sheet only explains', (tester) async {
    final store = await freshStore();
    final services = await testServices(store: store, ads: FakeAds());
    final controller = GameController(store: store)
      ..startNew(Difficulty.easy, seed: 3);
    addTearDown(controller.dispose);
    bool? result;
    await tester.pumpWidget(host(services, controller, (r) => result = r));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Watch an ad · +1 hint'), findsNothing);
    expect(find.textContaining('not available'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(result, isFalse);
  });
}
