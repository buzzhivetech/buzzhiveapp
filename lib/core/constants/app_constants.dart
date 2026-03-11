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

  /// Consider "disconnected" if no data for this many milliseconds.
  static const int connectionStaleMs = 30000;
}
