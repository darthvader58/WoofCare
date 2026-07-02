# WoofCare Server API

A Flask API that handles scraping and data management for the WoofCare application.

## Setup

1. **Install Python dependencies:**
   ```bash
   cd server
   pip install -r requirements.txt
   ```

2. **Get Firebase Service Account Key:**
   - Go to Firebase Console → Project Settings → Service Accounts
   - Click "Generate New Private Key"
   - Save the JSON file as `firebase-credentials.json` in the `server` directory

3. **Prepare Data Files:**
   - Ensure `org_data.json` is present in the `server` directory for location imports.

## Usage

### Run the API Server

```bash
python app.py
```
The server will start on `http://localhost:5000`.

### Endpoints

#### 1. Scrape Article
Scrapes an article from a URL and adds it to Firebase Firestore.

- **URL:** `/api/scrape-article`
- **Method:** `POST`
- **Body:**
  ```json
  {
    "url": "https://example.com/article",
    "category": "Guide",
    "author": "Voice of Stray Dogs"
  }
  ```
- **Response:** JSON with the created article ID and data.

#### 2. Scrape NGOs
Scrapes NGO information from a specified website.

- **URL:** `/api/scrape-ngos`
- **Method:** `GET`
- **Query Params:**
  - `url` (optional): URL to scrape (default: `https://makenewlife.in/`)
- **Response:** JSON list of NGOs with name, address, and contact info.

#### 3. Import Locations
Imports location data from `org_data.json` into Firebase Firestore.

- **URL:** `/api/import-locations`
- **Method:** `POST`
- **Response:** JSON with the count of imported locations.

## Health Check

- **URL:** `/health`
- **Method:** `GET`
- **Response:** `{"status": "ok", "firebase": true/false}`

## Legacy Scripts

You can still run the standalone scripts:

### Backfill Privacy Fields

After pulling the latest app changes, run this once so existing Firestore
documents include the same privacy fields that new app writes now create.

Preview changes:

```bash
python migrate_privacy_fields.py firebase-credentials.json
```

Apply changes:

```bash
python migrate_privacy_fields.py firebase-credentials.json --apply
```

This updates:

- `users/{uid}.shareProfile` to `true` when missing.
- `reports/{reportId}.isAnonymous` to `false` when missing.
- `reports/{reportId}.shareReporterPhone` to `false` when missing.
- `reports/{reportId}.reporterPhone` to `null` for anonymous or phone-private reports.
- `conversations/{conversationId}.requesterProfileShared` to `true` when missing.
- `conversations/{conversationId}.expiresAt` for anonymous report chats missing a 48-hour expiry.

### Article Scraper CLI


1. Edit `articles_config.json` with your article URLs:
   ```json
   [
     {
       "url": "https://example.com/article-url",
       "category": "Guide",
       "author": "Voice of Stray Dogs"
     }
   ]
   ```

2. Run the scraper:
   ```bash
   python article_scraper.py firebase-credentials.json articles_config.json
   ```

### Add Single Article

```bash
python article_scraper.py firebase-credentials.json --url <article-url> --category Guide
```

## Categories

- `Guide` - How-to guides and tips
- `Medical` - Health and medical information
- `Stories` - Inspirational stories

## What Gets Scraped

- Title
- Main content text
- Images (first image used as thumbnail)
- Publication date (if available)

## Adding New Sources

Simply add URLs to `articles_config.json`:

```json
[
  {
    "url": "https://newsite.com/article1",
    "category": "Medical",
    "author": "Voice of Stray Dogs"
  },
  {
    "url": "https://newsite.com/article2",
    "category": "Guide",
    "author": "Voice of Stray Dogs"
  }
]
```

Then run the scraper again to add new articles.

## Firestore Structure

Articles are stored with this structure:
```
articles/
  ├── {auto-generated-id}/
      ├── title: string
      ├── category: string (Guide/Medical/Stories)
      ├── author: string
      ├── date: timestamp
      ├── imageUrl: string
      ├── content: string
      └── sourceUrl: string
```

Privacy-aware app data uses these fields:

```
users/{uid}
  ├── shareProfile: boolean

reports/{reportId}
  ├── userID: string
  ├── reporterName: string
  ├── reporterEmail: string
  ├── isAnonymous: boolean
  ├── shareReporterPhone: boolean
  ├── reporterPhone: string | null
  ├── title: string
  ├── description: string
  ├── urgency: string
  └── timestamp: timestamp

conversations/{conversationId}
  ├── participants: string[]
  ├── isReportChat: boolean
  ├── reportId: string
  ├── anonymousReporter: boolean
  ├── reporterName: string
  ├── reporterDisplayName: string
  ├── requesterName: string
  ├── requesterDisplayName: string
  ├── requesterProfileShared: boolean
  └── expiresAt: timestamp only for anonymous report chats
```

## Deploying Firestore Rules

Deploy the security rules to Firebase:
```bash
firebase deploy --only firestore:rules
```

## Notes

- The scraper uses intelligent content extraction to find article text and images
- Images are automatically converted to absolute URLs
- Content is limited to 5000 characters to keep the database clean
- The app's frontend will automatically display new articles in real-time

# NGO Scraper

Scrapes NGO information from `https://makenewlife.in/` and saves it to a CSV file.

## Usage

```bash
python ngo_scraper.py
```

The script will generate `ngos_pune.csv` containing:
- NGO Name
- Address
- Contact
