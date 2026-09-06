import 'package:flutter/material.dart';

import 'core/theme.dart';
import 'features/home/home_screen.dart';
import 'l10n/app_localizations.dart';
import 'services.dart';

class MiniSudokuApp extends StatelessWidget {
  const MiniSudokuApp({super.key, required this.services});

  final Services services;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: services.settings,
    builder: (context, _) => MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      theme: buildTheme(),
      locale: services.settings.locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: HomeScreen(services: services),
    ),
  );
}
