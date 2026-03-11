import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/sensor_reading.dart';
import '../repositories/sensor_data_repository.dart';
import 'linked_sensors_provider.dart';

final sensorDataRepositoryProvider = Provider<SensorDataRepository>((ref) {
  return SensorDataRepositoryImpl();
});

/// Latest readings per firebase_sensor_id for the current user's linked sensors.
final latestReadingsProvider = StreamProvider<Map<String, SensorReading?>>((ref) {
  final links = ref.watch(linkedSensorsProvider).valueOrNull ?? [];
  final ids = links.map((l) => l.sensor.firebaseSensorId).toList();
  if (ids.isEmpty) return Stream.value({});
  return ref.watch(sensorDataRepositoryProvider).streamLatestReadings(ids);
});
