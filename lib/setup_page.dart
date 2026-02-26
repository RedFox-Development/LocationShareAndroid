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
  final _formKey = GlobalKey<FormState>();
  final _teamNameController = TextEditingController();
  final _eventController = TextEditingController();
  final _apiUrlController = TextEditingController(
    text: 'https://your-project.vercel.app/api',
  );
  final _imageUrlController = TextEditingController();
  DateTime? _selectedExpirationDate;
  String? _selectedTimezone;
  bool _isSaving = false;
  bool _showManualEntry = false;

  // Common timezones list
  final List<String> _commonTimezones = [
    'UTC',
    'Europe/Helsinki',
    'Europe/London',
    'Europe/Paris',
    'Europe/Berlin',
    'Europe/Stockholm',
    'Europe/Oslo',
    'Europe/Copenhagen',
    'America/New_York',
    'America/Chicago',
    'America/Los_Angeles',
    'America/Toronto',
    'Asia/Tokyo',
    'Asia/Shanghai',
    'Asia/Dubai',
    'Australia/Sydney',
  ];

  @override
  void dispose() {
    _teamNameController.dispose();
    _eventController.dispose();
    _apiUrlController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _selectExpirationDate() async {
    final loc = AppLocalizations.of(context);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _selectedExpirationDate ??
          DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: loc.selectExpirationDate,
    );

    if (picked != null) {
      setState(() {
        _selectedExpirationDate = picked;
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      final loc = AppLocalizations.of(context);
      return loc.notSelected;
    }
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _scanQRCode() async {
    try {
      final result = await Navigator.push<String>(
        context,
        MaterialPageRoute(builder: (context) => const QRScannerPage()),
      );

      if (result != null && mounted) {
        _parseQRData(result);
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

  void _parseQRData(String qrData) {
    try {
      final data = jsonDecode(qrData) as Map<String, dynamic>;

      setState(() {
        if (data['teamName'] != null) {
          _teamNameController.text = data['teamName'];
        }
        if (data['event'] != null) {
          _eventController.text = data['event'];
        }
        if (data['apiUrl'] != null) {
          _apiUrlController.text = data['apiUrl'];
        }
        if (data['imageUrl'] != null) {
          _imageUrlController.text = data['imageUrl'];
        }
        if (data['expirationDate'] != null) {
          try {
            _selectedExpirationDate = DateTime.parse(data['expirationDate']);
          } catch (e) {
            // Invalid date format, ignore
          }
        }
        if (data['timezone'] != null) {
          _selectedTimezone = data['timezone'];
        }
        // Switch to manual entry view to show populated fields
        _showManualEntry = true;
      });

      final loc = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            loc.qrLoadedReview,
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Color.fromRGBO(7, 84, 16, 0.8),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      final loc = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.invalidQRFormat),
          backgroundColor: Color.fromRGBO(188, 33, 52, 1.0),
        ),
      );
    }
  }

  Future<void> _saveConfiguration() async {
    final loc = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedExpirationDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.pleaseSelectDate),
          backgroundColor: Color.fromRGBO(207, 131, 41, 1.0),
        ),
      );
      return;
    }

    if (_selectedTimezone == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.pleaseSelectTimezone),
          backgroundColor: Color.fromRGBO(207, 131, 41, 1.0),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Fetch event data from GraphQL API to get images
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

        if (imageData != null && imageMimeType != null) {
          print('✅ Event images fetched from API');
        } else {
          print('ℹ️ No images configured for this event');
        }
      } else {
        print(
          '⚠️ Could not fetch event data from API, continuing without images',
        );
      }

      await widget.appConfig.saveConfig(
        teamName: _teamNameController.text.trim(),
        event: eventName,
        apiUrl: apiUrl,
        imageData: imageData,
        imageMimeType: imageMimeType,
        expirationDate: _selectedExpirationDate!,
        timezone: _selectedTimezone!,
      );

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              loc.configSavedSuccess,
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Color.fromRGBO(7, 84, 16, 0.8),
          ),
        );

        // Navigate to home page after a short delay
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      }
    } catch (e) {
      print('❌ Error saving configuration: $e');
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
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _changeLanguage(String languageCode) async {
    await widget.appConfig.setLanguage(languageCode);

    if (mounted) {
      // Update the app's locale
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
        automaticallyImplyLeading: false, // Prevent back navigation
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.language),
            tooltip: loc.language,
            onSelected: _changeLanguage,
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
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
              PopupMenuItem<String>(
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
        child: _showManualEntry ? _buildManualEntryView() : _buildQRScanView(),
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
                  // Dev logo - positioned to the right (background)
                  Positioned(
                    right: 5,
                    child: Image.asset(
                      'assets/dev/redfox_dev_app.png',
                      width: 100,
                      height: 100,
                      fit: BoxFit.contain,
                    ),
                  ),
                  // App icon - positioned to the left (foreground, on top)
                  Positioned(
                    left: 5,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        'assets/dev/icon.png',
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
            Builder(
              builder: (context) => Text(
                loc.scanQRPrompt,
                style: TextStyle(
                  fontSize: 18,
                  color: Theme.of(context).colorScheme.outline,
                ),
                textAlign: TextAlign.center,
              ),
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
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _showManualEntry = true;
                });
              },
              icon: const Icon(Icons.edit),
              label: Text(loc.enterManually),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualEntryView() {
    final loc = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      _showManualEntry = false;
                    });
                  },
                  icon: const Icon(Icons.arrow_back),
                  tooltip: loc.backToQRScan,
                ),
                Expanded(
                  child: Text(
                    loc.manualConfiguration,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 48), // Balance the back button
              ],
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _teamNameController,
              decoration: InputDecoration(
                labelText: loc.teamName,
                hintText: loc.teamNameHint,
                prefixIcon: const Icon(Icons.group),
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return loc.fieldRequired(loc.teamName);
                }
                return null;
              },
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _eventController,
              decoration: InputDecoration(
                labelText: loc.event,
                hintText: loc.eventHint,
                prefixIcon: const Icon(Icons.event),
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return loc.fieldRequired(loc.event);
                }
                return null;
              },
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _apiUrlController,
              decoration: const InputDecoration(
                labelText: 'API URL',
                hintText: 'https://your-project.vercel.app/api',
                prefixIcon: Icon(Icons.cloud),
                border: OutlineInputBorder(),
                helperText: 'GraphQL API endpoint',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'API URL is required';
                }
                final uri = Uri.tryParse(value.trim());
                if (uri == null ||
                    !uri.hasScheme ||
                    !uri.scheme.startsWith('http')) {
                  return 'Enter a valid URL';
                }
                return null;
              },
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _imageUrlController,
              decoration: InputDecoration(
                labelText: loc.imageUrl,
                hintText: loc.imageUrlHint,
                prefixIcon: const Icon(Icons.image),
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                // Image URL is optional, but if provided, must be valid
                if (value != null && value.trim().isNotEmpty) {
                  final uri = Uri.tryParse(value.trim());
                  if (uri == null ||
                      !uri.hasScheme ||
                      (!uri.scheme.startsWith('http'))) {
                    return loc.enterValidUrl;
                  }
                }
                return null;
              },
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 20),
            InkWell(
              onTap: _selectExpirationDate,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: loc.expirationDate,
                  hintText: loc.expirationDateHint,
                  prefixIcon: const Icon(Icons.calendar_today),
                  border: const OutlineInputBorder(),
                ),
                child: Builder(
                  builder: (context) => Text(
                    _formatDate(_selectedExpirationDate),
                    style: TextStyle(
                      fontSize: 16,
                      color: _selectedExpirationDate == null
                          ? Theme.of(context).colorScheme.outline
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ),
            if (_selectedExpirationDate != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0, left: 12.0),
                child: Builder(
                  builder: (context) => Text(
                    loc.configWillReset,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _selectedTimezone,
              decoration: InputDecoration(
                labelText: loc.timezone,
                hintText: loc.selectTimezone,
                prefixIcon: const Icon(Icons.public),
                border: const OutlineInputBorder(),
              ),
              items: _commonTimezones.map((String timezone) {
                return DropdownMenuItem<String>(
                  value: timezone,
                  child: Text(timezone),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedTimezone = newValue;
                });
              },
              validator: (value) {
                if (value == null) {
                  return loc.timezoneRequired;
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
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
                  : Text(
                      loc.saveConfiguration,
                      style: const TextStyle(fontSize: 18),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
