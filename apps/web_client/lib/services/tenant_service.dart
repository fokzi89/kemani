import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/tenant.dart';

class TenantService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetch the current user's profile
  Future<UserProfile?> getUserProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', user.id)
          .single();

      return UserProfile.fromJson(response);
    } catch (e) {
      // Handle error or return null
      return null;
    }
  }

  /// Fetch the tenant details for a given tenant ID
  Future<Tenant?> getTenant(String tenantId) async {
    try {
      final response = await _supabase
          .from('tenants')
          .select()
          .eq('id', tenantId)
          .single();

      // Mapping Supabase response to Tenant model
      // Adjust field names if necessary based on actual DB schema
      return Tenant.fromJson({
        'id': response['id'],
        'name': response['name'],
        'business_type': response['type'], // Assuming 'type' column
        'address': response['address'],
        'city': response['city'],
        'country': response['country'],
        'logo_url': response['logo_url'],
        'created_at': response['created_at'],
        'updated_at': response['updated_at'],
      });
    } catch (e) {
      // Log error
      return null;
    }
  }

  /// Update user profile
  Future<void> updateProfile(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    await _supabase.from('users').update(updates).eq('id', userId);
  }

  /// Update checking for tenant updates permissions
  Future<void> updateTenant(
    String tenantId,
    Map<String, dynamic> updates,
  ) async {
    // RLS should restrict this to admins
    await _supabase.from('tenants').update(updates).eq('id', tenantId);
  }
}
