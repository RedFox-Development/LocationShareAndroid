import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import 'app_config.dart';
import 'l10n/app_localizations.dart';
import 'main.dart';

class PermissionsSetupPage extends StatefulWidget {
  final AppConfig appConfig;

  const PermissionsSetupPage({super.key, required this.appConfig});

  @override
  State<PermissionsSetupPage> createState() => _PermissionsSetupPageState();
}

class _PermissionsSetupPageState extends State<PermissionsSetupPage> {
  bool _isLoading = true;
  bool _isUpdating = false;
  bool _notificationsGranted = false;
  bool _locationServiceEnabled = false;
  PermissionStatus _locationWhenInUseStatus = PermissionStatus.denied;
  PermissionStatus _locationAlwaysStatus = PermissionStatus.denied;
  bool _batteryBackgroundActivityConfirmed = false;
  bool _pauseAppActivityConfirmed = false;
  bool _ignoreBatteryOptimizationsGranted = false;

  @override
  void initState() {
    super.initState();
    _refreshStatuses();
  }

  Future<void> _refreshStatuses() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    if (defaultTargetPlatform != TargetPlatform.android) {
      if (!mounted) {
        return;
      }

      setState(() {
        _notificationsGranted = false;
        _locationServiceEnabled = false;
        _locationWhenInUseStatus = PermissionStatus.denied;
        _locationAlwaysStatus = PermissionStatus.denied;
        _batteryBackgroundActivityConfirmed = false;
        _pauseAppActivityConfirmed = false;
        _ignoreBatteryOptimizationsGranted = false;
        _isLoading = false;
      });
      return;
    }

    final notificationsGranted = await _safeBoolQuery(
      () => Permission.notification.status.then((status) => status.isGranted),
    );
    final locationServiceEnabled = await _safeBoolQuery(
      Geolocator.isLocationServiceEnabled,
    );
    final locationWhenInUseStatus = await _safePermissionStatusQuery(
      () => Permission.locationWhenInUse.status,
    );
    final locationAlwaysStatus = await _safePermissionStatusQuery(
      () => Permission.locationAlways.status,
    );
    final batteryBackgroundActivityConfirmed =
        widget.appConfig.hasConfirmedBatteryBackgroundActivity;
    final pauseAppActivityConfirmed =
        widget.appConfig.hasConfirmedPauseAppActivity;
    final ignoreBatteryOptimizationsGranted = await _safeBoolQuery(
      () => FlutterForegroundTask.isIgnoringBatteryOptimizations,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _notificationsGranted = notificationsGranted;
      _locationServiceEnabled = locationServiceEnabled;
      _locationWhenInUseStatus = locationWhenInUseStatus;
      _locationAlwaysStatus = locationAlwaysStatus;
      _batteryBackgroundActivityConfirmed = batteryBackgroundActivityConfirmed;
      _pauseAppActivityConfirmed = pauseAppActivityConfirmed;
      _ignoreBatteryOptimizationsGranted = ignoreBatteryOptimizationsGranted;
      _isLoading = false;
    });
  }

  Future<bool> _safeBoolQuery(Future<bool> Function() query) async {
    try {
      return await query();
    } catch (_) {
      return false;
    }
  }

  Future<PermissionStatus> _safePermissionStatusQuery(
    Future<PermissionStatus> Function() query,
  ) async {
    try {
      return await query();
    } catch (_) {
      return PermissionStatus.denied;
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

  Future<void> _runPermissionAction(Future<void> Function() action) async {
    if (_isUpdating) {
      return;
    }

    setState(() {
      _isUpdating = true;
    });

    try {
      await action();
    } finally {
      if (mounted) {
        await _refreshStatuses();
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  Future<void> _requestNotifications() async {
    await _runPermissionAction(() async {
      await Permission.notification.request();
    });
  }

  Future<void> _requestLocationWhenInUse() async {
    await _runPermissionAction(() async {
      await Permission.locationWhenInUse.request();
    });
  }

  Future<void> _requestLocationAlways() async {
    await _runPermissionAction(() async {
      await Permission.locationWhenInUse.request();
      await Permission.locationAlways.request();
    });
  }

  Future<void> _requestBatteryOptimizationsIgnore() async {
    await _runPermissionAction(() async {
      await FlutterForegroundTask.requestIgnoreBatteryOptimization();
    });
  }

  Future<void> _openIgnoreBatteryOptimizationSettings() async {
    await _runPermissionAction(() async {
      await FlutterForegroundTask.openIgnoreBatteryOptimizationSettings();
    });
  }

  Future<void> _openAppSettings() async {
    await _runPermissionAction(() async {
      await openAppSettings();
    });
  }

  Future<void> _confirmBatteryBackgroundActivity() async {
    await _runPermissionAction(() async {
      await widget.appConfig.confirmBatteryBackgroundActivity();
    });
  }

  Future<void> _confirmPauseAppActivity() async {
    await _runPermissionAction(() async {
      await widget.appConfig.confirmPauseAppActivity();
    });
  }

  Future<void> _openLocationSettings() async {
    await _runPermissionAction(() async {
      await Geolocator.openLocationSettings();
    });
  }

  Future<void> _continueToSetup() async {
    await widget.appConfig.completePermissionsSetup();
    if (!mounted) {
      return;
    }

    final nextRoute = widget.appConfig.isSetupComplete ? '/home' : '/setup';
    Navigator.of(context).pushReplacementNamed(nextRoute);
  }

  PermissionStatus _effectiveLocationStatus() {
    if (!_locationServiceEnabled) {
      return PermissionStatus.denied;
    }
    if (_locationAlwaysStatus.isGranted) {
      return _locationAlwaysStatus;
    }
    return _locationWhenInUseStatus;
  }

  Color _statusColor(bool granted) {
    return granted
        ? const Color.fromRGBO(7, 84, 16, 1.0)
        : const Color.fromRGBO(188, 33, 52, 1.0);
  }

  String _statusLabel(PermissionStatus status, {required bool granted}) {
    final loc = AppLocalizations.of(context);
    if (granted) {
      return loc.permissionSet;
    }
    if (status.isPermanentlyDenied) {
      return loc.permissionDeclined;
    }
    return loc.permissionUnset;
  }

  Widget _buildStatusChip({required bool granted, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _statusColor(granted).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: _statusColor(granted).withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            granted ? Icons.check_circle : Icons.cancel,
            size: 16,
            color: _statusColor(granted),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: _statusColor(granted),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionCard({
    required IconData icon,
    required String title,
    required String description,
    required bool granted,
    required PermissionStatus status,
    required String actionLabel,
    required VoidCallback? onAction,
    String? secondaryLabel,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: _statusColor(
                    granted,
                  ).withValues(alpha: 0.12),
                  child: Icon(icon, color: _statusColor(granted)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(description),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatusChip(
                  granted: granted,
                  label: _statusLabel(status, granted: granted),
                ),
                if (secondaryLabel != null) ...[
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      secondaryLabel,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: onAction, child: Text(actionLabel)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBatteryRow({
    required String title,
    required String description,
    required bool granted,
    required String statusLabel,
    required String actionLabel,
    required VoidCallback? onAction,
    String? secondaryActionLabel,
    VoidCallback? secondaryOnAction,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(description),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _buildStatusChip(granted: granted, label: statusLabel),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                TextButton(onPressed: onAction, child: Text(actionLabel)),
                if (secondaryActionLabel != null)
                  TextButton(
                    onPressed: secondaryOnAction,
                    child: Text(secondaryActionLabel),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBatterySection(AppLocalizations loc) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: _statusColor(
                    _batteryBackgroundActivityConfirmed,
                  ).withValues(alpha: 0.12),
                  child: Icon(
                    Icons.battery_saver_outlined,
                    color: _statusColor(_batteryBackgroundActivityConfirmed),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.batteryOptimizationTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(loc.batteryOptimizationDescription),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildBatteryRow(
              title: loc.allowBackgroundActivityTitle,
              description: loc.allowBackgroundActivityDescription,
              granted: _batteryBackgroundActivityConfirmed,
              statusLabel: _batteryBackgroundActivityConfirmed
                  ? loc.permissionGranted
                  : loc.permissionUnset,
              actionLabel: loc.openBatterySettings,
              onAction: _openIgnoreBatteryOptimizationSettings,
              secondaryActionLabel: _batteryBackgroundActivityConfirmed
                  ? null
                  : loc.confirmSet,
              secondaryOnAction: _batteryBackgroundActivityConfirmed
                  ? null
                  : _confirmBatteryBackgroundActivity,
            ),
            _buildBatteryRow(
              title: loc.pauseAppActivityTitle,
              description: loc.pauseAppActivityDescription,
              granted: _pauseAppActivityConfirmed,
              statusLabel: _pauseAppActivityConfirmed
                  ? loc.permissionGranted
                  : loc.permissionUnset,
              actionLabel: loc.openAppSettings,
              onAction: _openAppSettings,
              secondaryActionLabel: _pauseAppActivityConfirmed
                  ? null
                  : loc.confirmSet,
              secondaryOnAction: _pauseAppActivityConfirmed
                  ? null
                  : _confirmPauseAppActivity,
            ),
            _buildBatteryRow(
              title: loc.ignoreBatteryOptimizationsTitle,
              description: loc.ignoreBatteryOptimizationsDescription,
              granted: _ignoreBatteryOptimizationsGranted,
              statusLabel: _ignoreBatteryOptimizationsGranted
                  ? loc.permissionGranted
                  : loc.permissionUnset,
              actionLabel: _ignoreBatteryOptimizationsGranted
                  ? loc.permissionGranted
                  : (_isUpdating
                        ? loc.permissionWorking
                        : loc.requestPermission),
              onAction: _ignoreBatteryOptimizationsGranted
                  ? null
                  : _requestBatteryOptimizationsIgnore,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final currentLanguage = widget.appConfig.languageCode;
    final locationStatus = _effectiveLocationStatus();
    final locationGranted = _locationServiceEnabled && locationStatus.isGranted;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.permissionsSetupTitle),
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
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
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
                          Icons.manage_accounts_outlined,
                          color: Colors.white,
                          size: 40,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          loc.permissionsSetupTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          loc.permissionsSetupBody,
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
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  _buildPermissionCard(
                    icon: Icons.notifications_active_outlined,
                    title: loc.notificationsPermissionTitle,
                    description: loc.notificationsPermissionDescription,
                    granted: _notificationsGranted,
                    status: _notificationsGranted
                        ? PermissionStatus.granted
                        : PermissionStatus.denied,
                    actionLabel: _notificationsGranted
                        ? loc.permissionGranted
                        : (_isUpdating
                              ? loc.permissionWorking
                              : loc.requestPermission),
                    onAction: _notificationsGranted
                        ? null
                        : _requestNotifications,
                  ),
                  _buildPermissionCard(
                    icon: Icons.my_location_outlined,
                    title: loc.locationPermissionTitle,
                    description: loc.locationPermissionDescription,
                    granted: locationGranted,
                    status: locationStatus,
                    actionLabel: _locationServiceEnabled
                        ? (locationGranted
                              ? loc.permissionGranted
                              : (_isUpdating
                                    ? loc.permissionWorking
                                    : loc.requestPermission))
                        : (_isUpdating
                              ? loc.permissionWorking
                              : loc.openLocationSettings),
                    onAction: locationGranted
                        ? null
                        : (_locationServiceEnabled
                              ? _requestLocationWhenInUse
                              : _openLocationSettings),
                    secondaryLabel: _locationServiceEnabled
                        ? null
                        : loc.locationServicesDisabled,
                  ),
                  _buildPermissionCard(
                    icon: Icons.location_searching_outlined,
                    title: loc.backgroundLocationPermissionTitle,
                    description: loc.backgroundLocationPermissionDescription,
                    granted: _locationAlwaysStatus.isGranted,
                    status: _locationAlwaysStatus,
                    actionLabel: _locationAlwaysStatus.isGranted
                        ? loc.permissionGranted
                        : (_isUpdating
                              ? loc.permissionWorking
                              : loc.requestPermission),
                    onAction: _locationAlwaysStatus.isGranted
                        ? null
                        : _requestLocationAlways,
                  ),
                  _buildBatterySection(loc),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _isUpdating ? null : _continueToSetup,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      backgroundColor: const Color.fromRGBO(7, 84, 16, 0.9),
                      foregroundColor: Colors.white,
                    ),
                    child: _isUpdating
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
                            loc.permissionsContinue,
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
