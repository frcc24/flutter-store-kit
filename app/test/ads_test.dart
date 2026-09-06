import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_sudoku/core/ads/ads_config.dart';
import 'package:mini_sudoku/core/ads/ads_consent_dialog.dart';
import 'package:mini_sudoku/core/ads/ads_service.dart';
import 'package:mini_sudoku/l10n/app_localizations.dart';

import 'support/test_services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'an unconfigured AdsService never initializes and never shows',
    () async {
      final ads = AdsService(config: const AdsConfig());
      await ads.init(consent: true);
      expect(ads.isInitialized, isFalse);
      expect(ads.isRewardedReady, isFalse);
      expect(
        await ads.showRewarded(serverId: 'u1'),
        RewardedOutcome.unavailable,
      );
      await ads.showInterstitial();
    },
  );

  test('config picks the platform placement', () {
    const config = AdsConfig(androidGameId: '1', iosGameId: '2');
    expect(config.isConfigured, isTrue);
    expect(config.rewardedPlacement, anyOf('Rewarded_Android', 'Rewarded_iOS'));
    expect(const AdsConfig().isConfigured, isFalse);
  });

  test('consent persists', () async {
    final store = await freshStore();
    expect(store.loadAdsConsent(), isNull);
    await store.saveAdsConsent(false);
    expect(store.loadAdsConsent(), isFalse);
  });

  testWidgets('the consent dialog returns the choice', (tester) async {
    bool? choice;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => choice = await showAdsConsentDialog(context),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Ads in Mini Sudoku'), findsOneWidget);
    await tester.tap(find.text('Personalized ads'));
    await tester.pumpAndSettle();
    expect(choice, isTrue);
  });
}
