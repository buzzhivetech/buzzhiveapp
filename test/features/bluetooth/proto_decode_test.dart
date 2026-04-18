import 'package:buzzhive_app/generated/proto/buzzhive.pb.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BuzzHiveMessage protobuf decoding', () {
    test('decodes SensorData variant round-trip', () {
      final original = BuzzHiveMessage(
        sensorData: SensorData(
          nodeId: 15,
          micFreq: 220.5,
          micDb: 42.25,
          freqX: 1.0,
          freqY: 2.0,
          freqZ: 3.0,
          maxX: 0.1,
          maxY: 0.2,
          maxZ: 0.3,
          temp: 34.5,
          humid: 60.0,
          gas: 500.0,
          vbat: 3.8,
        ),
      );

      final bytes = original.writeToBuffer();
      final decoded = BuzzHiveMessage.fromBuffer(bytes);

      expect(decoded.whichPayload(), BuzzHiveMessage_Payload.sensorData);
      final s = decoded.sensorData;
      expect(s.nodeId, 15);
      expect(s.temp, closeTo(34.5, 0.001));
      expect(s.humid, closeTo(60.0, 0.001));
      expect(s.gas, closeTo(500.0, 0.001));
      expect(s.micFreq, closeTo(220.5, 0.001));
      expect(s.micDb, closeTo(42.25, 0.001));
      expect(s.freqX, closeTo(1.0, 0.001));
      expect(s.freqY, closeTo(2.0, 0.001));
      expect(s.freqZ, closeTo(3.0, 0.001));
      expect(s.maxX, closeTo(0.1, 0.001));
      expect(s.maxY, closeTo(0.2, 0.001));
      expect(s.maxZ, closeTo(0.3, 0.001));
      expect(s.vbat, closeTo(3.8, 0.001));
    });

    test('whichPayload() is notSet for empty buffer', () {
      final decoded = BuzzHiveMessage.fromBuffer(const []);
      expect(decoded.whichPayload(), BuzzHiveMessage_Payload.notSet);
    });

    test('decodes ScaleData variant and leaves sensorData default', () {
      final msg = BuzzHiveMessage(
        scaleData: ScaleData(nodeId: 7, weightKg: 12.34, battery: 95.5),
      );
      final bytes = msg.writeToBuffer();
      final decoded = BuzzHiveMessage.fromBuffer(bytes);

      expect(decoded.whichPayload(), BuzzHiveMessage_Payload.scaleData);
      expect(decoded.scaleData.nodeId, 7);
      expect(decoded.scaleData.weightKg, closeTo(12.34, 0.001));
    });
  });
}
