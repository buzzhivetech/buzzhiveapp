import 'package:firebase_database/firebase_database.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/app_logger.dart';
import '../../models/pending_reading.dart';

/// Uploads pending readings to Firebase Realtime Database.
/// Uses idempotent keys (`sensorTimestampMs_sequence`) so retries are safe.
class FirebaseUploadSyncService {
  FirebaseUploadSyncService();

  static const _log = 'Sync';

  DatabaseReference get _root => FirebaseDatabase.instance.ref();

  /// Upload a batch of readings. Returns the IDs that were successfully written.
  /// Each reading is written to: sensor_data/{firebaseSensorId}/{firebaseKey}
  Future<List<int>> uploadBatch(List<PendingReading> readings) async {
    if (readings.isEmpty) return [];
    AppLogger.info('Uploading batch of ${readings.length} readings', name: _log);

    final successIds = <int>[];
    final grouped = <String, List<PendingReading>>{};
    for (final r in readings) {
      (grouped[r.firebaseSensorId] ??= []).add(r);
    }

    for (final entry in grouped.entries) {
      final sensorRef = _root
          .child(AppConstants.firebaseSensorDataPath)
          .child(entry.key);

      final updates = <String, dynamic>{};
      for (final r in entry.value) {
        updates[r.firebaseKey] = r.toFirebaseMap();
      }

      try {
        await sensorRef.update(updates);
        successIds.addAll(entry.value.map((r) => r.id));
        AppLogger.debug(
          'Uploaded ${entry.value.length} readings for sensor ${entry.key}',
          name: _log,
        );
      } on Object catch (e, st) {
        AppLogger.error(
          'Failed to upload batch for sensor ${entry.key}',
          name: _log, error: e, stackTrace: st,
        );
      }
    }

    return successIds;
  }
}
