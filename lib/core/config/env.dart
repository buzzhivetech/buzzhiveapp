import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Runtime environment and API keys.
/// Reads from .env file first (via flutter_dotenv), then --dart-define.
/// Firebase keys live in [firebase_options.dart].
class Env {
  Env._();

  static const bool isProduction = bool.fromEnvironment(
    'dart.vm.product',
    defaultValue: false,
  );

  static String get supabaseUrl =>
      dotenv.env['SUPABASE_URL']?.trim() ??
      const String.fromEnvironment('SUPABASE_URL', defaultValue: '');

  static String get supabaseAnonKey =>
      dotenv.env['SUPABASE_ANON_KEY']?.trim() ??
      const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  static bool get hasSupabaseConfig =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
