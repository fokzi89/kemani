import { createClient } from '@/lib/supabase/client';
import {
  TenantRegistration,
  TenantInsert,
  UserInsert,
  BranchInsert,
} from '@/lib/types/database';

export class TenantService {
  /**
   * Register a new tenant with an admin user and default branch
   */
  static async registerTenant(registration: TenantRegistration) {
    const supabase = createClient();

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
      // First, create the auth user via Supabase Auth
      let authUserId: string;

      if (registration.adminEmail) {
        // Email-based registration
        const { data: authData, error: authError } = await supabase.auth.signUp({
          email: registration.adminEmail,
          password: crypto.randomUUID(), // Random password, user will use OTP
          options: {
            data: {
              full_name: registration.adminName,
              tenant_id: tenant.id,
              role: 'tenant_admin',
            },
          },
        });

        if (authError) throw authError;
        if (!authData.user) throw new Error('Failed to create auth user');
        authUserId = authData.user.id;
      } else if (registration.adminPhone) {
        // Phone-based registration
        const { data: authData, error: authError } = await supabase.auth.signUp({
          phone: registration.adminPhone,
          password: crypto.randomUUID(),
          options: {
            data: {
              full_name: registration.adminName,
              tenant_id: tenant.id,
              role: 'tenant_admin',
            },
          },
        });

        if (authError) throw authError;
        if (!authData.user) throw new Error('Failed to create auth user');
        authUserId = authData.user.id;
      } else {
        throw new Error('Either email or phone must be provided');
      }

      // 3. Create user record in users table
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
        business_type: 'retail', // Default business type
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
    const supabase = createClient();

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
   */
  static async getTenantBySlug(slug: string) {
    const supabase = createClient();

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
    const supabase = createClient();

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
   */
  static async isSlugAvailable(slug: string): Promise<boolean> {
    const supabase = createClient();

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
    const supabase = createClient();

    const { error } = await supabase
      .from('tenants')
      .update({ deleted_at: new Date().toISOString() })
      .eq('id', tenantId);

    if (error) throw error;
    return { success: true };
  }
}
