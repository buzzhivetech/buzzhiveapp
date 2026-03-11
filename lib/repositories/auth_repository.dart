import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../core/errors/app_exception.dart';
import '../services/supabase/supabase_auth_service.dart';

/// Supabase auth: sign up, sign in, sign out, session.
abstract class AuthRepository {
  Stream<bool> get authStateChanges;
  Future<void> signIn(String email, String password);
  Future<void> signUp(String email, String password);
  Future<void> signOut();
  String? get currentUserId;
}

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._authService);

  final SupabaseAuthService _authService;

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
    } on supabase.AuthException catch (e) {
      throw AuthException(e.message, code: e.statusCode);
    } on Object catch (e) {
      throw AuthException(e.toString());
    }
  }

  @override
  Future<void> signUp(String email, String password) async {
    try {
      await _authService.signUp(email: email, password: password);
    } on supabase.AuthException catch (e) {
      throw AuthException(e.message, code: e.statusCode);
    } on Object catch (e) {
      throw AuthException(e.toString());
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _authService.signOut();
    } on supabase.AuthException catch (e) {
      throw AuthException(e.message, code: e.statusCode);
    } on Object catch (e) {
      throw AuthException(e.toString());
    }
  }
}
