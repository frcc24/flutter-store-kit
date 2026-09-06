import 'package:flutter/material.dart';

import '../../core/storage/local_store.dart';
import '../../core/time_format.dart';
import '../../l10n/app_localizations.dart';
import '../sudoku/difficulty_label.dart';
import '../sudoku/engine.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key, required this.store});

  final LocalStore store;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final stats = store.loadStats();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.stats)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            title: Text(l10n.completedGames),
            trailing: Text('${stats.completedGames}'),
          ),
          for (final difficulty in Difficulty.values)
            ListTile(
              title: Text(
                '${l10n.bestTime} · ${difficultyLabel(l10n, difficulty)}',
              ),
              trailing: Text(switch (stats.bestTimeFor(difficulty)) {
                null => l10n.noBestTime,
                final ms => formatElapsed(ms),
              }),
            ),
        ],
      ),
    );
  }
}
