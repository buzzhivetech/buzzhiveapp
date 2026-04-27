// Generated-equivalent code for buzzhive_telemetry.proto messages.
// Regenerate with: protoc --dart_out=lib/proto proto/buzzhive_telemetry.proto

// ignore_for_file: non_constant_identifier_names, directives_ordering
// ignore_for_file: constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: camel_case_types

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'buzzhive_telemetry.pbenum.dart';

export 'buzzhive_telemetry.pbenum.dart';

// ---------------------------------------------------------------------------
// Vector3
// ---------------------------------------------------------------------------

class Vector3 extends $pb.GeneratedMessage {
  factory Vector3({double? x, double? y, double? z}) {
    final result = create();
    if (x != null) result.x = x;
    if (y != null) result.y = y;
    if (z != null) result.z = z;
    return result;
  }

  Vector3._() : super();
  factory Vector3.fromBuffer(List<int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory Vector3.fromJson(String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
    'Vector3',
    package: const $pb.PackageName('buzzhive.v1'),
    createEmptyInstance: create,
  )
    ..a<double>(1, 'x', $pb.PbFieldType.OF)
    ..a<double>(2, 'y', $pb.PbFieldType.OF)
    ..a<double>(3, 'z', $pb.PbFieldType.OF)
    ..hasRequiredFields = false;

  @override
  $pb.BuilderInfo get info_ => _i;

  static Vector3 create() => Vector3._();
  @override
  Vector3 createEmptyInstance() => create();
  static $pb.PbList<Vector3> createRepeated() => $pb.PbList<Vector3>();
  @override
  $pb.GeneratedMessage clone() => Vector3()..mergeFromMessage(this);

  @$pb.TagNumber(1)
  double get x => $_getN(0);
  @$pb.TagNumber(1)
  set x(double v) => $_setFloat(0, v);
  @$pb.TagNumber(1)
  bool hasX() => $_has(0);

  @$pb.TagNumber(2)
  double get y => $_getN(1);
  @$pb.TagNumber(2)
  set y(double v) => $_setFloat(1, v);
  @$pb.TagNumber(2)
  bool hasY() => $_has(1);

  @$pb.TagNumber(3)
  double get z => $_getN(2);
  @$pb.TagNumber(3)
  set z(double v) => $_setFloat(2, v);
  @$pb.TagNumber(3)
  bool hasZ() => $_has(2);
}

// ---------------------------------------------------------------------------
// HiveSensorTelemetry
// ---------------------------------------------------------------------------

class HiveSensorTelemetry extends $pb.GeneratedMessage {
  factory HiveSensorTelemetry({
    double? temperatureC,
    double? humidityPct,
    double? vocIndex,
    double? soundLevelDb,
    double? microphoneHz,
    Vector3? accel,
    Vector3? force,
    double? batteryVolts,
  }) {
    final result = create();
    if (temperatureC != null) result.temperatureC = temperatureC;
    if (humidityPct != null) result.humidityPct = humidityPct;
    if (vocIndex != null) result.vocIndex = vocIndex;
    if (soundLevelDb != null) result.soundLevelDb = soundLevelDb;
    if (microphoneHz != null) result.microphoneHz = microphoneHz;
    if (accel != null) result.accel = accel;
    if (force != null) result.force = force;
    if (batteryVolts != null) result.batteryVolts = batteryVolts;
    return result;
  }

  HiveSensorTelemetry._() : super();
  factory HiveSensorTelemetry.fromBuffer(List<int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory HiveSensorTelemetry.fromJson(String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
    'HiveSensorTelemetry',
    package: const $pb.PackageName('buzzhive.v1'),
    createEmptyInstance: create,
  )
    ..a<double>(1, 'temperatureC', $pb.PbFieldType.OF,
        protoName: 'temperature_c')
    ..a<double>(2, 'humidityPct', $pb.PbFieldType.OF,
        protoName: 'humidity_pct')
    ..a<double>(3, 'vocIndex', $pb.PbFieldType.OF, protoName: 'voc_index')
    ..a<double>(4, 'soundLevelDb', $pb.PbFieldType.OF,
        protoName: 'sound_level_db')
    ..a<double>(5, 'microphoneHz', $pb.PbFieldType.OF,
        protoName: 'microphone_hz')
    ..aOM<Vector3>(6, 'accel', subBuilder: Vector3.create)
    ..aOM<Vector3>(7, 'force', subBuilder: Vector3.create)
    ..a<double>(8, 'batteryVolts', $pb.PbFieldType.OF,
        protoName: 'battery_volts')
    ..hasRequiredFields = false;

  @override
  $pb.BuilderInfo get info_ => _i;

  static HiveSensorTelemetry create() => HiveSensorTelemetry._();
  @override
  HiveSensorTelemetry createEmptyInstance() => create();
  static $pb.PbList<HiveSensorTelemetry> createRepeated() =>
      $pb.PbList<HiveSensorTelemetry>();
  @override
  $pb.GeneratedMessage clone() =>
      HiveSensorTelemetry()..mergeFromMessage(this);

  @$pb.TagNumber(1)
  double get temperatureC => $_getN(0);
  @$pb.TagNumber(1)
  set temperatureC(double v) => $_setFloat(0, v);
  @$pb.TagNumber(1)
  bool hasTemperatureC() => $_has(0);

  @$pb.TagNumber(2)
  double get humidityPct => $_getN(1);
  @$pb.TagNumber(2)
  set humidityPct(double v) => $_setFloat(1, v);
  @$pb.TagNumber(2)
  bool hasHumidityPct() => $_has(1);

  @$pb.TagNumber(3)
  double get vocIndex => $_getN(2);
  @$pb.TagNumber(3)
  set vocIndex(double v) => $_setFloat(2, v);
  @$pb.TagNumber(3)
  bool hasVocIndex() => $_has(2);

  @$pb.TagNumber(4)
  double get soundLevelDb => $_getN(3);
  @$pb.TagNumber(4)
  set soundLevelDb(double v) => $_setFloat(3, v);
  @$pb.TagNumber(4)
  bool hasSoundLevelDb() => $_has(3);

  @$pb.TagNumber(5)
  double get microphoneHz => $_getN(4);
  @$pb.TagNumber(5)
  set microphoneHz(double v) => $_setFloat(4, v);
  @$pb.TagNumber(5)
  bool hasMicrophoneHz() => $_has(4);

  @$pb.TagNumber(6)
  Vector3 get accel => $_getN(5);
  @$pb.TagNumber(6)
  set accel(Vector3 v) => setField(6, v);
  @$pb.TagNumber(6)
  bool hasAccel() => $_has(5);
  @$pb.TagNumber(6)
  Vector3 ensureAccel() => $_ensure(5);

  @$pb.TagNumber(7)
  Vector3 get force => $_getN(6);
  @$pb.TagNumber(7)
  set force(Vector3 v) => setField(7, v);
  @$pb.TagNumber(7)
  bool hasForce() => $_has(6);
  @$pb.TagNumber(7)
  Vector3 ensureForce() => $_ensure(6);

  @$pb.TagNumber(8)
  double get batteryVolts => $_getN(7);
  @$pb.TagNumber(8)
  set batteryVolts(double v) => $_setFloat(7, v);
  @$pb.TagNumber(8)
  bool hasBatteryVolts() => $_has(7);
}

// ---------------------------------------------------------------------------
// BuzzHiveEnvelope
// ---------------------------------------------------------------------------

enum BuzzHiveEnvelope_Payload {
  hiveSensor,
  hiveScale,
  receiverStatus,
  pairing,
  notSet,
}

class BuzzHiveEnvelope extends $pb.GeneratedMessage {
  factory BuzzHiveEnvelope({
    String? schemaVersion,
    MessageType? messageType,
    DeviceType? deviceType,
    String? deviceId,
    String? receiverId,
    String? hiveId,
    String? accountId,
    $fixnum.Int64? timestampDeviceMs,
    $fixnum.Int64? sequenceNumber,
    String? firmwareVersion,
    String? source,
    HiveSensorTelemetry? hiveSensor,
  }) {
    final result = create();
    if (schemaVersion != null) result.schemaVersion = schemaVersion;
    if (messageType != null) result.messageType = messageType;
    if (deviceType != null) result.deviceType = deviceType;
    if (deviceId != null) result.deviceId = deviceId;
    if (receiverId != null) result.receiverId = receiverId;
    if (hiveId != null) result.hiveId = hiveId;
    if (accountId != null) result.accountId = accountId;
    if (timestampDeviceMs != null) {
      result.timestampDeviceMs = timestampDeviceMs;
    }
    if (sequenceNumber != null) result.sequenceNumber = sequenceNumber;
    if (firmwareVersion != null) result.firmwareVersion = firmwareVersion;
    if (source != null) result.source = source;
    if (hiveSensor != null) result.hiveSensor = hiveSensor;
    return result;
  }

  BuzzHiveEnvelope._() : super();
  factory BuzzHiveEnvelope.fromBuffer(List<int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory BuzzHiveEnvelope.fromJson(String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static const Map<int, BuzzHiveEnvelope_Payload> _oneofsByTag = {
    20: BuzzHiveEnvelope_Payload.hiveSensor,
    21: BuzzHiveEnvelope_Payload.hiveScale,
    22: BuzzHiveEnvelope_Payload.receiverStatus,
    23: BuzzHiveEnvelope_Payload.pairing,
  };

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
    'BuzzHiveEnvelope',
    package: const $pb.PackageName('buzzhive.v1'),
    createEmptyInstance: create,
  )
    ..aOS(1, 'schemaVersion', protoName: 'schema_version')
    ..e<MessageType>(2, 'messageType', $pb.PbFieldType.OE,
        protoName: 'message_type',
        defaultOrMaker: MessageType.MESSAGE_TYPE_UNSPECIFIED,
        valueOf: MessageType.valueOf,
        enumValues: MessageType.values)
    ..e<DeviceType>(3, 'deviceType', $pb.PbFieldType.OE,
        protoName: 'device_type',
        defaultOrMaker: DeviceType.DEVICE_TYPE_UNSPECIFIED,
        valueOf: DeviceType.valueOf,
        enumValues: DeviceType.values)
    ..aOS(4, 'deviceId', protoName: 'device_id')
    ..aOS(5, 'receiverId', protoName: 'receiver_id')
    ..aOS(6, 'hiveId', protoName: 'hive_id')
    ..aOS(7, 'accountId', protoName: 'account_id')
    ..a<$fixnum.Int64>(8, 'timestampDeviceMs', $pb.PbFieldType.OU6,
        protoName: 'timestamp_device_ms', defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(9, 'sequenceNumber', $pb.PbFieldType.OU6,
        protoName: 'sequence_number', defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOS(10, 'firmwareVersion', protoName: 'firmware_version')
    ..aOS(11, 'source')
    ..oo(0, [20, 21, 22, 23])
    ..aOM<HiveSensorTelemetry>(20, 'hiveSensor',
        protoName: 'hive_sensor', subBuilder: HiveSensorTelemetry.create)
    ..hasRequiredFields = false;

  @override
  $pb.BuilderInfo get info_ => _i;

  static BuzzHiveEnvelope create() => BuzzHiveEnvelope._();
  @override
  BuzzHiveEnvelope createEmptyInstance() => create();
  static $pb.PbList<BuzzHiveEnvelope> createRepeated() =>
      $pb.PbList<BuzzHiveEnvelope>();
  @override
  $pb.GeneratedMessage clone() =>
      BuzzHiveEnvelope()..mergeFromMessage(this);

  BuzzHiveEnvelope_Payload whichPayload() =>
      _oneofsByTag[$_whichOneof(0)] ?? BuzzHiveEnvelope_Payload.notSet;
  void clearPayload() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  String get schemaVersion => $_getSZ(0);
  @$pb.TagNumber(1)
  set schemaVersion(String v) => $_setString(0, v);

  @$pb.TagNumber(2)
  MessageType get messageType => $_getN(1);
  @$pb.TagNumber(2)
  set messageType(MessageType v) => setField(2, v);

  @$pb.TagNumber(3)
  DeviceType get deviceType => $_getN(2);
  @$pb.TagNumber(3)
  set deviceType(DeviceType v) => setField(3, v);

  @$pb.TagNumber(4)
  String get deviceId => $_getSZ(3);
  @$pb.TagNumber(4)
  set deviceId(String v) => $_setString(3, v);

  @$pb.TagNumber(5)
  String get receiverId => $_getSZ(4);
  @$pb.TagNumber(5)
  set receiverId(String v) => $_setString(4, v);

  @$pb.TagNumber(6)
  String get hiveId => $_getSZ(5);
  @$pb.TagNumber(6)
  set hiveId(String v) => $_setString(5, v);

  @$pb.TagNumber(7)
  String get accountId => $_getSZ(6);
  @$pb.TagNumber(7)
  set accountId(String v) => $_setString(6, v);

  @$pb.TagNumber(8)
  $fixnum.Int64 get timestampDeviceMs => $_getI64(7);
  @$pb.TagNumber(8)
  set timestampDeviceMs($fixnum.Int64 v) => $_setInt64(7, v);

  @$pb.TagNumber(9)
  $fixnum.Int64 get sequenceNumber => $_getI64(8);
  @$pb.TagNumber(9)
  set sequenceNumber($fixnum.Int64 v) => $_setInt64(8, v);

  @$pb.TagNumber(10)
  String get firmwareVersion => $_getSZ(9);
  @$pb.TagNumber(10)
  set firmwareVersion(String v) => $_setString(9, v);

  @$pb.TagNumber(11)
  String get source => $_getSZ(10);
  @$pb.TagNumber(11)
  set source(String v) => $_setString(10, v);

  @$pb.TagNumber(20)
  HiveSensorTelemetry get hiveSensor => $_getN(11);
  @$pb.TagNumber(20)
  set hiveSensor(HiveSensorTelemetry v) => setField(20, v);
  @$pb.TagNumber(20)
  bool hasHiveSensor() => $_has(11);
  @$pb.TagNumber(20)
  HiveSensorTelemetry ensureHiveSensor() => $_ensure(11);
}
