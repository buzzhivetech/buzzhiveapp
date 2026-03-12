import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../core/errors/app_exception.dart';
import '../core/utils/app_logger.dart';
import '../services/supabase/supabase_auth_service.dart';

/// Supabase auth: sign up, sign in, sign out, account management.
abstract class AuthRepository {
  Stream<bool> get authStateChanges;
  Future<void> signIn(String email, String password);
  Future<void> signUp(String email, String password);
  Future<void> signOut();
  String? get currentUserId;
  Future<void> updateEmail(String newEmail);
  Future<void> updatePassword(String newPassword);
  Future<void> deleteAccount();
}

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._authService);

  final SupabaseAuthService _authService;
  static const _log = 'Auth';

  @override
  Stream<bool> get authStateChanges => _authService.authStateChanges.map((state) {
        return state.session != null;
      });

  @override
  String? get currentUserId => _authService.currentUserId;

  @override
  Future<void> signIn(String email, String password) async {
    try {
      await _authService.signInWithPassword(email: email, password: password);
      AppLogger.info('Sign-in succeeded for $email', name: _log);
    } on supabase.AuthException catch (e, st) {
      AppLogger.error('Sign-in failed: ${e.message}', name: _log, error: e, stackTrace: st);
      throw AuthException(e.message, code: e.statusCode);
    } on Object catch (e, st) {
      AppLogger.error('Sign-in unexpected error', name: _log, error: e, stackTrace: st);
      throw AuthException(e.toString());
    }
  }

  @override
  Future<void> signUp(String email, String password) async {
    try {
      await _authService.signUp(email: email, password: password);
      AppLogger.info('Sign-up succeeded for $email', name: _log);
    } on supabase.AuthException catch (e, st) {
      AppLogger.error('Sign-up failed: ${e.message}', name: _log, error: e, stackTrace: st);
      throw AuthException(e.message, code: e.statusCode);
    } on Object catch (e, st) {
      AppLogger.error('Sign-up unexpected error', name: _log, error: e, stackTrace: st);
      throw AuthException(e.toString());
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _authService.signOut();
      AppLogger.info('Sign-out succeeded', name: _log);
    } on supabase.AuthException catch (e, st) {
      AppLogger.error('Sign-out failed: ${e.message}', name: _log, error: e, stackTrace: st);
      throw AuthException(e.message, code: e.statusCode);
    } on Object catch (e, st) {
      AppLogger.error('Sign-out unexpected error', name: _log, error: e, stackTrace: st);
      throw AuthException(e.toString());
    }
  }

  @override
  Future<void> updateEmail(String newEmail) async {
    try {
      await _authService.updateEmail(newEmail);
      AppLogger.info('Email update requested', name: _log);
    } on supabase.AuthException catch (e, st) {
      AppLogger.error('Email update failed: ${e.message}', name: _log, error: e, stackTrace: st);
      throw AuthException(e.message, code: e.statusCode);
    } on Object catch (e, st) {
      AppLogger.error('Email update unexpected error', name: _log, error: e, stackTrace: st);
      throw AuthException(e.toString());
    }
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    try {
      await _authService.updatePassword(newPassword);
      AppLogger.info('Password updated', name: _log);
    } on supabase.AuthException catch (e, st) {
      AppLogger.error('Password update failed: ${e.message}', name: _log, error: e, stackTrace: st);
      throw AuthException(e.message, code: e.statusCode);
    } on Object catch (e, st) {
      AppLogger.error('Password update unexpected error', name: _log, error: e, stackTrace: st);
      throw AuthException(e.toString());
    }
  }

  @override
  Future<void> deleteAccount() async {
    try {
      await _authService.deleteAccount();
      AppLogger.info('Account deleted', name: _log);
    } on supabase.AuthException catch (e, st) {
      AppLogger.error('Account delete failed: ${e.message}', name: _log, error: e, stackTrace: st);
      throw AuthException(e.message, code: e.statusCode);
    } on Object catch (e, st) {
      AppLogger.error('Account delete unexpected error', name: _log, error: e, stackTrace: st);
      throw AuthException(e.toString());
    }
  }
}
