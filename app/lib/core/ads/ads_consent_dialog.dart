import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Asked once, before the SDK starts. True means personalized ads. There is
/// no "no ads" answer here — that is the purchase in Settings.
Future<bool?> showAdsConsentDialog(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: Text(l10n.adsConsentTitle),
      content: Text(l10n.adsConsentBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.adsNonPersonalized),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(l10n.adsPersonalized),
        ),
      ],
    ),
  );
}
