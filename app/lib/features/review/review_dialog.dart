import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'review_prompt.dart';

Future<void> showReviewDialog(BuildContext context, ReviewPrompt prompt) async {
  final l10n = AppLocalizations.of(context);
  final accepted = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: Text(l10n.reviewTitle),
      content: Text(l10n.reviewBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.reviewLater),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(l10n.reviewNow),
        ),
      ],
    ),
  );
  if (accepted == true) {
    await prompt.accept();
  } else {
    await prompt.decline();
  }
}
