import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/tenant.dart'; // Contains both Tenant and UserProfile
import '../services/tenant_service.dart';
import 'auth_provider.dart';

// State class to hold both User Profile and Tenant info
class TenantState {
  final UserProfile? profile;
  final Tenant? tenant;

  const TenantState({this.profile, this.tenant});

  TenantState copyWith({UserProfile? profile, Tenant? tenant}) {
    return TenantState(
      profile: profile ?? this.profile,
      tenant: tenant ?? this.tenant,
    );
  }
}

final tenantServiceProvider = Provider<TenantService>((ref) => TenantService());

final tenantProvider = AsyncNotifierProvider<TenantNotifier, TenantState>(
  TenantNotifier.new,
);

class TenantNotifier extends AsyncNotifier<TenantState> {
  late final TenantService _service;

  @override
  Future<TenantState> build() async {
    _service = ref.read(tenantServiceProvider);

    // Watch auth user changes to trigger reload
    final authState = ref.watch(authProvider);

    if (authState.user != null) {
      return await _fetchTenantData(authState.user!.id);
    }

    return const TenantState();
  }

  Future<TenantState> _fetchTenantData(String userId) async {
    try {
      // 1. Fetch User Profile
      final profile = await _service.getUserProfile();

      if (profile == null) {
        return const TenantState();
      }

      // 2. Fetch Tenant Details if tenant_id exists
      Tenant? tenant;
      if (profile.tenantId != null) {
        tenant = await _service.getTenant(profile.tenantId!);
      }

      return TenantState(profile: profile, tenant: tenant);
    } catch (e) {
      // Return empty state or rethrow depending on desired behavior
      // For now, let UI handle error via AsyncValue
      rethrow;
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final authState = ref.read(authProvider);
      if (authState.user != null) {
        return _fetchTenantData(authState.user!.id);
      }
      return const TenantState();
    });
  }
}
