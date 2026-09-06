import 'package:flutter/material.dart';

import 'core/storage/local_store.dart';
import 'core/theme.dart';
import 'features/home/home_screen.dart';
import 'features/settings/settings_controller.dart';
import 'l10n/app_localizations.dart';

class MiniSudokuApp extends StatelessWidget {
  const MiniSudokuApp({super.key, required this.store, required this.settings});

  final LocalStore store;
  final SettingsController settings;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: settings,
    builder: (context, _) => MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      theme: buildTheme(),
      locale: settings.locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: HomeScreen(store: store, settings: settings),
    ),
  );
}
