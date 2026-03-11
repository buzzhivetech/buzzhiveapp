# BuzzHive iOS App

Flutter iOS app: Supabase auth, Firebase sensor data, dashboard parity.

## Structure

- **core/** – config (env, Firebase options), errors, router, theme, utils
- **models/** – SensorReading, Sensor, Profile, UserSensorLink
- **repositories/** – auth, profile, sensor_link, sensor_data (Supabase + Firebase)
- **services/** – Supabase and Firebase init
- **providers/** – Riverpod (auth, profile, linked sensors, readings)
- **features/** – auth, dashboard, analytics, sensors, map, alerts, settings

## Environment

1. Copy `.env.example` to `.env` and set values (or use dart-define).
2. Run with defines (example):

```bash
flutter run --dart-define=SUPABASE_URL=your-url --dart-define=SUPABASE_ANON_KEY=your-key
```

For Firebase, set `FIREBASE_*` or run `flutterfire configure` and use the generated `lib/firebase_options.dart` (then use that in `lib/core/config/firebase_options.dart` or import it from `main.dart`).

## Setup

1. Ensure Flutter SDK is installed.
2. From project root: `flutter pub get`
3. If platform folders (ios/, etc.) are missing: `flutter create . --org com.buzzhive --project-name buzzhive_app --platforms ios`
4. Run: `flutter run` (with env defines or .env as above)

## Architecture

- **Auth & user data**: Supabase (supabase_flutter)
- **Sensor data**: Firebase Realtime Database (read-only)
- **State**: Riverpod
- **Navigation**: go_router
