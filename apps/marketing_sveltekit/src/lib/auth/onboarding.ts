import { createClient } from '@/lib/supabase/server';
import { OnboardingProfileData, OnboardingCompanyData } from '@/lib/types/onboarding';

export class OnboardingService {
  /**
   * Save user profile information (Step 1)
   */
  static async saveProfile(userId: string, data: OnboardingProfileData) {
    const supabase = await createClient();

    const updates: any = {
      full_name: data.fullName,
      updated_at: new Date().toISOString(),
    };

    if (data.phoneNumber) updates.phone_number = data.phoneNumber; // Map camelCase to snake_case if needed, but DB is phone_number
    if (data.gender) updates.gender = data.gender;
    if (data.profilePictureUrl) updates.profile_picture_url = data.profilePictureUrl;

    const { data: user, error } = await supabase
      .from('users')
      .update(updates)
      .eq('id', userId)
      .select()
      .single();

    if (error) {
      console.error('Error saving profile:', error);
      throw error;
    }

    return user;
  }

  /**
   * Save company information (Step 2)
   * For new owners: Creates tenant, default branch, and links user
   * For existing tenants: Updates tenant information
   */
  static async saveCompany(userId: string, data: OnboardingCompanyData, tenantId?: string) {
    const supabase = await createClient();

    try {
      // If tenantId provided, update existing tenant (staff onboarding or tenant update)
      if (tenantId) {
        const updates: any = {
          business_type: data.businessType,
          address: data.address,
          country: data.country,
          city: data.city,
          updated_at: new Date().toISOString(),
        };

        if (data.businessName) updates.business_name = data.businessName;
        if (data.officeAddress) updates.office_address = data.officeAddress;
        if (data.logoUrl) updates.logo_url = data.logoUrl;
        if (data.latitude !== undefined) updates.latitude = data.latitude;
        if (data.longitude !== undefined) updates.longitude = data.longitude;

        const { data: tenant, error } = await supabase
          .from('tenants')
          .update(updates)
          .eq('id', tenantId)
          .select()
          .single();

        if (error) {
          console.error('Error updating tenant:', error);
          throw error;
        }

        return { tenant };
      }

      // Create new tenant for owner registration
      if (!data.businessName) {
        throw new Error('Business name is required for new tenant creation');
      }

      // 1. Generate unique subdomain/slug from business name
      const slug = data.businessName
        .toLowerCase()
        .replace(/[^a-z0-9]+/g, '-')
        .replace(/^-+|-+$/g, '')
        .substring(0, 100);

      // 2. Create tenant
      const { data: tenant, error: tenantError } = await supabase
        .from('tenants')
        .insert({
          name: data.businessName,
          slug: `${slug}-${Date.now()}`, // Add timestamp for uniqueness
          business_type: data.businessType,
          address: data.address,
          country: data.country,
          city: data.city,
          office_address: data.officeAddress || data.address,
          latitude: data.latitude || null,
          longitude: data.longitude || null,
          logo_url: data.logoUrl || null,
        })
        .select()
        .single();

      if (tenantError) {
        console.error('Error creating tenant:', tenantError);
        throw tenantError;
      }

      // 3. Create default branch
      const { data: branch, error: branchError } = await supabase
        .from('branches')
        .insert({
          tenant_id: tenant.id,
          name: 'Main Branch',
          business_type: data.businessType,
          address: data.address,
          latitude: data.latitude || null,
          longitude: data.longitude || null,
        })
        .select()
        .single();

      if (branchError) {
        console.error('Error creating branch:', branchError);
        // Rollback: Delete tenant if branch creation fails
        await supabase.from('tenants').delete().eq('id', tenant.id);
        throw branchError;
      }

      // 4. Update user with tenant_id, branch_id, and role
      const { error: userError } = await supabase
        .from('users')
        .update({
          tenant_id: tenant.id,
          branch_id: branch.id,
          role: 'tenant_admin',
          updated_at: new Date().toISOString(),
        })
        .eq('id', userId);

      if (userError) {
        console.error('Error updating user:', userError);
        // Rollback: Delete branch and tenant
        await supabase.from('branches').delete().eq('id', branch.id);
        await supabase.from('tenants').delete().eq('id', tenant.id);
        throw userError;
      }

      // 5. Update auth user metadata (for middleware checks)
      try {
        await supabase.auth.updateUser({
          data: {
            tenant_id: tenant.id,
            role: 'tenant_admin',
          },
        });
      } catch (authError) {
        console.warn('Failed to update auth metadata (non-critical):', authError);
      }

      return { tenant, branch };
    } catch (error) {
      console.error('Error in saveCompany:', error);
      throw error;
    }
  }

  /**
   * Mark onboarding as complete for the user
   */
  static async completeOnboarding(userId: string) {
    const supabase = await createClient();

    const { data: user, error } = await supabase
      .from('users')
      .update({
        onboarding_completed_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      })
      .eq('id', userId)
      .select()
      .single();

    if (error) {
      console.error('Error completing onboarding:', error);
      throw error;
    }

    // Also update tenant status to 'active' if it was 'trial' or similar? 
    // For now, valid tenant creation defaults to 'active'.
    // We might want to mark tenant as 'onboarding_completed' if we add that flag to tenants table later.
    // The migration added `onboarding_completed` boolean to tenants, let's update that too if user is admin.

    // Check if user is admin and update tenant
    if (user && user.role === 'tenant_admin' && user.tenant_id) {
      await supabase
        .from('tenants')
        .update({ onboarding_completed: true })
        .eq('id', user.tenant_id);
    }

    return user;
  }

  /**
   * Get current onboarding status for a user
   */
  static async getOnboardingStatus(userId: string) {
    const supabase = await createClient();

    const { data: user, error } = await supabase
      .from('users')
      .select('onboarding_completed_at, tenant_id, role')
      .eq('id', userId)
      .single();

    if (error) throw error;

    return {
      isComplete: !!user.onboarding_completed_at,
      completedAt: user.onboarding_completed_at,
      tenantId: user.tenant_id,
      role: user.role
    };
  }
}
