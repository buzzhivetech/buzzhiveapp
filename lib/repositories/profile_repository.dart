import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../core/errors/app_exception.dart';
import '../core/utils/app_logger.dart';
import '../models/profile.dart';
import '../services/supabase/supabase_user_data_service.dart';

/// Supabase profiles: get and update current user profile (RLS: own row only).
abstract class ProfileRepository {
  Future<Profile?> getProfile(String userId);
  Future<void> updateProfile(String userId, {String? displayName, String? avatarUrl});
}

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._userData);

  final SupabaseUserDataService _userData;
  static const _log = 'Profile';

  @override
  Future<Profile?> getProfile(String userId) async {
    try {
      final map = await _userData.getProfile(userId);
      AppLogger.debug('getProfile($userId): ${map != null ? 'found' : 'null'}', name: _log);
      return map == null ? null : Profile.fromMap(map);
    } on supabase.PostgrestException catch (e, st) {
      AppLogger.error('getProfile failed: ${e.message}', name: _log, error: e, stackTrace: st);
      throw AppException(e.message, code: e.code);
    } on Object catch (e, st) {
      AppLogger.error('getProfile unexpected error', name: _log, error: e, stackTrace: st);
      throw AppException(e.toString());
    }
  }

  @override
  Future<void> updateProfile(String userId, {String? displayName, String? avatarUrl}) async {
    try {
      await _userData.updateProfile(userId, displayName: displayName, avatarUrl: avatarUrl);
      AppLogger.info('Profile updated for $userId', name: _log);
    } on supabase.PostgrestException catch (e, st) {
      AppLogger.error('updateProfile failed: ${e.message}', name: _log, error: e, stackTrace: st);
      throw AppException(e.message, code: e.code);
    } on Object catch (e, st) {
      AppLogger.error('updateProfile unexpected error', name: _log, error: e, stackTrace: st);
      throw AppException(e.toString());
    }
  }
}
