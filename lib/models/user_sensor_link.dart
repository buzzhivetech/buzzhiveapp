import 'package:equatable/equatable.dart';

import 'sensor.dart';

/// User–sensor link from Supabase (user_sensor_links + sensors join).
class UserSensorLink extends Equatable {
  const UserSensorLink({
    required this.sensor,
    this.displayName,
    required this.linkedAt,
  });

  final Sensor sensor;
  final String? displayName;
  final DateTime linkedAt;

  @override
  List<Object?> get props => [sensor, displayName, linkedAt];
}
