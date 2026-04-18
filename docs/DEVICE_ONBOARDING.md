# Customer Device Onboarding

How a customer goes from "box arrives on the doorstep" to "sensor data on the
dashboard", and how the backend prevents a neighbour from stealing their hive.

## Customer flow

1. Customer unboxes a BuzzHive sensor. A sticker on the back shows:
   - A **device ID** (e.g. `10001`) — the `firebase_sensor_id` on the server.
   - An **8-character claim code** (Crockford base32 — no `I`, `L`, `O`, or `U`).
   - A **QR code** encoding `buzzhive://claim?d=10001&c=7K3M9PQT`.
2. In the app, customer taps **Add Sensor**. Three tabs:
   - **Scan QR** (primary) — camera scans the sticker, both fields filled automatically.
   - **Bluetooth** — app scans for nearby BuzzHive advertisements; customer picks one, then types the sticker claim code.
   - **Manual** — fallback when the QR is damaged; customer types both device ID and claim code.
3. App calls `DeviceClaimRepository.claim(deviceId, claimCode)`, which invokes the `claim_sensor` Supabase RPC.
4. On success, the sensor appears on the dashboard with a "Waiting for first reading" card until the first Firebase RTDB reading arrives.

## Architecture

```
+------------+    +----------------------+    +---------------------+
| AddSensor  | -> | DeviceClaimRepo      | -> | SupabaseClaimService|
| (3 tabs)   |    | (error mapping +     |    | (rpc call wrapper)  |
|            |    |  validation)         |    |                     |
+------------+    +----------------------+    +----------+----------+
                                                         |
                                                         v
                                              +----------+----------+
                                              | claim_sensor RPC    |
                                              | (SECURITY DEFINER)  |
                                              |  - SELECT FOR UPDATE|
                                              |  - bcrypt verify    |
                                              |  - rate limit 10/10m|
                                              |  - typed result     |
                                              +----------+----------+
                                                         |
                                   +---------------------+---------------------+
                                   v                                           v
                       +-----------+-----------+              +----------------+-------------+
                       | public.sensors        |              | public.user_sensor_links    |
                       |   status='claimed'    |              |   (user_id, sensor_id)       |
                       |   claimed_by = uid    |              +------------------------------+
                       +-----------------------+
```

## Claim code format

- 8 characters, alphabet `0-9A-Z` minus `I`, `L`, `O`, `U` (Crockford base32 without the ambiguous glyphs).
- 32^8 ≈ 1.1 × 10^12 codes.
- Stored as a **bcrypt** hash with cost 10, via `extensions.crypt` + `gen_salt('bf', 10)`.
- Case-insensitive: the client uppercases input before submission; the stored bcrypt hash preserves case but Crockford codes are emitted all-uppercase.

## Sticker specification

| Field | Requirement |
|---|---|
| Device ID | Matches `firebase_sensor_id` in `public.sensors`. Printed at ≥2.5 mm cap height. |
| Claim code | 8 characters, monospace, ≥2.5 mm cap height, grouped `XXXX-XXXX` for readability. |
| QR code | Encodes `buzzhive://claim?d={id}&c={code}`. Error correction level **M** or higher. ≥15×15 mm quiet-zone-included. |
| Placement | On the sensor body (not the box), in a location accessible after deployment so a user can re-pair after factory reset. |

## Rate limiting

The `claim_sensor` RPC logs every attempt (successful or failed) to `public.claim_attempts`. If a single `user_id` has ≥10 failed attempts in the last 10 minutes the RPC returns `error_code='rate_limited'` without querying the sensor row. This makes brute-forcing an 8-character code against a single account take >10^11 minutes.

> Sensors only become easier to brute-force if an attacker has many compromised accounts. If that becomes a concern, add an IP-based limit at the edge (Supabase Edge Functions + upstream `x-forwarded-for`).

## Factory provisioning

For every device that ships:

1. Generate a random 8-char claim code with the Crockford alphabet.
2. Compute `extensions.crypt(code, extensions.gen_salt('bf', 10))`.
3. Insert a row into `public.sensors` with `firebase_sensor_id`, `status='factory'`, `claim_code_hash`, and optionally `hw_rev` / `fw_version`.
4. Print a sticker with device ID, plaintext claim code, and QR code.
5. **Discard the plaintext** (don't save it anywhere once the sticker is printed).

Migration `20250106000000_seed_existing_sensors.sql` does steps 1-3 for pre-existing sensors (`5`, `8`, `10001`-`10005`) and emits the plaintext codes via `RAISE NOTICE` for the dev to record.

## Error codes

The RPC returns a typed `claim_result` row; the Dart client maps `error_code`
to subtypes of `ClaimException`:

| `error_code` | When | Customer-facing message |
|---|---|---|
| `not_authenticated` | RPC called without a session | "You must be signed in to claim a sensor." |
| `rate_limited` | >10 failed attempts in 10 min | "Too many attempts. Wait 10 minutes and try again." |
| `unknown_device` | No sensor row with that `firebase_sensor_id` | "Device not recognized. Check the ID on the sticker." |
| `disabled_device` | `sensors.status='disabled'` (recall / RMA) | "This device has been disabled. Contact support." |
| `already_claimed` | `sensors.status='claimed'` | "This device is already registered to another account." |
| `wrong_code` | bcrypt comparison failed | "Claim code does not match. Check the sticker and try again." |

## Out of scope (for this phase)

- LoRa gateway onboarding (separate flow).
- A BLE "Device Info" GATT characteristic with `hw_rev`/`fw_version` reads (requires firmware change).
- iOS Universal Links / Android App Links for `buzzhive://claim` (so tapping a link outside the app deep-links in).
- Customer-facing claim-code reset when the sticker is lost (needs an email-verified RPC).
