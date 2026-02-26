import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:graphql_flutter/graphql_flutter.dart';

/// Service for uploading location data via GraphQL API
class LocationService {
  static bool _timezoneInitialized = false;

  /// Upload location data to GraphQL API
  static Future<bool> uploadLocation({
    required double latitude,
    required double longitude,
    required DateTime timestamp,
  }) async {
    try {
      // Initialize timezone data if not already done
      if (!_timezoneInitialized) {
        tz.initializeTimeZones();
        _timezoneInitialized = true;
      }

      final prefs = await SharedPreferences.getInstance();
      final apiUrl = prefs.getString('api_url');
      final teamName = prefs.getString('team_name');
      final event = prefs.getString('event');
      final timezone = prefs.getString('timezone') ?? 'UTC';

      if (apiUrl == null || teamName == null || event == null) {
        print('❌ Missing configuration for location upload');
        return false;
      }

      // Convert timestamp to configured timezone
      final location = tz.getLocation(timezone);
      final tzTime = tz.TZDateTime.from(timestamp, location);

      // Convert to ISO 8601 string for GraphQL
      final timestampStr = tzTime.toUtc().toIso8601String();

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
          'lat': latitude,
          'lon': longitude,
          'timestamp': timestampStr,
        },
      );

      final QueryResult result = await client.mutate(options);

      if (result.hasException) {
        print('❌ GraphQL error: ${result.exception}');
        return false;
      }

      print('✅ Location uploaded successfully via GraphQL API');
      return true;
    } catch (e) {
      print('❌ Error uploading location: $e');
      return false;
    }
  }
}
