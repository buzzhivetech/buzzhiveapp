import 'package:equatable/equatable.dart';

/// Single sensor reading from Firebase (sensor_data/{id}/{timestamp}).
class SensorReading extends Equatable {
  const SensorReading({
    required this.temp,
    required this.hum,
    required this.gas,
    required this.mic,
    required this.db,
    required this.ax,
    required this.ay,
    required this.az,
    required this.fx,
    required this.fy,
    required this.fz,
    required this.id,
    required this.timestamp,
  });

  final double temp;
  final double hum;
  final double gas;
  final double mic;
  final double db;
  final double ax;
  final double ay;
  final double az;
  final double fx;
  final double fy;
  final double fz;
  final String id;
  final DateTime timestamp;

  /// Temperature in Fahrenheit (dashboard displays °F).
  double get tempF => (temp * 9 / 5) + 32;

  @override
  List<Object?> get props => [temp, hum, gas, mic, db, ax, ay, az, fx, fy, fz, id, timestamp];

  /// From Firebase map (nested key = timestamp string or ms).
  static SensorReading? fromMap(Map<dynamic, dynamic> map, {String? timestampKey}) {
    try {
      final id = map['id']?.toString() ?? timestampKey ?? '';
      final ts = map['timestamp'];
      final DateTime dateTime;
      if (ts is int) {
        dateTime = DateTime.fromMillisecondsSinceEpoch(ts > 9999999999 ? ts : ts * 1000);
      } else if (ts is String) {
        dateTime = DateTime.tryParse(ts) ?? DateTime.now();
      } else {
        dateTime = DateTime.now();
      }
      return SensorReading(
        temp: _toDouble(map['temp']),
        hum: _toDouble(map['hum']),
        gas: _toDouble(map['gas']),
        mic: _toDouble(map['mic']),
        db: _toDouble(map['db']),
        ax: _toDouble(map['ax']),
        ay: _toDouble(map['ay']),
        az: _toDouble(map['az']),
        fx: _toDouble(map['fx']),
        fy: _toDouble(map['fy']),
        fz: _toDouble(map['fz']),
        id: id,
        timestamp: dateTime,
      );
    } catch (_) {
      return null;
    }
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }
}
