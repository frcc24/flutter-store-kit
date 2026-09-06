import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_sudoku/core/remote/force_update_gate.dart';
import 'package:mini_sudoku/core/remote/remote_flags.dart';
import 'package:mini_sudoku/l10n/app_localizations.dart';

void main() {
  test('requiresUpdate compares build numbers', () {
    const flags = RemoteFlags(minSupportedBuild: 5);
    expect(flags.requiresUpdate(4), isTrue);
    expect(flags.requiresUpdate(5), isFalse);
    expect(const RemoteFlags().requiresUpdate(1), isFalse);
  });

  test('fetch without Firebase returns the defaults', () async {
    final flags = await RemoteFlags.fetch();
    expect(flags.adsEnabled, isTrue);
    expect(flags.iapEnabled, isTrue);
    expect(flags.minSupportedBuild, 0);
  });

  Widget gate(RemoteFlags flags, int build) => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: ForceUpdateGate(
      flags: flags,
      currentBuild: build,
      packageName: 'br.com.frcc24.mini_sudoku',
      child: const Text('game'),
    ),
  );

  testWidgets('the gate blocks an old build and lets a current one through', (
    tester,
  ) async {
    await tester.pumpWidget(gate(const RemoteFlags(minSupportedBuild: 9), 3));
    await tester.pumpAndSettle();
    expect(find.text('Update required'), findsOneWidget);
    expect(find.text('game'), findsNothing);

    await tester.pumpWidget(gate(const RemoteFlags(minSupportedBuild: 9), 9));
    await tester.pumpAndSettle();
    expect(find.text('game'), findsOneWidget);
  });
}
