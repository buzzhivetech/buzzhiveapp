// ignore_for_file: lines_longer_than_80_chars
// Run: flutterfire configure (generates this file), or use env vars below.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

/// Default Firebase options from environment or dart-defines.
FirebaseOptions get defaultFirebaseOptions {
  // ignore: prefer_const_constructors - FirebaseOptions has no const constructor
  return FirebaseOptions(
    apiKey: const String.fromEnvironment(
      'FIREBASE_API_KEY',
      defaultValue: '',
    ),
    appId: const String.fromEnvironment(
      'FIREBASE_APP_ID',
      defaultValue: '',
    ),
    messagingSenderId: const String.fromEnvironment(
      'FIREBASE_MESSAGING_SENDER_ID',
      defaultValue: '',
    ),
    projectId: const String.fromEnvironment(
      'FIREBASE_PROJECT_ID',
      defaultValue: '',
    ),
    authDomain: const String.fromEnvironment(
      'FIREBASE_AUTH_DOMAIN',
      defaultValue: '',
    ),
    databaseURL: const String.fromEnvironment(
      'FIREBASE_DATABASE_URL',
      defaultValue: 'https://buzz-hive-1c599-default-rtdb.firebaseio.com',
    ),
    storageBucket: const String.fromEnvironment(
      'FIREBASE_STORAGE_BUCKET',
      defaultValue: '',
    ),
  );
}
