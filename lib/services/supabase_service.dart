import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/env.dart';
import '../core/utils/app_logger.dart';

/// Supabase initialization; call from main() before runApp.
Future<void> initSupabase() async {
  if (!Env.hasSupabaseConfig) {
    AppLogger.warn('Supabase skipped: URL or anon key missing', name: 'Supabase');
    return;
  }
  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
  );
  AppLogger.info('Supabase initialized', name: 'Supabase');
}

/// Access to Supabase client (after init).
SupabaseClient get supabaseClient => Supabase.instance.client;
