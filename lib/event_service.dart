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
}
