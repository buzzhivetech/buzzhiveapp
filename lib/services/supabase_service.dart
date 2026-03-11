import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/env.dart';

/// Supabase initialization; call from main() before runApp.
Future<void> initSupabase() async {
  if (!Env.hasSupabaseConfig) return;
  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
  );
}

/// Access to Supabase client (after init).
SupabaseClient get supabaseClient => Supabase.instance.client;
