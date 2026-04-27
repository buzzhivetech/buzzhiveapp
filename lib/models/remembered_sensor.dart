import 'package:equatable/equatable.dart';

/// A BLE device identity remembered after the initial sensor discovery flow.
/// Maps a Firebase sensor ID to the BLE device MAC/ID so future sessions
/// can auto-select the correct device during scanning.
class RememberedSensor extends Equatable {
  const RememberedSensor({
    required this.firebaseSensorId,
    required this.bleDeviceId,
    required this.deviceName,
    required this.addedAt,
    required this.lastSeenAt,
  });

  final String firebaseSensorId;
  final String bleDeviceId;
  final String deviceName;
  final DateTime addedAt;
  final DateTime lastSeenAt;

  @override
  List<Object?> get props => [
        firebaseSensorId,
        bleDeviceId,
        deviceName,
        addedAt,
        lastSeenAt,
      ];

  static RememberedSensor fromMap(Map<String, dynamic> map) {
    return RememberedSensor(
      firebaseSensorId: map['firebase_sensor_id'] as String,
      bleDeviceId: map['ble_device_id'] as String,
      deviceName: map['device_name'] as String? ?? '',
      addedAt: DateTime.parse(map['added_at'] as String),
      lastSeenAt: DateTime.parse(map['last_seen_at'] as String),
    );
  }

  Map<String, dynamic> toMap() => {
        'firebase_sensor_id': firebaseSensorId,
        'ble_device_id': bleDeviceId,
        'device_name': deviceName,
        'added_at': addedAt.toUtc().toIso8601String(),
        'last_seen_at': lastSeenAt.toUtc().toIso8601String(),
      };
}
