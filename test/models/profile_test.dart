import 'package:flutter_test/flutter_test.dart';
import 'package:buzzhive_app/models/profile.dart';

void main() {
  group('Profile.fromMap', () {
    test('parses complete map', () {
      final map = <String, dynamic>{
        'id': 'user-123',
        'display_name': 'Alice',
        'avatar_url': 'https://example.com/avatar.png',
        'created_at': '2024-01-01T00:00:00.000Z',
        'updated_at': '2024-06-01T12:00:00.000Z',
      };
      final profile = Profile.fromMap(map);
      expect(profile.id, 'user-123');
      expect(profile.displayName, 'Alice');
      expect(profile.avatarUrl, 'https://example.com/avatar.png');
      expect(profile.createdAt, DateTime.utc(2024));
    });

    test('handles null optional fields', () {
      final map = <String, dynamic>{
        'id': 'user-456',
        'display_name': null,
        'avatar_url': null,
        'created_at': '2024-01-01T00:00:00.000Z',
        'updated_at': '2024-01-01T00:00:00.000Z',
      };
      final profile = Profile.fromMap(map);
      expect(profile.id, 'user-456');
      expect(profile.displayName, isNull);
      expect(profile.avatarUrl, isNull);
    });
  });
}
