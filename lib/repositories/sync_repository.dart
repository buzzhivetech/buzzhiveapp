import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import '../core/errors/app_exception.dart';
import '../core/utils/app_logger.dart';
import '../services/local/local_packet_store.dart';
import '../services/sync/firebase_upload_sync_service.dart';

/// Manages the upload queue: drains unsynced readings from local store
/// to Firebase in batches, respecting connectivity policy.
class SyncRepository {
  SyncRepository(this._store, this._upload, {Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final LocalPacketStore _store;
  final FirebaseUploadSyncService _upload;
  final Connectivity _connectivity;
  static const _log = 'Sync';

  static const int _batchSize = 50;

  bool _syncing = false;

  /// Number of readings waiting to be uploaded.
  Future<int> get pendingCount => _store.getUnsyncedCount();

  /// Run one sync cycle: upload all unsynced readings in batches.
  /// Returns the total number of readings successfully uploaded.
  /// Throws [SyncException] if connectivity is unavailable.
  Future<int> syncNow({bool wifiOnly = false}) async {
    if (_syncing) {
      AppLogger.debug('Sync already in progress, skipping', name: _log);
      return 0;
    }
    _syncing = true;

    try {
      final connectivityResults = await _connectivity.checkConnectivity();
      final hasWifi = connectivityResults.contains(ConnectivityResult.wifi);
      final hasAny = connectivityResults.any((r) =>
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.ethernet);

      if (wifiOnly && !hasWifi) {
        AppLogger.info('Sync skipped: Wi-Fi only but not on Wi-Fi', name: _log);
        return 0;
      }
      if (!hasAny) {
        throw const SyncException('No internet connection');
      }

      var totalUploaded = 0;
      while (true) {
        final batch = await _store.getUnsyncedReadings(limit: _batchSize);
        if (batch.isEmpty) break;

        final successIds = await _upload.uploadBatch(batch);
        if (successIds.isNotEmpty) {
          await _store.markSynced(successIds);
          totalUploaded += successIds.length;
        }
        if (successIds.length < batch.length) {
          AppLogger.warn(
            'Partial batch: ${successIds.length}/${batch.length} succeeded',
            name: _log,
          );
          break;
        }
      }

      AppLogger.info('Sync complete: $totalUploaded readings uploaded', name: _log);
      return totalUploaded;
    } finally {
      _syncing = false;
    }
  }

  /// Stream that fires whenever connectivity changes, so the UI / provider
  /// can trigger auto-sync.
  Stream<List<ConnectivityResult>> get connectivityChanges =>
      _connectivity.onConnectivityChanged;

  /// Purge synced readings older than 7 days.
  Future<int> purgeOldSyncedReadings() {
    return _store.purgeSyncedBefore(
      DateTime.now().subtract(const Duration(days: 7)),
    );
  }
}
