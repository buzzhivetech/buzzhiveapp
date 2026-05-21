# BuzzHive App — Intern Onboarding Guide

This document orients a new developer to the **buzzhiveapp** Flutter mobile repo: what each part does, how Firebase and Supabase fit together, current project status, and what is still left to build.

**Related repos** (same parent folder `BuzzHive/`, not submodules of buzzhiveapp):

| Repo | Role |
|------|------|
| **buzzhiveapp** (this repo) | Flutter mobile app — auth, sensor linking, live readings, BLE offline sync, receiver provisioning |
| **buzzhivedash** | Web dashboard, **Firebase RTDB security rules** (`database.rules.json`), Cloud Functions for ML/analysis pipeline |
| **Buzzhive-V0** | ESP32 receiver + sensor firmware (Arduino), BLE provisioning protocol |

---

## 1. Architecture at a glance

BuzzHive uses a **split backend** on purpose:

```
┌─────────────────────────────────────────────────────────────────┐
│                     Flutter app (buzzhiveapp)                    │
├──────────────────────────────┬──────────────────────────────────┤
│         Supabase             │           Firebase                │
│  • Email/password auth       │  • Realtime Database (RTDB)     │
│  • profiles                  │  • Sensor readings (read +      │
│  • sensors (metadata)        │    selective write from app)    │
│  • user_sensor_links         │  • receiver_connections         │
│  • delete_user_account RPC   │  • Anonymous Auth (ID token     │
│                              │    for receiver provisioning)   │
└──────────────────────────────┴──────────────────────────────────┘
         ▲                                    ▲
         │                                    │
    Beekeeper account                    Live telemetry + devices
```

**Rules the codebase enforces:**

- Never mix Firebase and Supabase in the same service class.
- UI → Riverpod providers → repositories → services → SDK.
- Firebase is **telemetry + device paths**; Supabase is **users and ownership**.

See also: [ARCHITECTURE_SERVICES_AND_REPOSITORIES.md](./ARCHITECTURE_SERVICES_AND_REPOSITORIES.md).

---

## 2. Repository layout (folders and key files)

### Root

| Path | Purpose |
|------|---------|
| `lib/` | All Dart application code |
| `docs/` | Architecture and schema docs (start here) |
| `test/` | Unit tests (models, repositories, utils) |
| `proto/` | Source `.proto` files for telemetry / V0 firmware messages |
| `supabase/migrations/` | SQL migrations to run in Supabase Dashboard (not auto-applied by the app) |
| `android/`, `ios/` | Platform shells; Firebase `google-services.json` lives under `android/app/` (gitignored pattern — obtain from team) |
| `.env` | Local secrets (copy from `.env.example`; **never commit**) |
| `pubspec.yaml` | Dependencies and Flutter asset bundle (includes `.env`) |
| `README.md` | Quick start and env variable table |
| `.github/workflows/flutter_ci.yml` | CI: `flutter analyze`, `flutter test`, iOS build on `main` |

### `lib/` — application code

| Path | Purpose |
|------|---------|
| `main.dart` | Loads `.env`, initializes Firebase and Supabase, starts `ProviderScope` with error observer |
| `app.dart` | `MaterialApp.router` — wires auth state to `go_router` |

#### `lib/core/`

| Path | Purpose |
|------|---------|
| `config/env.dart` | Reads `APP_ENV`, Supabase URL/key from dotenv or `--dart-define` |
| `config/firebase_options.dart` | Platform-specific Firebase options from env |
| `constants/app_constants.dart` | RTDB path constants (`sensor_data`, `receiver_connections`, etc.) |
| `constants/ble_protocol.dart` | BLE GATT UUIDs, frame types, provisioning status strings, sensor-transfer protocol |
| `errors/` | `AppException` hierarchy, `Failure`, `ErrorHandler`, Riverpod `AppProviderObserver` |
| `router/app_router.dart` | All routes; auth redirect; some screens still placeholders |
| `router/main_shell.dart` | Bottom nav: Dashboard, Sensors, Account |
| `router/routes.dart` | Path string constants |
| `theme/app_theme.dart` | Light/dark `ThemeData` |
| `utils/app_logger.dart` | Structured logging (`dart:developer`) |
| `utils/ble_permissions.dart` | Runtime BLE/location permission helpers |
| `utils/crc16.dart` | CRC-16/CCITT-FALSE for BLE frames |
| `utils/extensions.dart` | Small Dart extensions |
| `widgets/` | `AsyncValueWidget`, `ErrorDisplay`, `LoadingIndicator` |

#### `lib/models/`

| File | Purpose |
|------|---------|
| `profile.dart` | Supabase profile row |
| `sensor.dart` | Sensor metadata (`firebase_sensor_id`, display name) |
| `user_sensor_link.dart` | Join of user + sensor + optional per-user label |
| `sensor_reading.dart` | Parsed RTDB reading (temp, hum, gas, IMU, timestamp, etc.) |
| `pending_reading.dart` | SQLite-queued reading awaiting Firebase upload |
| `ble_transfer_session.dart` | Offline BLE download session metadata |
| `remembered_sensor.dart` | Locally stored BLE device identity for rediscovery |

#### `lib/services/`

| File | Backend | Purpose |
|------|---------|---------|
| `supabase_service.dart` | Supabase | `Supabase.initialize()` |
| `supabase/supabase_auth_service.dart` | Supabase | Sign in/up/out, session stream |
| `supabase/supabase_user_data_service.dart` | Supabase | CRUD on `profiles`, `sensors`, `user_sensor_links` |
| `firebase_service.dart` | Firebase | `Firebase.initializeApp()` |
| `firebase/firebase_sensor_data_service.dart` | Firebase | Read/stream RTDB under `sensor_data/{id}` |
| `firebase/firebase_receiver_connections_service.dart` | Firebase | Write `receiver_connections/{id}` metadata after provisioning |
| `bluetooth/ble_sensor_transfer_service.dart` | Device | BLE scan, connect, sensor data transfer + receiver WiFi/auth provisioning |
| `local/local_packet_store.dart` | Local SQLite | `pending_readings` + `ble_transfer_sessions` |
| `local/remembered_sensor_store.dart` | Local | Persist BLE MAC/name ↔ Firebase node ID |
| `sync/firebase_upload_sync_service.dart` | Firebase | Batch upload pending readings to RTDB |

#### `lib/repositories/`

Domain layer: map SDK errors to `AppException`, return models.

| File | Uses | Purpose |
|------|------|---------|
| `auth_repository.dart` | Supabase auth | Login lifecycle |
| `profile_repository.dart` | Supabase | Profile get/update |
| `sensor_link_repository.dart` | Supabase | Link/unlink sensors, list linked sensors |
| `sensor_data_repository.dart` | Firebase | `sensorExists`, stream latest readings, range queries |
| `ble_transfer_repository.dart` | BLE + SQLite | Orchestrate offline download (V0 protobuf + legacy binary) |
| `sync_repository.dart` | SQLite + Firebase upload + connectivity | Pending count, sync now, Wi‑Fi-only option |

#### `lib/providers/`

Riverpod wiring exposed to UI.

| File | Purpose |
|------|---------|
| `service_providers.dart` | Service singletons |
| `auth_provider.dart` | Auth state, user id, email |
| `profile_provider.dart` | Current user profile |
| `linked_sensors_provider.dart` | User's linked sensors (Supabase) |
| `sensor_readings_provider.dart` | Latest readings per linked Firebase IDs |
| `ble_providers.dart` | BLE transfer + sync state |

#### `lib/features/` — screens (UI only)

| Feature | Files | Status |
|---------|-------|--------|
| **auth** | `login_screen.dart`, `register_screen.dart` | Working (requires Supabase config) |
| **dashboard** | `dashboard_screen.dart`, reading cards | Working — shows latest readings for linked sensors |
| **sensors** | `my_sensors_screen.dart`, `add_sensor_screen.dart`, `ble_sensor_discovery_screen.dart` | Working — link by Firebase node ID; BLE discovery flow |
| **bluetooth** | `ble_download_screen.dart`, `sync_status_screen.dart`, `receiver_setup_screen.dart` | Working — offline download + upload queue; receiver WiFi/Firebase provisioning |
| **analytics** | `analytics_screen.dart`, line chart widgets | Working — historical chart for one linked sensor |
| **settings** | `account_screen.dart` | Working — profile, unlink sensors, logout, delete account |
| **alerts** | `alerts_screen.dart` | **Placeholder** — "Coming soon" |
| **map** | `hive_map_screen.dart` | **Placeholder** — stub text only |

**Router placeholders** (route exists, minimal UI): sensor detail `sensors/:id`, edit profile.

#### `lib/proto/`

Generated Dart from `proto/*.proto` (checked in). Used when decoding V0 firmware protobuf over BLE. Regenerate with `build_runner` / `protoc` when `.proto` changes.

### `proto/` (repo root)

| File | Purpose |
|------|---------|
| `buzzhive_telemetry.proto` | Shared telemetry envelope (aligned with buzzhivedash backend contract) |
| `buzzhive_v0.proto` | V0 sensor message types for BLE decode |

### `supabase/migrations/`

Run **in order** in Supabase SQL Editor (see [SUPABASE_SETUP.md](./SUPABASE_SETUP.md)):

| Migration | Purpose |
|-----------|---------|
| `20250101000000_initial_schema.sql` | `profiles`, `sensors`, `user_sensor_links`, RLS, signup trigger |
| `20250102000000_sensors_rls_fix.sql` | `created_by` on sensors; policy fixes |
| `20250103000000_simplify_sensors_rls.sql` | Any logged-in user can read/insert/update `sensors` |
| `20250104000000_delete_user_function.sql` | RPC `delete_user_account()` for GDPR-style account deletion |

### `test/`

| Area | Coverage |
|------|----------|
| Models | Parsing for `SensorReading`, `Profile`, `Sensor`, `PendingReading` |
| Repositories | Auth, profile, sensor link, sensor data (mocked services) |
| Utils | `AppLogger`, `crc16` |
| `widget_test.dart` | Minimal smoke test |

### `docs/` (existing deep dives)

| Doc | Topic |
|-----|-------|
| [ARCHITECTURE_SERVICES_AND_REPOSITORIES.md](./ARCHITECTURE_SERVICES_AND_REPOSITORIES.md) | Service/repository split, error flow, dashboard data path |
| [SUPABASE_SETUP.md](./SUPABASE_SETUP.md) | Migrations, tables, RLS troubleshooting |
| [FIREBASE_SENSOR_DATA_SCHEMA.md](./FIREBASE_SENSOR_DATA_SCHEMA.md) | RTDB paths, receiver provisioning, BLE contract |
| [BLE_OFFLINE_SYNC.md](./BLE_OFFLINE_SYNC.md) | Store-and-forward BLE → SQLite → Firebase upload |

---

## 3. Firebase — status and responsibilities

**Project:** BuzzHive uses Firebase project **`buzz-hive-1c599`** (RTDB URL typically `https://buzz-hive-1c599-default-rtdb.firebaseio.com`). Android `google-services.json` may reference a related legacy URL — confirm with the team which RTDB instance is live.

### What the app does today

| Capability | Implementation | RTDB path |
|------------|----------------|-----------|
| Read live sensor data | `FirebaseSensorDataService` | `sensor_data/{node_id}/{timestamp}/...` |
| Validate sensor exists before link | `sensor_data_repository.sensorExists` | Same |
| Upload offline BLE readings | `FirebaseUploadSyncService` | `sensor_data/{id}/{timestampMs_seq}` |
| Receiver provisioning metadata | `FirebaseReceiverConnectionsService` | `receiver_connections/{receiver_id}/...` |
| Provisioning ping (receiver firmware) | Anonymous Firebase Auth → ID token → GET `provisioning_ping.json?auth=...` | Documented in schema doc; rules in buzzhivedash |

**Auth model:** Supabase handles **user login**. Firebase **Anonymous sign-in** is used only to obtain an ID token during receiver BLE provisioning (must be enabled in Firebase Console → Authentication → Sign-in method).

### Security rules (critical — not fully “done” until deployed)

Rules live in the **sibling repo** `buzzhivedash/database.rules.json`, referenced by `buzzhivedash/firebase.json`. They are **not** in buzzhiveapp.

Current rules (draft in repo) include:

- `sensor_data` — public read; writes allowed for authenticated clients **or** unauthenticated writes that pass strict field validation (firmware path)
- `receiver_connections` — read/write only when `auth != null`
- `provisioning_ping` — read when `auth != null`
- `raw_ingest`, `analyzed_data`, `latest_hive_state`, `device_status` — read-only from clients (backend/functions write)
- Registries — auth required

**Deployment status:** Rules exist in source control; they must be published to the live Firebase project:

```bash
cd buzzhivedash
firebase deploy --only database
```

Until deployed, receiver provisioning (`FIREBASE_OK`), app writes to `receiver_connections`, and validated sensor uploads may fail with permission errors.

### Data layout caveat

The app expects readings under **`sensor_data/{node_id}/...`** (e.g. `10001`), not flat push keys. If firmware writes `sensor_data/{autoPushId}/...`, linking and dashboard streams will not find the sensor. See [FIREBASE_SENSOR_DATA_SCHEMA.md](./FIREBASE_SENSOR_DATA_SCHEMA.md) — Option A (fix writer) is recommended.

### Future / backend-owned paths (app constants exist; UI not fully migrated)

Defined in `app_constants.dart` but primarily consumed by **buzzhivedash** Cloud Functions and dashboard:

- `raw_ingest`, `analyzed_data`, `latest_hive_state`, `device_status`
- `device_registry`, `hive_registry`, `receiver_registry`

The mobile app still reads **`sensor_data`** for dashboard parity; migrating reads to `latest_hive_state` is future work.

---

## 4. Supabase — status and responsibilities

### What the app does today

| Capability | Tables / RPC | Status |
|------------|--------------|--------|
| Register / login | `auth.users` + trigger → `profiles` | Implemented |
| Profile display | `profiles` | Implemented |
| Link sensor to user | `sensors` + `user_sensor_links` | Implemented |
| Unlink sensor | `user_sensor_links` delete | Implemented |
| Delete account | RPC `delete_user_account()` | Implemented (migration 4 required) |

### Schema status

- **In repo:** Four migrations under `supabase/migrations/` — complete and ordered.
- **In cloud:** Must be applied manually per environment. If the app errors with `PGRST205` (table not found), migrations were not run.
- **RLS:** After migration 3, any authenticated user can read/insert/update `sensors` (shared lookup table); links remain per-user.

### Local setup checklist

1. Create Supabase project (or use team project).
2. Run all four migrations in SQL Editor.
3. Copy project URL + anon key into `buzzhiveapp/.env`.
4. `flutter pub get` && `flutter run`.

No Supabase CLI config is checked into buzzhiveapp; dashboard SQL is the source of truth.

---

## 5. Current general project status

**Active branch:** `app-to-receiver` (recent work: receiver BLE WiFi provisioning, runtime permissions, Firebase receiver connection writes).

**Maturity by area:**

| Area | Status | Notes |
|------|--------|-------|
| Supabase auth + linking | **Production-ready path** | Needs migrations applied on each Supabase project |
| Dashboard live readings | **Working** | Depends on correct `sensor_data/{node_id}` layout |
| Add / link sensor (manual ID) | **Working** | Validates RTDB path before Supabase link |
| BLE sensor discovery + remember device | **Working** | V0 protobuf + legacy paths in `ble_transfer_repository` |
| BLE offline download → SQLite | **Working** | Documented in BLE_OFFLINE_SYNC.md |
| Manual sync upload to Firebase | **Working** | Wi‑Fi-only toggle; no background `workmanager` yet |
| Receiver setup (WiFi + Firebase token) | **Implemented** | Requires Anonymous Firebase Auth + **deployed RTDB rules** |
| Analytics chart | **Working** | Single-sensor line chart |
| Alerts | **Not started** | Placeholder screen |
| Map | **Not started** | Placeholder screen |
| Sensor detail route | **Stub** | Router placeholder only |
| Edit profile route | **Stub** | Router placeholder only |
| CI | **On `main`** | Analyze + test + iOS build; feature branches may diverge |
| iOS Firebase plist | **Team-dependent** | May use `firebase_options.dart` from `.env` |

**Platform focus:** README and pubspec description emphasize iOS; Android is supported (separate Firebase app IDs in `.env`).

---

## 6. Remaining work / handoff backlog

Prioritize in consultation with the team; ordered roughly by dependency.

### Firebase / infrastructure

1. **Deploy RTDB security rules** from `buzzhivedash/database.rules.json` (`firebase deploy --only database`). Verify receiver provisioning and app writes in a staging project first.
2. **Enable Firebase Anonymous Auth** in console if not already on.
3. **Confirm live RTDB URL** matches `.env` / `google-services.json` (legacy vs `buzz-hive-1c599`).
4. **Align firmware writer** to `sensor_data/{node_id}/{timestamp}` if still using flat push keys.
5. **Provision `provisioning_ping`** path (can be empty) so authenticated GET succeeds during receiver setup.

### App features

6. **Alerts screen** — design thresholds, notification strategy (local vs push), data source (`latest_hive_state` vs `sensor_data`).
7. **Hive map** — geolocation per hive/sensor; likely needs new Supabase columns or RTDB registry fields.
8. **Sensor detail screen** — replace `app_router` placeholder; deep link to analytics + BLE download.
9. **Edit profile screen** — wire to `profile_repository.updateProfile`.
10. **Background auto-sync** — `workmanager` (or equivalent) mentioned in BLE_OFFLINE_SYNC.md as future.
11. **Read path migration** — optionally consume `latest_hive_state` / `analyzed_data` when backend pipeline is live (buzzhivedash functions).

### BLE / firmware coordination

12. **Sensor firmware** — full GATT store-and-forward protocol (`BEE50001` service) per BLE_OFFLINE_SYNC.md if not complete on all hardware.
13. **Receiver firmware** — stay in sync with `ble_protocol.dart` status strings and WiFi/auth characteristic payloads.
14. **Protobuf contract** — keep `proto/buzzhive_telemetry.proto` in sync with buzzhivedash copy.

### Supabase / ops

15. **Staging vs production** projects — document which URLs/keys interns should use.
16. **Migration discipline** — any new SQL should add `20250105...sql` files and update SUPABASE_SETUP.md.
17. **Account deletion testing** — run through `delete_user_account` RPC after migration 4.

### Testing / quality

18. Expand tests for BLE repositories and sync (currently light).
19. Device/integration tests on real ESP32 hardware for provisioning flow.

### Security hygiene

20. Never commit `.env` or `google-services.json` with real keys.
21. Rotate any exposed Firebase API keys (called out in buzzhivedash README).

---

## 7. Key user flows (for debugging)

### Link a sensor

1. User logs in (Supabase).
2. User enters Firebase **node ID** (e.g. `10001`) on Add Sensor or BLE discovery flow.
3. App checks `sensor_data/10001` has children (Firebase).
4. App upserts `sensors` row and `user_sensor_links` (Supabase).

### View dashboard

1. `linkedSensorsProvider` → list of `firebase_sensor_id`s.
2. `latestReadingsProvider` → subscribes to each `sensor_data/{id}`.
3. Cards render `SensorReading` values.

### Offline BLE sync

1. My Sensors → Bluetooth icon → scan → download.
2. Readings land in SQLite (`local_packet_store`).
3. Sync Status → Sync now → `firebase_upload_sync_service` (needs network; writes need RTDB rules).

### Provision a receiver

1. Navigate to Receiver Setup (route `Routes.receiverSetup`).
2. BLE: WiFi credentials → wait `WIFI_OK`.
3. Firebase anonymous sign-in → send ID token → wait `FIREBASE_OK`.
4. On `PROVISION_COMPLETE`, app writes `receiver_connections/{id}`.

---

## 8. Environment variables (quick reference)

Copy `.env.example` → `.env`. Required for full functionality:

| Variable | Required for |
|----------|----------------|
| `SUPABASE_URL`, `SUPABASE_ANON_KEY` | Auth, linking, profile |
| `FIREBASE_*` (project, database URL, app IDs, API keys) | RTDB, Anonymous Auth |
| `APP_ENV` | Optional logging/environment label |

Without Supabase config, router skips auth redirect (`Env.hasSupabaseConfig`). Without Firebase config, init is skipped and sensor features fail gracefully in logs.

---

## 9. Commands you'll use daily

```bash
cd buzzhiveapp
flutter pub get
cp .env.example .env   # then fill in values
flutter run
flutter test
flutter analyze
```

Deploy Firebase rules (from sibling repo):

```bash
cd ../buzzhivedash
firebase deploy --only database
```

---

## 10. Who to read next

1. This file — orientation.
2. [README.md](../README.md) — env table and quick start.
3. [ARCHITECTURE_SERVICES_AND_REPOSITORIES.md](./ARCHITECTURE_SERVICES_AND_REPOSITORIES.md) — before changing services/repos.
4. [FIREBASE_SENSOR_DATA_SCHEMA.md](./FIREBASE_SENSOR_DATA_SCHEMA.md) — before touching RTDB or provisioning.
5. [SUPABASE_SETUP.md](./SUPABASE_SETUP.md) — before touching auth or linking.
6. [BLE_OFFLINE_SYNC.md](./BLE_OFFLINE_SYNC.md) — before touching BLE or SQLite sync.
7. **buzzhivedash** README — dashboard, Cloud Functions, and **rule deployment**.

---

*Last updated: May 2026 — reflects `app-to-receiver` branch state. Update this doc when major features ship or Firebase/Supabase contracts change.*
