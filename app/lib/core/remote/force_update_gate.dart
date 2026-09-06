import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
import 'remote_flags.dart';

/// Blocks the app when the installed build is older than the one operations
/// still supports — the way to retire a client with a bug the server cannot
/// tolerate. Everything below the gate is untouched.
class ForceUpdateGate extends StatelessWidget {
  const ForceUpdateGate({
    super.key,
    required this.flags,
    required this.currentBuild,
    required this.packageName,
    required this.child,
  });

  final RemoteFlags flags;
  final int currentBuild;
  final String packageName;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!flags.requiresUpdate(currentBuild)) return child;
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.updateRequiredTitle,
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(l10n.updateRequiredBody, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => launchUrl(
                  Uri.parse(
                    'https://play.google.com/store/apps/details?id=$packageName',
                  ),
                  mode: LaunchMode.externalApplication,
                ),
                child: Text(l10n.updateNow),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
