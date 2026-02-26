# location_share_android

Android app for team-based location sharing during events.

## Features

- ✅ QR code-based setup for quick configuration
- ✅ Background location tracking with foreground service
- ✅ Database storage for location data via GraphQL API
- ✅ Multilingual support (English UK, Finnish)
- ✅ Timezone-aware location timestamps
- ✅ Automatic configuration expiration
- ✅ Dark/Light mode support
- ✅ Material Design 3 UI

## Setup

1. **Set up PostgreSQL database**

2. **Generate QR code** with database configuration:
```json
{
  "teamName": "Team Alpha",
  "event": "Event name",
  "apiUrl": "api-url.for.gql/api",
  "imageUrl": "https://example.com/image.png",
  "expirationDate": "2027-03-01",
  "timezone": "Europe/Helsinki"
}
```

## Roadmap

- testing with OP8T (Android 14)
  - battery consumption
