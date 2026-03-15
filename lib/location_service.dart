import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:graphql_flutter/graphql_flutter.dart';

/// 1-D scalar Kalman filter for a single coordinate (latitude or longitude).
/// Models position as a random walk: position changes by up to ~14 km/h per second.
/// Measurement noise assumes ~10 m GPS horizontal accuracy.
class _ScalarKalman {
  double estimate;
  double errorCovariance;

  // (10 m / 111 111 m·deg⁻¹)² ≈ 8.1e-9 deg²
  static const double _measurementNoise = 8.1e-9;

  // Process noise per second — tunes tracking vs. smoothing trade-off.
  // sqrt(1.3e-9) * 111 111 ≈ 4 m/s → ~14 km/h modelled speed → K_ss ≈ 0.40
  static const double _processNoisePerSecond = 1.3e-9;

  _ScalarKalman(this.estimate) : errorCovariance = _measurementNoise;

  double update(double measurement, double dtSeconds) {
    // Predict
    final double predictedP =
        errorCovariance + _processNoisePerSecond * dtSeconds;
    // Update
    final double k = predictedP / (predictedP + _measurementNoise);
    estimate = estimate + k * (measurement - estimate);
    errorCovariance = (1.0 - k) * predictedP;
    return estimate;
  }
}

/// Service for uploading location data via GraphQL API
class LocationService {
  static bool _timezoneInitialized = false;

  // --- Anti-jamming filter state ---
  static _ScalarKalman? _kalmanLat;
  static _ScalarKalman? _kalmanLon;
  static double? _lastAcceptedLat;
  static double? _lastAcceptedLon;
  static DateTime? _lastAcceptedTime;
  // 120 km/h expressed in m/s
  static const double _maxSpeedMs = 120.0 / 3.6;

  static String _normalizeTimezoneId(String timezone) {
    final trimmed = timezone.trim();
    if (trimmed.isEmpty) {
      return 'Etc/UTC';
    }

    // Keep backward compatibility with historical/default values.
    switch (trimmed.toUpperCase()) {
      case 'UTC':
      case 'GMT':
      case 'ETC/UTC':
        return 'Etc/UTC';
      default:
        return trimmed;
    }
  }

  static double _haversineMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double r = 6371000.0;
    final double phi1 = lat1 * pi / 180.0;
    final double phi2 = lat2 * pi / 180.0;
    final double dPhi = (lat2 - lat1) * pi / 180.0;
    final double dLambda = (lon2 - lon1) * pi / 180.0;
    final double a =
        pow(sin(dPhi / 2), 2) +
        cos(phi1) * cos(phi2) * pow(sin(dLambda / 2), 2);
    return r * 2.0 * atan2(sqrt(a.toDouble()), sqrt((1.0 - a).toDouble()));
  }

  /// Upload location data to GraphQL API
  static Future<bool> uploadLocation({
    required double latitude,
    required double longitude,
    required DateTime timestamp,
  }) async {
    try {
      // Initialize timezone data if not already done
      if (!_timezoneInitialized) {
        try {
          tz.initializeTimeZones();
          _timezoneInitialized = true;
        } catch (e) {
          print('⚠️ Timezone initialization warning: $e');
          _timezoneInitialized =
              true; // Mark as initialized anyway to avoid repeated attempts
        }
      }

      final prefs = await SharedPreferences.getInstance();
      final apiUrl = prefs.getString('api_url');
      final teamName = prefs.getString('team_name');
      final event = prefs.getString('event');
      final timezoneStr = prefs.getString('timezone') ?? 'UTC';
      final normalizedTimezone = _normalizeTimezoneId(timezoneStr);

      if (apiUrl == null || teamName == null || event == null) {
        print('❌ Missing configuration for location upload');
        print('   API URL: $apiUrl');
        print('   Team Name: $teamName');
        print('   Event: $event');
        return false;
      }

      // Convert timestamp to configured timezone
      DateTime tzTime;
      try {
        final location = tz.getLocation(normalizedTimezone);
        tzTime = tz.TZDateTime.from(timestamp, location);
      } catch (e) {
        print('⚠️ Timezone "$timezoneStr" not found, using UTC: $e');
        tzTime = timestamp.toUtc();
      }

      // Convert to ISO 8601 string for GraphQL
      final timestampStr = tzTime.toUtc().toIso8601String();

      print('📤 Uploading location:');
      print('   Team: $teamName');
      print('   Event: $event');
      print('   Lat: $latitude, Lon: $longitude');
      print('   Timestamp: $timestampStr');
      print('   API URL: $apiUrl');

      // ── Speed gate ──────────────────────────────────────────────────────────
      // Reject any point whose implied velocity since the last accepted point
      // exceeds 120 km/h — physically impossible for a ground participant and
      // a clear sign of GNSS spoofing / jamming-induced position leap.
      if (_lastAcceptedLat != null && _lastAcceptedTime != null) {
        final double dtGate =
            timestamp.difference(_lastAcceptedTime!).inMilliseconds / 1000.0;
        if (dtGate > 0) {
          final double dist = _haversineMeters(
            _lastAcceptedLat!,
            _lastAcceptedLon!,
            latitude,
            longitude,
          );
          final double impliedSpeed = dist / dtGate;
          if (impliedSpeed > _maxSpeedMs) {
            print(
              '🚫 Speed gate: implied ${impliedSpeed.toStringAsFixed(1)} m/s '
              '> ${_maxSpeedMs.toStringAsFixed(1)} m/s — point dropped',
            );
            return true; // silently dropped; not an API error
          }
        }
      }

      // ── Kalman filter ───────────────────────────────────────────────────────
      // Smooth sub-second positional jitter caused by jamming-induced noise
      // while still following legitimate movement at up to ~14 km/h.
      _kalmanLat ??= _ScalarKalman(latitude);
      _kalmanLon ??= _ScalarKalman(longitude);
      final double dtKalman = _lastAcceptedTime != null
          ? timestamp.difference(_lastAcceptedTime!).inMilliseconds / 1000.0
          : 1.0;
      final double filteredLat = _kalmanLat!.update(latitude, dtKalman);
      final double filteredLon = _kalmanLon!.update(longitude, dtKalman);
      _lastAcceptedLat = filteredLat;
      _lastAcceptedLon = filteredLon;
      _lastAcceptedTime = timestamp;
      print(
        '   Filtered Lat: ${filteredLat.toStringAsFixed(6)}, '
        'Lon: ${filteredLon.toStringAsFixed(6)}',
      );

      // Create GraphQL client
      final httpLink = HttpLink(apiUrl);
      final client = GraphQLClient(
        link: httpLink,
        cache: GraphQLCache(store: InMemoryStore()),
      );

      // GraphQL mutation
      const String mutation = r'''
        mutation CreateLocationUpdate($team: String!, $event: String!, $lat: Float!, $lon: Float!, $timestamp: String) {
          createLocationUpdate(team: $team, event: $event, lat: $lat, lon: $lon, timestamp: $timestamp) {
            id
            timestamp
          }
        }
      ''';

      final MutationOptions options = MutationOptions(
        document: gql(mutation),
        variables: {
          'team': teamName,
          'event': event,
          'lat': filteredLat,
          'lon': filteredLon,
          'timestamp': timestampStr,
        },
      );

      final QueryResult result = await client.mutate(options);

      if (result.hasException) {
        print('❌ GraphQL error: ${result.exception}');
        print('   Exception: ${result.exception.toString()}');
        if (result.exception is OperationException) {
          final opException = result.exception as OperationException;
          print('   GraphQL Errors: ${opException.graphqlErrors}');
          print('   Link Exception: ${opException.linkException}');
        }
        return false;
      }

      if (result.data == null) {
        print('❌ No data returned from mutation');
        return false;
      }

      final data = result.data?['createLocationUpdate'];
      if (data != null) {
        print('✅ Location uploaded successfully via GraphQL API');
        print('   ID: ${data['id']}');
        print('   Timestamp: ${data['timestamp']}');
        return true;
      } else {
        print('❌ Mutation returned null data');
        return false;
      }
    } catch (e) {
      print('❌ Error uploading location: $e');
      print('   Stack trace: ${StackTrace.current}');
      return false;
    }
  }
}
