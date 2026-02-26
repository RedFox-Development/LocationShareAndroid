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
        final location = tz.getLocation(timezoneStr);
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
