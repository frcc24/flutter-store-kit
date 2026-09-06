import 'package:flutter/material.dart';

import '../../core/ads/ads_consent_dialog.dart';
import '../../core/iap/products.dart';
import '../../l10n/app_localizations.dart';
import '../../services.dart';
import '../privacy/privacy_policy_screen.dart';
import '../rules/rules_screen.dart';
import '../settings/settings_screen.dart';
import '../stats/stats_screen.dart';
import '../sudoku/difficulty_label.dart';
import '../sudoku/engine.dart';
import '../sudoku/game_controller.dart';
import '../sudoku/game_screen.dart';
import '../sudoku/game_session.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.services});

  final Services services;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  GameSession? _saved;

  @override
  void initState() {
    super.initState();
    _saved = widget.services.store.loadSession();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootServices());
  }

  /// The shop first (it only queries), then ads: consent dialog, SDK second.
  /// Consent is asked once; the answer lives in the store and can be changed
  /// in Settings.
  Future<void> _bootServices() async {
    final services = widget.services;
    await services.iap.init(kitProductIds);
    if (!mounted || !services.ads.config.isConfigured) return;
    var consent = services.store.loadAdsConsent();
    if (consent == null) {
      consent = await showAdsConsentDialog(context) ?? false;
      await services.store.saveAdsConsent(consent);
    }
    await services.ads.init(consent: consent);
  }

  /// Pushes the game and owns the controller's lifetime.
  Future<void> _open(GameController controller) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            GameScreen(controller: controller, services: widget.services),
      ),
    );
    controller.dispose();
    if (!mounted) return;
    setState(() => _saved = widget.services.store.loadSession());
  }

  Future<void> _continue() async {
    final controller = widget.services.newGameController();
    if (!controller.resume()) {
      controller.dispose();
      setState(() => _saved = null);
      return;
    }
    await _open(controller);
  }

  Future<void> _newGame() async {
    final l10n = AppLocalizations.of(context);
    final difficulty = await showDialog<Difficulty>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(l10n.chooseDifficulty),
        children: [
          for (final d in Difficulty.values)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, d),
              child: Text(difficultyLabel(l10n, d)),
            ),
        ],
      ),
    );
    if (difficulty == null || !mounted) return;
    await _open(widget.services.newGameController()..startNew(difficulty));
  }

  void _push(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: ListView(
              padding: const EdgeInsets.all(24),
              shrinkWrap: true,
              children: [
                Text(
                  l10n.appTitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 32),
                if (_saved != null) ...[
                  FilledButton(
                    onPressed: _continue,
                    child: Text(l10n.continueGame),
                  ),
                  const SizedBox(height: 12),
                ],
                FilledButton.tonal(
                  onPressed: _newGame,
                  child: Text(l10n.newGame),
                ),
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: () =>
                      _push(StatsScreen(store: widget.services.store)),
                  child: Text(l10n.stats),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => _push(const RulesScreen()),
                  child: Text(l10n.rules),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () =>
                      _push(SettingsScreen(services: widget.services)),
                  child: Text(l10n.settings),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => _push(const PrivacyPolicyScreen()),
                  child: Text(l10n.privacyPolicy),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
