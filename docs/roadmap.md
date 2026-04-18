# Roadmap — BLE sync & observability

Deferred items that the MVP ships **without**, tracked here so we're honest
about what "market-ready" still means. Order roughly reflects user-impact
priority.

## BLE

- **Historical backfill.** Today a sync captures one fresh sample. If a hive
  is offline for days the cached readings on the ESP32 aren't pulled. Needs
  either (a) extending the protobuf to stream an array of `SensorData` or
  (b) keeping a session-framed custom protocol. Pick (a) to avoid a second
  wire protocol.
- **Timestamps from the sensor.** We stamp `sensor_timestamp_ms` on the
  phone at receive time. Adding a `sensor_unix_ms` field to `SensorData`
  keeps offline-backfill accurate.
- **Pairing & encryption.** Service is open; anyone with the app (or with
  their own GATT client) can pull data from a nearby sensor. Add
  just-works pairing or a claim-code-derived shared key.
- **Multi-sensor sync.** UI pulls one sensor at a time. A background
  "BLE opportunistic sync" queue would help at scale.
- **Android MTU defaults.** We request 185. If a phone refuses, we silently
  fall back to 23, which would truncate larger future payloads. Track
  actual MTUs via analytics and warn if <100 on a device we've seen before.
- **OTA.** No firmware update path. Needs a sibling `ota` service UUID +
  signed-image flow. Separate hard project.

## iOS

- **Background sync.** The current flow requires the app foreground. iOS
  supports background BLE with `bluetooth-central` entitlement + careful
  state-preservation code. Not in MVP.
- **GATT cache invalidation.** If we ever change service/characteristic
  UUIDs we need in-app guidance ("toggle Bluetooth off/on"). We only use
  standard `0x180F` today so it's quiet.

## Sync / backend

- **RTDB sharding.** All readings live under a single `sensors/<id>/readings`
  path. Fine for dozens of devices, rough at thousands. Plan: shard by
  tenant, enable RTDB indexes, and compact to BigQuery on a schedule.
- **Partial-batch retry.** `SyncRepository` breaks on the first partial
  batch. Should retry the failed tail with exponential backoff instead of
  waiting for the next user-initiated sync.
- **Conflict strategy.** `ConflictAlgorithm.ignore` is safe but means we
  silently drop a reading if `(firebase_sensor_id, sensor_timestamp_ms,
  sequence)` collides. Fine for one-reading-per-tap, re-examine if we
  backfill.

## Observability

- **Crashlytics.** Not wired up. Riverpod's `ProviderObserver` +
  `FlutterError.onError` → Crashlytics is a ~30-line add. Defer until the
  first external user hits a crash we can't reproduce.
- **BLE session metrics.** We log info-level breadcrumbs. We don't ship
  structured metrics (scan duration, connect latency, decode failure rate)
  anywhere. Add once we have >10 active installs.

## UI / UX

- **Legacy firmware hint.** A sensor that only advertises `BuzzHive_Sensor`
  (no ID in name) forces the user to type the ID on claim. Add an
  "update my sensor firmware" prompt once an OTA path exists.
- **Connection-progress indicator.** The download screen shows three
  spinners (scan / connect / wait) but no time estimate. Once we have real
  connect-latency data, show "usually takes ~5s."
