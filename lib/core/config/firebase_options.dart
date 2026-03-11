// ignore_for_file: lines_longer_than_80_chars
// Options from .env (loaded in main) or --dart-define. Android uses FIREBASE_APP_ID_ANDROID / FIREBASE_API_KEY_ANDROID when set.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter_dotenv/flutter_dotenv.dart';

String _fromEnv(String key) => (dotenv.env[key] ?? '').trim();

/// Default Firebase options from .env or dart-defines. Use platform-specific app ID on Android when set.
FirebaseOptions get defaultFirebaseOptions {
  final isAndroid = defaultTargetPlatform == TargetPlatform.android;
  final appId = isAndroid
      ? (_fromEnv('FIREBASE_APP_ID_ANDROID').isNotEmpty
            ? _fromEnv('FIREBASE_APP_ID_ANDROID')
            : _fromEnv('FIREBASE_APP_ID'))
      : _fromEnv('FIREBASE_APP_ID');
  final apiKey = isAndroid
      ? (_fromEnv('FIREBASE_API_KEY_ANDROID').isNotEmpty
            ? _fromEnv('FIREBASE_API_KEY_ANDROID')
            : _fromEnv('FIREBASE_API_KEY'))
      : _fromEnv('FIREBASE_API_KEY');

  // ignore: prefer_const_constructors - FirebaseOptions has no const constructor
  return FirebaseOptions(
    apiKey: apiKey.isNotEmpty ? apiKey : const String.fromEnvironment('FIREBASE_API_KEY', defaultValue: ''),
    appId: appId.isNotEmpty ? appId : const String.fromEnvironment('FIREBASE_APP_ID', defaultValue: ''),
    messagingSenderId: _fromEnv('FIREBASE_MESSAGING_SENDER_ID').isNotEmpty
        ? _fromEnv('FIREBASE_MESSAGING_SENDER_ID')
        : const String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID', defaultValue: ''),
    projectId: _fromEnv('FIREBASE_PROJECT_ID').isNotEmpty
        ? _fromEnv('FIREBASE_PROJECT_ID')
        : const String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: ''),
    authDomain: _fromEnv('FIREBASE_AUTH_DOMAIN').isNotEmpty
        ? _fromEnv('FIREBASE_AUTH_DOMAIN')
        : const String.fromEnvironment('FIREBASE_AUTH_DOMAIN', defaultValue: ''),
    databaseURL: _fromEnv('FIREBASE_DATABASE_URL').isNotEmpty
        ? _fromEnv('FIREBASE_DATABASE_URL')
        : const String.fromEnvironment('FIREBASE_DATABASE_URL', defaultValue: 'https://buzz-hive-1c599-default-rtdb.firebaseio.com'),
    storageBucket: _fromEnv('FIREBASE_STORAGE_BUCKET').isNotEmpty
        ? _fromEnv('FIREBASE_STORAGE_BUCKET')
        : const String.fromEnvironment('FIREBASE_STORAGE_BUCKET', defaultValue: ''),
  );
}
