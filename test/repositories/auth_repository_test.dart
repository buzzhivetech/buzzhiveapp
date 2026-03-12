import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import 'package:buzzhive_app/core/errors/app_exception.dart';
import 'package:buzzhive_app/repositories/auth_repository.dart';
import 'package:buzzhive_app/services/supabase/supabase_auth_service.dart';

class MockSupabaseAuthService extends Mock implements SupabaseAuthService {}

class FakeAuthResponse extends Fake implements supabase.AuthResponse {}

void main() {
  late MockSupabaseAuthService mockAuth;
  late AuthRepositoryImpl repo;

  setUp(() {
    mockAuth = MockSupabaseAuthService();
    repo = AuthRepositoryImpl(mockAuth);
  });

  group('signIn', () {
    test('succeeds when service returns normally', () async {
      when(() => mockAuth.signInWithPassword(email: any(named: 'email'), password: any(named: 'password')))
          .thenAnswer((_) async => FakeAuthResponse());

      await expectLater(repo.signIn('test@example.com', 'pass123'), completes);
    });

    test('throws AuthException on supabase AuthException', () async {
      when(() => mockAuth.signInWithPassword(email: any(named: 'email'), password: any(named: 'password')))
          .thenThrow(const supabase.AuthException('Invalid login'));

      expect(
        () => repo.signIn('test@example.com', 'wrong'),
        throwsA(isA<AuthException>().having((e) => e.message, 'message', 'Invalid login')),
      );
    });

    test('throws AuthException on unexpected error', () async {
      when(() => mockAuth.signInWithPassword(email: any(named: 'email'), password: any(named: 'password')))
          .thenThrow(Exception('network'));

      expect(
        () => repo.signIn('test@example.com', 'pass'),
        throwsA(isA<AuthException>()),
      );
    });
  });

  group('signUp', () {
    test('succeeds when service returns normally', () async {
      when(() => mockAuth.signUp(email: any(named: 'email'), password: any(named: 'password')))
          .thenAnswer((_) async => FakeAuthResponse());

      await expectLater(repo.signUp('new@example.com', 'pass123'), completes);
    });

    test('throws AuthException on supabase AuthException', () async {
      when(() => mockAuth.signUp(email: any(named: 'email'), password: any(named: 'password')))
          .thenThrow(const supabase.AuthException('User exists'));

      expect(
        () => repo.signUp('new@example.com', 'pass'),
        throwsA(isA<AuthException>().having((e) => e.message, 'message', 'User exists')),
      );
    });
  });

  group('signOut', () {
    test('succeeds when service returns normally', () async {
      when(() => mockAuth.signOut()).thenAnswer((_) async {});

      await expectLater(repo.signOut(), completes);
    });

    test('throws AuthException on failure', () async {
      when(() => mockAuth.signOut()).thenThrow(const supabase.AuthException('Session expired'));

      expect(
        () => repo.signOut(),
        throwsA(isA<AuthException>()),
      );
    });
  });

  group('currentUserId', () {
    test('delegates to service', () {
      when(() => mockAuth.currentUserId).thenReturn('uid-123');
      expect(repo.currentUserId, 'uid-123');
    });

    test('returns null when not signed in', () {
      when(() => mockAuth.currentUserId).thenReturn(null);
      expect(repo.currentUserId, isNull);
    });
  });
}
