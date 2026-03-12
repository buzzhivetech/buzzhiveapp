import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

import '../core/config/firebase_options.dart' as app_config;
import '../core/utils/app_logger.dart';

/// Firebase initialization; call from main() before runApp.
/// No-op if projectId is not set (e.g. missing env / dart-define).
Future<void> initFirebase() async {
  final options = app_config.defaultFirebaseOptions;
  if (options.projectId.isEmpty) {
    AppLogger.warn('Firebase skipped: projectId is empty', name: 'Firebase');
    return;
  }
  await Firebase.initializeApp(options: options);
  AppLogger.info('Firebase initialized (project: ${options.projectId})', name: 'Firebase');
}

/// Root Firebase Realtime Database reference.
DatabaseReference get firebaseDatabaseRef => FirebaseDatabase.instance.ref();
