import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:buzzhive_app/core/errors/app_exception.dart';
import 'package:buzzhive_app/features/sensors/presentation/widgets/manual_entry_tab.dart';
import 'package:buzzhive_app/providers/device_claim_provider.dart';
import 'package:buzzhive_app/repositories/device_claim_repository.dart';

class MockDeviceClaimRepository extends Mock implements DeviceClaimRepository {}

Future<void> _pumpManualTab(
  WidgetTester tester,
  DeviceClaimRepository repo,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        deviceClaimRepositoryProvider.overrideWithValue(repo),
      ],
      child: const MaterialApp(
        home: Scaffold(body: ManualEntryTab()),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('ManualEntryTab', () {
    testWidgets('renders device ID + claim code fields and claim button',
        (tester) async {
      await _pumpManualTab(tester, MockDeviceClaimRepository());

      expect(find.widgetWithText(TextFormField, 'Device ID'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Claim code'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Claim sensor'), findsOneWidget);
    });

    testWidgets('shows validation errors when fields are empty', (tester) async {
      final repo = MockDeviceClaimRepository();
      await _pumpManualTab(tester, repo);

      await tester.tap(find.widgetWithText(FilledButton, 'Claim sensor'));
      await tester.pump();

      expect(find.text('Enter the device ID'), findsOneWidget);
      expect(find.text('Enter the claim code'), findsOneWidget);
      verifyNever(() => repo.claim(
            deviceId: any(named: 'deviceId'),
            claimCode: any(named: 'claimCode'),
          ));
    });

    testWidgets('calls repo.claim with entered values', (tester) async {
      final repo = MockDeviceClaimRepository();
      when(() => repo.claim(
            deviceId: any(named: 'deviceId'),
            claimCode: any(named: 'claimCode'),
          )).thenAnswer(
        (_) async => const ClaimedSensor(sensorId: 's-1', deviceId: '10001'),
      );

      await _pumpManualTab(tester, repo);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Device ID'),
        '10001',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Claim code'),
        'ABCDEFGH',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Claim sensor'));
      await tester.pump();

      verify(() => repo.claim(deviceId: '10001', claimCode: 'ABCDEFGH')).called(1);
    });

    testWidgets('surfaces failure message from the controller', (tester) async {
      final repo = MockDeviceClaimRepository();
      when(() => repo.claim(
            deviceId: any(named: 'deviceId'),
            claimCode: any(named: 'claimCode'),
          )).thenThrow(const ClaimException(
        'Claim code does not match.',
        code: ClaimErrorCode.wrongCode,
      ));

      await _pumpManualTab(tester, repo);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Device ID'),
        '10001',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Claim code'),
        'WRONGCODE',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Claim sensor'));
      await tester.pumpAndSettle();

      expect(find.text('Claim code does not match.'), findsOneWidget);
    });
  });
}
