import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing app configuration
class AppConfig {
  static const String _keyTeamName = 'team_name';
  static const String _keyEvent = 'event';
  static const String _keyApiUrl = 'api_url';
  static const String _keyImageUrl = 'image_url';
  static const String _keySetupComplete = 'setup_complete';
  static const String _keyExpirationDate = 'expiration_date';
  static const String _keyLanguageCode = 'language_code';
  static const String _keyTimezone = 'timezone';

  final SharedPreferences _prefs;

  AppConfig._(this._prefs);

  /// Initialize the app configuration
  static Future<AppConfig> init() async {
    final prefs = await SharedPreferences.getInstance();
    final config = AppConfig._(prefs);

    // Check if configuration has expired
    if (config.isSetupComplete && config.isExpired) {
      await config.clearConfig();
    }

    return config;
  }

  /// Check if initial setup has been completed
  bool get isSetupComplete => _prefs.getBool(_keySetupComplete) ?? false;

  /// Check if the configuration has expired
  bool get isExpired {
    final expirationDateStr = _prefs.getString(_keyExpirationDate);
    if (expirationDateStr == null) return false;

    final expirationDate = DateTime.parse(expirationDateStr);
    final now = DateTime.now();

    // Compare dates only (ignore time)
    final expirationDateOnly = DateTime(
      expirationDate.year,
      expirationDate.month,
      expirationDate.day,
    );
    final nowDateOnly = DateTime(now.year, now.month, now.day);

    return nowDateOnly.isAfter(expirationDateOnly);
  }

  /// Get team name
  String? get teamName => _prefs.getString(_keyTeamName);

  /// Get event
  String? get event => _prefs.getString(_keyEvent);

  /// Get GraphQL API URL
  String get apiUrl =>
      _prefs.getString(_keyApiUrl) ?? 'https://your-project.vercel.app/api';

  /// Get image URL
  String? get imageUrl => _prefs.getString(_keyImageUrl);

  /// Get expiration date
  DateTime? get expirationDate {
    final dateStr = _prefs.getString(_keyExpirationDate);
    return dateStr != null ? DateTime.parse(dateStr) : null;
  }

  /// Get language code (defaults to 'en')
  String get languageCode => _prefs.getString(_keyLanguageCode) ?? 'en';

  /// Set language code
  Future<void> setLanguage(String languageCode) async {
    await _prefs.setString(_keyLanguageCode, languageCode);
  }

  /// Get timezone (defaults to 'UTC')
  String get timezone => _prefs.getString(_keyTimezone) ?? 'UTC';

  /// Save configuration and mark setup as complete
  Future<void> saveConfig({
    required String teamName,
    required String event,
    required String apiUrl,
    required String imageUrl,
    required DateTime expirationDate,
    required String timezone,
  }) async {
    await _prefs.setString(_keyTeamName, teamName);
    await _prefs.setString(_keyEvent, event);
    await _prefs.setString(_keyApiUrl, apiUrl);
    await _prefs.setString(_keyImageUrl, imageUrl);
    await _prefs.setString(
      _keyExpirationDate,
      expirationDate.toIso8601String(),
    );
    await _prefs.setString(_keyTimezone, timezone);
    await _prefs.setBool(_keySetupComplete, true);
  }

  /// Clear all configuration (for testing or reset)
  Future<void> clearConfig() async {
    await _prefs.remove(_keyTeamName);
    await _prefs.remove(_keyEvent);
    await _prefs.remove(_keyApiUrl);
    await _prefs.remove(_keyImageUrl);
    await _prefs.remove(_keyExpirationDate);
    await _prefs.remove(_keyTimezone);
    await _prefs.remove(_keySetupComplete);
  }
}
