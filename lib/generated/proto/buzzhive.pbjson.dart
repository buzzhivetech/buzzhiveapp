// This is a generated file - do not edit.
//
// Generated from buzzhive.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use buzzHiveMessageDescriptor instead')
const BuzzHiveMessage$json = {
  '1': 'BuzzHiveMessage',
  '2': [
    {
      '1': 'sensor_data',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.SensorData',
      '9': 0,
      '10': 'sensorData'
    },
    {
      '1': 'scale_data',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.ScaleData',
      '9': 0,
      '10': 'scaleData'
    },
  ],
  '8': [
    {'1': 'payload'},
  ],
};

/// Descriptor for `BuzzHiveMessage`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List buzzHiveMessageDescriptor = $convert.base64Decode(
    'Cg9CdXp6SGl2ZU1lc3NhZ2USLgoLc2Vuc29yX2RhdGEYASABKAsyCy5TZW5zb3JEYXRhSABSCn'
    'NlbnNvckRhdGESKwoKc2NhbGVfZGF0YRgCIAEoCzIKLlNjYWxlRGF0YUgAUglzY2FsZURhdGFC'
    'CQoHcGF5bG9hZA==');

@$core.Deprecated('Use sensorDataDescriptor instead')
const SensorData$json = {
  '1': 'SensorData',
  '2': [
    {'1': 'node_id', '3': 1, '4': 1, '5': 5, '10': 'nodeId'},
    {'1': 'mic_freq', '3': 2, '4': 1, '5': 2, '10': 'micFreq'},
    {'1': 'mic_db', '3': 3, '4': 1, '5': 2, '10': 'micDb'},
    {'1': 'freq_x', '3': 4, '4': 1, '5': 2, '10': 'freqX'},
    {'1': 'freq_y', '3': 5, '4': 1, '5': 2, '10': 'freqY'},
    {'1': 'freq_z', '3': 6, '4': 1, '5': 2, '10': 'freqZ'},
    {'1': 'max_x', '3': 7, '4': 1, '5': 2, '10': 'maxX'},
    {'1': 'max_y', '3': 8, '4': 1, '5': 2, '10': 'maxY'},
    {'1': 'max_z', '3': 9, '4': 1, '5': 2, '10': 'maxZ'},
    {'1': 'temp', '3': 10, '4': 1, '5': 2, '10': 'temp'},
    {'1': 'humid', '3': 11, '4': 1, '5': 2, '10': 'humid'},
    {'1': 'gas', '3': 12, '4': 1, '5': 2, '10': 'gas'},
    {'1': 'vbat', '3': 13, '4': 1, '5': 2, '10': 'vbat'},
  ],
};

/// Descriptor for `SensorData`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sensorDataDescriptor = $convert.base64Decode(
    'CgpTZW5zb3JEYXRhEhcKB25vZGVfaWQYASABKAVSBm5vZGVJZBIZCghtaWNfZnJlcRgCIAEoAl'
    'IHbWljRnJlcRIVCgZtaWNfZGIYAyABKAJSBW1pY0RiEhUKBmZyZXFfeBgEIAEoAlIFZnJlcVgS'
    'FQoGZnJlcV95GAUgASgCUgVmcmVxWRIVCgZmcmVxX3oYBiABKAJSBWZyZXFaEhMKBW1heF94GA'
    'cgASgCUgRtYXhYEhMKBW1heF95GAggASgCUgRtYXhZEhMKBW1heF96GAkgASgCUgRtYXhaEhIK'
    'BHRlbXAYCiABKAJSBHRlbXASFAoFaHVtaWQYCyABKAJSBWh1bWlkEhAKA2dhcxgMIAEoAlIDZ2'
    'FzEhIKBHZiYXQYDSABKAJSBHZiYXQ=');

@$core.Deprecated('Use scaleDataDescriptor instead')
const ScaleData$json = {
  '1': 'ScaleData',
  '2': [
    {'1': 'node_id', '3': 1, '4': 1, '5': 5, '10': 'nodeId'},
    {'1': 'weight_kg', '3': 2, '4': 1, '5': 2, '10': 'weightKg'},
    {'1': 'battery', '3': 3, '4': 1, '5': 2, '10': 'battery'},
  ],
};

/// Descriptor for `ScaleData`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List scaleDataDescriptor = $convert.base64Decode(
    'CglTY2FsZURhdGESFwoHbm9kZV9pZBgBIAEoBVIGbm9kZUlkEhsKCXdlaWdodF9rZxgCIAEoAl'
    'IId2VpZ2h0S2cSGAoHYmF0dGVyeRgDIAEoAlIHYmF0dGVyeQ==');
