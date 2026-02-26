import 'package:graphql_flutter/graphql_flutter.dart';

/// Service for fetching event data via GraphQL API
class EventService {
  /// Query event details including images by event name
  /// Returns event data with image_data and image_mime_type fields
  static Future<Map<String, dynamic>?> queryEventByName({
    required String apiUrl,
    required String eventName,
  }) async {
    try {
      // Create GraphQL client
      final httpLink = HttpLink(apiUrl);
      final client = GraphQLClient(
        link: httpLink,
        cache: GraphQLCache(store: InMemoryStore()),
      );

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

      final QueryResult result = await client.query(options);

      if (result.hasException) {
        print('❌ GraphQL error querying event: ${result.exception}');
        return null;
      }

      // Extract event data from response
      final eventData = result.data?['eventByName'] as Map<String, dynamic>?;
      if (eventData == null) {
        print('❌ No event found with name: $eventName');
        return null;
      }

      print('✅ Event data fetched successfully via GraphQL API');
      return eventData;
    } catch (e) {
      print('❌ Error querying event data: $e');
      return null;
    }
  }
}
