# BuzzHive App

Flutter mobile app for monitoring BuzzHive sensors. Supabase for auth and user data, Firebase Realtime Database for live sensor readings.

## Prerequisites

- Flutter SDK >= 3.2.0
- A Supabase project with the schema applied (see [docs/SUPABASE_SETUP.md](docs/SUPABASE_SETUP.md))
- A Firebase project with Realtime Database enabled
- For Android: `android/app/google-services.json` (not committed; see `.gitignore`)
- For iOS: Firebase configured via `ios/GoogleService-Info.plist` or `firebase_options.dart`

## Quick Start

```bash
# 1. Install dependencies
flutter pub get

# 2. Create .env from example
cp .env.example .env
# Fill in real Supabase and Firebase values

# 3. Apply Supabase schema (see docs/SUPABASE_SETUP.md)
# Run the SQL migrations in your Supabase Dashboard → SQL Editor

# 4. Run the app
flutter run
```

Alternatively, pass config via `--dart-define`:

```bash
flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
```

## Environment

Config is loaded from `.env` (via flutter_dotenv), falling back to `--dart-define`.

| Variable | Required | Description |
|---|---|---|
| `APP_ENV` | No | `development` (default), `staging`, or `production` |
| `SUPABASE_URL` | Yes | Supabase project URL |
| `SUPABASE_ANON_KEY` | Yes | Supabase anon/public key |
| `FIREBASE_API_KEY` | Yes | Firebase API key (iOS) |
| `FIREBASE_APP_ID` | Yes | Firebase App ID (iOS) |
| `FIREBASE_APP_ID_ANDROID` | Android | Firebase App ID (Android) |
| `FIREBASE_API_KEY_ANDROID` | Android | Firebase API key (Android) |
| `FIREBASE_PROJECT_ID` | Yes | Firebase project ID |
| `FIREBASE_DATABASE_URL` | Yes | Firebase RTDB URL |

See `.env.example` for all variables.

## Running Tests

```bash
flutter test
```

Tests use `mocktail` for mocking services. Test coverage includes:

- **Models**: `SensorReading`, `Profile`, `Sensor` parsing
- **Repositories**: Auth, profile, sensor link, sensor data (with mocked services)
- **Utilities**: AppLogger

## Project Structure

```
lib/
├── main.dart                         # Entry point
├── app.dart                          # MaterialApp with router and theme
├── core/
│   ├── config/
│   │   ├── env.dart                  # Environment variables (APP_ENV, Supabase, Firebase)
│   │   └── firebase_options.dart     # Platform-aware Firebase options from .env
│   ├── constants/app_constants.dart
│   ├── errors/
│   │   ├── app_exception.dart        # Domain exception hierarchy
│   │   ├── error_handler.dart        # Maps errors → user-facing Failure
│   │   ├── failure.dart              # UI-facing error model
│   │   └── provider_logger.dart      # Riverpod ProviderObserver for error logging
│   ├── router/
│   │   ├── app_router.dart           # go_router config with auth redirect
│   │   ├── main_shell.dart           # Bottom navigation shell
│   │   └── routes.dart               # Route path constants
│   ├── theme/app_theme.dart
│   ├── utils/
│   │   ├── app_logger.dart           # Structured logging (dart:developer)
│   │   └── extensions.dart
│   └── widgets/
│       ├── async_value_widget.dart    # Generic AsyncValue → loading/error/data
│       ├── error_display.dart         # Reusable error + retry widget
│       └── loading_indicator.dart     # Centered spinner with optional message
├── models/
│   ├── profile.dart
│   ├── sensor.dart
│   ├── sensor_reading.dart
│   └── user_sensor_link.dart
├── providers/                        # Riverpod providers
│   ├── auth_provider.dart
│   ├── linked_sensors_provider.dart
│   ├── profile_provider.dart
│   ├── sensor_readings_provider.dart
│   └── service_providers.dart
├── repositories/                     # Domain logic, error mapping
│   ├── auth_repository.dart          # Supabase auth
│   ├── profile_repository.dart       # Supabase profiles
│   ├── sensor_data_repository.dart   # Firebase sensor readings
│   └── sensor_link_repository.dart   # Supabase sensor linking
├── services/                         # SDK wrappers (no cross-backend)
│   ├── firebase/firebase_sensor_data_service.dart
│   ├── firebase_service.dart         # Firebase init
│   ├── supabase/supabase_auth_service.dart
│   ├── supabase/supabase_user_data_service.dart
│   └── supabase_service.dart         # Supabase init
└── features/
    ├── auth/presentation/            # Login, register screens
    ├── dashboard/presentation/       # Dashboard with sensor reading cards
    ├── sensors/presentation/         # My Sensors, Add Sensor screens
    ├── settings/presentation/        # Account screen (profile, unlink, logout)
    ├── analytics/presentation/
    ├── alerts/presentation/
    └── map/presentation/
```

## Architecture

- **Services** wrap SDK calls (Supabase or Firebase, never both in one file)
- **Repositories** use one service each, map SDK errors to domain `AppException` subclasses, and log via `AppLogger`
- **Providers** (Riverpod) wire repositories and expose state to the UI
- **Widgets** use `AsyncValueWidget` for consistent loading/error/data handling
- **Error handling** flows through `ErrorHandler.handle()` which logs and returns `Failure`
- **Logging** uses `dart:developer` via `AppLogger` (debug/info/warn/error); suppressed in release builds

See [docs/ARCHITECTURE_SERVICES_AND_REPOSITORIES.md](docs/ARCHITECTURE_SERVICES_AND_REPOSITORIES.md) for details.
