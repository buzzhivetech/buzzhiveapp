import '../core/errors/app_exception.dart';
import '../models/profile.dart';

/// Supabase profiles: get and update current user profile.
abstract class ProfileRepository {
  Future<Profile?> getProfile(String userId);
  Future<void> updateProfile(String userId, {String? displayName, String? avatarUrl});
}

class ProfileRepositoryImpl implements ProfileRepository {
  @override
  Future<Profile?> getProfile(String userId) async {
    throw const NotFoundException('Not implemented: configure Supabase');
  }

  @override
  Future<void> updateProfile(String userId, {String? displayName, String? avatarUrl}) async {
    throw const AppException('Not implemented: configure Supabase');
  }
}
