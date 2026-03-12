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
