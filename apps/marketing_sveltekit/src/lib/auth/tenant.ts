import { createClient, createAdminClient } from '@/lib/supabase/server';
import {
  TenantRegistration,
  TenantInsert,
  UserInsert,
  BranchInsert,
} from '@/lib/types/database';

export class TenantService {
  /**
   * Register a new tenant with an admin user and default branch
   * Uses Admin Client to bypass RLS during initial setup
   */
  static async registerTenant(registration: TenantRegistration) {
    // Use admin client to bypass RLS for initial setup
    const supabase = await createAdminClient();

    try {
      // 1. Create the tenant
      const tenantData: TenantInsert = {
        name: registration.tenantName,
        slug: registration.tenantSlug,
        email: registration.email,
        phone: registration.phone,
      };

      const { data: tenant, error: tenantError } = await supabase
        .from('tenants')
        .insert(tenantData)
        .select()
        .single();

      if (tenantError) throw tenantError;
      if (!tenant) throw new Error('Failed to create tenant');

      // 2. Create the admin user
      // First, create the auth user via Supabase Auth Admin API
      let authUserId: string;

      if (registration.adminEmail) {
        // Email-based registration
        const { data: authData, error: authError } = await supabase.auth.admin.createUser({
          email: registration.adminEmail,
          password: crypto.randomUUID(), // Random password, user will use OTP or set password later
          email_confirm: true, // Auto-confirm since we are admin creating it? Or false? 
          // For a self-registration flow, usually we want them to verify. 
          // But if this is "Register Tenant", maybe we verify email first? 
          // Implementation plan says "OTP Authentication". 
          // If we use admin.createUser, we can manually confirm or leave unconfirmed.
          // Let's assume unconfirmed if we want OTP flow, but standard admin creation might auto-confirm.
          // Let's stick to simple creation.
          user_metadata: {
            full_name: registration.adminName,
            tenant_id: tenant.id,
            role: 'tenant_admin',
          },
        });

        if (authError) throw authError;
        if (!authData.user) throw new Error('Failed to create auth user');
        authUserId = authData.user.id;
      } else if (registration.adminPhone) {
        // Phone-based registration
        const { data: authData, error: authError } = await supabase.auth.admin.createUser({
          phone: registration.adminPhone,
          password: crypto.randomUUID(),
          phone_confirm: true, // Assuming phone verification happens separately or trusted
          user_metadata: {
            full_name: registration.adminName,
            tenant_id: tenant.id,
            role: 'tenant_admin',
          },
        });

        if (authError) throw authError;
        if (!authData.user) throw new Error('Failed to create auth user');
        authUserId = authData.user.id;
      } else {
        throw new Error('Either email or phone must be provided');
      }

      // 3. Create user record in users table
      // We need to insert into public.users. Admin client allows this even if RLS is strict.
      const userData: UserInsert = {
        id: authUserId,
        full_name: registration.adminName,
        email: registration.adminEmail,
        phone: registration.adminPhone,
        role: 'tenant_admin',
        tenant_id: tenant.id,
      };

      const { error: userError } = await supabase
        .from('users')
        .insert(userData);

      if (userError) throw userError;

      // 4. Create default branch for the tenant
      const branchData: BranchInsert = {
        name: `${registration.tenantName} - Main Branch`,
        tenant_id: tenant.id,
        business_type: 'supermarket', // Default business type from enum
      };

      const { data: branch, error: branchError } = await supabase
        .from('branches')
        .insert(branchData)
        .select()
        .single();

      if (branchError) throw branchError;

      return {
        success: true,
        tenant,
        userId: authUserId,
        branch,
      };
    } catch (error) {
      console.error('Tenant registration error:', error);
      throw error;
    }
  }

  /**
   * Get tenant by ID
   */
  static async getTenant(tenantId: string) {
    const supabase = await createClient(); // Use standard client (respects RLS)

    const { data, error } = await supabase
      .from('tenants')
      .select('*')
      .eq('id', tenantId)
      .single();

    if (error) throw error;
    return data;
  }

  /**
   * Get tenant by slug
   * Uses Admin Client to ensure we can find it even if RLS is strict (public lookup)
   */
  static async getTenantBySlug(slug: string) {
    const supabase = await createAdminClient();

    const { data, error } = await supabase
      .from('tenants')
      .select('*')
      .eq('slug', slug)
      .single();

    if (error) throw error;
    return data;
  }

  /**
   * Update tenant information
   */
  static async updateTenant(tenantId: string, updates: Partial<TenantInsert>) {
    const supabase = await createClient(); // Respect RLS

    const { data, error } = await supabase
      .from('tenants')
      .update(updates)
      .eq('id', tenantId)
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  /**
   * Check if tenant slug is available
   * Uses Admin Client to ensure global uniqueness check
   */
  static async isSlugAvailable(slug: string): Promise<boolean> {
    const supabase = await createAdminClient();

    const { data, error } = await supabase
      .from('tenants')
      .select('id')
      .eq('slug', slug)
      .maybeSingle();

    if (error) throw error;
    return !data; // Available if no tenant found
  }

  /**
   * Soft delete a tenant
   */
  static async deleteTenant(tenantId: string) {
    const supabase = await createClient();

    const { error } = await supabase
      .from('tenants')
      .update({ deleted_at: new Date().toISOString() })
      .eq('id', tenantId);

    if (error) throw error;
    return { success: true };
  }
}
