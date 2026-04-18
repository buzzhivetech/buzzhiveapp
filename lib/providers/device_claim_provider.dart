import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/device_claim_repository.dart';
import 'service_providers.dart';

final deviceClaimRepositoryProvider = Provider<DeviceClaimRepository>((ref) {
  return DeviceClaimRepositoryImpl(ref.watch(supabaseClaimServiceProvider));
});
