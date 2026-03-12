import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Runtime environment and API keys.
/// Reads from .env file first (via flutter_dotenv), then --dart-define.
/// Firebase keys live in [firebase_options.dart].
class Env {
  Env._();

  // -- Environment name --

  static String get appEnv =>
      _fromEnv('APP_ENV', const String.fromEnvironment('APP_ENV', defaultValue: 'development'));

  static bool get isDevelopment => appEnv == 'development';
  static bool get isStaging => appEnv == 'staging';
  static bool get isProduction =>
      appEnv == 'production' || const bool.fromEnvironment('dart.vm.product', defaultValue: false);

  // -- Supabase --

  static String get supabaseUrl =>
      _fromEnv('SUPABASE_URL', const String.fromEnvironment('SUPABASE_URL', defaultValue: ''));

  static String get supabaseAnonKey =>
      _fromEnv('SUPABASE_ANON_KEY', const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: ''));

  static bool get hasSupabaseConfig =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  // -- Helpers --

  static String _fromEnv(String key, String fallback) {
    try {
      final value = (dotenv.env[key] ?? '').trim();
      return value.isNotEmpty ? value : fallback;
    } on Object {
      return fallback;
    }
  }
}
