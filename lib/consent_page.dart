import 'package:flutter/material.dart';

import 'app_config.dart';
import 'l10n/app_localizations.dart';
import 'main.dart';

class ConsentPage extends StatefulWidget {
  final AppConfig appConfig;

  const ConsentPage({super.key, required this.appConfig});

  @override
  State<ConsentPage> createState() => _ConsentPageState();
}

class _ConsentPageState extends State<ConsentPage> {
  bool _acceptedNotifications = false;
  bool _acceptedPreciseLocation = false;
  bool _isSaving = false;

  bool get _canContinue =>
      _acceptedNotifications && _acceptedPreciseLocation && !_isSaving;

  Future<void> _acceptAndContinue() async {
    if (!_canContinue) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await widget.appConfig.acceptDisclosure();
      if (!mounted) {
        return;
      }

      final nextRoute = widget.appConfig.isSetupComplete
          ? '/home'
          : '/permissions';
      Navigator.of(context).pushReplacementNamed(nextRoute);
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _changeLanguage(String languageCode) async {
    await widget.appConfig.setLanguage(languageCode);
    if (!mounted) {
      return;
    }

    final appState = MyApp.of(context);
    if (appState != null) {
      final newLocale = languageCode == 'fi'
          ? const Locale('fi', 'FI')
          : const Locale('en', 'GB');
      appState.setLocale(newLocale);
    }

    setState(() {});
  }

  Widget _buildConsentCard({
    required IconData icon,
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: CheckboxListTile(
        value: value,
        onChanged: onChanged,
        secondary: Icon(icon, color: const Color.fromRGBO(7, 84, 16, 1.0)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(description),
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final title = loc.disclosureTitle;
    final body = loc.disclosureBody;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        automaticallyImplyLeading: false,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.language),
            tooltip: loc.selectLanguage,
            initialValue: widget.appConfig.languageCode,
            onSelected: _changeLanguage,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'en',
                child: Row(
                  children: [
                    if (widget.appConfig.languageCode == 'en')
                      const Icon(Icons.check, size: 20),
                    if (widget.appConfig.languageCode == 'en')
                      const SizedBox(width: 8),
                    const Text('English (UK)'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'fi',
                child: Row(
                  children: [
                    if (widget.appConfig.languageCode == 'fi')
                      const Icon(Icons.check, size: 20),
                    if (widget.appConfig.languageCode == 'fi')
                      const SizedBox(width: 8),
                    const Text('Suomi'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color.fromRGBO(7, 84, 16, 0.95),
                          Color.fromRGBO(0, 67, 89, 0.95),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.privacy_tip_outlined,
                          color: Colors.white,
                          size: 40,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          body,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildConsentCard(
                    icon: Icons.notifications_active_outlined,
                    title: loc.disclosureNotificationsTitle,
                    description: loc.disclosureNotificationsDescription,
                    value: _acceptedNotifications,
                    onChanged: (value) {
                      setState(() {
                        _acceptedNotifications = value ?? false;
                      });
                    },
                  ),
                  _buildConsentCard(
                    icon: Icons.my_location_outlined,
                    title: loc.disclosureLocationTitle,
                    description: loc.disclosureLocationDescription,
                    value: _acceptedPreciseLocation,
                    onChanged: (value) {
                      setState(() {
                        _acceptedPreciseLocation = value ?? false;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _canContinue ? _acceptAndContinue : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      backgroundColor: const Color.fromRGBO(7, 84, 16, 0.9),
                      foregroundColor: Colors.white,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            loc.disclosureContinue,
                            style: const TextStyle(fontSize: 18),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
