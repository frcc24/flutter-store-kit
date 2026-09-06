import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_sudoku/features/privacy/privacy_policy_screen.dart';
import 'package:mini_sudoku/l10n/app_localizations.dart';

void main() {
  testWidgets('shows the policy sections and the link button', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const PrivacyPolicyScreen(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('only on your device'), findsOneWidget);
    expect(find.textContaining('Crashlytics'), findsOneWidget);
    expect(find.text('Open full policy'), findsOneWidget);
    expect(privacyPolicyUrl.host, 'github.com');
  });
}
