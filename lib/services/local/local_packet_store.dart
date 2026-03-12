import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/utils/app_logger.dart';
import '../../models/ble_transfer_session.dart';
import '../../models/pending_reading.dart';

/// SQLite-backed local store for BLE transfer sessions and pending readings.
/// Provides the offline queue between BLE download and Firebase upload.
class LocalPacketStore {
  static const _dbName = 'buzzhive_packets.db';
  static const _dbVersion = 1;
  static const _log = 'LocalStore';

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, _dbName);
    AppLogger.info('Opening packet store at $path', name: _log);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ble_transfer_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sensor_id TEXT NOT NULL,
        firebase_sensor_id TEXT NOT NULL,
        started_at TEXT NOT NULL,
        completed_at TEXT,
        expected_count INTEGER NOT NULL DEFAULT 0,
        received_count INTEGER NOT NULL DEFAULT 0,
        last_confirmed_seq INTEGER NOT NULL DEFAULT -1,
        status TEXT NOT NULL DEFAULT 'inProgress'
      )
    ''');
    await db.execute('''
      CREATE TABLE pending_readings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER NOT NULL,
        firebase_sensor_id TEXT NOT NULL,
        sequence INTEGER NOT NULL,
        temp REAL NOT NULL DEFAULT 0,
        hum REAL NOT NULL DEFAULT 0,
        gas REAL NOT NULL DEFAULT 0,
        mic REAL NOT NULL DEFAULT 0,
        db_val REAL NOT NULL DEFAULT 0,
        ax REAL NOT NULL DEFAULT 0,
        ay REAL NOT NULL DEFAULT 0,
        az REAL NOT NULL DEFAULT 0,
        fx REAL NOT NULL DEFAULT 0,
        fy REAL NOT NULL DEFAULT 0,
        fz REAL NOT NULL DEFAULT 0,
        sensor_timestamp_ms INTEGER NOT NULL,
        received_at TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (session_id) REFERENCES ble_transfer_sessions(id)
      )
    ''');
    await db.execute('''
      CREATE UNIQUE INDEX idx_pending_dedup
        ON pending_readings(firebase_sensor_id, sensor_timestamp_ms, sequence)
    ''');
    await db.execute('''
      CREATE INDEX idx_pending_unsynced
        ON pending_readings(synced) WHERE synced = 0
    ''');
  }

  // ---- Sessions ----

  Future<int> createSession({
    required String sensorId,
    required String firebaseSensorId,
    int expectedCount = 0,
  }) async {
    final db = await database;
    final id = await db.insert('ble_transfer_sessions', {
      'sensor_id': sensorId,
      'firebase_sensor_id': firebaseSensorId,
      'started_at': DateTime.now().toUtc().toIso8601String(),
      'expected_count': expectedCount,
      'status': TransferSessionStatus.inProgress.name,
    });
    AppLogger.info('Created session $id for sensor $firebaseSensorId', name: _log);
    return id;
  }

  Future<void> updateSessionProgress(int sessionId, {int? receivedCount, int? lastSeq}) async {
    final db = await database;
    final updates = <String, dynamic>{};
    if (receivedCount != null) updates['received_count'] = receivedCount;
    if (lastSeq != null) updates['last_confirmed_seq'] = lastSeq;
    if (updates.isNotEmpty) {
      await db.update('ble_transfer_sessions', updates, where: 'id = ?', whereArgs: [sessionId]);
    }
  }

  Future<void> completeSession(int sessionId, TransferSessionStatus status) async {
    final db = await database;
    await db.update('ble_transfer_sessions', {
      'completed_at': DateTime.now().toUtc().toIso8601String(),
      'status': status.name,
    }, where: 'id = ?', whereArgs: [sessionId]);
    AppLogger.info('Session $sessionId marked ${status.name}', name: _log);
  }

  Future<BleTransferSession?> getSession(int sessionId) async {
    final db = await database;
    final rows = await db.query('ble_transfer_sessions', where: 'id = ?', whereArgs: [sessionId]);
    if (rows.isEmpty) return null;
    return _mapToSession(rows.first);
  }

  Future<List<BleTransferSession>> getSessionsForSensor(String firebaseSensorId) async {
    final db = await database;
    final rows = await db.query(
      'ble_transfer_sessions',
      where: 'firebase_sensor_id = ?',
      whereArgs: [firebaseSensorId],
      orderBy: 'started_at DESC',
    );
    return rows.map(_mapToSession).toList();
  }

  // ---- Readings ----

  Future<void> insertReading({
    required int sessionId,
    required String firebaseSensorId,
    required int sequence,
    required double temp,
    required double hum,
    required double gas,
    required double mic,
    required double db,
    required double ax,
    required double ay,
    required double az,
    required double fx,
    required double fy,
    required double fz,
    required int sensorTimestampMs,
  }) async {
    final dbInstance = await database;
    await dbInstance.insert(
      'pending_readings',
      {
        'session_id': sessionId,
        'firebase_sensor_id': firebaseSensorId,
        'sequence': sequence,
        'temp': temp,
        'hum': hum,
        'gas': gas,
        'mic': mic,
        'db_val': db,
        'ax': ax,
        'ay': ay,
        'az': az,
        'fx': fx,
        'fy': fy,
        'fz': fz,
        'sensor_timestamp_ms': sensorTimestampMs,
        'received_at': DateTime.now().toUtc().toIso8601String(),
        'synced': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  /// Fetch up to [limit] unsynced readings, oldest first.
  Future<List<PendingReading>> getUnsyncedReadings({int limit = 100}) async {
    final db = await database;
    final rows = await db.query(
      'pending_readings',
      where: 'synced = 0',
      orderBy: 'sensor_timestamp_ms ASC',
      limit: limit,
    );
    return rows.map(_mapToReading).toList();
  }

  /// Count of readings that have not been uploaded yet.
  Future<int> getUnsyncedCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) AS c FROM pending_readings WHERE synced = 0');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Mark a batch of reading IDs as synced.
  Future<void> markSynced(List<int> ids) async {
    if (ids.isEmpty) return;
    final db = await database;
    final placeholders = List.filled(ids.length, '?').join(',');
    await db.rawUpdate(
      'UPDATE pending_readings SET synced = 1 WHERE id IN ($placeholders)',
      ids,
    );
    AppLogger.debug('Marked ${ids.length} readings as synced', name: _log);
  }

  /// Delete synced readings older than [before] to reclaim space.
  Future<int> purgeSyncedBefore(DateTime before) async {
    final db = await database;
    final count = await db.delete(
      'pending_readings',
      where: 'synced = 1 AND received_at < ?',
      whereArgs: [before.toUtc().toIso8601String()],
    );
    if (count > 0) AppLogger.info('Purged $count old synced readings', name: _log);
    return count;
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  // ---- Mapping ----

  BleTransferSession _mapToSession(Map<String, dynamic> row) {
    return BleTransferSession(
      id: row['id'] as int,
      sensorId: row['sensor_id'] as String,
      firebaseSensorId: row['firebase_sensor_id'] as String,
      startedAt: DateTime.parse(row['started_at'] as String),
      completedAt: row['completed_at'] != null ? DateTime.parse(row['completed_at'] as String) : null,
      expectedCount: row['expected_count'] as int,
      receivedCount: row['received_count'] as int,
      lastConfirmedSeq: row['last_confirmed_seq'] as int,
      status: TransferSessionStatus.fromString(row['status'] as String),
    );
  }

  PendingReading _mapToReading(Map<String, dynamic> row) {
    return PendingReading(
      id: row['id'] as int,
      sessionId: row['session_id'] as int,
      firebaseSensorId: row['firebase_sensor_id'] as String,
      sequence: row['sequence'] as int,
      temp: (row['temp'] as num).toDouble(),
      hum: (row['hum'] as num).toDouble(),
      gas: (row['gas'] as num).toDouble(),
      mic: (row['mic'] as num).toDouble(),
      db: (row['db_val'] as num).toDouble(),
      ax: (row['ax'] as num).toDouble(),
      ay: (row['ay'] as num).toDouble(),
      az: (row['az'] as num).toDouble(),
      fx: (row['fx'] as num).toDouble(),
      fy: (row['fy'] as num).toDouble(),
      fz: (row['fz'] as num).toDouble(),
      sensorTimestampMs: row['sensor_timestamp_ms'] as int,
      receivedAt: DateTime.parse(row['received_at'] as String),
      synced: (row['synced'] as int) == 1,
    );
  }
}
