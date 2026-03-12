# Service and Repository Architecture

This document defines how the Flutter app talks to **Firebase** and **Supabase** without mixing the two backends. It covers the service layer, repository layer, error handling, logging, file layout, Riverpod usage, and how the dashboard gets sensor data for the logged-in user.

---

## Architectural Rules

1. **Firebase and Supabase are never mixed in the same service class.** Each backend has its own service(s).
2. **Each backend has its own service layer.** Services wrap SDK calls and hide backend-specific details.
3. **Repositories sit above services** and expose domain operations and models. UI (and providers) use only repositories, not services or SDKs directly.
4. **Firebase is read-only** in the app: sensor data only. No auth, no user data.
5. **Supabase handles** auth and all user/account data (profiles, sensors table, user-sensor links).

---

## 1. Service Layer

**Role:** Wrap one backend's SDK. Services do low-level operations (e.g. "get DB ref", "listen at path", "sign in") and return raw or lightly shaped data. They do **not** define app-wide domain models; that's the repository's job.

- **One backend per service (or per group of related services).** No class should import both `firebase_*` and `supabase_flutter`.
- Services are **injectable** (e.g. via Riverpod) so repositories can depend on them and tests can replace them.

### 1.1 Supabase Services

**File: `lib/services/supabase/supabase_auth_service.dart`**

- **Responsibility:** Authentication only.
- **Operations:** Sign in, sign up, sign out, current session, auth state stream.
- **Uses:** `Supabase.instance.client.auth` only.
- **Does not:** Touch Firebase, profiles, or sensor links.

**File: `lib/services/supabase/supabase_user_data_service.dart`**

- **Responsibility:** All non-auth Supabase data (Postgres).
- **Operations:**
  - Profiles: get/update profile by user id.
  - Sensors: get by id, upsert by `firebase_sensor_id`.
  - User-sensor links: list links for user, add link, remove link.
- **Uses:** `Supabase.instance.client.from('profiles'|'sensors'|'user_sensor_links')` and RPC if needed.
- **Does not:** Touch Firebase or auth (beyond using the same Supabase client that auth uses).

### 1.2 Firebase Service

**File: `lib/services/firebase/firebase_sensor_data_service.dart`**

- **Responsibility:** Read-only access to sensor data in Firebase Realtime Database.
- **Operations:**
  - Get a `DatabaseReference` for a path (e.g. `sensor_data/{firebase_sensor_id}`).
  - Stream child events (e.g. `onChildAdded` / `onValue` for latest or all children under a sensor).
  - One-off read (e.g. `once`) for a path (for analytics range queries).
- **Uses:** `FirebaseDatabase.instance.ref(...)` only.
- **Does not:** Write data, touch Supabase, or know about "users" or "linked sensors"; it only knows paths and keys.

---

## 2. Repository Layer

**Role:** Provide app-facing, domain-oriented API. Repositories use **one or more services** (or a single backend's service), map results to **domain models** (e.g. `Sensor`, `SensorReading`, `Profile`), and throw **domain exceptions** (e.g. `AuthException`, `NotFoundException`). The UI and state layer (Riverpod) depend only on repositories.

- **One repository per cohesive domain area.** A repository may use one or two services from the **same** backend; it must never use both Firebase and Supabase in the same class.
- Repositories return domain types from `lib/models/` and throw types from `lib/core/errors/`.

### 2.1 Repositories That Use Supabase Only

**`lib/repositories/auth_repository.dart`** - Uses `SupabaseAuthService`. Exposes sign in/up/out, auth state stream. Maps Supabase `AuthException` to domain `AuthException`.

**`lib/repositories/profile_repository.dart`** - Uses `SupabaseUserDataService`. Exposes `getProfile`, `updateProfile`. Returns `Profile` model.

**`lib/repositories/sensor_link_repository.dart`** - Uses `SupabaseUserDataService`. Exposes `getLinkedSensors`, `linkSensor`, `unlinkSensor`. Returns `UserSensorLink`/`Sensor` models. Duplicate link (23505) becomes `ValidationException`.

### 2.2 Repository That Uses Firebase Only

**`lib/repositories/sensor_data_repository.dart`** - Uses `FirebaseSensorDataService`. Exposes `sensorExists`, `streamLatestReadings`, `getReadingsInRange`. Supports both nested (`{nodeId}/{timestamp}/data`) and flat (`{pushKey}/data`) Firebase structures. Returns `SensorReading` model; throws `FirebaseReadException`.

---

## 3. Error Handling

Errors flow through three layers:

1. **Services** throw SDK exceptions (e.g. `PostgrestException`, `AuthException`).
2. **Repositories** catch those and rethrow as domain exceptions from `lib/core/errors/app_exception.dart`:
   - `AuthException` - auth failures
   - `ValidationException` - input or constraint violations
   - `NotFoundException` - missing resources
   - `NetworkException` - connectivity issues
   - `FirebaseReadException` - Firebase read failures
   - `AppException` - general fallback
3. **ErrorHandler** (`lib/core/errors/error_handler.dart`) maps any error to a user-facing `Failure(message, code, recoverable)` and logs it via `AppLogger`.
4. **UI** uses `ErrorDisplay` widget or `AsyncValueWidget` which calls `ErrorHandler.userMessage(error)` automatically.

The `AppProviderObserver` (`lib/core/errors/provider_logger.dart`) is wired into `ProviderScope` and logs any provider failures.

---

## 4. Logging

**`lib/core/utils/app_logger.dart`** provides `debug`, `info`, `warn`, `error` methods using `dart:developer` `log()`.

- Named loggers per module: `AppLogger.info('message', name: 'Auth')`.
- In release builds (`dart.vm.product`), debug and info are suppressed; only warn and error are emitted.
- Used in: `main.dart` (init), services (init success/skip), all repositories (errors, lifecycle), `ErrorHandler`, `AppProviderObserver`.

---

## 5. Loading States

Reusable widgets in `lib/core/widgets/`:

- **`AsyncValueWidget<T>`** - Generic wrapper for Riverpod `AsyncValue.when()`. Shows `LoadingIndicator` for loading, `ErrorDisplay` for errors, and calls the data builder for data.
- **`LoadingIndicator`** - Centered spinner with optional message.
- **`ErrorDisplay`** - Error icon, user message (via `ErrorHandler`), optional retry button. Supports compact mode for inline use.

---

## 6. Environment Configuration

**`lib/core/config/env.dart`** loads values from `.env` (flutter_dotenv) with `--dart-define` fallback.

- `APP_ENV` - `development` (default), `staging`, or `production`.
- `Env.isDevelopment`, `Env.isStaging`, `Env.isProduction` - convenience getters.
- `Env.supabaseUrl`, `Env.supabaseAnonKey` - required for Supabase.
- Firebase keys are in `firebase_options.dart` with platform-aware Android/iOS selection.
- `.env.example` contains all variables with placeholder values.

---

## 7. Riverpod: Exposing Services and Repositories

- **Services** are provided as low-level dependencies with `Provider`.
  - `supabaseAuthServiceProvider`, `supabaseUserDataServiceProvider`, `firebaseSensorDataServiceProvider`.
- **Repositories** depend on the appropriate service(s).
  - `authRepositoryProvider`, `profileRepositoryProvider`, `sensorLinkRepositoryProvider`, `sensorDataRepositoryProvider`.
- **Feature providers** depend on **repositories**, not services.
  - `authStateProvider`, `linkedSensorsProvider`, `latestReadingsProvider`, `profileProvider`.

**Dependency direction:**
UI / features -> providers (state) -> repositories -> services -> SDKs (Supabase / Firebase).

---

## 8. How the Dashboard Gets Sensor Data

1. **Auth (Supabase)**: `authStateProvider` / `currentUserIdProvider` expose the logged-in user.
2. **Linked sensors (Supabase)**: `linkedSensorsProvider` loads `getLinkedSensors(userId)` returning `UserSensorLink` list with `firebase_sensor_id` per sensor.
3. **Sensor readings (Firebase)**: `latestReadingsProvider` extracts IDs from linked sensors and calls `streamLatestReadings(ids)`. The repository subscribes to `sensor_data/{id}` for each ID and parses snapshots into `SensorReading`.
4. **Dashboard UI**: Watches both providers; uses `AsyncValueWidget` for loading/error/data states.

**Supabase** answers "who is logged in?" and "which sensors belong to this user?"; **Firebase** answers "what are the readings for these sensors?". The repository layer keeps them behind separate abstractions.

---

## Summary Table

| Layer | Firebase | Supabase |
|---|---|---|
| **Service** | `firebase_sensor_data_service` | `supabase_auth_service`, `supabase_user_data_service` |
| **Repository** | `sensor_data_repository` | `auth_repository`, `profile_repository`, `sensor_link_repository` |
| **Responsibility** | Read-only sensor data | Auth; user accounts; user-sensor relationships |

No class in the service or repository layer touches both Firebase and Supabase.
