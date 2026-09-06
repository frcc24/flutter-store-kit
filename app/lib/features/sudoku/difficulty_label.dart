import '../../l10n/app_localizations.dart';
import 'engine.dart';

String difficultyLabel(AppLocalizations l10n, Difficulty difficulty) =>
    switch (difficulty) {
      Difficulty.easy => l10n.easy,
      Difficulty.medium => l10n.medium,
      Difficulty.hard => l10n.hard,
    };
