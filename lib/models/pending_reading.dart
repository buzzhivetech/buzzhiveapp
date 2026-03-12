import 'package:equatable/equatable.dart';

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
        'id': firebaseKey,
        'timestamp': sensorTimestampMs,
      };

  @override
  List<Object?> get props => [
        id, sessionId, firebaseSensorId, sequence,
        temp, hum, gas, mic, db, ax, ay, az, fx, fy, fz,
        sensorTimestampMs, receivedAt, synced,
      ];
}
