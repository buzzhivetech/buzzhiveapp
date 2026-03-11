import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

import '../core/config/firebase_options.dart' as app_config;

/// Firebase initialization; call from main() before runApp.
/// No-op if projectId is not set (e.g. missing env / dart-define).
Future<void> initFirebase() async {
  final options = app_config.defaultFirebaseOptions;
  if (options.projectId.isEmpty) return;
  await Firebase.initializeApp(options: options);
}

/// Root Firebase Realtime Database reference.
DatabaseReference get firebaseDatabaseRef => FirebaseDatabase.instance.ref();
