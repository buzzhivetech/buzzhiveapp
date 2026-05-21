# Firebase Realtime Database – sensor data schema

The app expects sensor data to be keyed by **node ID** so it can validate and stream by sensor.

## Expected path structure

```
sensor_data/
  {node_id}/           ← e.g. "10001" (the sensor’s node ID)
    {timestamp}/        ← e.g. "1734567890123" or "-NxYz..."
      temp: number
      hum: number
      gas: number
      mic: number
      db: number
      ax, ay, az: number
      fx, fy, fz: number
      id: string        ← optional; can match node_id
      timestamp: number or string
      raw_packet: string   ← optional; original LoRa payload (receiver firmware)
```

- **Top-level key under `sensor_data` must be the node ID** (e.g. `10001`).
- Each child of that key is one reading, keyed by timestamp (ms or push key).
- The app uses this so that:
  - **Linking:** It checks that `sensor_data/10001` exists and has at least one child before allowing a user to link “10001”.
  - **Dashboard:** It subscribes to `sensor_data/10001` and parses each child as a `SensorReading`.

## If your data is currently flat

If your writer uses:

```
sensor_data/
  {pushKey}/    ← unique push key, not node_id
    { ... reading + maybe node_id inside ... }
```

then the app will **not** find `sensor_data/10001`, so:

- `sensorExists("10001")` returns false → “Sensor not found.”
- You cannot link by node_id 10001 until the paths match.

## What to change

**Option A – Recommended: change the Firebase writer**

- Write to `sensor_data/{node_id}/{timestamp}` instead of `sensor_data/{pushKey}`.
- For node 10001, write under `sensor_data/10001/<timestamp>` so the app can:
  - Validate the sensor at link time.
  - Stream readings for that node on the dashboard.

**Option B – Keep flat structure and change the app**

- The app would need to stop using `sensor_data/{node_id}` and instead query/filter by `node_id` (e.g. `orderByChild('id').equalTo('10001')` under `sensor_data`). This requires a different Firebase layout and more app changes; Option A is simpler if you control the writer.

## Additive backend paths

The ML analysis rollout keeps the legacy path above, then adds backend-owned paths:

```
raw_ingest/{hiveId}/{readingId}
analyzed_data/{hiveId}/{readingId}
latest_hive_state/{hiveId}
device_status/{deviceId}
device_registry/{deviceId}
hive_registry/{hiveId}
receiver_registry/{receiverId}
provisioning_ping/          ← optional; used only for authenticated GET during device setup
receiver_connections/{receiverId}
```

- `sensor_data` remains the backward-compatible ingest path for app and receiver uploads.
- `raw_ingest` stores normalized telemetry after validation.
- `analyzed_data` stores placeholder or future ML outputs.
- `latest_hive_state` is the preferred UI read path for current hive health.
- `device_status` exposes battery, firmware, and ingest connectivity.

## Receiver connections (post–BLE provisioning)

After the mobile app walks through receiver setup, it writes metadata under `receiver_connections` (see `AppConstants.firebaseReceiverConnectionsPath`). Authenticated users only (`auth != null` in security rules).

```
receiver_connections/
  {receiver_node_id}/          ← user-assigned during setup (string, e.g. R001)
    connected_sensors/
      {sensor_node_id}: true   ← LoRa sensors allowed to upload through this receiver
    app_connections/
      {timestamp_ms}: "wifi" | "firebase"   ← audit trail when Wi‑Fi / Firebase checks succeeded
```

- **`connected_sensors`** is updated when provisioning completes (`PROVISION_COMPLETE` over BLE).
- **`app_connections`** records two events when Wi‑Fi and Firebase verification succeed (`WIFI_OK` / `FIREBASE_OK` notifications).

## Provisioning ping (device Firebase check)

Receivers validate RTDB access using the signed-in user’s **Firebase ID token** (the app uses anonymous Firebase Auth for token issuance). The firmware performs an authenticated HTTP GET to:

`provisioning_ping.json?auth=<idToken>`

Rules: `provisioning_ping` is readable only when `auth != null`. No writes required; the path may be empty.

**Console:** Enable **Anonymous** under Firebase Authentication → Sign-in method so the app can obtain an ID token before provisioning.

## BLE provisioning contract (receiver firmware ↔ app)

**Service / characteristics** — UUIDs match `buzzhiveapp/lib/core/constants/ble_protocol.dart`:

| Role | UUID |
|------|------|
| Service | `4fafc201-1fb5-459e-8fcc-c5c9c331914b` |
| Wi‑Fi write | `beb5483e-36e1-4688-b7f5-ea07361b26a8` — payload `SSID\nPASSWORD\noptionalSensorIdsCsv` |
| Auth write | `beb5483e-36e1-4688-b7f5-ea07361b26aa` — payload `receiver_node_id\nfirebase_id_token` (JWT) |
| Status notify | `beb5483e-36e1-4688-b7f5-ea07361b26a9` |

**Status strings (UTF-8):** `READY`, `WIFI_OK`, `FIREBASE_OK`, `PROVISION_COMPLETE`; failures `ERR_WIFI|code|detail` or `ERR_FIREBASE|code|detail`. On failure the receiver stops BLE and reboots so the user can retry.

## Shared envelope contract

The cross-device typed contract now lives in the dashboard/backend repo at:

```
proto/buzzhive_telemetry.proto
```

The app can continue uploading legacy JSON for now, but `PendingReading.toTelemetryEnvelopeMap()` mirrors the future envelope fields so direct typed writers can be added later without changing the downstream analysis schema.
