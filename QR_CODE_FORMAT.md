# QR Code Format for Setup

The QR code should contain a JSON object with the following fields:

## JSON Structure

```json
{
  "teamName": "Team Alpha",
  "event": "Competition 2026",
  "apiUrl": "https://your-project.vercel.app/api",
  "expirationDate": 1767225599000,
  "timezone": "Europe/Helsinki"
}
```

## Field Descriptions

- **teamName** (required): The name of your team
- **event** (required): The event name
- **apiUrl** (required): The GraphQL API endpoint URL (e.g., "https://your-project.vercel.app/api")
- **expirationDate** (required): The date when the configuration expires as Unix timestamp in milliseconds (e.g., 1767225599000 for 2026-03-01 23:59:59)
- **timezone** (required): The timezone for the event (e.g., "UTC", "Europe/Helsinki", "America/New_York")
