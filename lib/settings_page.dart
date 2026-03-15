import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_config.dart';
import 'main.dart';
import 'l10n/app_localizations.dart';

class SettingsPage extends StatefulWidget {
  final AppConfig appConfig;

  const SettingsPage({super.key, required this.appConfig});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Future<void> _showResetConfirmationDialog(BuildContext context) async {
    final loc = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(loc.resetConfirmTitle),
          content: Text(loc.resetConfirmMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(loc.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Color.fromRGBO(188, 33, 52, 1.0),
              ),
              child: Text(loc.reset),
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      await _resetConfiguration(context);
    }
  }

  Future<void> _resetConfiguration(BuildContext context) async {
    final loc = AppLocalizations.of(context);
    try {
      await widget.appConfig.clearConfig();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.configResetSuccess),
            backgroundColor: Color.fromRGBO(207, 131, 41, 1.0),
          ),
        );

        // Navigate back to setup page
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/setup', (route) => false);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.errorResettingConfig),
            backgroundColor: Color.fromRGBO(188, 33, 52, 1.0),
          ),
        );
      }
    }
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Color.fromRGBO(37, 55, 100, 1.0), size: 20),
              const SizedBox(width: 8),
              Builder(
                builder: (context) => Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimezoneCard(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoItem(
              icon: Icons.calendar_today,
              label: loc.expirationDate,
              value: widget.appConfig.expirationDate != null
                  ? _formatDate(widget.appConfig.expirationDate!)
                  : loc.notSet,
            ),
            const SizedBox(width: 24),
            _buildInfoItem(
              icon: Icons.public,
              label: loc.timezone,
              value: widget.appConfig.timezone,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageCard(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final currentLanguage = widget.appConfig.languageCode;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Icon(Icons.language, color: Color.fromRGBO(0, 67, 89, 1.0)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Builder(
                    builder: (context) => Text(
                      loc.language,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ),
                  DropdownButton<String>(
                    value: currentLanguage,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(
                        value: 'en',
                        child: Text('English (UK)'),
                      ),
                      DropdownMenuItem(value: 'fi', child: Text('Suomi')),
                    ],
                    onChanged: (String? newLanguage) async {
                      if (newLanguage != null &&
                          newLanguage != currentLanguage) {
                        await widget.appConfig.setLanguage(newLanguage);

                        if (context.mounted) {
                          // Update the app's locale
                          final appState = MyApp.of(context);
                          if (appState != null) {
                            final newLocale = newLanguage == 'fi'
                                ? const Locale('fi', 'FI')
                                : const Locale('en', 'GB');
                            appState.setLocale(newLocale);
                          }

                          setState(() {});
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Widget _buildConfigItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, color: Color.fromRGBO(0, 67, 89, 1.0)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color.fromRGBO(0, 67, 89, 1.0),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            loc.currentConfiguration,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          _buildConfigItem(
            icon: Icons.group,
            label: loc.teamName,
            value: widget.appConfig.teamName ?? loc.notSet,
          ),
          _buildConfigItem(
            icon: Icons.event,
            label: loc.event,
            value: widget.appConfig.event ?? loc.notSet,
          ),
          _buildDateTimezoneCard(context),
          _buildLanguageCard(context),
          const SizedBox(height: 4),
          const Divider(),
          const SizedBox(height: 4),
          OutlinedButton.icon(
            onPressed: () => _showResetConfirmationDialog(context),
            icon: const Icon(Icons.refresh),
            label: Text(loc.resetConfiguration),
            style: OutlinedButton.styleFrom(
              foregroundColor: Color.fromRGBO(188, 33, 52, 1.0),
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: Color.fromRGBO(188, 33, 52, 1.0)),
            ),
          ),
          const SizedBox(height: 8),
          Builder(
            builder: (context) => Text(
              loc.resetWarning,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
