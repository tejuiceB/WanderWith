# WanderWith

WanderWith is a modern group travel planner that combines social planning, shared itineraries, and AI-assisted trip intelligence. The app is built in Flutter with Supabase as the backend and includes offline-first caching for key flows.

## Product Overview
- Group trip planning with shared itineraries and day-by-day schedules.
- Trip chat with media sharing, mentions, and realtime updates.
- AI-assisted trip summaries and suggestions (Gemini).
- Social feed and profiles with privacy controls.
- Offline-first caching for trips and chat.

## Developer Overview
### Tech Stack
- Flutter (UI, routing, state management)
- Supabase (Auth, Postgres, Storage, Realtime)
- Isar (local cache + offline queue)
- Google Maps and Places (itinerary and location features)
- Gemini API (AI trip summaries and suggestions)

### Architecture Highlights
- Routing: `go_router` in [lib/main.dart](lib/main.dart)
- Auth state + profile loading: [lib/services/auth_service.dart](lib/services/auth_service.dart)
- Offline cache: [lib/local/local_db.dart](lib/local/local_db.dart)
- Trips core domain: [lib/services/trip_service.dart](lib/services/trip_service.dart)
- Notifications: [lib/services/notification_service.dart](lib/services/notification_service.dart)
- AI features: [lib/services/gemini_service.dart](lib/services/gemini_service.dart)
- Plan orchestration: [lib/providers/plan_provider.dart](lib/providers/plan_provider.dart)

### App Flow (High Level)
1. App bootstrap initializes env, local DB, network monitor, and Supabase.
2. Auth determines route (login, onboarding, or main app).
3. Trips and chat load from Supabase with local caching and offline queueing.
4. AI services augment trip planning and chat features.

## Requirements
- Flutter 3.19+
- Dart 3.1+
- Supabase project configured with SQL from the `sql/` directory

## Environment Configuration
Runtime secrets live in `.env` (ignored) or `.env.local`. Copy `.env.example` and fill in values, or supply them via `--dart-define`.

Required keys:
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `GOOGLE_WEB_CLIENT_ID`
- `GEMINI_API_KEY`

### Option A: `.env` (ignored) or `.env.local`
1. Duplicate `.env.example` into `.env` or `.env.local`.
2. Add Supabase, Google, and Gemini credentials.
3. Keep these files out of version control.

### Option B: `--dart-define`
```
flutter run \
	--dart-define=SUPABASE_URL=https://your-project.supabase.co \
	--dart-define=SUPABASE_ANON_KEY=your-anon-key \
	--dart-define=GOOGLE_WEB_CLIENT_ID=your-web-client-id \
	--dart-define=GEMINI_API_KEY=your-gemini-key
```

## Database Setup (Supabase)
1. Create a Supabase project.
2. SQL scripts have been archived under `archive/sql/`.
3. Apply the required schema/migration files from that folder to create tables, policies, functions, and triggers.
4. Configure Storage buckets for trip photos and uploads.

If you use a consolidated schema file, run it once against your Supabase instance.

## Local Development
Install dependencies:
```
flutter pub get
```

Run the app:
```
flutter run
```

Run tests:
```
flutter test
```

## Build and Release
### Android (Play Store)
1. Update `version` in [pubspec.yaml](pubspec.yaml).
2. Build the release AAB:
```
flutter build appbundle --release \
	--dart-define=SUPABASE_URL=... \
	--dart-define=SUPABASE_ANON_KEY=... \
	--dart-define=GOOGLE_WEB_CLIENT_ID=... \
	--dart-define=GEMINI_API_KEY=...
```
3. Sign with the release keystore.
4. Upload `build/app/outputs/bundle/release/app-release.aab` to Play Console.

### iOS
Use Xcode to archive and upload after configuring signing.

### Web
```
flutter build web --release \
	--dart-define=SUPABASE_URL=... \
	--dart-define=SUPABASE_ANON_KEY=... \
	--dart-define=GOOGLE_WEB_CLIENT_ID=... \
	--dart-define=GEMINI_API_KEY=...
```

## Offline Support
- Cached trips, chat, and some assets are stored in Isar.
- Pending actions are queued and synced when back online.
- Network monitoring triggers background sync.

## Notifications
- Local notifications are used for trip and social events.
- Supabase realtime channels deliver notification inserts.

## Screenshots and Recording
I cannot capture screenshots or screen recordings directly. Please provide assets or follow the steps below:

### Screenshots
- Capture 4-6 key screens: Home feed, Trip dashboard, Plan tab, Chat, Profile, Settings.
- Save in `assets/screenshots/` and update this section with paths.

### Short Recording
- Record a 20-40 second walkthrough (home -> trip -> plan -> chat).
- Upload to a shareable link or store under `assets/recordings/` if size allows.

## Troubleshooting
- If Supabase init fails while offline, the app will still start but network features will be limited.
- If auth redirects loop, verify `SUPABASE_URL` and `SUPABASE_ANON_KEY` are correct.
- If Google sign-in fails, confirm the Web Client ID and SHA keys are registered.

## Contributing
- Use feature branches.
- Keep PRs small and link to issues.
- Update README if you change setup or build steps.
