# BLE Offline Sync Architecture

This document describes the Bluetooth Low Energy (BLE) store-and-forward feature that allows beekeepers to download sensor data via Bluetooth when out of internet range, then upload it to Firebase later.

## Overview

The feature adds a three-stage pipeline to the existing app:

```
Sensor Firmware  →  BLE Transfer  →  Local SQLite Queue  →  Firebase Upload
```

1. **BLE Transfer**: Phone connects to sensor via BLE, downloads readings as framed binary packets.
2. **Local Storage**: Readings are persisted immediately to SQLite on the phone.
3. **Cloud Upload**: When internet is available, a sync engine uploads batched readings to Firebase RTDB using idempotent keys.

## BLE Protocol

### GATT Service

The sensor firmware must advertise a custom BLE service:

| UUID | Role |
|------|------|
| `BEE50001-...` | Service UUID (advertised) |
| `BEE50002-...` | Control characteristic (phone writes commands) |
| `BEE50003-...` | Data characteristic (sensor sends notifications) |
| `BEE50004-...` | Status characteristic (read/notify metadata) |

Full UUIDs are defined in `lib/core/constants/ble_protocol.dart`.

### Control Commands

| Byte | Command | Payload |
|------|---------|---------|
| `0x01` | START_TRANSFER | none |
| `0x02` | ACK_BATCH | 2-byte last confirmed sequence |
| `0x03` | RESUME | 2-byte sequence to resume from |
| `0x04` | ABORT | none |
| `0x05` | DELETE_CONFIRMED | none (sensor may purge data) |

### Data Frame Format

Each BLE notification carries one frame:

```
[0]       Frame type: 0x10=SESSION_START, 0x20=DATA, 0x30=SESSION_END
[1..2]    Sequence number (big-endian uint16)
[3..N-2]  Payload
[N-1..N]  CRC-16/CCITT-FALSE over bytes [0..N-2]
```

### DATA Payload Layout (52 bytes, little-endian)

```
[0..7]    timestamp_ms (int64 LE)
[8..11]   temp (float32 LE)
[12..15]  hum (float32 LE)
[16..19]  gas (float32 LE)
[20..23]  mic (float32 LE)
[24..27]  db (float32 LE)
[28..31]  ax (float32 LE)
[32..35]  ay (float32 LE)
[36..39]  az (float32 LE)
[40..43]  fx (float32 LE)
[44..47]  fy (float32 LE)
[48..51]  fz (float32 LE)
```

## Local Storage Schema

SQLite database `buzzhive_packets.db` with two tables:

### `ble_transfer_sessions`
Tracks each connect-download-disconnect cycle.

| Column | Type | Description |
|--------|------|-------------|
| id | INTEGER PK | Auto-increment |
| sensor_id | TEXT | Supabase sensor UUID |
| firebase_sensor_id | TEXT | Firebase node ID |
| started_at | TEXT | ISO-8601 UTC |
| completed_at | TEXT | ISO-8601 UTC (null if in progress) |
| expected_count | INTEGER | Readings the sensor said it would send |
| received_count | INTEGER | Readings actually received |
| last_confirmed_seq | INTEGER | Last ACK'd sequence number |
| status | TEXT | `inProgress`, `complete`, `failed`, `aborted` |

### `pending_readings`
Buffered readings waiting for upload.

| Column | Type | Description |
|--------|------|-------------|
| id | INTEGER PK | Auto-increment |
| session_id | INTEGER FK | References `ble_transfer_sessions` |
| firebase_sensor_id | TEXT | Firebase node ID |
| sequence | INTEGER | Sequence number from BLE transfer |
| temp, hum, gas, mic, db_val, ax, ay, az, fx, fy, fz | REAL | Sensor values |
| sensor_timestamp_ms | INTEGER | Timestamp from the sensor's clock |
| received_at | TEXT | When the phone received it |
| synced | INTEGER | 0 = pending, 1 = uploaded |

A unique index on `(firebase_sensor_id, sensor_timestamp_ms, sequence)` prevents duplicate inserts on resume/retry.

## Upload Strategy

- Readings are uploaded in batches of 50.
- Firebase key per reading: `{sensorTimestampMs}_{sequence}` — deterministic, so retries don't create duplicates.
- Path: `sensor_data/{firebaseSensorId}/{key}`
- Batch upload uses `DatabaseReference.update()` for atomicity per sensor.
- Only readings confirmed written are marked `synced = 1`.
- A purge method removes synced readings older than 7 days.

## Sync Triggers

- **Manual**: "Sync now" button on the Sync Status screen.
- **Wi-Fi only option**: User can restrict uploads to Wi-Fi connections.
- **Auto-sync**: Future enhancement via `workmanager` for background sync.
- **Connectivity detection**: Uses `connectivity_plus` to check network state.

## App Layer Structure

```
lib/
├── core/constants/ble_protocol.dart       # GATT UUIDs, command bytes, frame format
├── core/utils/crc16.dart                  # CRC-16/CCITT-FALSE
├── models/
│   ├── ble_transfer_session.dart          # Session metadata model
│   └── pending_reading.dart               # Offline-queued reading model
├── services/
│   ├── bluetooth/ble_sensor_transfer_service.dart  # BLE scan/connect/commands
│   ├── local/local_packet_store.dart               # SQLite persistence
│   └── sync/firebase_upload_sync_service.dart      # Firebase batch upload
├── repositories/
│   ├── ble_transfer_repository.dart       # Orchestrates download session
│   └── sync_repository.dart               # Manages upload queue + connectivity
├── providers/ble_providers.dart           # Riverpod wiring
└── features/bluetooth/presentation/
    ├── ble_download_screen.dart            # Scan, connect, download UI
    └── sync_status_screen.dart            # Pending count, sync now, purge
```

## User Flows

### Download via Bluetooth
1. Navigate to **My Sensors** tab.
2. Tap the Bluetooth icon on a linked sensor.
3. App scans for nearby BuzzHive BLE devices.
4. Select the sensor from the list and tap **Download**.
5. App connects, negotiates MTU, and streams data frames.
6. On completion, readings are stored locally and a success screen is shown.

### Upload to Cloud
1. Navigate to **Sync Status** (cloud icon on My Sensors, or badge on Dashboard).
2. See the count of pending readings.
3. Toggle **Wi-Fi only** if desired.
4. Tap **Sync now** to upload.
5. Optionally **Purge old synced data** to reclaim storage.

### Dashboard Badge
When unsynced readings exist, the Dashboard app bar shows a cloud-upload icon with a count badge. Tapping it opens the Sync Status screen.

## Dependencies Added

- `flutter_reactive_ble` — BLE scanning, connection, characteristics
- `sqflite` — Local SQLite database
- `path_provider` — App documents directory for DB file
- `connectivity_plus` — Network state detection

## Firmware Integration Notes

The sensor firmware team needs to implement:
1. Advertise the BLE service UUID `BEE50001-...`.
2. Implement the control/data/status characteristics.
3. On `START_TRANSFER` command: begin sending `SESSION_START`, then `DATA` frames, then `SESSION_END`.
4. On `ACK_BATCH`: note the confirmed sequence for resume.
5. On `DELETE_CONFIRMED`: purge stored readings from flash.
6. Use the binary payload layout above (52 bytes per reading).
7. Append CRC-16/CCITT-FALSE to every frame.
