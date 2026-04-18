// This is a generated file - do not edit.
//
// Generated from buzzhive.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

enum BuzzHiveMessage_Payload { sensorData, scaleData, notSet }

class BuzzHiveMessage extends $pb.GeneratedMessage {
  factory BuzzHiveMessage({
    SensorData? sensorData,
    ScaleData? scaleData,
  }) {
    final result = create();
    if (sensorData != null) result.sensorData = sensorData;
    if (scaleData != null) result.scaleData = scaleData;
    return result;
  }

  BuzzHiveMessage._();

  factory BuzzHiveMessage.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory BuzzHiveMessage.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, BuzzHiveMessage_Payload>
      _BuzzHiveMessage_PayloadByTag = {
    1: BuzzHiveMessage_Payload.sensorData,
    2: BuzzHiveMessage_Payload.scaleData,
    0: BuzzHiveMessage_Payload.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BuzzHiveMessage',
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<SensorData>(1, _omitFieldNames ? '' : 'sensorData',
        subBuilder: SensorData.create)
    ..aOM<ScaleData>(2, _omitFieldNames ? '' : 'scaleData',
        subBuilder: ScaleData.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BuzzHiveMessage clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BuzzHiveMessage copyWith(void Function(BuzzHiveMessage) updates) =>
      super.copyWith((message) => updates(message as BuzzHiveMessage))
          as BuzzHiveMessage;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BuzzHiveMessage create() => BuzzHiveMessage._();
  @$core.override
  BuzzHiveMessage createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static BuzzHiveMessage getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BuzzHiveMessage>(create);
  static BuzzHiveMessage? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  BuzzHiveMessage_Payload whichPayload() =>
      _BuzzHiveMessage_PayloadByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearPayload() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  SensorData get sensorData => $_getN(0);
  @$pb.TagNumber(1)
  set sensorData(SensorData value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasSensorData() => $_has(0);
  @$pb.TagNumber(1)
  void clearSensorData() => $_clearField(1);
  @$pb.TagNumber(1)
  SensorData ensureSensorData() => $_ensure(0);

  @$pb.TagNumber(2)
  ScaleData get scaleData => $_getN(1);
  @$pb.TagNumber(2)
  set scaleData(ScaleData value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasScaleData() => $_has(1);
  @$pb.TagNumber(2)
  void clearScaleData() => $_clearField(2);
  @$pb.TagNumber(2)
  ScaleData ensureScaleData() => $_ensure(1);
}

/// Payload containing the data from ALL_FUNC.ino
class SensorData extends $pb.GeneratedMessage {
  factory SensorData({
    $core.int? nodeId,
    $core.double? micFreq,
    $core.double? micDb,
    $core.double? freqX,
    $core.double? freqY,
    $core.double? freqZ,
    $core.double? maxX,
    $core.double? maxY,
    $core.double? maxZ,
    $core.double? temp,
    $core.double? humid,
    $core.double? gas,
    $core.double? vbat,
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

  SensorData._();

  factory SensorData.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SensorData.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SensorData',
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'nodeId')
    ..aD(2, _omitFieldNames ? '' : 'micFreq', fieldType: $pb.PbFieldType.OF)
    ..aD(3, _omitFieldNames ? '' : 'micDb', fieldType: $pb.PbFieldType.OF)
    ..aD(4, _omitFieldNames ? '' : 'freqX', fieldType: $pb.PbFieldType.OF)
    ..aD(5, _omitFieldNames ? '' : 'freqY', fieldType: $pb.PbFieldType.OF)
    ..aD(6, _omitFieldNames ? '' : 'freqZ', fieldType: $pb.PbFieldType.OF)
    ..aD(7, _omitFieldNames ? '' : 'maxX', fieldType: $pb.PbFieldType.OF)
    ..aD(8, _omitFieldNames ? '' : 'maxY', fieldType: $pb.PbFieldType.OF)
    ..aD(9, _omitFieldNames ? '' : 'maxZ', fieldType: $pb.PbFieldType.OF)
    ..aD(10, _omitFieldNames ? '' : 'temp', fieldType: $pb.PbFieldType.OF)
    ..aD(11, _omitFieldNames ? '' : 'humid', fieldType: $pb.PbFieldType.OF)
    ..aD(12, _omitFieldNames ? '' : 'gas', fieldType: $pb.PbFieldType.OF)
    ..aD(13, _omitFieldNames ? '' : 'vbat', fieldType: $pb.PbFieldType.OF)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SensorData clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SensorData copyWith(void Function(SensorData) updates) =>
      super.copyWith((message) => updates(message as SensorData)) as SensorData;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SensorData create() => SensorData._();
  @$core.override
  SensorData createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SensorData getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SensorData>(create);
  static SensorData? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get nodeId => $_getIZ(0);
  @$pb.TagNumber(1)
  set nodeId($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasNodeId() => $_has(0);
  @$pb.TagNumber(1)
  void clearNodeId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.double get micFreq => $_getN(1);
  @$pb.TagNumber(2)
  set micFreq($core.double value) => $_setFloat(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMicFreq() => $_has(1);
  @$pb.TagNumber(2)
  void clearMicFreq() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.double get micDb => $_getN(2);
  @$pb.TagNumber(3)
  set micDb($core.double value) => $_setFloat(2, value);
  @$pb.TagNumber(3)
  $core.bool hasMicDb() => $_has(2);
  @$pb.TagNumber(3)
  void clearMicDb() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.double get freqX => $_getN(3);
  @$pb.TagNumber(4)
  set freqX($core.double value) => $_setFloat(3, value);
  @$pb.TagNumber(4)
  $core.bool hasFreqX() => $_has(3);
  @$pb.TagNumber(4)
  void clearFreqX() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.double get freqY => $_getN(4);
  @$pb.TagNumber(5)
  set freqY($core.double value) => $_setFloat(4, value);
  @$pb.TagNumber(5)
  $core.bool hasFreqY() => $_has(4);
  @$pb.TagNumber(5)
  void clearFreqY() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.double get freqZ => $_getN(5);
  @$pb.TagNumber(6)
  set freqZ($core.double value) => $_setFloat(5, value);
  @$pb.TagNumber(6)
  $core.bool hasFreqZ() => $_has(5);
  @$pb.TagNumber(6)
  void clearFreqZ() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.double get maxX => $_getN(6);
  @$pb.TagNumber(7)
  set maxX($core.double value) => $_setFloat(6, value);
  @$pb.TagNumber(7)
  $core.bool hasMaxX() => $_has(6);
  @$pb.TagNumber(7)
  void clearMaxX() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.double get maxY => $_getN(7);
  @$pb.TagNumber(8)
  set maxY($core.double value) => $_setFloat(7, value);
  @$pb.TagNumber(8)
  $core.bool hasMaxY() => $_has(7);
  @$pb.TagNumber(8)
  void clearMaxY() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.double get maxZ => $_getN(8);
  @$pb.TagNumber(9)
  set maxZ($core.double value) => $_setFloat(8, value);
  @$pb.TagNumber(9)
  $core.bool hasMaxZ() => $_has(8);
  @$pb.TagNumber(9)
  void clearMaxZ() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.double get temp => $_getN(9);
  @$pb.TagNumber(10)
  set temp($core.double value) => $_setFloat(9, value);
  @$pb.TagNumber(10)
  $core.bool hasTemp() => $_has(9);
  @$pb.TagNumber(10)
  void clearTemp() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.double get humid => $_getN(10);
  @$pb.TagNumber(11)
  set humid($core.double value) => $_setFloat(10, value);
  @$pb.TagNumber(11)
  $core.bool hasHumid() => $_has(10);
  @$pb.TagNumber(11)
  void clearHumid() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.double get gas => $_getN(11);
  @$pb.TagNumber(12)
  set gas($core.double value) => $_setFloat(11, value);
  @$pb.TagNumber(12)
  $core.bool hasGas() => $_has(11);
  @$pb.TagNumber(12)
  void clearGas() => $_clearField(12);

  @$pb.TagNumber(13)
  $core.double get vbat => $_getN(12);
  @$pb.TagNumber(13)
  set vbat($core.double value) => $_setFloat(12, value);
  @$pb.TagNumber(13)
  $core.bool hasVbat() => $_has(12);
  @$pb.TagNumber(13)
  void clearVbat() => $_clearField(13);
}

/// Temporary payload for scale data
class ScaleData extends $pb.GeneratedMessage {
  factory ScaleData({
    $core.int? nodeId,
    $core.double? weightKg,
    $core.double? battery,
  }) {
    final result = create();
    if (nodeId != null) result.nodeId = nodeId;
    if (weightKg != null) result.weightKg = weightKg;
    if (battery != null) result.battery = battery;
    return result;
  }

  ScaleData._();

  factory ScaleData.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ScaleData.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ScaleData',
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'nodeId')
    ..aD(2, _omitFieldNames ? '' : 'weightKg', fieldType: $pb.PbFieldType.OF)
    ..aD(3, _omitFieldNames ? '' : 'battery', fieldType: $pb.PbFieldType.OF)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ScaleData clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ScaleData copyWith(void Function(ScaleData) updates) =>
      super.copyWith((message) => updates(message as ScaleData)) as ScaleData;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ScaleData create() => ScaleData._();
  @$core.override
  ScaleData createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ScaleData getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ScaleData>(create);
  static ScaleData? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get nodeId => $_getIZ(0);
  @$pb.TagNumber(1)
  set nodeId($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasNodeId() => $_has(0);
  @$pb.TagNumber(1)
  void clearNodeId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.double get weightKg => $_getN(1);
  @$pb.TagNumber(2)
  set weightKg($core.double value) => $_setFloat(1, value);
  @$pb.TagNumber(2)
  $core.bool hasWeightKg() => $_has(1);
  @$pb.TagNumber(2)
  void clearWeightKg() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.double get battery => $_getN(2);
  @$pb.TagNumber(3)
  set battery($core.double value) => $_setFloat(2, value);
  @$pb.TagNumber(3)
  $core.bool hasBattery() => $_has(2);
  @$pb.TagNumber(3)
  void clearBattery() => $_clearField(3);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
