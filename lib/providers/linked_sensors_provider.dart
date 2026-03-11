import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_sensor_link.dart';
import '../repositories/sensor_link_repository.dart';
import 'auth_provider.dart';

final sensorLinkRepositoryProvider = Provider<SensorLinkRepository>((ref) {
  return SensorLinkRepositoryImpl();
});

final linkedSensorsProvider = FutureProvider<List<UserSensorLink>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];
  return ref.watch(sensorLinkRepositoryProvider).getLinkedSensors(userId);
});
