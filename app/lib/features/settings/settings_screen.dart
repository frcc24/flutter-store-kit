import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'settings_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.settings});

  final SettingsController settings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListenableBuilder(
        listenable: settings,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<String>(
              initialValue: settings.locale?.languageCode ?? 'system',
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
                  settings.setLocale(code == 'system' ? null : code),
            ),
          ],
        ),
      ),
    );
  }
}
