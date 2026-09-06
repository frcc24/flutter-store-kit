import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_sudoku/core/auth/anonymous_session.dart';
import 'package:mini_sudoku/features/privacy/privacy_policy_screen.dart';
import 'package:mini_sudoku/l10n/app_localizations.dart';

import 'support/test_services.dart';

class FakeSession extends AnonymousSession {
  @override
  Future<String?> uid() async => 'abc123';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows the policy sections, the account id and the link button', (
    tester,
  ) async {
    final services = await testServices(session: FakeSession());
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PrivacyPolicyScreen(services: services),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('only on your device'), findsOneWidget);
    expect(find.textContaining('Crashlytics'), findsOneWidget);
    expect(find.textContaining('Unity Ads'), findsOneWidget);
    expect(find.textContaining('Google Play'), findsOneWidget);
    expect(find.textContaining('anonymous account'), findsOneWidget);
    // The list is lazy and taller than the test viewport: scroll to the end.
    await tester.scrollUntilVisible(
      find.text('Open full policy'),
      200,
      // The SelectableText has a Scrollable of its own; the list comes first.
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Account id: abc123'), findsOneWidget);
    expect(find.text('Open full policy'), findsOneWidget);
    expect(privacyPolicyUrl.host, 'github.com');
  });

  testWidgets('without a session no account id is shown', (tester) async {
    final services = await testServices();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PrivacyPolicyScreen(services: services),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Account id'), findsNothing);
  });
}
