import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing app configuration
class AppConfig {
  static const String _keyTeamName = 'team_name';
  static const String _keyEvent = 'event';
  static const String _keyApiUrl = 'api_url';
  static const String _keyImageUrl =
      'image_url'; // Deprecated, kept for backward compatibility
  static const String _keyImageData = 'image_data';
  static const String _keyImageMimeType = 'image_mime_type';
  static const String _keySetupComplete = 'setup_complete';
  static const String _keyExpirationDate = 'expiration_date';
  static const String _keyLanguageCode = 'language_code';
  static const String _keyTimezone = 'timezone';
  static const String _keyTimeframeStartDate = 'timeframe_start';
  static const String _keyTimeframeEndDate = 'timeframe_end';

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

  /// Check if the configuration has expired (timeframe end reached)
  bool get isExpired {
    final nowUtc = DateTime.now().toUtc();

    // Check team access timeframe - if configured, must be within the window
    final timeframeStart = timeframeStartDate?.toUtc();
    final timeframeEnd = timeframeEndDate?.toUtc();
    if (timeframeStart != null && timeframeEnd != null) {
      if (nowUtc.isBefore(timeframeStart) || nowUtc.isAfter(timeframeEnd)) {
        return true; // Outside team access timeframe
      }
    }

    // Backward compatibility fallback for older stored configs.
    final expirationDateStr = _prefs.getString(_keyExpirationDate);
    if (expirationDateStr == null) return false;

    try {
      final expirationDate = DateTime.parse(expirationDateStr);
      final expirationDateOnly = DateTime(
        expirationDate.year,
        expirationDate.month,
        expirationDate.day,
      );
      final now = DateTime.now();
      final nowDateOnly = DateTime(now.year, now.month, now.day);
      return nowDateOnly.isAfter(expirationDateOnly);
    } catch (e) {
      return false;
    }
  }

  /// Get team name
  String? get teamName => _prefs.getString(_keyTeamName);

  /// Get event
  String? get event => _prefs.getString(_keyEvent);

  /// Get GraphQL API URL
  String get apiUrl =>
      _prefs.getString(_keyApiUrl) ?? 'https://your-project.vercel.app/api';

  /// Get image URL (deprecated, for backward compatibility)
  String? get imageUrl => _prefs.getString(_keyImageUrl);

  /// Get image data (base64 encoded)
  String? get imageData => _prefs.getString(_keyImageData);

  /// Get image MIME type
  String? get imageMimeType => _prefs.getString(_keyImageMimeType);

  /// Get expiration date
  DateTime? get expirationDate {
    final dateStr = _prefs.getString(_keyExpirationDate);
    if (dateStr == null) return null;
    try {
      return DateTime.parse(dateStr);
    } catch (e) {
      return null;
    }
  }

  /// Get language code (defaults to 'en')
  String get languageCode => _prefs.getString(_keyLanguageCode) ?? 'en';

  /// Set language code
  Future<void> setLanguage(String languageCode) async {
    await _prefs.setString(_keyLanguageCode, languageCode);
  }

  /// Get timezone (defaults to 'UTC')
  String get timezone => _prefs.getString(_keyTimezone) ?? 'UTC';

  /// Get team access timeframe start date
  DateTime? get timeframeStartDate {
    final dateStr = _prefs.getString(_keyTimeframeStartDate);
    if (dateStr == null) return null;
    try {
      return DateTime.parse(dateStr);
    } catch (e) {
      return null;
    }
  }

  /// Get team access timeframe end date
  DateTime? get timeframeEndDate {
    final dateStr = _prefs.getString(_keyTimeframeEndDate);
    if (dateStr == null) return null;
    try {
      return DateTime.parse(dateStr);
    } catch (e) {
      return null;
    }
  }

  /// Save configuration and mark setup as complete
  Future<void> saveConfig({
    required String teamName,
    required String event,
    required String apiUrl,
    String? imageData,
    String? imageMimeType,
    DateTime? expirationDate,
    required String timezone,
    DateTime? timeframeStartDate,
    DateTime? timeframeEndDate,
  }) async {
    await _prefs.setString(_keyTeamName, teamName);
    await _prefs.setString(_keyEvent, event);
    await _prefs.setString(_keyApiUrl, apiUrl);

    // Save image data if provided
    if (imageData != null && imageMimeType != null) {
      await _prefs.setString(_keyImageData, imageData);
      await _prefs.setString(_keyImageMimeType, imageMimeType);
    } else {
      // Clear image data if not provided
      await _prefs.remove(_keyImageData);
      await _prefs.remove(_keyImageMimeType);
    }

    if (expirationDate != null) {
      await _prefs.setString(
        _keyExpirationDate,
        '${expirationDate.year.toString().padLeft(4, '0')}-${expirationDate.month.toString().padLeft(2, '0')}-${expirationDate.day.toString().padLeft(2, '0')}',
      );
    } else {
      await _prefs.remove(_keyExpirationDate);
    }
    await _prefs.setString(_keyTimezone, timezone);

    if (timeframeStartDate != null) {
      await _prefs.setString(
        _keyTimeframeStartDate,
        timeframeStartDate.toUtc().toIso8601String(),
      );
    } else {
      await _prefs.remove(_keyTimeframeStartDate);
    }

    if (timeframeEndDate != null) {
      await _prefs.setString(
        _keyTimeframeEndDate,
        timeframeEndDate.toUtc().toIso8601String(),
      );
    } else {
      await _prefs.remove(_keyTimeframeEndDate);
    }

    await _prefs.setBool(_keySetupComplete, true);
  }

  /// Clear all configuration (for testing or reset)
  Future<void> clearConfig() async {
    await _prefs.remove(_keyTeamName);
    await _prefs.remove(_keyEvent);
    await _prefs.remove(_keyApiUrl);
    await _prefs.remove(_keyImageUrl); // Legacy
    await _prefs.remove(_keyImageData);
    await _prefs.remove(_keyImageMimeType);
    await _prefs.remove(_keyExpirationDate);
    await _prefs.remove(_keyTimezone);
    await _prefs.remove(_keyTimeframeStartDate);
    await _prefs.remove(_keyTimeframeEndDate);
    await _prefs.remove(_keySetupComplete);
  }
}
