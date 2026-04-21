import 'package:equatable/equatable.dart';

import '../core/constants/app_constants.dart';

/// A sensor reading stored locally, pending upload to Firebase.
class PendingReading extends Equatable {
  const PendingReading({
    required this.id,
    required this.sessionId,
    required this.firebaseSensorId,
    required this.sequence,
    required this.temp,
    required this.hum,
    required this.gas,
    required this.mic,
    required this.db,
    required this.ax,
    required this.ay,
    required this.az,
    required this.fx,
    required this.fy,
    required this.fz,
    required this.vbat,
    required this.weightKg,
    required this.sensorTimestampMs,
    required this.receivedAt,
    required this.synced,
  });

  final int id;
  final int sessionId;
  final String firebaseSensorId;
  final int sequence;
  final double temp;
  final double hum;
  final double gas;
  final double mic;
  final double db;
  final double ax;
  final double ay;
  final double az;
  final double fx;
  final double fy;
  final double fz;
  final double vbat;
  final double weightKg;
  final int sensorTimestampMs;
  final DateTime receivedAt;
  final bool synced;

  /// Deterministic Firebase key: avoids duplicate uploads on retry.
  String get firebaseKey => '${sensorTimestampMs}_$sequence';

  /// Convert to the map shape expected by Firebase RTDB.
  Map<String, dynamic> toFirebaseMap() => {
        'temp': temp,
        'hum': hum,
        'gas': gas,
        'mic': mic,
        'db': db,
        'ax': ax,
        'ay': ay,
        'az': az,
        'fx': fx,
        'fy': fy,
        'fz': fz,
        if (vbat != 0) 'vbat': vbat,
        if (weightKg != 0) 'weight_kg': weightKg,
        'id': firebaseKey,
        'timestamp': sensorTimestampMs,
      };

  /// Future-facing JSON projection of the shared protobuf envelope.
  Map<String, dynamic> toTelemetryEnvelopeMap() => {
        'schema_version': AppConstants.schemaVersion,
        'message_type': AppConstants.messageTypeTelemetry,
        'device_type': AppConstants.deviceTypeHiveSensor,
        'device_id': firebaseSensorId,
        'timestamp_device_ms': sensorTimestampMs,
        'sequence_number': sequence,
        'source': 'ble_app_sync',
        'payload': {
          'temperature_c': temp,
          'humidity_pct': hum,
          'voc_index': gas,
          'sound_level_db': db,
          'microphone_hz': mic,
          'accel': {
            'x': ax,
            'y': ay,
            'z': az,
          },
          'force': {
            'x': fx,
            'y': fy,
            'z': fz,
          },
          if (vbat != 0) 'battery_volts': vbat,
          if (weightKg != 0) 'weight_kg': weightKg,
        },
      };

  @override
  List<Object?> get props => [
        id, sessionId, firebaseSensorId, sequence,
        temp, hum, gas, mic, db, ax, ay, az, fx, fy, fz,
        vbat, weightKg,
        sensorTimestampMs, receivedAt, synced,
      ];
}
