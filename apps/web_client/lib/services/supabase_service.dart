import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseClient client = Supabase.instance.client;

  Future<void> signInWithOtp(String phone) {
    return client.auth.signInWithOtp(phone: phone);
  }

  Future<AuthResponse> verifyOtp(String phone, String token) {
    return client.auth.verifyOTP(token: token, type: OtpType.sms, phone: phone);
  }

  Future<void> signOut() {
    return client.auth.signOut();
  }

  // Add other methods as needed for data access if not using PowerSync
}
