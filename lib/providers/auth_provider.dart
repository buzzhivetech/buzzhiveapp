import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/auth_repository.dart';
import 'service_providers.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final authService = ref.watch(supabaseAuthServiceProvider);
  return AuthRepositoryImpl(authService);
});

final authStateProvider = StreamProvider<bool>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(authRepositoryProvider).currentUserId;
});
