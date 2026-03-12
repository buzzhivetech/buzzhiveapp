import 'dart:async';

import '../core/errors/app_exception.dart';
import '../core/utils/app_logger.dart';
import '../models/sensor_reading.dart';
import '../services/firebase/firebase_sensor_data_service.dart';

/// Firebase Realtime DB: stream latest readings, fetch range, check sensor exists.
abstract class SensorDataRepository {
  Future<bool> sensorExists(String firebaseSensorId);
  Stream<Map<String, SensorReading?>> streamLatestReadings(List<String> firebaseSensorIds);
  Future<List<SensorReading>> getReadingsInRange(String firebaseSensorId, int startMs, int endMs);
}

class SensorDataRepositoryImpl implements SensorDataRepository {
  SensorDataRepositoryImpl(this._firebase);

  final FirebaseSensorDataService _firebase;
  static const _log = 'SensorData';

  @override
  Future<bool> sensorExists(String firebaseSensorId) async {
    try {
      final snapshot = await _firebase.readOnce(firebaseSensorId);
      if (!snapshot.exists) {
        AppLogger.debug('sensorExists($firebaseSensorId): not found', name: _log);
        return false;
      }
      final value = snapshot.value;
      if (value == null || value is! Map || (value).isEmpty) {
        AppLogger.debug('sensorExists($firebaseSensorId): empty or non-map', name: _log);
        return false;
      }
      AppLogger.debug('sensorExists($firebaseSensorId): found', name: _log);
      return true;
    } on Object catch (e, st) {
      AppLogger.error('sensorExists failed for $firebaseSensorId', name: _log, error: e, stackTrace: st);
      throw FirebaseReadException(e.toString());
    }
  }

  @override
  Stream<Map<String, SensorReading?>> streamLatestReadings(List<String> firebaseSensorIds) {
    if (firebaseSensorIds.isEmpty) return Stream.value({});
    AppLogger.info('Streaming ${firebaseSensorIds.length} sensor(s)', name: _log);
    return _mergeSensorStreams(firebaseSensorIds);
  }

  /// Try to parse the newest reading from a Firebase value.
  /// Supports two structures:
  ///   Nested: { timestamp1: {temp, hum, ...}, timestamp2: {temp, hum, ...} }
  ///   Flat:   { temp, hum, gas, ..., id, timestamp }
  SensorReading? _parseNewestReading(Object value, String sensorId) {
    if (value is! Map) return null;

    SensorReading? newest;
    bool hasNestedChildren = false;
    for (final entry in value.entries) {
      final child = entry.value;
      if (child is! Map) continue;
      hasNestedChildren = true;
      final reading = SensorReading.fromMap(
        Map<dynamic, dynamic>.from(child),
        timestampKey: entry.key.toString(),
      );
      if (reading != null &&
          (newest == null || reading.timestamp.isAfter(newest.timestamp))) {
        newest = reading;
      }
    }
    if (hasNestedChildren) return newest;

    return SensorReading.fromMap(Map<dynamic, dynamic>.from(value));
  }

  Stream<Map<String, SensorReading?>> _mergeSensorStreams(List<String> ids) {
    final controller = StreamController<Map<String, SensorReading?>>();
    final latest = <String, SensorReading?>{for (final id in ids) id: null};
    final subscriptions = <StreamSubscription>[];

    void emit() => controller.add(Map<String, SensorReading?>.from(latest));

    for (final id in ids) {
      final sub = _firebase.streamValue(id).listen((event) {
        final value = event.snapshot.value;
        if (value != null) {
          final reading = _parseNewestReading(value, id);
          latest[id] = reading;
          if (reading != null) {
            AppLogger.debug('Reading received for $id (temp: ${reading.temp})', name: _log);
          }
        }
        emit();
      }, onError: (Object e, StackTrace st) {
        AppLogger.error('Stream error for sensor $id', name: _log, error: e, stackTrace: st);
        controller.addError(e, st);
      });
      subscriptions.add(sub);
    }

    controller.onCancel = () {
      AppLogger.debug('Stream cancelled for ${ids.length} sensor(s)', name: _log);
      for (final sub in subscriptions) {
        sub.cancel();
      }
    };

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

      bool hasNestedChildren = false;
      for (final entry in value.entries) {
        final child = entry.value;
        if (child is! Map) continue;
        hasNestedChildren = true;
        final reading = SensorReading.fromMap(
          Map<dynamic, dynamic>.from(child),
          timestampKey: entry.key.toString(),
        );
        if (reading != null) {
          final ms = reading.timestamp.millisecondsSinceEpoch;
          if (ms >= startMs && ms <= endMs) list.add(reading);
        }
      }

      if (!hasNestedChildren) {
        final reading = SensorReading.fromMap(Map<dynamic, dynamic>.from(value));
        if (reading != null) {
          final ms = reading.timestamp.millisecondsSinceEpoch;
          if (ms >= startMs && ms <= endMs) list.add(reading);
        }
      }

      list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      AppLogger.debug('getReadingsInRange($firebaseSensorId): ${list.length} readings', name: _log);
      return list;
    } on Object catch (e, st) {
      AppLogger.error('getReadingsInRange failed for $firebaseSensorId', name: _log, error: e, stackTrace: st);
      throw FirebaseReadException(e.toString());
    }
  }
}
