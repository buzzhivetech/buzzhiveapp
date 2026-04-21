// Dart protobuf classes for the V0 hardware wire format.
//
// These MUST match the field tags and types in Buzzhive-V0/buzzhive.pb.h
// (nanopb-generated).  The canonical .proto lives at proto/buzzhive_v0.proto.
//
// Regenerate (or verify) with:
//   protoc --dart_out=lib/proto proto/buzzhive_v0.proto

// ignore_for_file: non_constant_identifier_names, directives_ordering
// ignore_for_file: constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: camel_case_types

import 'package:protobuf/protobuf.dart' as $pb;

// ---------------------------------------------------------------------------
// DataType enum  (wire values 0 / 1 / 2)
// ---------------------------------------------------------------------------

class V0DataType extends $pb.ProtobufEnum {
  static const V0DataType UNKNOWN = V0DataType._(0, 'UNKNOWN');
  static const V0DataType SENSOR_NODE = V0DataType._(1, 'SENSOR_NODE');
  static const V0DataType SCALE_NODE = V0DataType._(2, 'SCALE_NODE');

  static const List<V0DataType> values = [UNKNOWN, SENSOR_NODE, SCALE_NODE];

  static final Map<int, V0DataType> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static V0DataType? valueOf(int value) => _byValue[value];

  const V0DataType._(super.v, super.n);
}

// ---------------------------------------------------------------------------
// SensorData  (13 fields, tags 1–13)
// ---------------------------------------------------------------------------

class V0SensorData extends $pb.GeneratedMessage {
  factory V0SensorData({
    int? nodeId,
    double? micFreq,
    double? micDb,
    double? freqX,
    double? freqY,
    double? freqZ,
    double? maxX,
    double? maxY,
    double? maxZ,
    double? temp,
    double? humid,
    double? gas,
    double? vbat,
  }) {
    final result = create();
    if (nodeId != null) result.nodeId = nodeId;
    if (micFreq != null) result.micFreq = micFreq;
    if (micDb != null) result.micDb = micDb;
    if (freqX != null) result.freqX = freqX;
    if (freqY != null) result.freqY = freqY;
    if (freqZ != null) result.freqZ = freqZ;
    if (maxX != null) result.maxX = maxX;
    if (maxY != null) result.maxY = maxY;
    if (maxZ != null) result.maxZ = maxZ;
    if (temp != null) result.temp = temp;
    if (humid != null) result.humid = humid;
    if (gas != null) result.gas = gas;
    if (vbat != null) result.vbat = vbat;
    return result;
  }

  V0SensorData._() : super();

  factory V0SensorData.fromBuffer(List<int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);

  factory V0SensorData.fromJson(String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
    'SensorData',
    createEmptyInstance: create,
  )
    ..a<int>(1, 'nodeId', $pb.PbFieldType.O3, protoName: 'node_id')
    ..a<double>(2, 'micFreq', $pb.PbFieldType.OF, protoName: 'mic_freq')
    ..a<double>(3, 'micDb', $pb.PbFieldType.OF, protoName: 'mic_db')
    ..a<double>(4, 'freqX', $pb.PbFieldType.OF, protoName: 'freq_x')
    ..a<double>(5, 'freqY', $pb.PbFieldType.OF, protoName: 'freq_y')
    ..a<double>(6, 'freqZ', $pb.PbFieldType.OF, protoName: 'freq_z')
    ..a<double>(7, 'maxX', $pb.PbFieldType.OF, protoName: 'max_x')
    ..a<double>(8, 'maxY', $pb.PbFieldType.OF, protoName: 'max_y')
    ..a<double>(9, 'maxZ', $pb.PbFieldType.OF, protoName: 'max_z')
    ..a<double>(10, 'temp', $pb.PbFieldType.OF)
    ..a<double>(11, 'humid', $pb.PbFieldType.OF)
    ..a<double>(12, 'gas', $pb.PbFieldType.OF)
    ..a<double>(13, 'vbat', $pb.PbFieldType.OF)
    ..hasRequiredFields = false;

  @override
  $pb.BuilderInfo get info_ => _i;

  static V0SensorData create() => V0SensorData._();
  @override
  V0SensorData createEmptyInstance() => create();
  static $pb.PbList<V0SensorData> createRepeated() =>
      $pb.PbList<V0SensorData>();
  @override
  $pb.GeneratedMessage clone() => V0SensorData()..mergeFromMessage(this);

  @$pb.TagNumber(1)
  int get nodeId => $_getIZ(0);
  @$pb.TagNumber(1)
  set nodeId(int v) => $_setSignedInt32(0, v);
  @$pb.TagNumber(1)
  bool hasNodeId() => $_has(0);

  @$pb.TagNumber(2)
  double get micFreq => $_getN(1);
  @$pb.TagNumber(2)
  set micFreq(double v) => $_setFloat(1, v);

  @$pb.TagNumber(3)
  double get micDb => $_getN(2);
  @$pb.TagNumber(3)
  set micDb(double v) => $_setFloat(2, v);

  @$pb.TagNumber(4)
  double get freqX => $_getN(3);
  @$pb.TagNumber(4)
  set freqX(double v) => $_setFloat(3, v);

  @$pb.TagNumber(5)
  double get freqY => $_getN(4);
  @$pb.TagNumber(5)
  set freqY(double v) => $_setFloat(4, v);

  @$pb.TagNumber(6)
  double get freqZ => $_getN(5);
  @$pb.TagNumber(6)
  set freqZ(double v) => $_setFloat(5, v);

  @$pb.TagNumber(7)
  double get maxX => $_getN(6);
  @$pb.TagNumber(7)
  set maxX(double v) => $_setFloat(6, v);

  @$pb.TagNumber(8)
  double get maxY => $_getN(7);
  @$pb.TagNumber(8)
  set maxY(double v) => $_setFloat(7, v);

  @$pb.TagNumber(9)
  double get maxZ => $_getN(8);
  @$pb.TagNumber(9)
  set maxZ(double v) => $_setFloat(8, v);

  @$pb.TagNumber(10)
  double get temp => $_getN(9);
  @$pb.TagNumber(10)
  set temp(double v) => $_setFloat(9, v);

  @$pb.TagNumber(11)
  double get humid => $_getN(10);
  @$pb.TagNumber(11)
  set humid(double v) => $_setFloat(10, v);

  @$pb.TagNumber(12)
  double get gas => $_getN(11);
  @$pb.TagNumber(12)
  set gas(double v) => $_setFloat(11, v);

  @$pb.TagNumber(13)
  double get vbat => $_getN(12);
  @$pb.TagNumber(13)
  set vbat(double v) => $_setFloat(12, v);
}

// ---------------------------------------------------------------------------
// ScaleData  (3 fields, tags 1–3)
// ---------------------------------------------------------------------------

class V0ScaleData extends $pb.GeneratedMessage {
  factory V0ScaleData({
    int? nodeId,
    double? weightKg,
    double? battery,
  }) {
    final result = create();
    if (nodeId != null) result.nodeId = nodeId;
    if (weightKg != null) result.weightKg = weightKg;
    if (battery != null) result.battery = battery;
    return result;
  }

  V0ScaleData._() : super();

  factory V0ScaleData.fromBuffer(List<int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);

  factory V0ScaleData.fromJson(String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
    'ScaleData',
    createEmptyInstance: create,
  )
    ..a<int>(1, 'nodeId', $pb.PbFieldType.O3, protoName: 'node_id')
    ..a<double>(2, 'weightKg', $pb.PbFieldType.OF, protoName: 'weight_kg')
    ..a<double>(3, 'battery', $pb.PbFieldType.OF)
    ..hasRequiredFields = false;

  @override
  $pb.BuilderInfo get info_ => _i;

  static V0ScaleData create() => V0ScaleData._();
  @override
  V0ScaleData createEmptyInstance() => create();
  static $pb.PbList<V0ScaleData> createRepeated() =>
      $pb.PbList<V0ScaleData>();
  @override
  $pb.GeneratedMessage clone() => V0ScaleData()..mergeFromMessage(this);

  @$pb.TagNumber(1)
  int get nodeId => $_getIZ(0);
  @$pb.TagNumber(1)
  set nodeId(int v) => $_setSignedInt32(0, v);
  @$pb.TagNumber(1)
  bool hasNodeId() => $_has(0);

  @$pb.TagNumber(2)
  double get weightKg => $_getN(1);
  @$pb.TagNumber(2)
  set weightKg(double v) => $_setFloat(1, v);

  @$pb.TagNumber(2)
  bool hasWeightKg() => $_has(1);

  @$pb.TagNumber(3)
  double get battery => $_getN(2);
  @$pb.TagNumber(3)
  set battery(double v) => $_setFloat(2, v);

  @$pb.TagNumber(3)
  bool hasBattery() => $_has(2);
}

// ---------------------------------------------------------------------------
// BuzzHiveMessage  (type at tag 1, oneof payload at tags 2–3)
// ---------------------------------------------------------------------------

enum V0BuzzHiveMessage_Payload { sensorData, scaleData, notSet }

class V0BuzzHiveMessage extends $pb.GeneratedMessage {
  factory V0BuzzHiveMessage({
    V0DataType? type,
    V0SensorData? sensorData,
    V0ScaleData? scaleData,
  }) {
    final result = create();
    if (type != null) result.type = type;
    if (sensorData != null) result.sensorData = sensorData;
    if (scaleData != null) result.scaleData = scaleData;
    return result;
  }

  V0BuzzHiveMessage._() : super();

  factory V0BuzzHiveMessage.fromBuffer(List<int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);

  factory V0BuzzHiveMessage.fromJson(String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static const Map<int, V0BuzzHiveMessage_Payload> _oneofsByTag = {
    2: V0BuzzHiveMessage_Payload.sensorData,
    3: V0BuzzHiveMessage_Payload.scaleData,
  };

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
    'BuzzHiveMessage',
    createEmptyInstance: create,
  )
    ..e<V0DataType>(1, 'type', $pb.PbFieldType.OE,
        defaultOrMaker: V0DataType.UNKNOWN,
        valueOf: V0DataType.valueOf,
        enumValues: V0DataType.values)
    ..oo(0, [2, 3])
    ..aOM<V0SensorData>(2, 'sensorData',
        protoName: 'sensor_data', subBuilder: V0SensorData.create)
    ..aOM<V0ScaleData>(3, 'scaleData',
        protoName: 'scale_data', subBuilder: V0ScaleData.create)
    ..hasRequiredFields = false;

  @override
  $pb.BuilderInfo get info_ => _i;

  static V0BuzzHiveMessage create() => V0BuzzHiveMessage._();
  @override
  V0BuzzHiveMessage createEmptyInstance() => create();
  static $pb.PbList<V0BuzzHiveMessage> createRepeated() =>
      $pb.PbList<V0BuzzHiveMessage>();
  @override
  $pb.GeneratedMessage clone() =>
      V0BuzzHiveMessage()..mergeFromMessage(this);

  V0BuzzHiveMessage_Payload whichPayload() =>
      _oneofsByTag[$_whichOneof(0)] ?? V0BuzzHiveMessage_Payload.notSet;
  void clearPayload() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  V0DataType get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(V0DataType v) => setField(1, v);
  @$pb.TagNumber(1)
  bool hasType() => $_has(0);

  @$pb.TagNumber(2)
  V0SensorData get sensorData => $_getN(1);
  @$pb.TagNumber(2)
  set sensorData(V0SensorData v) => setField(2, v);
  @$pb.TagNumber(2)
  bool hasSensorData() => $_has(1);
  @$pb.TagNumber(2)
  V0SensorData ensureSensorData() => $_ensure(1);

  @$pb.TagNumber(3)
  V0ScaleData get scaleData => $_getN(2);
  @$pb.TagNumber(3)
  set scaleData(V0ScaleData v) => setField(3, v);
  @$pb.TagNumber(3)
  bool hasScaleData() => $_has(2);
  @$pb.TagNumber(3)
  V0ScaleData ensureScaleData() => $_ensure(2);
}
