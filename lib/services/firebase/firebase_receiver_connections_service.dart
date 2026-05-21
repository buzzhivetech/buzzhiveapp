import 'package:firebase_database/firebase_database.dart';

import '../../core/constants/app_constants.dart';

/// Writes `receiver_connections` entries after BLE provisioning completes.
class FirebaseReceiverConnectionsService {
  FirebaseReceiverConnectionsService();

  DatabaseReference get _root => FirebaseDatabase.instance.ref();

  DatabaseReference _receiverRef(String receiverNodeId) =>
      _root.child(AppConstants.firebaseReceiverConnectionsPath).child(receiverNodeId);

  /// One event under `app_connections/{timestamp}` with value `wifi` or `firebase`.
  Future<void> recordAppConnectionEvent(String receiverNodeId, String kind) async {
    final ts = DateTime.now().millisecondsSinceEpoch.toString();
    await _receiverRef(receiverNodeId).child('app_connections').child(ts).set(kind);
  }

  /// Replaces `connected_sensors` with the given node IDs (boolean map).
  Future<void> setConnectedSensors(
    String receiverNodeId,
    List<String> sensorNodeIds,
  ) async {
    final map = <String, dynamic>{
      for (final id in sensorNodeIds) id: true,
    };
    await _receiverRef(receiverNodeId).child('connected_sensors').set(map);
  }
}
