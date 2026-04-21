// Generated-equivalent code for buzzhive_telemetry.proto enums.
// Regenerate with: protoc --dart_out=lib/proto proto/buzzhive_telemetry.proto

// ignore_for_file: non_constant_identifier_names, directives_ordering
// ignore_for_file: constant_identifier_names

import 'package:protobuf/protobuf.dart' as $pb;

class DeviceType extends $pb.ProtobufEnum {
  static const DeviceType DEVICE_TYPE_UNSPECIFIED =
      DeviceType._(0, 'DEVICE_TYPE_UNSPECIFIED');
  static const DeviceType DEVICE_TYPE_HIVE_SENSOR =
      DeviceType._(1, 'DEVICE_TYPE_HIVE_SENSOR');
  static const DeviceType DEVICE_TYPE_HIVE_SCALE =
      DeviceType._(2, 'DEVICE_TYPE_HIVE_SCALE');
  static const DeviceType DEVICE_TYPE_RECEIVER =
      DeviceType._(3, 'DEVICE_TYPE_RECEIVER');
  static const DeviceType DEVICE_TYPE_MOBILE_APP =
      DeviceType._(4, 'DEVICE_TYPE_MOBILE_APP');

  static const List<DeviceType> values = [
    DEVICE_TYPE_UNSPECIFIED,
    DEVICE_TYPE_HIVE_SENSOR,
    DEVICE_TYPE_HIVE_SCALE,
    DEVICE_TYPE_RECEIVER,
    DEVICE_TYPE_MOBILE_APP,
  ];

  static final Map<int, DeviceType> _byValue = $pb.ProtobufEnum.initByValue(values);
  static DeviceType? valueOf(int value) => _byValue[value];

  const DeviceType._(super.v, super.n);
}

class MessageType extends $pb.ProtobufEnum {
  static const MessageType MESSAGE_TYPE_UNSPECIFIED =
      MessageType._(0, 'MESSAGE_TYPE_UNSPECIFIED');
  static const MessageType MESSAGE_TYPE_TELEMETRY =
      MessageType._(1, 'MESSAGE_TYPE_TELEMETRY');
  static const MessageType MESSAGE_TYPE_HEARTBEAT =
      MessageType._(2, 'MESSAGE_TYPE_HEARTBEAT');
  static const MessageType MESSAGE_TYPE_PAIRING =
      MessageType._(3, 'MESSAGE_TYPE_PAIRING');
  static const MessageType MESSAGE_TYPE_CONFIG_ACK =
      MessageType._(4, 'MESSAGE_TYPE_CONFIG_ACK');
  static const MessageType MESSAGE_TYPE_STATUS =
      MessageType._(5, 'MESSAGE_TYPE_STATUS');

  static const List<MessageType> values = [
    MESSAGE_TYPE_UNSPECIFIED,
    MESSAGE_TYPE_TELEMETRY,
    MESSAGE_TYPE_HEARTBEAT,
    MESSAGE_TYPE_PAIRING,
    MESSAGE_TYPE_CONFIG_ACK,
    MESSAGE_TYPE_STATUS,
  ];

  static final Map<int, MessageType> _byValue = $pb.ProtobufEnum.initByValue(values);
  static MessageType? valueOf(int value) => _byValue[value];

  const MessageType._(super.v, super.n);
}
