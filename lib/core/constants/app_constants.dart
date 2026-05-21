/// App-wide constants (map center, time ranges, etc.).
class AppConstants {
  AppConstants._();

  /// Hive location used for map (matches dashboard).
  static const double mapCenterLat = 42.065221;
  static const double mapCenterLng = -76.091067;

  /// Analytics time range keys.
  static const String range24h = '24h';
  static const String range7d = '7d';
  static const String range30d = '30d';
  static const String rangeAll = 'all';

  /// Firebase Realtime Database path for sensor data.
  static const String firebaseSensorDataPath = 'sensor_data';

  /// Receiver registry: connected sensors + app-assisted provisioning history.
  static const String firebaseReceiverConnectionsPath = 'receiver_connections';
  static const String firebaseRawIngestPath = 'raw_ingest';
  static const String firebaseAnalyzedDataPath = 'analyzed_data';
  static const String firebaseLatestHiveStatePath = 'latest_hive_state';
  static const String firebaseDeviceStatusPath = 'device_status';

  /// Typed telemetry identifiers shared with the backend envelope.
  static const String schemaVersion = '1.0.0';
  static const String messageTypeTelemetry = 'telemetry';
  static const String deviceTypeHiveSensor = 'hive_sensor';

  /// Consider "disconnected" if no data for this many milliseconds.
  static const int connectionStaleMs = 30000;
}
