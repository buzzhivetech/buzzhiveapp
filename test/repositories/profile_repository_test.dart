import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import 'package:buzzhive_app/core/errors/app_exception.dart';
import 'package:buzzhive_app/repositories/profile_repository.dart';
import 'package:buzzhive_app/services/supabase/supabase_user_data_service.dart';

class MockUserDataService extends Mock implements SupabaseUserDataService {}

void main() {
  late MockUserDataService mockData;
  late ProfileRepositoryImpl repo;

  setUp(() {
    mockData = MockUserDataService();
    repo = ProfileRepositoryImpl(mockData);
  });

  group('getProfile', () {
    test('returns profile when found', () async {
      when(() => mockData.getProfile('uid-1')).thenAnswer((_) async => {
            'id': 'uid-1',
            'display_name': 'Alice',
            'avatar_url': null,
            'created_at': '2024-01-01T00:00:00.000Z',
            'updated_at': '2024-01-01T00:00:00.000Z',
          });

      final profile = await repo.getProfile('uid-1');
      expect(profile, isNotNull);
      expect(profile!.id, 'uid-1');
      expect(profile.displayName, 'Alice');
    });

    test('returns null when not found', () async {
      when(() => mockData.getProfile('uid-2')).thenAnswer((_) async => null);

      final profile = await repo.getProfile('uid-2');
      expect(profile, isNull);
    });

    test('throws AppException on PostgrestException', () async {
      when(() => mockData.getProfile(any())).thenThrow(
        supabase.PostgrestException(message: 'RLS denied', code: '42501'),
      );

      expect(
        () => repo.getProfile('uid-3'),
        throwsA(isA<AppException>().having((e) => e.code, 'code', '42501')),
      );
    });
  });
}
