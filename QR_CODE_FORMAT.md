# QR Code Format for Setup

The QR code should contain a JSON object with the following fields:

## JSON Structure

```json
{
  "teamName": "Team Alpha",
  "event": "Competition 2026",
  "apiUrl": "https://your-project.vercel.app/api",
  "imageUrl": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAUA...",
  "expirationDate": "2026-03-01",
  "timezone": "Europe/Helsinki"
}
```

## Field Descriptions

- **teamName** (required): The name of your team
- **event** (required): The event name
- **apiUrl** (required): The GraphQL API endpoint URL (e.g., "https://your-project.vercel.app/api")
- **imageUrl** (required): The image to display on the sharing page. Can be either:
  - A data URI (e.g., "data:image/png;base64,..." or "data:image/jpeg;base64,...")
  - A valid HTTP/HTTPS URL (e.g., "https://example.com/image.png")
- **expirationDate** (required): The date when the configuration expires in ISO 8601 format (YYYY-MM-DD)
- **timezone** (required): The timezone for the event (e.g., "UTC", "Europe/Helsinki", "America/New_York")
