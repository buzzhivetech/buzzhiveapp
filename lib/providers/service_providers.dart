import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/firebase/firebase_sensor_data_service.dart';
import '../services/supabase/supabase_auth_service.dart';

final supabaseAuthServiceProvider = Provider<SupabaseAuthService>((ref) {
  return SupabaseAuthService();
});

final firebaseSensorDataServiceProvider = Provider<FirebaseSensorDataService>((ref) {
  return FirebaseSensorDataService();
});
