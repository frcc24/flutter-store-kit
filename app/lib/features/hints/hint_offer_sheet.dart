import 'package:flutter/material.dart';

import '../../core/ads/ads_service.dart';
import '../../l10n/app_localizations.dart';
import '../../services.dart';
import '../sudoku/game_controller.dart';

enum _Offer { ad }

/// Shown when the game has no hint left. Returns true when the wallet now
/// has a hint (the caller then calls useHint again). The reward is credited
/// by Unity's server-to-server callback, so after the video the wallet is
/// polled a few times rather than incremented here.
Future<bool> showHintOffer(
  BuildContext context, {
  required Services services,
  required GameController controller,
}) async {
  final l10n = AppLocalizations.of(context);
  final api = services.api;
  final canWatch = api != null && services.ads.isRewardedReady;
  final choice = await showModalBottomSheet<_Offer>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text(
              l10n.hintOfferTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          if (canWatch)
            ListTile(
              leading: const Icon(Icons.play_circle_outline),
              title: Text(l10n.watchAdForHint),
              onTap: () => Navigator.pop(context, _Offer.ad),
            )
          else
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(l10n.hintsUnavailable),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    ),
  );
  if (choice == null || !context.mounted) return false;
  return _watchAd(context, services, controller);
}

Future<bool> _watchAd(
  BuildContext context,
  Services services,
  GameController controller,
) async {
  final api = services.api;
  final uid = await services.session.uid();
  if (api == null || uid == null) return false;
  final outcome = await services.ads.showRewarded(serverId: uid);
  if (outcome != RewardedOutcome.finished) return false;
  for (var attempt = 0; attempt < 4; attempt++) {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    final hints = await api.wallet();
    if (hints != null && hints > 0) {
      controller.setHintBalance(hints);
      return true;
    }
  }
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).rewardPending)),
    );
  }
  return false;
}
