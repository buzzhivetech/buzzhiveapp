# BLE firmware protocol (current)

This doc describes the over-the-air contract between the BuzzHive app and the
ESP32 firmware in `Buzzhive-V0/ALL_FUNC`. It's intentionally narrow — the app
only cares about pulling a single fresh reading when a user taps "Sync" on an
un-reporting sensor card.

## Wire

| Layer | Value |
| --- | --- |
| Advertised service UUID | `0x180F` (standard Battery Service) |
| Advertised local name | `BuzzHive-<NODE_ID>` (or legacy `BuzzHive_Sensor`) |
| Payload characteristic | `0x2A19` (Battery Level), **notify** |
| Encoding | protobuf (`BuzzHiveMessage`, see `proto/buzzhive.proto`) |
| Flow | server-push: firmware emits one frame on subscribe |
| MTU (requested) | 185 bytes (Android); iOS negotiates automatically |

Standard UUIDs are used because the firmware predates our custom GATT profile
and iOS/Android's `flutter_reactive_ble` is happier filtering on 16-bit
service UUIDs. The characteristic is re-purposed; we never interpret it as a
battery percentage.

## Field mapping

`BuzzHiveMessage.sensor_data` → `pending_readings` column:

| Protobuf field | DB column | Notes |
| --- | --- | --- |
| `node_id` | (routing, not stored) | matches `firebase_sensor_id` |
| `mic_freq` | `mic` | Hz |
| `mic_db` | `db_val` | dB |
| `freq_x` / `freq_y` / `freq_z` | `fx` / `fy` / `fz` | vibration FFT peak Hz |
| `max_x` / `max_y` / `max_z` | `ax` / `ay` / `az` | accelerometer magnitude |
| `temp` | `temp` | °C |
| `humid` | `hum` | %RH |
| `gas` | `gas` | raw ADC |
| `vbat` | (not stored yet) | see `roadmap.md` |

Sensor-side timestamps aren't in the protobuf today, so we stamp
`sensor_timestamp_ms` at receive time on the phone. Good enough for a single
"latest reading" pull; see the roadmap for historical backfills.

## Code path

1. `_WaitingForFirstReadingCard.onTap` → `context.push(Routes.bleDownload, extra: BleDownloadArgs)`
2. `BleDownloadScreen` reads args, kicks off `sensorSyncControllerProvider(args)`
3. `SensorSyncController.start()` subscribes to
   `BleTransferRepository.syncSingleReading(...)`
4. Repository:
   - `scanForUnclaimedSensors()` — scan for `0x180F`, match on local name
   - `connectToDevice()` + `requestMtu(185)`
   - `subscribeToLegacyPayload()` — first frame wins
   - `BuzzHiveMessage.fromBuffer(bytes)` → `SensorData`
   - `LocalPacketStore.insertReading(...)` with `ConflictAlgorithm.ignore`
5. On success, controller kicks `SyncRepository.syncNow()` to push to Firebase;
   the dashboard's `latestReadingsProvider` stream refreshes automatically.

## Regenerating Dart classes

Source of truth lives at `/Users/mbron/Documents/buzzhive/Buzzhive-V0/buzzhive.proto`.
An app-local copy is kept at `proto/buzzhive.proto` so the build doesn't
depend on a sibling checkout.

```bash
# one-time
brew install protobuf
dart pub global activate protoc_plugin

# regenerate
cp /Users/mbron/Documents/buzzhive/Buzzhive-V0/buzzhive.proto proto/buzzhive.proto
PATH="$PATH:$HOME/.pub-cache/bin" \
  protoc --dart_out=lib/generated/proto \
         --proto_path=proto \
         proto/buzzhive.proto
flutter test test/features/bluetooth/proto_decode_test.dart
```

Generated files live under `lib/generated/**` and are:
- excluded from `analysis_options.yaml`
- marked `linguist-generated=true` via `.gitattributes`
- committed so CI doesn't need `protoc` installed

## iOS GATT cache caveats

iOS caches GATT attributes per-peripheral indefinitely. When the firmware
schema changes (service UUID, characteristic UUID, descriptors), users will
see stale behavior until they:

1. Toggle Bluetooth off/on, **or**
2. Forget the device in Settings → Bluetooth

We only rely on standard `0x180F`/`0x2A19` today, so this shouldn't bite in
practice. If the firmware moves to a custom service later, surface an
in-app "stuck connecting?" troubleshoot hint.
