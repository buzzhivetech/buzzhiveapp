import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/errors/provider_logger.dart';
import 'core/utils/app_logger.dart';
import 'services/firebase_service.dart';
import 'services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppLogger.info('App starting', name: 'Main');

  try {
    await dotenv.load(fileName: '.env');
    AppLogger.info('.env loaded', name: 'Main');
  } catch (e) {
    AppLogger.warn('.env not found, using dart-define or defaults', name: 'Main', error: e);
  }

  try {
    await initFirebase();
  } catch (e, st) {
    AppLogger.error('Firebase init failed', name: 'Main', error: e, stackTrace: st);
  }

  try {
    await initSupabase();
  } catch (e, st) {
    AppLogger.error('Supabase init failed', name: 'Main', error: e, stackTrace: st);
  }

  AppLogger.info('Starting app', name: 'Main');
  runApp(ProviderScope(
    observers: [AppProviderObserver()],
    child: const BuzzHiveApp(),
  ));
}
