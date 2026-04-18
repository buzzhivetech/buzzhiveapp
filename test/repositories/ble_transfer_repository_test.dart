import 'dart:async';
import 'dart:typed_data';

import 'package:buzzhive_app/generated/proto/buzzhive.pb.dart';
import 'package:buzzhive_app/models/ble_transfer_session.dart';
import 'package:buzzhive_app/repositories/ble_transfer_repository.dart';
import 'package:buzzhive_app/services/bluetooth/ble_sensor_transfer_service.dart';
import 'package:buzzhive_app/services/local/local_packet_store.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _FakeBleService extends Mock implements BleSensorTransferService {}

class _FakeStore extends Mock implements LocalPacketStore {}

DiscoveredDevice _device(String id, String name) => DiscoveredDevice(
      id: id,
      name: name,
      serviceData: const {},
      serviceUuids: const [],
      manufacturerData: Uint8List(0),
      rssi: -40,
    );

void main() {
  setUpAll(() {
    registerFallbackValue(TransferSessionStatus.inProgress);
  });

  group('BleTransferRepository.syncSingleReading', () {
    late _FakeBleService ble;
    late _FakeStore store;
    late BleTransferRepository repo;

    setUp(() {
      ble = _FakeBleService();
      store = _FakeStore();
      repo = BleTransferRepository(ble, store);
    });

    test(
        'captures one protobuf push and persists it as a pending reading',
        () async {
      // Arrange: scan stream yields the target device on the second tick.
      final scanCtrl = StreamController<DiscoveredDevice>();
      final connCtrl = StreamController<ConnectionStateUpdate>();
      final payloadCtrl = StreamController<List<int>>();

      when(() => ble.scanForUnclaimedSensors()).thenAnswer((_) => scanCtrl.stream);
      when(() => ble.connectToDevice(any())).thenAnswer((_) => connCtrl.stream);
      when(() => ble.subscribeToLegacyPayload(any()))
          .thenAnswer((_) => payloadCtrl.stream);
      when(() => ble.requestMtu(any())).thenAnswer((_) async => 185);

      when(() => store.createSession(
            sensorId: any(named: 'sensorId'),
            firebaseSensorId: any(named: 'firebaseSensorId'),
            expectedCount: any(named: 'expectedCount'),
          )).thenAnswer((_) async => 42);
      when(() => store.insertReading(
            sessionId: any(named: 'sessionId'),
            firebaseSensorId: any(named: 'firebaseSensorId'),
            sequence: any(named: 'sequence'),
            temp: any(named: 'temp'),
            hum: any(named: 'hum'),
            gas: any(named: 'gas'),
            mic: any(named: 'mic'),
            db: any(named: 'db'),
            ax: any(named: 'ax'),
            ay: any(named: 'ay'),
            az: any(named: 'az'),
            fx: any(named: 'fx'),
            fy: any(named: 'fy'),
            fz: any(named: 'fz'),
            sensorTimestampMs: any(named: 'sensorTimestampMs'),
          )).thenAnswer((_) async {});
      when(() => store.updateSessionProgress(
            any(),
            receivedCount: any(named: 'receivedCount'),
            lastSeq: any(named: 'lastSeq'),
          )).thenAnswer((_) async {});
      when(() => store.completeSession(any(), any()))
          .thenAnswer((_) async {});

      // Encode a realistic push.
      final msg = BuzzHiveMessage(
        sensorData: SensorData(
          nodeId: 15,
          temp: 34.5,
          humid: 60.0,
          gas: 500.0,
          micFreq: 220.0,
          micDb: 42.0,
          maxX: 0.1,
          maxY: 0.2,
          maxZ: 0.3,
          freqX: 1.0,
          freqY: 2.0,
          freqZ: 3.0,
          vbat: 3.8,
        ),
      ).writeToBuffer();

      // Act: drive the orchestration by pushing events after the
      // subscription is live.
      final states = <SensorSyncState>[];
      final done = Completer<void>();
      final sub = repo
          .syncSingleReading(
            advertisedName: 'BuzzHive-15',
            sensorId: 'sensor-uuid',
            firebaseSensorId: '15',
            timeout: const Duration(seconds: 5),
          )
          .listen(
        states.add,
        onDone: done.complete,
      );

      // Emit events in the right order.
      await Future<void>.delayed(const Duration(milliseconds: 10));
      scanCtrl.add(_device('ABC', 'BuzzHive-15'));

      await Future<void>.delayed(const Duration(milliseconds: 10));
      connCtrl.add(
        const ConnectionStateUpdate(
          deviceId: 'ABC',
          connectionState: DeviceConnectionState.connected,
          failure: null,
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 10));
      payloadCtrl.add(msg);

      await done.future.timeout(const Duration(seconds: 2));
      await sub.cancel();

      // Assert: we saw scanning → connecting → waiting → success.
      expect(states.length, greaterThanOrEqualTo(4));
      expect(states.first, isA<SensorSyncScanning>());
      expect(states.last, isA<SensorSyncSuccess>());
      expect(states.whereType<SensorSyncConnecting>(), isNotEmpty);
      expect(states.whereType<SensorSyncWaiting>(), isNotEmpty);

      // And we inserted exactly one reading mapped from SensorData.
      verify(() => store.createSession(
            sensorId: 'sensor-uuid',
            firebaseSensorId: '15',
            expectedCount: 1,
          )).called(1);
      // Floats get a round-trip through protobuf's 32-bit encoding, so we
      // only assert the structural/id mapping, not exact float equality.
      final insertCall = verify(() => store.insertReading(
            sessionId: 42,
            firebaseSensorId: '15',
            sequence: 0,
            temp: captureAny(named: 'temp'),
            hum: captureAny(named: 'hum'),
            gas: captureAny(named: 'gas'),
            mic: captureAny(named: 'mic'),
            db: captureAny(named: 'db'),
            ax: any(named: 'ax'),
            ay: any(named: 'ay'),
            az: any(named: 'az'),
            fx: any(named: 'fx'),
            fy: any(named: 'fy'),
            fz: any(named: 'fz'),
            sensorTimestampMs: any(named: 'sensorTimestampMs'),
          ))
        ..called(1);
      final captured = insertCall.captured;
      expect(captured[0], closeTo(34.5, 0.01)); // temp
      expect(captured[1], closeTo(60.0, 0.01)); // hum
      expect(captured[2], closeTo(500.0, 0.01)); // gas
      expect(captured[3], closeTo(220.0, 0.01)); // mic
      expect(captured[4], closeTo(42.0, 0.01)); // db
      verify(() => store.completeSession(42, TransferSessionStatus.complete))
          .called(1);
    });

    test('yields SensorSyncFailure if scan never finds the device', () async {
      final scanCtrl = StreamController<DiscoveredDevice>();
      when(() => ble.scanForUnclaimedSensors()).thenAnswer((_) => scanCtrl.stream);

      final states = <SensorSyncState>[];
      await repo
          .syncSingleReading(
            advertisedName: 'BuzzHive-99',
            sensorId: 'sensor-uuid',
            firebaseSensorId: '99',
            timeout: const Duration(milliseconds: 50),
          )
          .forEach(states.add);

      expect(states.last, isA<SensorSyncFailure>());
      final failure = states.last as SensorSyncFailure;
      expect(failure.message, contains('BuzzHive-99'));

      await scanCtrl.close();
    });
  });
}
