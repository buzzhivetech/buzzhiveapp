/// QR code payload for claiming a BuzzHive sensor.
///
/// Format: `buzzhive://claim?d={device_id}&c={claim_code}`
///
/// The deep-link-friendly scheme lets us later add iOS Universal Links /
/// Android App Links that open directly into the Add Sensor flow.
class QrPayload {
  const QrPayload({required this.deviceId, required this.claimCode});

  final String deviceId;
  final String claimCode;

  static const String scheme = 'buzzhive';
  static const String host = 'claim';
  static const String deviceIdParam = 'd';
  static const String claimCodeParam = 'c';

  /// Parse a raw QR payload. Throws [QrPayloadException] on invalid input.
  ///
  /// Accepts whitespace around the URI and uppercases the claim code so
  /// users scanning a lowercase version still succeed.
  static QrPayload parse(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      throw const QrPayloadException('QR code is empty.');
    }

    final Uri uri;
    try {
      uri = Uri.parse(trimmed);
    } on FormatException catch (e) {
      throw QrPayloadException('QR code is not a valid URI: ${e.message}');
    }

    if (uri.scheme.toLowerCase() != scheme) {
      throw QrPayloadException(
        'Unexpected scheme "${uri.scheme}". Expected "$scheme://".',
      );
    }

    if (uri.host.toLowerCase() != host) {
      throw QrPayloadException(
        'Unexpected host "${uri.host}". Expected "$host".',
      );
    }

    final deviceId = uri.queryParameters[deviceIdParam]?.trim();
    final claimCode = uri.queryParameters[claimCodeParam]?.trim();

    if (deviceId == null || deviceId.isEmpty) {
      throw const QrPayloadException('QR code is missing the device ID (d).');
    }
    if (claimCode == null || claimCode.isEmpty) {
      throw const QrPayloadException('QR code is missing the claim code (c).');
    }

    return QrPayload(
      deviceId: deviceId,
      claimCode: claimCode.toUpperCase(),
    );
  }

  /// Build a QR payload string. Used by factory provisioning tooling and tests.
  String encode() {
    final uri = Uri(
      scheme: scheme,
      host: host,
      queryParameters: {
        deviceIdParam: deviceId,
        claimCodeParam: claimCode,
      },
    );
    return uri.toString();
  }

  @override
  String toString() => 'QrPayload(deviceId: $deviceId, claimCode: ***)';
}

class QrPayloadException implements Exception {
  const QrPayloadException(this.message);

  final String message;

  @override
  String toString() => 'QrPayloadException: $message';
}
