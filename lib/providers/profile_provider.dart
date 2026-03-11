import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/profile.dart';
import '../repositories/profile_repository.dart';
import 'auth_provider.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepositoryImpl();
});

final profileProvider = FutureProvider<Profile?>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;
  return ref.watch(profileRepositoryProvider).getProfile(userId);
});
