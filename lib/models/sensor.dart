import 'package:equatable/equatable.dart';

/// Sensor record from Supabase (sensors table); identified by Firebase node ID.
class Sensor extends Equatable {
  const Sensor({
    required this.id,
    required this.firebaseSensorId,
    this.displayName,
    required this.createdAt,
  });

  final String id;
  final String firebaseSensorId;
  final String? displayName;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, firebaseSensorId, displayName, createdAt];

  static Sensor fromMap(Map<String, dynamic> map) {
    return Sensor(
      id: map['id'] as String,
      firebaseSensorId: map['firebase_sensor_id'] as String,
      displayName: map['display_name'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
