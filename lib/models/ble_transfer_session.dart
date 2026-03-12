import 'package:equatable/equatable.dart';

/// Metadata for one BLE download session (one connect-transfer-disconnect cycle).
class BleTransferSession extends Equatable {
  const BleTransferSession({
    required this.id,
    required this.sensorId,
    required this.firebaseSensorId,
    required this.startedAt,
    this.completedAt,
    required this.expectedCount,
    required this.receivedCount,
    required this.lastConfirmedSeq,
    required this.status,
  });

  final int id;
  final String sensorId;
  final String firebaseSensorId;
  final DateTime startedAt;
  final DateTime? completedAt;
  final int expectedCount;
  final int receivedCount;
  final int lastConfirmedSeq;
  final TransferSessionStatus status;

  bool get isComplete => status == TransferSessionStatus.complete;

  @override
  List<Object?> get props => [
        id, sensorId, firebaseSensorId, startedAt, completedAt,
        expectedCount, receivedCount, lastConfirmedSeq, status,
      ];
}

enum TransferSessionStatus {
  inProgress,
  complete,
  failed,
  aborted;

  static TransferSessionStatus fromString(String s) =>
      TransferSessionStatus.values.firstWhere(
        (v) => v.name == s,
        orElse: () => TransferSessionStatus.failed,
      );
}
