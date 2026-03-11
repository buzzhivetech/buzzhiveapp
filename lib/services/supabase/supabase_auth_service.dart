import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/env.dart';

/// Supabase authentication only. No Firebase or user data tables.
/// Call [initSupabase] from main before using.
class SupabaseAuthService {
  SupabaseAuthService();

  GoTrueClient get _auth => Supabase.instance.client.auth;

  bool get isConfigured => Env.hasSupabaseConfig;

  Session? get currentSession => _auth.currentSession;

  User? get currentUser => _auth.currentUser;

  String? get currentUserId => _auth.currentUser?.id;

  Stream<AuthState> get authStateChanges => _auth.onAuthStateChange;

  /// Sign in with email and password.
  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) {
    if (!isConfigured) {
      throw StateError('Supabase not configured: set SUPABASE_URL and SUPABASE_ANON_KEY');
    }
    return _auth.signInWithPassword(email: email, password: password);
  }

  /// Sign up with email and password.
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) {
    if (!isConfigured) {
      throw StateError('Supabase not configured: set SUPABASE_URL and SUPABASE_ANON_KEY');
    }
    return _auth.signUp(email: email, password: password);
  }

  /// Sign out.
  Future<void> signOut() => _auth.signOut();
}
