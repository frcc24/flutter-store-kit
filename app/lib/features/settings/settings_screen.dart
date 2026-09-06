import 'package:flutter/material.dart';

import '../../core/iap/products.dart';
import '../../l10n/app_localizations.dart';
import '../../services.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.services});

  final Services services;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final services = widget.services;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListenableBuilder(
        // The shop notifies when a delivery marks the purchase as owned.
        listenable: Listenable.merge([services.settings, services.iap]),
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<String>(
              initialValue: services.settings.locale?.languageCode ?? 'system',
              decoration: InputDecoration(labelText: l10n.language),
              items: [
                DropdownMenuItem(
                  value: 'system',
                  child: Text(l10n.systemLanguage),
                ),
                const DropdownMenuItem(value: 'en', child: Text('English')),
                const DropdownMenuItem(value: 'pt', child: Text('Português')),
                const DropdownMenuItem(value: 'es', child: Text('Español')),
              ],
              onChanged: (code) =>
                  services.settings.setLocale(code == 'system' ? null : code),
            ),
            if (services.ads.config.isConfigured)
              SwitchListTile(
                title: Text(l10n.adsPersonalizedSetting),
                value: services.store.loadAdsConsent() ?? false,
                onChanged: (value) async {
                  await services.store.saveAdsConsent(value);
                  await services.ads.setConsent(value);
                  setState(() {});
                },
              ),
            if (services.iap.available) ...[
              const SizedBox(height: 24),
              Text(
                l10n.purchases,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (services.store.loadStats().adFree)
                ListTile(
                  leading: const Icon(Icons.check),
                  title: Text(l10n.adsRemoved),
                )
              else if (services.iap.products[removeAdsId] case final product?)
                ListTile(
                  leading: const Icon(Icons.block),
                  title: Text('${l10n.removeAds} · ${product.price}'),
                  onTap: () => services.iap.buyNonConsumable(removeAdsId),
                ),
              TextButton(
                onPressed: () async {
                  await services.iap.restore();
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(l10n.restoreDone)));
                  }
                },
                child: Text(l10n.restorePurchases),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
