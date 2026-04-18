/// Parses BuzzHive device identity out of a BLE advertisement.
///
/// Convention: the sensor advertises a local name of the form
/// `BuzzHive-<device_id>`, where `<device_id>` matches the
/// `firebase_sensor_id` stored in Supabase (e.g. `10001`).
///
/// Using the advertisement name avoids needing a custom "Device Info"
/// GATT characteristic (which would require a firmware change), and lets
/// the pairing tab show device candidates before connecting.
class BleAdvertisementIdentity {
  const BleAdvertisementIdentity({
    required this.deviceId,
    required this.localName,
  });

  /// Firebase/Supabase device ID extracted from the advertisement.
  final String deviceId;

  /// Raw local name as advertised (kept for UI display).
  final String localName;

  static const String namePrefix = 'BuzzHive-';

  /// Try to parse a device ID from a raw advertisement name.
  /// Returns `null` when the name is not a BuzzHive advertisement.
  static BleAdvertisementIdentity? tryParse(String? advertisementName) {
    if (advertisementName == null) return null;
    final name = advertisementName.trim();
    if (name.length <= namePrefix.length) return null;
    if (!name.toLowerCase().startsWith(namePrefix.toLowerCase())) return null;

    final deviceId = name.substring(namePrefix.length).trim();
    if (deviceId.isEmpty) return null;

    return BleAdvertisementIdentity(deviceId: deviceId, localName: name);
  }
}
