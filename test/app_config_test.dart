import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:location_share_android/app_config.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AppConfig - Initialization', () {
    test('initializes with empty configuration', () async {
      final config = await AppConfig.init();

      expect(config.isSetupComplete, isFalse);
      expect(config.teamName, isNull);
      expect(config.event, isNull);
      expect(
        config.apiUrl,
        equals('https://your-project.vercel.app/api'),
      ); // Has default
      expect(config.imageUrl, isNull);
      expect(config.expirationDate, isNull);
      expect(config.timezone, equals('UTC')); // Has default
    });

    test('loads existing configuration from preferences', () async {
      SharedPreferences.setMockInitialValues({
        'team_name': 'Test Team',
        'event': 'Test Event',
        'api_url': 'https://api.example.com/api',
        'image_url': 'https://example.com/logo.png',
        'expiration_date': '2026-12-31',
        'timezone': 'UTC',
        'language_code': 'en',
        'setup_complete': true,
      });

      final config = await AppConfig.init();

      expect(config.isSetupComplete, isTrue);
      expect(config.teamName, equals('Test Team'));
      expect(config.event, equals('Test Event'));
      expect(config.apiUrl, equals('https://api.example.com/api'));
      expect(config.imageUrl, equals('https://example.com/logo.png'));
      expect(config.expirationDate, equals(DateTime(2026, 12, 31)));
      expect(config.timezone, equals('UTC'));
      expect(config.languageCode, equals('en'));
    });

    test('defaults to English language', () async {
      final config = await AppConfig.init();
      expect(config.languageCode, equals('en'));
    });
  });

  group('AppConfig - Save Configuration', () {
    test('saves all configuration fields', () async {
      final config = await AppConfig.init();

      await config.saveConfig(
        teamName: 'New Team',
        event: 'New Event',
        apiUrl: 'https://new-api.com/api',
        imageData: 'ZmFrZV9pbWFnZV9kYXRh',
        imageMimeType: 'image/png',
        expirationDate: DateTime(2027, 6, 15),
        timezone: 'Europe/Helsinki',
      );

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('team_name'), equals('New Team'));
      expect(prefs.getString('event'), equals('New Event'));
      expect(prefs.getString('api_url'), equals('https://new-api.com/api'));
      expect(prefs.getString('image_data'), equals('ZmFrZV9pbWFnZV9kYXRh'));
      expect(prefs.getString('image_mime_type'), equals('image/png'));
      expect(prefs.getString('expiration_date'), equals('2027-06-15'));
      expect(prefs.getString('timezone'), equals('Europe/Helsinki'));
    });

    test('marks setup as complete after saving', () async {
      final config = await AppConfig.init();
      expect(config.isSetupComplete, isFalse);

      await config.saveConfig(
        teamName: 'Team',
        event: 'Event',
        apiUrl: 'https://api.com/api',
        imageData: 'dGVzdA==',
        imageMimeType: 'image/png',
        expirationDate: DateTime(2027, 1, 1),
        timezone: 'UTC',
      );

      final newConfig = await AppConfig.init();
      expect(newConfig.isSetupComplete, isTrue);
    });
  });

  group('AppConfig - Reset Configuration', () {
    test('clears all configuration data', () async {
      // First save some config
      SharedPreferences.setMockInitialValues({
        'team_name': 'Test Team',
        'event': 'Test Event',
        'api_url': 'https://api.example.com/api',
        'image_url': 'https://example.com/logo.png',
        'expiration_date': '2026-12-31',
        'timezone': 'UTC',
        'language_code': 'fi',
        'setup_complete': true,
      });

      final config = await AppConfig.init();
      expect(config.isSetupComplete, isTrue);

      await config.clearConfig();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('team_name'), isNull);
      expect(prefs.getString('event'), isNull);
      expect(prefs.getString('api_url'), isNull);
      expect(prefs.getString('image_url'), isNull);
      expect(prefs.getString('expiration_date'), isNull);
      expect(prefs.getString('timezone'), isNull);
      // Language should be preserved
      expect(prefs.getString('language_code'), equals('fi'));
    });

    test('preserves language setting after reset', () async {
      final config = await AppConfig.init();
      await config.setLanguage('fi');

      await config.saveConfig(
        teamName: 'Team',
        event: 'Event',
        apiUrl: 'https://api.com/api',
        imageData: 'dGVzdA==',
        imageMimeType: 'image/png',
        expirationDate: DateTime(2027, 1, 1),
        timezone: 'UTC',
      );

      await config.clearConfig();

      final newConfig = await AppConfig.init();
      expect(newConfig.languageCode, equals('fi'));
    });
  });

  group('AppConfig - Language Settings', () {
    test('changes language setting', () async {
      final config = await AppConfig.init();
      expect(config.languageCode, equals('en'));

      await config.setLanguage('fi');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('language_code'), equals('fi'));
    });

    test('language persists across instances', () async {
      final config1 = await AppConfig.init();
      await config1.setLanguage('fi');

      final config2 = await AppConfig.init();
      expect(config2.languageCode, equals('fi'));
    });
  });

  group('AppConfig - Validation', () {
    test('isSetupComplete returns false with partial data', () async {
      SharedPreferences.setMockInitialValues({
        'team_name': 'Test Team',
        'event': 'Test Event',
        // Missing other required fields
      });

      final config = await AppConfig.init();
      expect(config.isSetupComplete, isFalse);
    });

    test('isSetupComplete returns true with all data', () async {
      SharedPreferences.setMockInitialValues({
        'team_name': 'Test Team',
        'event': 'Test Event',
        'api_url': 'https://api.example.com/api',
        'image_url': 'https://example.com/logo.png',
        'expiration_date': '2026-12-31',
        'timezone': 'UTC',
        'setup_complete': true,
      });

      final config = await AppConfig.init();
      expect(config.isSetupComplete, isTrue);
    });
  });

  group('AppConfig - Date Handling', () {
    test('parses dates correctly', () async {
      SharedPreferences.setMockInitialValues({'expiration_date': '2026-03-15'});

      final config = await AppConfig.init();
      expect(config.expirationDate, equals(DateTime(2026, 3, 15)));
    });

    test('handles invalid date format', () async {
      SharedPreferences.setMockInitialValues({
        'expiration_date': 'invalid-date',
      });

      final config = await AppConfig.init();
      expect(config.expirationDate, isNull);
    });

    test('saves dates in correct format', () async {
      final config = await AppConfig.init();

      await config.saveConfig(
        teamName: 'Team',
        event: 'Event',
        apiUrl: 'https://api.com/api',
        imageData: 'dGVzdA==',
        imageMimeType: 'image/png',
        expirationDate: DateTime(2026, 3, 15),
        timezone: 'UTC',
      );

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('expiration_date'), equals('2026-03-15'));
    });
  });
}
