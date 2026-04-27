# Integration Status

This is the snapshot after the `integration-branch-buildup` plan ran on Apr 26, 2026. Both repos now have a fresh `integration` branch built from `main` plus all active feature branches merged in dependency order. This document captures what works, what doesn't, what was skipped, and the open questions to resolve before re-applying our session's `feat/customer-ble-onboarding` work on top.

## What's on each integration branch

### App: `buzzhivetech/buzzhiveapp` @ `integration` (pushed)

`origin/main` (Mar 12) + `origin/feature/v0-protobuf-ble-compatibility` (PR #1, Jack's work through Apr 21).

Merge commit: `f121e35 Merge feature/v0-protobuf-ble-compatibility into integration`. Clean merge, no conflicts.

PR #1 brings in:
- New `BleSensorDiscoveryScreen` (474 lines) — alternative onboarding UI.
- Analytics screen + line chart + metric selector (≈440 lines).
- `lib/proto/buzzhive_v0.pb.dart` and `lib/proto/buzzhive_telemetry.pb.dart` — parallel protobuf paths to the `lib/generated/proto` we made in our session.
- `lib/core/constants/ble_protocol.dart` reintroduced with a **dual-path** advertised: standard `0x180F` (`v0` path) and custom `BEE5xxxx` (framed/legacy path).
- `lib/services/local/remembered_sensor_store.dart` for persisting scan history.
- `flutter_reactive_ble` bumped to 5.4.0; `protobuf` 2.1.0 stays.

### Firmware: `Jay947462/Buzzhive-V0` @ `integration` (pushed)

`origin/main` (Mar 5, basically empty) + `origin/protobuf-ble-matching` (Jack's PR #2 through Apr 21) + `origin/receiver-setup` (Jay's Apr 24-26 receiver work).

Merge commits:
- `bdddc25 Merge protobuf-ble-matching into integration` — fast-forward-ish, no conflicts.
- `abb8d16 Merge receiver-setup into integration` — one conflict on `RECIEVER_CODE/RECIEVER_CODE.ino`, resolved by taking `receiver-setup`'s version per plan.

Sensor unit (`sensor_unit/`, `ALL_FUNC/ALL_FUNC.ino`) and receiver (`reciever/`, `RECIEVER_CODE/RECIEVER_CODE.ino`) are both present.

## What was verified

| Check | Result | Notes |
|---|---|---|
| App `flutter pub get` (post-merge) | OK | 60 dep updates available, none required |
| App `flutter analyze` (post-merge) | OK | "No issues found!" |
| App `flutter test` (post-merge) | OK | 53/53 pass; PR #1 added only 4 new test lines, the new BLE/protobuf/analytics code has no test coverage |
| App `flutter build ios --debug --no-codesign` | OK | Built `Runner.app` after a `flutter clean`. First attempt hit Xcode `TDDistiller` asset cache error — environmental, fixed by clean. |
| Firmware `pio run -d sensor_unit` | OK | Builds clean for `heltec_wifi_lora_32_V3`. RAM 23.8%, Flash 23.8%. |
| Firmware `pio run -d reciever` | OK | Builds clean — **but compiles the OLD `reciever/src/reciever.cpp`, not the new BLE-provisioning `RECIEVER_CODE/RECIEVER_CODE.ino`** (see open questions). |

## What was skipped (needs hardware / your hands)

These steps in the plan require physical bench hardware and were left for you to do manually. Mark them off as you go:

- [ ] **App on iPhone** — codesign the `Runner.app` from `build/ios/iphoneos/`, install via Xcode/Devicectl, walk add-sensor flow on the new `BleSensorDiscoveryScreen`, try to connect to bench sensor (device 15), confirm scan finds it, connect succeeds, data appears, analytics chart renders.
- [ ] **Sensor firmware flashed to ESP32** — `pio run -d sensor_unit -t upload` on bench device, verify boot log (BLE init, NODE_ID load, advertising starts), verify protobuf send on connect.
- [ ] **Receiver firmware flashed** — only if you have a Heltec LoRa receiver on the bench. Verify it advertises as `BuzzHive-Receiver` on service `4fafc201-1fb5-459e-8fcc-c5c9c331914b`, write test creds via LightBlue (`SSID\nPASS\nID1,ID2`), confirm WiFi connects and allowed-IDs are parsed.

## Open questions (decide before re-applying our session work)

### App

1. **Dual-path BLE: keep or fold?** PR #1 reintroduced `lib/core/constants/ble_protocol.dart` with both `BEE5xxxx` and `0x180F` UUIDs, and added a parallel `lib/proto/buzzhive_v0.pb.dart` next to our `lib/generated/proto/buzzhive.pb.dart`. Right now the app has *two* protobuf sources and *two* BLE service paths. The firmware only emits one (180F + protobuf). Either we trim back to one path per `roadmap.md`, or we live with the dual-path until firmware actually justifies it.
2. **Proto field-number alignment.** Jack's commit `998470a` (Apr 21) fixed field numbers in firmware's `buzzhive.proto` to match the nanopb-generated `.pb.h`. The app's `proto/buzzhive.proto` (which we copied earlier) and `lib/generated/proto/buzzhive.pb.dart` may now be one revision behind. Diff `Buzzhive-V0/buzzhive.proto` against `buzzhiveapp/proto/buzzhive.proto` and regenerate Dart classes if drifted.
3. **Two onboarding flows.** Our session's `BleScanTab` flow and PR #1's `BleSensorDiscoveryScreen` both exist on `integration`. Ship one, archive the other.
4. **Stale doc still in repo.** `docs/BLE_OFFLINE_SYNC.md` describes the deleted custom-protocol design. Either delete or move under `docs/archive/`.

### Firmware

5. **Two receiver implementations live in the same tree.** `RECIEVER_CODE/RECIEVER_CODE.ino` (281 lines, Apr 26 BLE-provisioning, Arduino IDE) is the active code Jay is working on. `reciever/src/reciever.cpp` (508 lines, OLED + SPIFFS + AP-mode portal) is the older PlatformIO version. PlatformIO's `pio run -d reciever` builds the old one. Decide: port BLE-provisioning into `reciever/src/reciever.cpp`, or delete `reciever/` and stay on Arduino IDE.
6. **App side of receiver provisioning is unbuilt.** Jay's receiver expects a writeable BLE characteristic carrying `SSID\nPASS\nID1,ID2,...`. There's no app-side flow to send that. Project ticket [#44 (assigned to Jack)](https://github.com/buzzhivetech/buzzhive/issues/44) covers it.
7. **Sensor-unit divergence.** `sensor_unit/src/sensor_unit.cpp` (PlatformIO, in `protobuf-ble-matching` since Apr 6) and `ALL_FUNC/ALL_FUNC.ino` (Arduino IDE, Jay's Apr 18 patch on top) are similar but not identical. Same problem as the receiver: pick one canonical source.

## Preserved work — not on integration yet

These branches still hold our session's work and are untouched:

- App: `feat/customer-ble-onboarding` on origin (13 commits ahead of `main` plus the `chore: archive session research artifacts` commit). Includes the GoRouter stability fix, single-shot sync flow, `lib/generated/proto/`, our `BleScanTab` work, the deletion of `BEE5*`/`crc16` (now reintroduced by PR #1), and the docs/research artifacts.
- Firmware: `session-firmware-patch` local branch (one commit ahead of `ble-pairing`). Adds the `BuzzHive-<NODE_ID>` advertising name fallback to `ALL_FUNC/ALL_FUNC.ino`. Not pushed (we don't have write access to `Jay947462/Buzzhive-V0`).

Re-applying our work on top of `integration` is **explicitly out of scope for this plan** — that's the next decision after the bench-test results come back.

## Quick reference

| Repo | Path | Branch |
|---|---|---|
| App | `/Users/mbron/Documents/buzzhive/buzzhiveapp` | `integration` (currently checked out, pushed) |
| Firmware | `/Users/mbron/Documents/buzzhive/Buzzhive-V0` | `integration` (currently checked out, pushed) |

App PR draft URL (do not open as PR yet, just reference): https://github.com/buzzhivetech/buzzhiveapp/pull/new/integration
Firmware PR draft URL: https://github.com/Jay947462/Buzzhive-V0/pull/new/integration
