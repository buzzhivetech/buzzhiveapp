import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../providers/device_claim_provider.dart';
import '../../../repositories/device_claim_repository.dart';

/// UI state for the Add Sensor flow across its three tabs (QR / BLE / Manual).
sealed class DeviceClaimState {
  const DeviceClaimState();
}

class DeviceClaimIdle extends DeviceClaimState {
  const DeviceClaimIdle();
}

class DeviceClaimSubmitting extends DeviceClaimState {
  const DeviceClaimSubmitting();
}

class DeviceClaimSuccess extends DeviceClaimState {
  const DeviceClaimSuccess(this.sensor);
  final ClaimedSensor sensor;
}

class DeviceClaimFailure extends DeviceClaimState {
  const DeviceClaimFailure(this.message, {this.code});
  final String message;
  final String? code;
}

/// Hand-written Riverpod 2 StateNotifier (matches repo style; no codegen).
class DeviceClaimController extends StateNotifier<DeviceClaimState> {
  DeviceClaimController(this._repo) : super(const DeviceClaimIdle());

  final DeviceClaimRepository _repo;

  Future<void> claim({required String deviceId, required String claimCode}) async {
    state = const DeviceClaimSubmitting();
    try {
      final sensor = await _repo.claim(deviceId: deviceId, claimCode: claimCode);
      state = DeviceClaimSuccess(sensor);
    } on ClaimException catch (e) {
      state = DeviceClaimFailure(e.message, code: e.code);
    } on ValidationException catch (e) {
      state = DeviceClaimFailure(e.message, code: e.code);
    } on AppException catch (e) {
      state = DeviceClaimFailure(e.message, code: e.code);
    } on Object catch (_) {
      state = const DeviceClaimFailure('Something went wrong. Please try again.');
    }
  }

  void reset() => state = const DeviceClaimIdle();
}

final deviceClaimControllerProvider =
    StateNotifierProvider.autoDispose<DeviceClaimController, DeviceClaimState>((ref) {
  return DeviceClaimController(ref.watch(deviceClaimRepositoryProvider));
});
