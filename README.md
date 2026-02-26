# location_share_android

Android app for team-based location sharing during events.

## Features

- ✅ QR code-based setup for quick configuration
- ✅ Background location tracking with foreground service
- ✅ GraphQL API integration for location data and event images
- ✅ Base64 image loading from database (no external URLs required)
- ✅ Multilingual support (English UK, Finnish)
- ✅ Timezone-aware location timestamps
- ✅ Automatic configuration expiration
- ✅ Dark/Light mode support
- ✅ Material Design 3 UI

## Architecture

The app uses a GraphQL API for both location updates and event data:

- **Location Tracking**: Uploads GPS coordinates via `createLocationUpdate` mutation
- **Event Images**: Fetches event images via `eventByName` query on setup
- **Image Storage**: Images stored as base64 data in memory (no network requests during runtime)

### Data Flow

1. **Setup**: User scans QR code with team name, event name, API URL
2. **Image Fetch**: App queries GraphQL API to fetch event images (base64 data)
3. **Storage**: Images decoded and stored in SharedPreferences
4. **Display**: Images rendered from memory using `Image.memory()`
5. **Tracking**: Background service uploads location to API

## Setup

1. **Set up PostgreSQL database** (see [location_tracker_api](../location_tracker_api/README.md))

2. **Generate QR code** with configuration:
```json
{
  "teamName": "Team Alpha",
  "event": "Event name",
  "apiUrl": "https://your-project.vercel.app/api",
  "imageUrl": "data:image/png;base64,..." (optional, for backward compatibility),
  "expirationDate": "2027-03-01",
  "timezone": "Europe/Helsinki"
}
```

**Note**: `imageUrl` in QR code is optional. Images are fetched from the GraphQL API automatically.

## Roadmap

- testing with OP8T (Android 14)
  - battery consumption
