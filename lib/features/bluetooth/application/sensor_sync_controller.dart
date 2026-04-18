import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/app_router.dart';
import '../../../providers/ble_providers.dart';
import '../../../repositories/ble_transfer_repository.dart';
import '../../../repositories/sync_repository.dart';

/// Drives a single-shot BLE pull for one targeted sensor. Mirrors the
/// `DeviceClaimController` pattern: sealed state, `StateNotifier`, and an
/// `autoDispose.family` provider that keys on the route args so navigating
/// away cleans up the BLE subscription.
class SensorSyncController extends StateNotifier<SensorSyncState> {
  SensorSyncController({
    required BleTransferRepository repository,
    required SyncRepository syncRepository,
    required BleDownloadArgs args,
  })  : _repo = repository,
        _sync = syncRepository,
        _args = args,
        super(const SensorSyncIdle());

  final BleTransferRepository _repo;
  final SyncRepository _sync;
  final BleDownloadArgs _args;
  StreamSubscription<SensorSyncState>? _sub;

  /// Kick off the sync. Safe to call multiple times — any in-flight attempt
  /// is cancelled first.
  void start() {
    _sub?.cancel();
    _sub = _repo
        .syncSingleReading(
          advertisedName: _args.advertisedName,
          sensorId: _args.sensorId,
          firebaseSensorId: _args.firebaseSensorId,
        )
        .listen(
      (s) {
        if (!mounted) return;
        state = s;
        if (s is SensorSyncSuccess) {
          // Fire-and-forget upload; failures are logged upstream and
          // don't affect the "reading captured" UX.
          unawaited(_sync.syncNow());
        }
      },
      onError: (Object e) {
        if (!mounted) return;
        state = SensorSyncFailure(e.toString());
      },
    );
  }

  void cancel() {
    _sub?.cancel();
    _sub = null;
    if (mounted) state = const SensorSyncIdle();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final sensorSyncControllerProvider = StateNotifierProvider.autoDispose
    .family<SensorSyncController, SensorSyncState, BleDownloadArgs>(
  (ref, args) {
    return SensorSyncController(
      repository: ref.watch(bleTransferRepositoryProvider),
      syncRepository: ref.watch(syncRepositoryProvider),
      args: args,
    );
  },
);
