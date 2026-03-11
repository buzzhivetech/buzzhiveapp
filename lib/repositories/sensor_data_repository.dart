import 'dart:async';

import '../core/errors/app_exception.dart';
import '../models/sensor_reading.dart';
import '../services/firebase/firebase_sensor_data_service.dart';

/// Firebase Realtime DB: stream latest readings, fetch range, check sensor exists.
abstract class SensorDataRepository {
  /// True if sensor_data/{firebaseSensorId} exists and has at least one child.
  Future<bool> sensorExists(String firebaseSensorId);

  Stream<Map<String, SensorReading?>> streamLatestReadings(List<String> firebaseSensorIds);

  Future<List<SensorReading>> getReadingsInRange(
    String firebaseSensorId,
    int startMs,
    int endMs,
  );
}

class SensorDataRepositoryImpl implements SensorDataRepository {
  SensorDataRepositoryImpl(this._firebase);

  final FirebaseSensorDataService _firebase;

  @override
  Future<bool> sensorExists(String firebaseSensorId) async {
    try {
      final snapshot = await _firebase.readOnce(firebaseSensorId);
      if (!snapshot.exists) return false;
      final value = snapshot.value;
      if (value == null) return false;
      if (value is! Map) return false;
      return value.isNotEmpty;
    } on Object catch (e) {
      throw FirebaseReadException(e.toString());
    }
  }

  @override
  Stream<Map<String, SensorReading?>> streamLatestReadings(List<String> firebaseSensorIds) {
    if (firebaseSensorIds.isEmpty) return Stream.value({});
    return _mergeSensorStreams(firebaseSensorIds);
  }

  Stream<Map<String, SensorReading?>> _mergeSensorStreams(List<String> ids) {
    final controller = StreamController<Map<String, SensorReading?>>.broadcast();
    final latest = <String, SensorReading?>{};
    for (final id in ids) {
      latest[id] = null;
    }
    void emit() => controller.add(Map.from(latest));
    for (final id in ids) {
      _firebase.streamValue(id).listen((event) {
        final snap = event.snapshot;
        final value = snap.value;
        if (value is Map) {
          SensorReading? newest;
          for (final entry in value.entries) {
            final child = entry.value;
            if (child is! Map) continue;
            final reading = SensorReading.fromMap(
              Map<dynamic, dynamic>.from(child),
              timestampKey: entry.key.toString(),
            );
            if (reading != null &&
                (newest == null ||
                    reading.timestamp.isAfter(newest.timestamp))) {
              newest = reading;
            }
          }
          if (newest != null) {
            latest[id] = newest;
            emit();
          }
        }
      }, onError: controller.addError);
    }
    emit();
    return controller.stream;
  }

  @override
  Future<List<SensorReading>> getReadingsInRange(
    String firebaseSensorId,
    int startMs,
    int endMs,
  ) async {
    try {
      final snapshot = await _firebase.readOnce(firebaseSensorId);
      if (!snapshot.exists || snapshot.value == null) return [];
      final value = snapshot.value;
      if (value is! Map) return [];
      final list = <SensorReading>[];
      for (final entry in value.entries) {
        final child = entry.value;
        if (child is! Map) continue;
        final reading = SensorReading.fromMap(
          Map<dynamic, dynamic>.from(child),
          timestampKey: entry.key.toString(),
        );
        if (reading != null) {
          final ms = reading.timestamp.millisecondsSinceEpoch;
          if (ms >= startMs && ms <= endMs) list.add(reading);
        }
      }
      list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return list;
    } on Object catch (e) {
      throw FirebaseReadException(e.toString());
    }
  }
}
