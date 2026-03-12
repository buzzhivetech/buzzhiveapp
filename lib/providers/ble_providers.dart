import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/ble_transfer_repository.dart';
import '../repositories/sync_repository.dart';
import '../services/bluetooth/ble_sensor_transfer_service.dart';
import '../services/local/local_packet_store.dart';
import '../services/sync/firebase_upload_sync_service.dart';

// ---- Services ----

final bleSensorTransferServiceProvider = Provider<BleSensorTransferService>((ref) {
  return BleSensorTransferService();
});

final localPacketStoreProvider = Provider<LocalPacketStore>((ref) {
  return LocalPacketStore();
});

final firebaseUploadSyncServiceProvider = Provider<FirebaseUploadSyncService>((ref) {
  return FirebaseUploadSyncService();
});

// ---- Repositories ----

final bleTransferRepositoryProvider = Provider<BleTransferRepository>((ref) {
  return BleTransferRepository(
    ref.watch(bleSensorTransferServiceProvider),
    ref.watch(localPacketStoreProvider),
  );
});

final syncRepositoryProvider = Provider<SyncRepository>((ref) {
  return SyncRepository(
    ref.watch(localPacketStoreProvider),
    ref.watch(firebaseUploadSyncServiceProvider),
  );
});

// ---- State ----

/// BLE adapter status (on/off/unauthorized).
final bleAdapterStatusProvider = StreamProvider<BleStatus>((ref) {
  return ref.watch(bleSensorTransferServiceProvider).statusStream;
});

/// Number of readings waiting to be uploaded.
final pendingSyncCountProvider = FutureProvider<int>((ref) {
  return ref.watch(syncRepositoryProvider).pendingCount;
});
