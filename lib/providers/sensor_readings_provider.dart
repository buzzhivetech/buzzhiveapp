import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/sensor_reading.dart';
import '../repositories/sensor_data_repository.dart';
import 'linked_sensors_provider.dart';
import 'service_providers.dart';

final sensorDataRepositoryProvider = Provider<SensorDataRepository>((ref) {
  return SensorDataRepositoryImpl(ref.watch(firebaseSensorDataServiceProvider));
});

/// Latest readings per firebase_sensor_id for the current user's linked sensors.
final latestReadingsProvider = StreamProvider<Map<String, SensorReading?>>((ref) {
  final links = ref.watch(linkedSensorsProvider).valueOrNull ?? [];
  final ids = links.map((l) => l.sensor.firebaseSensorId).toList();
  if (ids.isEmpty) return Stream.value({});
  return ref.watch(sensorDataRepositoryProvider).streamLatestReadings(ids);
});

/// Parameter tuple for [readingsInRangeProvider].
class ReadingsRangeParams extends Equatable {
  const ReadingsRangeParams(this.sensorId, this.startMs, this.endMs);

  final String sensorId;
  final int startMs;
  final int endMs;

  @override
  List<Object?> get props => [sensorId, startMs, endMs];
}

/// Fetches historical readings for a sensor within a time window.
/// Used by the analytics screen for chart data.
final readingsInRangeProvider =
    FutureProvider.family<List<SensorReading>, ReadingsRangeParams>(
  (ref, params) {
    return ref
        .watch(sensorDataRepositoryProvider)
        .getReadingsInRange(params.sensorId, params.startMs, params.endMs);
  },
);
