# Service and Repository Architecture

This document defines how the Flutter app talks to **Firebase** and **Supabase** without mixing the two backends. It covers the service layer, repository layer, file layout, Riverpod usage, and how the dashboard gets sensor data for the logged-in user.

---

## Architectural Rules

1. **Firebase and Supabase are never mixed in the same service class.** Each backend has its own service(s).
2. **Each backend has its own service layer.** Services wrap SDK calls and hide backend-specific details.
3. **Repositories sit above services** and expose domain operations and models. UI (and providers) use only repositories, not services or SDKs directly.
4. **Firebase is read-only** in the app: sensor data only. No auth, no user data.
5. **Supabase handles** auth and all user/account data (profiles, sensors table, user–sensor links).

---

## 1. Service Layer

**Role:** Wrap one backend’s SDK. Services do low-level operations (e.g. “get DB ref”, “listen at path”, “sign in”) and return raw or lightly shaped data. They do **not** define app-wide domain models; that’s the repository’s job.

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
  - User–sensor links: list links for user, add link, remove link.
- **Uses:** `Supabase.instance.client.from('profiles'|'sensors'|'user_sensor_links')` and RPC if needed.
- **Does not:** Touch Firebase or auth (beyond using the same Supabase client that auth uses).

Keeping auth and user data in **separate services** (auth vs user_data) keeps a single backend (Supabase) but clear separation of concerns.

### 1.2 Firebase Service

**File: `lib/services/firebase/firebase_sensor_data_service.dart`**

- **Responsibility:** Read-only access to sensor data in Firebase Realtime Database.
- **Operations:**
  - Get a `DatabaseReference` for a path (e.g. `sensor_data/{firebase_sensor_id}`).
  - Stream child events (e.g. `onChildAdded` / `onValue` for latest or all children under a sensor).
  - One-off read (e.g. `once`) for a path (for analytics range queries).
- **Uses:** `FirebaseDatabase.instance.ref(...)` only.
- **Does not:** Write data, touch Supabase, or know about “users” or “linked sensors”; it only knows paths and keys.

---

## 2. Repository Layer

**Role:** Provide app-facing, domain-oriented API. Repositories use **one or more services** (or a single backend’s service), map results to **domain models** (e.g. `Sensor`, `SensorReading`, `Profile`), and throw **domain exceptions** (e.g. `AuthException`, `NotFoundException`). The UI and state layer (Riverpod) depend only on repositories.

- **One repository per cohesive domain area.** A repository may use one or two services from the **same** backend; it must never use both Firebase and Supabase in the same class.
- Repositories return domain types from `lib/models/` and throw types from `lib/core/errors/`.

### 2.1 Repositories That Use Supabase Only

**File: `lib/repositories/auth_repository.dart`**

- **Uses:** `SupabaseAuthService` only.
- **Exposes:** `signIn`, `signUp`, `signOut`, `currentSession`, `authStateChanges`, `currentUserId`.
- **Returns/throws:** Domain auth concepts; maps Supabase auth errors to `AuthException` (or similar).

**File: `lib/repositories/profile_repository.dart`**

- **Uses:** `SupabaseUserDataService` only (profiles table).
- **Exposes:** `getProfile(userId)`, `updateProfile(userId, { displayName, avatarUrl })`.
- **Returns:** `Profile` model; throws domain exceptions on failure.

**File: `lib/repositories/sensor_link_repository.dart`**

- **Uses:** `SupabaseUserDataService` only (sensors + user_sensor_links).
- **Exposes:** `getLinkedSensors(userId)`, `linkSensor(userId, firebaseSensorId, { displayName })`, `unlinkSensor(userId, sensorId)`.
- **Returns:** `List<UserSensorLink>`, `Sensor`; throws domain exceptions. No Firebase calls.

### 2.2 Repository That Uses Firebase Only

**File: `lib/repositories/sensor_data_repository.dart`**

- **Uses:** `FirebaseSensorDataService` only.
- **Exposes:**
  - `streamLatestReadings(List<String> firebaseSensorIds)` → `Stream<Map<String, SensorReading?>>` (key = firebase_sensor_id).
  - `getReadingsInRange(firebaseSensorId, startMs, endMs)` → `Future<List<SensorReading>>` for analytics.
- **Returns:** `SensorReading` (and collections); parses Firebase snapshot/maps into domain model; throws `FirebaseReadException` (or similar). No Supabase calls.

---

## 3. File Structure

```
lib/
├── core/
│   ├── config/
│   ├── errors/
│   ├── router/
│   ├── theme/
│   └── utils/
├── models/
│   ├── profile.dart
│   ├── sensor.dart
│   ├── sensor_reading.dart
│   └── user_sensor_link.dart
├── services/
│   ├── supabase/
│   │   ├── supabase_auth_service.dart      # Auth only
│   │   └── supabase_user_data_service.dart # Profiles, sensors, user_sensor_links
│   └── firebase/
│       └── firebase_sensor_data_service.dart  # Read-only sensor data
├── repositories/
│   ├── auth_repository.dart               # → SupabaseAuthService
│   ├── profile_repository.dart            # → SupabaseUserDataService
│   ├── sensor_link_repository.dart        # → SupabaseUserDataService
│   └── sensor_data_repository.dart        # → FirebaseSensorDataService
├── providers/
│   ├── auth_provider.dart
│   ├── profile_provider.dart
│   ├── linked_sensors_provider.dart
│   └── sensor_readings_provider.dart
├── features/
│   └── ...
├── app.dart
└── main.dart
```

**Summary**

- **Services:** 3 files — 2 Supabase (auth, user_data), 1 Firebase (sensor_data). No file imports both Firebase and Supabase.
- **Repositories:** 4 files — 3 Supabase-backed (auth, profile, sensor_link), 1 Firebase-backed (sensor_data). Each repository uses only one backend’s service(s).

---

## 4. Riverpod: Exposing Services and Repositories

- **Services** are provided as low-level dependencies, typically with `Provider` (or `Provider` + override in tests).
  - Example: `supabaseAuthServiceProvider`, `supabaseUserDataServiceProvider`, `firebaseSensorDataServiceProvider`.
- **Repositories** are provided and depend on the appropriate service(s).
  - Example: `authRepositoryProvider` depends on `supabaseAuthServiceProvider`; `sensorDataRepositoryProvider` depends on `firebaseSensorDataServiceProvider`.
- **Feature and app state** should depend on **repositories**, not on services.
  - Example: `authStateProvider` uses `authRepositoryProvider`; `linkedSensorsProvider` uses `sensorLinkRepositoryProvider`; `latestReadingsProvider` uses `sensorDataRepositoryProvider` (and `linkedSensorsProvider` for the list of IDs).

**Dependency direction:**  
UI / features → providers (state) → repositories → services → SDKs (Supabase / Firebase).

---

## 5. How the Dashboard Gets Sensor Data for the Logged-In User

Flow:

1. **Auth (Supabase)**  
   `authStateProvider` / `currentUserIdProvider` use `auth_repository` (backed by `SupabaseAuthService`). When the user is logged in, `currentUserId` is available.

2. **Linked sensors (Supabase)**  
   `linkedSensorsProvider` uses `sensor_link_repository` (backed by `SupabaseUserDataService`) to load `getLinkedSensors(userId)`. That returns a list of `UserSensorLink`, each containing a `Sensor` with `firebase_sensor_id`. So the app gets **only the Firebase sensor IDs that this user is allowed to see**.

3. **Sensor readings (Firebase)**  
   A provider (e.g. `latestReadingsProvider`) depends on `linkedSensorsProvider` and `sensor_data_repository`:
   - Reads the list of linked sensors and extracts `firebase_sensor_id` for each.
   - Calls `sensor_data_repository.streamLatestReadings(firebaseSensorIds)`.
   - The repository uses `FirebaseSensorDataService` to subscribe to `sensor_data/{id}/...` for each ID and parses snapshots into `SensorReading`.
   - The provider exposes a `Stream<Map<String, SensorReading?>>` (or similar) to the UI.

4. **Dashboard UI**  
   The dashboard screen watches:
   - `authStateProvider` / `currentUserIdProvider` for login state.
   - `linkedSensorsProvider` for “my sensors” (and labels).
   - `latestReadingsProvider` (or equivalent) for live readings keyed by `firebase_sensor_id`.

So: **Supabase** answers “who is logged in?” and “which sensor IDs belong to this user?”; **Firebase** answers “what are the latest (or historical) readings for these sensor IDs?”. No mixing: auth and links in Supabase, readings in Firebase, and the repository layer keeps the two backends behind separate abstractions.

---

## Summary Table

| Layer        | Firebase                          | Supabase                                      |
|-------------|------------------------------------|-----------------------------------------------|
| **Service** | `firebase_sensor_data_service`    | `supabase_auth_service`, `supabase_user_data_service` |
| **Repository** | `sensor_data_repository`      | `auth_repository`, `profile_repository`, `sensor_link_repository` |
| **Responsibility** | Read-only sensor data        | Auth; user accounts; user–sensor relationships |

No class in the service or repository layer touches both Firebase and Supabase.
