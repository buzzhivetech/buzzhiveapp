/// Parses BuzzHive device identity out of a BLE advertisement.
///
/// Two advertisement formats are supported:
///
///   1. `BuzzHive-<device_id>` — preferred. The `<device_id>` matches the
///      `firebase_sensor_id` stored in Supabase (e.g. `15`, `10001`).
///      Parsed into an identified sensor with [deviceId] populated.
///
///   2. `BuzzHive_Sensor` — legacy/generic name used by current firmware.
///      Every sensor advertises the same string, so [deviceId] is left
///      null and the UI must prompt the user for the ID printed on the
///      sensor's sticker.
///
/// Using the advertisement name avoids requiring a dedicated
/// "Device Info" GATT characteristic (which would mean a firmware
/// change and a BLE connect+pair dance just to read an ID).
class BleAdvertisementIdentity {
  const BleAdvertisementIdentity({
    required this.localName,
    this.deviceId,
  });

  /// Firebase/Supabase device ID extracted from the advertisement, when the
  /// firmware embeds it in the local name. `null` for generic BuzzHive
  /// advertisements (legacy firmware); the UI must then prompt.
  final String? deviceId;

  /// Raw local name as advertised (kept for UI display).
  final String localName;

  /// Prefix used by the preferred `BuzzHive-<id>` scheme.
  static const String identifiedPrefix = 'BuzzHive-';

  /// Name used by legacy firmware that doesn't encode an ID.
  static const String genericName = 'BuzzHive_Sensor';

  /// Any BuzzHive advertisement starts with this, case-insensitive.
  static const String brandPrefix = 'BuzzHive';

  /// True when the advertisement encodes the device ID in the name.
  bool get isIdentified => deviceId != null;

  /// Try to parse a BuzzHive advertisement. Returns `null` when the name
  /// does not belong to a BuzzHive device at all.
  static BleAdvertisementIdentity? tryParse(String? advertisementName) {
    if (advertisementName == null) return null;
    final name = advertisementName.trim();
    if (name.isEmpty) return null;

    // 1. Preferred: BuzzHive-<id>
    if (name.length > identifiedPrefix.length &&
        name.toLowerCase().startsWith(identifiedPrefix.toLowerCase())) {
      final deviceId = name.substring(identifiedPrefix.length).trim();
      if (deviceId.isEmpty) return null;
      return BleAdvertisementIdentity(deviceId: deviceId, localName: name);
    }

    // 2. Legacy/generic: BuzzHive_Sensor (or anything else starting with
    //    "BuzzHive" without the dash-id format).
    if (name.toLowerCase().startsWith(brandPrefix.toLowerCase())) {
      return BleAdvertisementIdentity(localName: name);
    }

    return null;
  }
}
