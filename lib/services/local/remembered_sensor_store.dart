import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/utils/app_logger.dart';
import '../../models/remembered_sensor.dart';

/// SQLite-backed store for BLE device identities that were paired via the
/// sensor discovery flow. Enables auto-selection during future BLE scans.
class RememberedSensorStore {
  static const _dbName = 'buzzhive_remembered_sensors.db';
  static const _dbVersion = 1;
  static const _table = 'remembered_sensors';
  static const _log = 'RememberedStore';

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, _dbName);
    AppLogger.info('Opening remembered-sensor store at $path', name: _log);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_table (
        firebase_sensor_id TEXT PRIMARY KEY,
        ble_device_id TEXT NOT NULL,
        device_name TEXT NOT NULL DEFAULT '',
        added_at TEXT NOT NULL,
        last_seen_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE INDEX idx_remembered_ble_id
        ON $_table(ble_device_id)
    ''');
  }

  /// Save or update a remembered sensor.
  Future<void> save(RememberedSensor sensor) async {
    final db = await database;
    await db.insert(
      _table,
      sensor.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    AppLogger.info(
      'Saved remembered sensor ${sensor.firebaseSensorId} '
      '(BLE: ${sensor.bleDeviceId})',
      name: _log,
    );
  }

  /// Retrieve all remembered sensors.
  Future<List<RememberedSensor>> getAll() async {
    final db = await database;
    final rows = await db.query(_table, orderBy: 'last_seen_at DESC');
    return rows.map(RememberedSensor.fromMap).toList();
  }

  /// Look up by Firebase sensor ID.
  Future<RememberedSensor?> getByFirebaseId(String firebaseSensorId) async {
    final db = await database;
    final rows = await db.query(
      _table,
      where: 'firebase_sensor_id = ?',
      whereArgs: [firebaseSensorId],
    );
    if (rows.isEmpty) return null;
    return RememberedSensor.fromMap(rows.first);
  }

  /// Look up by BLE device ID (e.g. MAC address).
  Future<RememberedSensor?> getByBleDeviceId(String bleDeviceId) async {
    final db = await database;
    final rows = await db.query(
      _table,
      where: 'ble_device_id = ?',
      whereArgs: [bleDeviceId],
    );
    if (rows.isEmpty) return null;
    return RememberedSensor.fromMap(rows.first);
  }

  /// Update the last-seen timestamp for a sensor.
  Future<void> updateLastSeen(String firebaseSensorId) async {
    final db = await database;
    await db.update(
      _table,
      {'last_seen_at': DateTime.now().toUtc().toIso8601String()},
      where: 'firebase_sensor_id = ?',
      whereArgs: [firebaseSensorId],
    );
  }

  /// Remove a remembered sensor.
  Future<void> delete(String firebaseSensorId) async {
    final db = await database;
    await db.delete(
      _table,
      where: 'firebase_sensor_id = ?',
      whereArgs: [firebaseSensorId],
    );
    AppLogger.info('Deleted remembered sensor $firebaseSensorId', name: _log);
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
