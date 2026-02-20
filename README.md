# WanderWith

Modern group travel planner built with Flutter and Supabase.

## Requirements

- Flutter 3.19+
- Dart 3.1+
- Supabase project with Postgres functions from the `/sql` directory

## Environment Configuration

Runtime secrets live in `.env` (ignored) or `.env.local`. Copy `.env.example` and fill in the values, or supply them via `--dart-define`. The app expects the following keys:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `GOOGLE_WEB_CLIENT_ID`
- `GEMINI_API_KEY`

### Option A: `.env` (ignored) or `.env.local`

1. Duplicate `.env.example` into `.env` or `.env.local`.
2. Supply your Supabase, Google, and Gemini credentials.
3. Keep these files out of version control (already ignored).

### Option B: `--dart-define`

```
flutter run \
	--dart-define=SUPABASE_URL=https://your-project.supabase.co \
	--dart-define=SUPABASE_ANON_KEY=your-anon-key \
	--dart-define=GOOGLE_WEB_CLIENT_ID=your-web-client-id
```

The same flags work for release bundles if you prefer not to use an `.env` file.

## Database Setup

Run the consolidated schema script in `sql/production_schema.sql` against your Supabase instance to set up all tables, RLS policies, functions, and triggers. Historical migrations are archived in `sql/legacy/`.

## Google Play Upload

1. Bump `version` in `pubspec.yaml`.
2. Build the AAB with the dart-define flags above.
3. Sign with the release keystore (`android/keystore/` is ignored by git).
4. Upload `build/app/outputs/bundle/release/app-release.aab` to the Play Console.

## Tests

Run the widget tests:

```
flutter test
```
