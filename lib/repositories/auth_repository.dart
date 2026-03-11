import '../core/errors/app_exception.dart';

/// Supabase auth: sign up, sign in, sign out, session.
abstract class AuthRepository {
  /// Current session if logged in.
  Stream<bool> get authStateChanges;

  /// Sign in with email and password.
  Future<void> signIn(String email, String password);

  /// Sign up with email and password.
  Future<void> signUp(String email, String password);

  /// Sign out.
  Future<void> signOut();

  /// Current user id if authenticated.
  String? get currentUserId;
}

/// Stub implementation; replace with Supabase client.
class AuthRepositoryImpl implements AuthRepository {
  @override
  Stream<bool> get authStateChanges => Stream.value(false);

  @override
  Future<void> signIn(String email, String password) async {
    throw const AuthException('Not implemented: configure Supabase');
  }

  @override
  Future<void> signUp(String email, String password) async {
    throw const AuthException('Not implemented: configure Supabase');
  }

  @override
  Future<void> signOut() async {}

  @override
  String? get currentUserId => null;
}
