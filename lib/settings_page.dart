import 'package:flutter/material.dart';
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

  Widget _buildTimeFrameCard(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final start = widget.appConfig.timeframeStartDate;
    final end = widget.appConfig.timeframeEndDate;

    final isFinnish = Localizations.localeOf(context).languageCode == 'fi';
    final timeframeLabel = isFinnish ? 'Aikarajat' : 'Time frame';
    final startLabel = isFinnish ? 'Alku' : 'Start';
    final endLabel = isFinnish ? 'Loppu' : 'End';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.schedule,
                  color: Color.fromRGBO(0, 67, 89, 1.0),
                ),
                const SizedBox(width: 16),
                Text(
                  timeframeLabel,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color.fromRGBO(0, 67, 89, 1.0),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        startLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        start != null ? _formatDate(start) : loc.notSet,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 2),
                      _buildTimeWithTimezone(
                        context,
                        start,
                        widget.appConfig.timezone,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        endLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        end != null ? _formatDate(end) : loc.notSet,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 2),
                      _buildTimeWithTimezone(
                        context,
                        end,
                        widget.appConfig.timezone,
                      ),
                    ],
                  ),
                ),
              ],
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

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildTimeWithTimezone(
    BuildContext context,
    DateTime? value,
    String timezone,
  ) {
    final loc = AppLocalizations.of(context);

    if (value == null) {
      return Text(
        loc.notSet,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: Theme.of(context).colorScheme.outline,
        ),
      );
    }

    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: Theme.of(context).colorScheme.outline,
        ),
        children: [
          TextSpan(text: _formatTime(value)),
          WidgetSpan(
            alignment: PlaceholderAlignment.top,
            child: Transform.translate(
              offset: const Offset(0, -5),
              child: Text(
                ' $timezone',
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionDivider() {
    return const Column(
      children: [SizedBox(height: 4), Divider(), SizedBox(height: 4)],
    );
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

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isFinnish = Localizations.localeOf(context).languageCode == 'fi';
    final teamLabel = isFinnish ? 'Ryhmän nimi' : loc.teamName;

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
            label: teamLabel,
            value: widget.appConfig.teamName ?? loc.notSet,
          ),
          _buildConfigItem(
            icon: Icons.event,
            label: loc.event,
            value: widget.appConfig.event ?? loc.notSet,
          ),
          _buildSectionDivider(),
          _buildTimeFrameCard(context),
          _buildSectionDivider(),
          _buildLanguageCard(context),
          _buildSectionDivider(),
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
