import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'app_config.dart';
import 'setup_page.dart';
import 'settings_page.dart';
import 'about.dart';
import 'l10n/app_localizations.dart';
import 'location_service.dart';
import 'splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AppLoader());
}

class AppLoader extends StatefulWidget {
  const AppLoader({super.key});

  @override
  State<AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<AppLoader> {
  AppConfig? _appConfig;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final appConfig = await AppConfig.init();

    // Keep splash screen visible for at least 3 seconds for shimmer effect
    await Future.delayed(const Duration(milliseconds: 3000));

    if (mounted) {
      setState(() {
        _appConfig = appConfig;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _appConfig == null) {
      return const SplashScreen();
    }
    return MyApp(appConfig: _appConfig!);
  }
}

/// Background task handler for location updates
@pragma('vm:entry-point')
class LocationTaskHandler extends TaskHandler {
  @override
  void onNotificationPressed() {}

  @override
  void onNotificationButtonPressed(String id) {}

  @override
  void onRepeatEvent(DateTime timestamp) async {
    final LocationSettings locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 0,
    );
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );
      final lat = position.latitude.toStringAsFixed(5);
      final lon = position.longitude.toStringAsFixed(5);

      // Format the timestamp to a readable time string (HH:MM:SS)
      final time =
          "${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}";

      // Update notification with current location and time
      await FlutterForegroundTask.updateService(
        notificationText: 'Lat: $lat, Lon: $lon at $time',
      );

      // Upload location to PostgreSQL
      final uploaded = await LocationService.uploadLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: timestamp,
      );

      if (uploaded) {
        print("📍 Location: $lat, $lon at $time - Uploaded ✅");
      } else {
        print("📍 Location: $lat, $lon at $time - Upload failed ❌");
      }
    } catch (e) {
      print("❌ Error getting location: $e");
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTaskRemoved) async {}

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}
}

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(LocationTaskHandler());
}

class MyApp extends StatefulWidget {
  final AppConfig appConfig;

  const MyApp({super.key, required this.appConfig});

  @override
  State<MyApp> createState() => _MyAppState();

  static _MyAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>();
}

class _MyAppState extends State<MyApp> {
  late Locale _locale;

  @override
  void initState() {
    super.initState();
    _locale = _getLocaleFromLanguageCode(widget.appConfig.languageCode);
  }

  Locale _getLocaleFromLanguageCode(String code) {
    switch (code) {
      case 'fi':
        return const Locale('fi', 'FI');
      case 'en':
      default:
        return const Locale('en', 'GB');
    }
  }

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Location Share',
      debugShowCheckedModeBanner: false,
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: ThemeMode.system,
      locale: _locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      initialRoute: widget.appConfig.isSetupComplete ? '/home' : '/setup',
      routes: {
        '/setup': (context) => SetupPage(appConfig: widget.appConfig),
        '/home': (context) => HomePage(appConfig: widget.appConfig),
      },
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color.fromRGBO(7, 84, 16, 1.0),
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(centerTitle: false, elevation: 2),
      cardTheme: const CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color.fromRGBO(7, 84, 16, 1.0),
        brightness: Brightness.dark,
      ),
      appBarTheme: const AppBarTheme(centerTitle: false, elevation: 2),
      cardTheme: const CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final AppConfig appConfig;

  const HomePage({super.key, required this.appConfig});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    _initForegroundTask();
    _requestPermissions();

    // Debug: Log image data status
    print('🏠 HomePage initialized');
    print('   Team: ${widget.appConfig.teamName}');
    print('   Event: ${widget.appConfig.event}');
    print('   Has imageData: ${widget.appConfig.imageData != null}');
    print('   Has imageMimeType: ${widget.appConfig.imageMimeType != null}');
    if (widget.appConfig.imageData != null) {
      print(
        '   ImageData length: ${widget.appConfig.imageData!.length} characters',
      );
      print(
        '   ImageData preview: ${widget.appConfig.imageData!.substring(0, 50)}...',
      );
    }
  }

  int _navigationIndex = 0;
  bool _sharingState = false;

  void _initForegroundTask() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'location_channel',
        channelName: 'Location Tracking On',
        channelDescription: 'Sharing location updates in background',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.HIGH,
        enableVibration: false,
        playSound: false,
        showWhen: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(
          15000,
        ), // Update every 15 seconds
        autoRunOnBoot: false,
        allowWakeLock: true,
      ),
    );
  }

  Future<void> _requestPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      await Geolocator.requestPermission();
    }

    final isIgnoring =
        await FlutterForegroundTask.isIgnoringBatteryOptimizations;
    if (!isIgnoring) {
      await FlutterForegroundTask.requestIgnoreBatteryOptimization();
    }
  }

  Future<void> _startService() async {
    setState(() {
      _sharingState = true;
    });
    await FlutterForegroundTask.startService(
      notificationTitle: 'Sharing Location',
      notificationText: 'Waiting for location...',
      callback: startCallback,
    );
  }

  Future<void> _stopService() async {
    setState(() {
      _sharingState = false;
    });
    await FlutterForegroundTask.stopService();
  }

  void _onNavigationItemTapped(int index) {
    setState(() {
      _navigationIndex = index;
    });
  }

  final IconAlignment _iconAlignment = IconAlignment.start;

  Widget _buildHomeView() {
    final loc = AppLocalizations.of(context);
    return Column(
      children: [
        // Upper half - centered button
        Expanded(
          child: Center(
            child: _sharingState
                ? ElevatedButton.icon(
                    icon: const Icon(Icons.location_off_outlined, size: 30),
                    style: const ButtonStyle(
                      backgroundColor: WidgetStatePropertyAll<Color>(
                        Color.fromRGBO(7, 84, 16, 0.8),
                      ),
                      foregroundColor: WidgetStatePropertyAll<Color>(
                        Colors.white,
                      ),
                      padding: WidgetStatePropertyAll<EdgeInsets>(
                        EdgeInsets.symmetric(horizontal: 22, vertical: 20),
                      ),
                    ),
                    onPressed: _stopService,
                    label: Text(
                      loc.stopLocationSharing,
                      style: const TextStyle(fontSize: 20),
                    ),
                    iconAlignment: _iconAlignment,
                  )
                : ElevatedButton.icon(
                    icon: const Icon(Icons.location_on_outlined, size: 30),
                    style: const ButtonStyle(
                      backgroundColor: WidgetStatePropertyAll<Color>(
                        Color.fromRGBO(219, 79, 2, 0.8),
                      ),
                      foregroundColor: WidgetStatePropertyAll<Color>(
                        Colors.white,
                      ),
                      padding: WidgetStatePropertyAll<EdgeInsets>(
                        EdgeInsets.symmetric(horizontal: 22, vertical: 20),
                      ),
                    ),
                    onPressed: _startService,
                    label: Text(
                      loc.startLocationSharing,
                      style: const TextStyle(fontSize: 20),
                    ),
                    iconAlignment: _iconAlignment,
                  ),
          ),
        ),
        // Lower half - event name and image display
        Expanded(
          child:
              widget.appConfig.imageData != null &&
                  widget.appConfig.imageMimeType != null
              ? Column(
                  children: [
                    // Event name
                    Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: Text(
                        widget.appConfig.event ?? 'No event',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    // Image from base64 data
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                        child: Builder(
                          builder: (context) {
                            try {
                              final imageBytes = base64Decode(
                                widget.appConfig.imageData!,
                              );
                              return Image.memory(
                                imageBytes,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.broken_image,
                                          size: 64,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.outline,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          loc.failedToLoadImage,
                                          style: TextStyle(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.outline,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            } catch (e) {
                              print('❌ Error decoding image: $e');
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.broken_image,
                                      size: 64,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.outline,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      loc.failedToLoadImage,
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.outline,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    // Event name
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        widget.appConfig.event ?? loc.noEvent,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    // No image message
                    Expanded(
                      child: Center(
                        child: Text(
                          loc.noImageConfigured,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final List<Widget> pages = [
      _buildHomeView(),
      SettingsPage(appConfig: widget.appConfig),
      const AboutPage(),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(loc.appTitle)),
      body: pages[_navigationIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navigationIndex,
        elevation: 16.0,
        onDestinationSelected: _onNavigationItemTapped,
        destinations: <Widget>[
          NavigationDestination(
            icon: const Icon(Icons.share_location_outlined),
            label: loc.sharing,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            label: loc.settings,
          ),
          NavigationDestination(
            icon: const Icon(Icons.info_outline),
            label: loc.about,
          ),
        ],
      ),
    );
  }
}

// Transform.rotate(
//   angle: -35 * pi / 180,
//   child: const Icon(Icons.share),
// )
