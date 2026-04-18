import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import 'package:buzzhive_app/core/errors/app_exception.dart';
import 'package:buzzhive_app/repositories/device_claim_repository.dart';
import 'package:buzzhive_app/services/supabase/supabase_claim_service.dart';

class MockClaimService extends Mock implements SupabaseClaimService {}

Map<String, dynamic> _row({
  required bool ok,
  String? errorCode,
  String? sensorId,
}) =>
    {'ok': ok, 'error_code': errorCode, 'sensor_id': sensorId};

void main() {
  late MockClaimService service;
  late DeviceClaimRepositoryImpl repo;

  setUp(() {
    service = MockClaimService();
    repo = DeviceClaimRepositoryImpl(service);
  });

  group('input validation', () {
    test('empty device id throws ValidationException without hitting service', () async {
      expect(
        () => repo.claim(deviceId: '  ', claimCode: 'ABCDEF'),
        throwsA(isA<ValidationException>()),
      );
      verifyNever(() => service.claimSensor(
            deviceId: any(named: 'deviceId'),
            claimCode: any(named: 'claimCode'),
          ));
    });

    test('empty claim code throws ValidationException', () async {
      expect(
        () => repo.claim(deviceId: '10001', claimCode: ''),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('success path', () {
    test('returns ClaimedSensor on ok=true', () async {
      when(() => service.claimSensor(
            deviceId: '10001',
            claimCode: 'ABCDEFGH',
          )).thenAnswer(
        (_) async => _row(ok: true, sensorId: 'sensor-uuid-1'),
      );

      final result = await repo.claim(deviceId: '10001', claimCode: 'abcdefgh');
      expect(result.sensorId, 'sensor-uuid-1');
      expect(result.deviceId, '10001');
      verify(() => service.claimSensor(deviceId: '10001', claimCode: 'ABCDEFGH')).called(1);
    });
  });

  group('error_code mapping', () {
    final cases = <String, String>{
      ClaimErrorCode.notAuthenticated: 'not_authenticated',
      ClaimErrorCode.rateLimited: 'rate_limited',
      ClaimErrorCode.unknownDevice: 'unknown_device',
      ClaimErrorCode.disabledDevice: 'disabled_device',
      ClaimErrorCode.alreadyClaimed: 'already_claimed',
      ClaimErrorCode.wrongCode: 'wrong_code',
    };

    for (final entry in cases.entries) {
      test('${entry.value} -> ClaimException with matching code', () async {
        when(() => service.claimSensor(
              deviceId: any(named: 'deviceId'),
              claimCode: any(named: 'claimCode'),
            )).thenAnswer(
          (_) async => _row(ok: false, errorCode: entry.value),
        );

        expect(
          () => repo.claim(deviceId: '10001', claimCode: 'ABCDEFGH'),
          throwsA(isA<ClaimException>().having((e) => e.code, 'code', entry.value)),
        );
      });
    }

    test('unknown error_code falls back to a generic ClaimException', () async {
      when(() => service.claimSensor(
            deviceId: any(named: 'deviceId'),
            claimCode: any(named: 'claimCode'),
          )).thenAnswer(
        (_) async => _row(ok: false, errorCode: 'novel_error'),
      );

      expect(
        () => repo.claim(deviceId: '10001', claimCode: 'ABCDEFGH'),
        throwsA(isA<ClaimException>().having((e) => e.code, 'code', 'novel_error')),
      );
    });
  });

  group('unexpected failures', () {
    test('PostgrestException becomes AppException with code', () async {
      when(() => service.claimSensor(
            deviceId: any(named: 'deviceId'),
            claimCode: any(named: 'claimCode'),
          )).thenThrow(
        const supabase.PostgrestException(message: 'RLS denied', code: '42501'),
      );

      expect(
        () => repo.claim(deviceId: '10001', claimCode: 'ABCDEFGH'),
        throwsA(
          isA<AppException>()
              .having((e) => e.code, 'code', '42501')
              .having((e) => e is ClaimException, 'not a ClaimException', isFalse),
        ),
      );
    });

    test('unexpected exception becomes AppException', () async {
      when(() => service.claimSensor(
            deviceId: any(named: 'deviceId'),
            claimCode: any(named: 'claimCode'),
          )).thenThrow(Exception('network'));

      expect(
        () => repo.claim(deviceId: '10001', claimCode: 'ABCDEFGH'),
        throwsA(isA<AppException>()),
      );
    });
  });
}
