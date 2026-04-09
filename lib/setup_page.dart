import 'dart:convert';
import 'package:flutter/material.dart';
import 'app_config.dart';
import 'event_service.dart';
import 'qr_scanner_page.dart';
import 'l10n/app_localizations.dart';
import 'main.dart';

class SetupPage extends StatefulWidget {
  final AppConfig appConfig;
  const SetupPage({super.key, required this.appConfig});

  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  final _teamNameController = TextEditingController();
  final _eventController = TextEditingController();
  final _apiUrlController = TextEditingController(
    text: 'https://your-project.vercel.app/api',
  );

  DateTime? _teamAccessStartDate;
  DateTime? _teamAccessEndDate;
  String? _selectedTimezone;
  bool _isSaving = false;
  bool _showConfigurationReview = false;

  @override
  void dispose() {
    _teamNameController.dispose();
    _eventController.dispose();
    _apiUrlController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Not selected';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _scanQRCode() async {
    try {
      final result = await Navigator.push<String>(
        context,
        MaterialPageRoute(builder: (context) => const QRScannerPage()),
      );
      if (result != null && mounted) {
        await _parseQRData(result);
      }
    } catch (e) {
      if (mounted) {
        final loc = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.errorScanningQR),
            backgroundColor: Color.fromRGBO(188, 33, 52, 1.0),
          ),
        );
      }
    }
  }

  Future<void> _parseQRData(String qrData) async {
    try {
      final data = jsonDecode(qrData) as Map<String, dynamic>;

      final hasRequiredFields =
          data['teamName'] != null &&
          data['event'] != null &&
          data['apiUrl'] != null;

      if (!hasRequiredFields) {
        final loc = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.invalidQRFormat),
            backgroundColor: Color.fromRGBO(188, 33, 52, 1.0),
          ),
        );
        return;
      }

      final teamName = data['teamName'] as String;
      final eventName = data['event'] as String;
      final apiUrl = data['apiUrl'] as String;

      final setupConfig = await EventService.queryTeamSetupConfig(
        apiUrl: apiUrl,
        eventName: eventName,
        teamName: teamName,
      );

      if (!mounted) return;

      if (setupConfig == null) {
        final loc = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.errorSavingConfig),
            backgroundColor: Color.fromRGBO(188, 33, 52, 1.0),
          ),
        );
        return;
      }

      DateTime? teamAccessStartDate;
      final teamAccessStartRaw = setupConfig['timeframe_start'];
      if (teamAccessStartRaw is String && teamAccessStartRaw.isNotEmpty) {
        try {
          teamAccessStartDate = DateTime.parse(teamAccessStartRaw);
        } catch (_) {}
      }

      DateTime? teamAccessEndDate;
      final teamAccessEndRaw = setupConfig['timeframe_end'];
      if (teamAccessEndRaw is String && teamAccessEndRaw.isNotEmpty) {
        try {
          teamAccessEndDate = DateTime.parse(teamAccessEndRaw);
        } catch (_) {}
      }

      if (teamAccessEndDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Team access window not configured by organizer'),
            backgroundColor: Color.fromRGBO(188, 33, 52, 1.0),
          ),
        );
        return;
      }

      final apiTimezone =
          (setupConfig['timezone'] as String?)?.trim().isNotEmpty == true
          ? setupConfig['timezone'] as String
          : 'UTC';

      setState(() {
        _teamNameController.text = data['teamName'] ?? '';
        _eventController.text = data['event'] ?? '';
        _apiUrlController.text = data['apiUrl'] ?? '';
        _selectedTimezone = apiTimezone;
        _teamAccessStartDate = teamAccessStartDate;
        _teamAccessEndDate = teamAccessEndDate;
        _showConfigurationReview = true;
      });

      final loc = AppLocalizations.of(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${loc.qrLoadedReview} ($apiTimezone)',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Color.fromRGBO(7, 84, 16, 0.8),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      final loc = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.invalidQRFormat),
          backgroundColor: Color.fromRGBO(188, 33, 52, 1.0),
        ),
      );
    }
  }

  Future<void> _resetConfiguration() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Configuration'),
        content: const Text(
          'Are you sure you want to reset the configuration? You will need to scan the QR code again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      await widget.appConfig.clearConfig();
      setState(() {
        _teamNameController.clear();
        _eventController.clear();
        _apiUrlController.text = 'https://your-project.vercel.app/api';
        _selectedTimezone = null;
        _teamAccessStartDate = null;
        _teamAccessEndDate = null;
        _showConfigurationReview = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configuration reset'),
            backgroundColor: Color.fromRGBO(7, 84, 16, 0.8),
          ),
        );
      }
    }
  }

  Future<void> _saveConfiguration() async {
    final loc = AppLocalizations.of(context);
    setState(() => _isSaving = true);

    try {
      String? imageData;
      String? imageMimeType;
      final eventName = _eventController.text.trim();
      final apiUrl = _apiUrlController.text.trim();

      print('🔍 Fetching event data from GraphQL API...');
      final eventInfo = await EventService.queryEventByName(
        apiUrl: apiUrl,
        eventName: eventName,
      );

      if (eventInfo != null) {
        imageData = eventInfo['image_data'] as String?;
        imageMimeType = eventInfo['image_mime_type'] as String?;
      }

      await widget.appConfig.saveConfig(
        teamName: _teamNameController.text.trim(),
        event: eventName,
        apiUrl: apiUrl,
        imageData: imageData,
        imageMimeType: imageMimeType,
        timezone: _selectedTimezone!,
        timeframeStartDate: _teamAccessStartDate,
        timeframeEndDate: _teamAccessEndDate,
      );

      print('✅ Configuration saved');

      await EventService.setTeamActivated(
        apiUrl: apiUrl,
        eventName: eventName,
        teamName: _teamNameController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              loc.configSavedSuccess,
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Color.fromRGBO(7, 84, 16, 0.8),
          ),
        );

        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      }
    } catch (e) {
      print('❌ Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.errorSavingConfig),
            backgroundColor: Color.fromRGBO(188, 33, 52, 1.0),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _changeLanguage(String languageCode) async {
    await widget.appConfig.setLanguage(languageCode);
    if (mounted) {
      final appState = MyApp.of(context);
      if (appState != null) {
        final newLocale = languageCode == 'fi'
            ? const Locale('fi', 'FI')
            : const Locale('en', 'GB');
        appState.setLocale(newLocale);
      }
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final currentLanguage = widget.appConfig.languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.initialSetup),
        automaticallyImplyLeading: false,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.language),
            onSelected: _changeLanguage,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'en',
                child: Row(
                  children: [
                    if (currentLanguage == 'en')
                      const Icon(Icons.check, size: 20),
                    if (currentLanguage == 'en') const SizedBox(width: 8),
                    const Text('English (UK)'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'fi',
                child: Row(
                  children: [
                    if (currentLanguage == 'fi')
                      const Icon(Icons.check, size: 20),
                    if (currentLanguage == 'fi') const SizedBox(width: 8),
                    const Text('Suomi'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: _showConfigurationReview
            ? _buildConfigurationReviewView()
            : _buildQRScanView(),
      ),
    );
  }

  Widget _buildQRScanView() {
    final loc = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 120,
              width: 140,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    right: 5,
                    child: Image.asset(
                      'assets/redfox_dev_app.png',
                      width: 100,
                      height: 100,
                      fit: BoxFit.contain,
                    ),
                  ),
                  Positioned(
                    left: 5,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        'assets/icon.png',
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              loc.welcome,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              loc.scanQRPrompt,
              style: TextStyle(
                fontSize: 18,
                color: Theme.of(context).colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            ElevatedButton.icon(
              onPressed: _scanQRCode,
              icon: const Icon(Icons.qr_code_scanner, size: 32),
              label: Text(loc.scanQRCode, style: const TextStyle(fontSize: 20)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 20,
                ),
                backgroundColor: Color.fromRGBO(7, 84, 16, 0.8),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigurationReviewView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Configuration Review',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Team', _teamNameController.text),
                const SizedBox(height: 16),
                _buildInfoRow('Event', _eventController.text),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (_teamAccessStartDate != null || _teamAccessEndDate != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color.fromRGBO(7, 84, 16, 0.05),
                border: Border.all(
                  color: Color.fromRGBO(7, 84, 16, 0.2),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Team Access Window',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color.fromRGBO(7, 84, 16, 1.0),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Start',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDate(_teamAccessStartDate),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'End',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDate(_teamAccessEndDate),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: _isSaving ? null : _saveConfiguration,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Color.fromRGBO(7, 84, 16, 0.8),
              foregroundColor: Colors.white,
            ),
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Save & Continue', style: TextStyle(fontSize: 18)),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _resetConfiguration,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
            ),
            child: const Text('Reset', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
