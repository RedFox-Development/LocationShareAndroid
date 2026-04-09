import 'package:graphql_flutter/graphql_flutter.dart';

/// Service for fetching event data via GraphQL API
class EventService {
  static GraphQLClient _buildClient(String apiUrl) {
    final httpLink = HttpLink(apiUrl);
    return GraphQLClient(
      link: httpLink,
      cache: GraphQLCache(store: InMemoryStore()),
    );
  }

  /// Query event details including images by event name
  /// Returns event data with image_data and image_mime_type fields
  static Future<Map<String, dynamic>?> queryEventByName({
    required String apiUrl,
    required String eventName,
  }) async {
    try {
      final client = _buildClient(apiUrl);

      // GraphQL query - note: this is a public query without authentication
      // It only fetches non-sensitive event data (name and images)
      const String query = r'''
        query GetEventByName($eventName: String!) {
          eventByName(event_name: $eventName) {
            id
            name
            image_data
            image_mime_type
            logo_data
            logo_mime_type
          }
        }
      ''';

      final QueryOptions options = QueryOptions(
        document: gql(query),
        variables: {'eventName': eventName},
      );

      print('📡 Sending GraphQL query to: $apiUrl');
      print('📝 Query variables: eventName = "$eventName"');

      final QueryResult result = await client.query(options);

      print('📥 GraphQL result received');
      print('   Has exception: ${result.hasException}');
      print('   Data: ${result.data}');

      if (result.hasException) {
        print('❌ GraphQL error querying event: ${result.exception}');
        print('   Exception details: ${result.exception.toString()}');
        return null;
      }

      // Extract event data from response
      final eventData = result.data?['eventByName'] as Map<String, dynamic>?;

      print('🔍 Extracted eventData: $eventData');

      if (eventData == null) {
        print('❌ No event found with name: $eventName');
        print('   Full response data: ${result.data}');
        return null;
      }

      print('✅ Event data fetched successfully via GraphQL API');
      print(
        '   Image data length: ${(eventData['image_data'] as String?)?.length ?? 0}',
      );
      print('   Image MIME type: ${eventData['image_mime_type']}');
      return eventData;
    } catch (e) {
      print('❌ Error querying event data: $e');
      return null;
    }
  }

  /// Query setup metadata for a specific team + event pair.
  static Future<Map<String, dynamic>?> queryTeamSetupConfig({
    required String apiUrl,
    required String eventName,
    required String teamName,
  }) async {
    try {
      final client = _buildClient(apiUrl);

      const String query = r'''
        query TeamSetupConfig($eventName: String!, $teamName: String!) {
          teamSetupConfig(event_name: $eventName, team_name: $teamName) {
            team_name
            event_name
            timeframe_start
            timeframe_end
            event_expiration_date
            timezone
            image_data
            image_mime_type
            logo_data
            logo_mime_type
            organization_name
          }
        }
      ''';

      final QueryOptions options = QueryOptions(
        document: gql(query),
        variables: {'eventName': eventName, 'teamName': teamName},
      );

      final QueryResult result = await client.query(options);
      if (result.hasException) {
        print(
          '❌ GraphQL error querying team setup config: ${result.exception}',
        );
        return null;
      }

      return result.data?['teamSetupConfig'] as Map<String, dynamic>?;
    } catch (e) {
      print('❌ Error querying team setup config: $e');
      return null;
    }
  }

  /// Set team activation status by event and team names.
  static Future<bool> setTeamActivated({
    required String apiUrl,
    required String eventName,
    required String teamName,
    bool activated = true,
  }) async {
    try {
      final client = _buildClient(apiUrl);

      const String mutation = r'''
        mutation SetTeamActivated($eventName: String!, $teamName: String!, $activated: Boolean) {
          setTeamActivated(event_name: $eventName, team_name: $teamName, activated: $activated) {
            id
            name
            activated
          }
        }
      ''';

      final MutationOptions options = MutationOptions(
        document: gql(mutation),
        variables: {
          'eventName': eventName,
          'teamName': teamName,
          'activated': activated,
        },
      );

      final QueryResult result = await client.mutate(options);
      if (result.hasException) {
        print('❌ GraphQL error setting team activation: ${result.exception}');
        return false;
      }

      return result.data?['setTeamActivated'] != null;
    } catch (e) {
      print('❌ Error setting team activation: $e');
      return false;
    }
  }
}
