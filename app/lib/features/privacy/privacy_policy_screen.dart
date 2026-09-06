import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
import '../../services.dart';

/// The hosted copy of the policy. The Play Console requires a public URL;
/// a Markdown file in the public repository is the cheapest one that exists.
final privacyPolicyUrl = Uri.parse(
  'https://github.com/frcc24/flutter-store-kit/blob/main/docs/privacy-policy.md',
);

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key, required this.services});

  final Services services;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.privacyPolicy)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(l10n.privacyIntro),
          const SizedBox(height: 16),
          Text(l10n.privacyCrash),
          const SizedBox(height: 16),
          Text(l10n.privacyAds),
          const SizedBox(height: 16),
          Text(l10n.privacyPurchases),
          const SizedBox(height: 16),
          Text(l10n.privacyAccount),
          const SizedBox(height: 16),
          Text(l10n.privacyChildren),
          const SizedBox(height: 16),
          Text(l10n.privacyContact),
          const SizedBox(height: 16),
          // The anonymous id, so a deletion request by e-mail can name the
          // account. Nothing shows until the app has one.
          FutureBuilder<String?>(
            future: services.session.uid(),
            builder: (context, snapshot) => switch (snapshot.data) {
              null => const SizedBox.shrink(),
              final id => SelectableText(
                l10n.accountId(id),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            },
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => launchUrl(
              privacyPolicyUrl,
              mode: LaunchMode.externalApplication,
            ),
            child: Text(l10n.openFullPolicy),
          ),
        ],
      ),
    );
  }
}
