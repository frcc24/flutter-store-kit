import 'package:flutter/material.dart';

import '../../core/analytics/app_analytics.dart';
import '../../core/time_format.dart';
import '../../l10n/app_localizations.dart';
import '../../services.dart';
import '../hints/hint_offer_sheet.dart';
import 'board_widget.dart';
import 'difficulty_label.dart';
import 'game_controller.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.controller,
    required this.services,
  });

  final GameController controller;
  final Services services;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  bool _completionShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.controller.addListener(_onChanged);
    widget.services.iap.addListener(_onPurchase);
    widget.controller.startTicker();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.controller.removeListener(_onChanged);
    widget.services.iap.removeListener(_onPurchase);
    widget.controller.pause();
    super.dispose();
  }

  /// A delivery wrote the wallet to the store; the controller re-reads it.
  void _onPurchase() => widget.controller.reloadStats();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        widget.controller.startTicker();
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        widget.controller.pause();
    }
  }

  void _onChanged() {
    final session = widget.controller.session;
    if (session == null || !session.isCompleted || _completionShown) return;
    _completionShown = true;
    AppAnalytics.logGameCompleted(
      difficulty: session.difficulty.name,
      elapsedMs: session.elapsedMs,
      mistakes: session.mistakes,
      hintsUsed: session.hintsUsed,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _showCompleted());
  }

  Future<void> _showCompleted() async {
    final controller = widget.controller;
    final session = controller.session!;
    final l10n = AppLocalizations.of(context);
    final playAgain = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.completedTitle),
        content: Text(
          l10n.completedBody(
            formatElapsed(session.elapsedMs),
            session.mistakes,
            session.hintsUsed,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.backHome),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.playAgain),
          ),
        ],
      ),
    );
    if (!mounted) return;
    await _afterGame();
    if (!mounted) return;
    if (playAgain == true) {
      _completionShown = false;
      controller.startNew(session.difficulty);
      controller.startTicker();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  /// Review card first, ad second, never both on the same game. An ad right
  /// before the card is the wrong mood, and the policy forbids asking the
  /// player anything of our own either way.
  Future<void> _afterGame() async {
    final services = widget.services;
    final stats = widget.controller.stats;
    if (services.review.willAsk(stats.completedGames)) {
      await services.review.maybeAsk(stats.completedGames);
      return;
    }
    if (!stats.adFree &&
        services.flags.adsEnabled &&
        stats.completedGames % 2 == 0) {
      await services.ads.showInterstitial();
    }
  }

  Future<void> _hint() async {
    final controller = widget.controller;
    final wasFree = controller.hasFreeHint;
    final result = await controller.useHint();
    if (!mounted) return;
    switch (result) {
      case HintResult.applied:
        AppAnalytics.logHintUsed(source: wasFree ? 'free' : 'paid');
      case HintResult.nothingToReveal:
        return;
      case HintResult.unavailable:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).hintsUnavailable),
          ),
        );
      case HintResult.noHintsLeft:
        final credited = await showHintOffer(
          context,
          services: widget.services,
          controller: controller,
        );
        if (credited && mounted) await controller.useHint();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = widget.controller;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final session = controller.session;
        if (session == null) return const Scaffold(body: SizedBox.shrink());
        final hintLabel = controller.hasFreeHint
            ? l10n.freeHint
            : l10n.hintsLeft(controller.hintBalance);
        return Scaffold(
          appBar: AppBar(
            title: Text(difficultyLabel(l10n, session.difficulty)),
            actions: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Text(
                    formatElapsed(session.elapsedMs),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l10n.mistakesCount(session.mistakes)),
                      Text(hintLabel),
                    ],
                  ),
                ),
                // The largest square that fits: full width on a phone in
                // portrait, height-bound in landscape and on tablets.
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: BoardWidget(
                        session: session,
                        selected: controller.selected,
                        conflicts: controller.conflicts,
                        onTap: controller.select,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      for (var n = 1; n <= 9; n++)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(2),
                            child: OutlinedButton(
                              key: Key('key-$n'),
                              onPressed: () => controller.input(n),
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 48),
                              ),
                              child: Text('$n'),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton.icon(
                      onPressed: controller.erase,
                      icon: const Icon(Icons.backspace_outlined),
                      label: Text(l10n.erase),
                    ),
                    const SizedBox(width: 16),
                    FilledButton.tonalIcon(
                      onPressed: _hint,
                      icon: const Icon(Icons.lightbulb_outline),
                      label: Text(l10n.hint),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
