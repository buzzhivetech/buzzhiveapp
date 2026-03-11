import 'package:firebase_database/firebase_database.dart';

import '../../core/constants/app_constants.dart';

/// Read-only access to sensor data in Firebase Realtime Database.
/// No Supabase. Call Firebase.initializeApp from main before using.
class FirebaseSensorDataService {
  FirebaseSensorDataService();

  DatabaseReference get _root => FirebaseDatabase.instance.ref();

  /// Reference for one sensor's data: sensor_data/{firebaseSensorId}.
  DatabaseReference refForSensor(String firebaseSensorId) {
    return _root.child(AppConstants.firebaseSensorDataPath).child(firebaseSensorId);
  }

  /// Stream of child events (child_added, child_changed, etc.) for one sensor.
  /// Use in repository to build latest-reading or history.
  Stream<DatabaseEvent> streamChildEvents(String firebaseSensorId) {
    return refForSensor(firebaseSensorId).onChildAdded;
  }

  /// Stream of value events for the whole sensor node (all timestamp keys).
  Stream<DatabaseEvent> streamValue(String firebaseSensorId) {
    return refForSensor(firebaseSensorId).onValue;
  }

  /// One-off read of the sensor node. Use for analytics range or snapshot.
  Future<DataSnapshot> readOnce(String firebaseSensorId) {
    return refForSensor(firebaseSensorId).get();
  }
}
