import { createClient, createAdminClient } from '@/lib/supabase/server';
import { UserInsert, UserUpdate, UserRole, UserInvite } from '@/lib/types/database';

export class UserService {
  /**
   * Create a new staff user (invite)
   * Uses Admin Client to bypass permissions for creating auth users
   */
  static async createUser(invite: UserInvite, tenantId: string) {
    // Use admin client for user creation privileges
    const supabase = await createAdminClient();

    try {
      // 1. Create auth user
      let authUserId: string;

      if (invite.email) {
        // Create user via Admin API (doesn't require password, sends magic link or just creates)
        const { data: authData, error: authError } = await supabase.auth.admin.createUser({
          email: invite.email,
          phone: invite.phone,
          user_metadata: {
            full_name: invite.fullName,
            tenant_id: tenantId,
            role: invite.role,
          },
          email_confirm: true, // Auto-confirm for staff invites? Or let them verify?
          // Usually for staff invites, we might set email_confirm: true and send a password reset link manually
          // or let Supabase handle the invite email.
          // For now, auto-confirm to simplify the flow as per standard SaaS patterns where admin adds user.
        });

        if (authError) throw authError;
        if (!authData.user) throw new Error('Failed to create auth user');
        authUserId = authData.user.id;

        // Optionally send invite email here if Supabase doesn't auto-send
        // (Supabase Admin InviteUser usually sends email if configured)

      } else if (invite.phone) {
        const { data: authData, error: authError } = await supabase.auth.admin.createUser({
          phone: invite.phone,
          password: crypto.randomUUID(), // Random password
          phone_confirm: true,
          user_metadata: {
            full_name: invite.fullName,
            tenant_id: tenantId,
            role: invite.role,
          },
        });

        if (authError) throw authError;
        if (!authData.user) throw new Error('Failed to create auth user');
        authUserId = authData.user.id;
      } else {
        throw new Error('Either email or phone must be provided');
      }

      // 2. Create user record
      const userData: UserInsert = {
        id: authUserId,
        full_name: invite.fullName,
        email: invite.email,
        phone: invite.phone,
        role: invite.role,
        tenant_id: tenantId,
        branch_id: invite.branchId,
      };

      const { data, error } = await supabase
        .from('users')
        .insert(userData)
        .select()
        .single();

      if (error) throw error;

      return { success: true, user: data };
    } catch (error) {
      console.error('User creation error:', error);
      throw error;
    }
  }

  /**
   * Get user by ID
   */
  static async getUser(userId: string) {
    const supabase = await createClient();

    const { data, error } = await supabase
      .from('users')
      .select(`
        *,
        tenant:tenants(*),
        branch:branches(*)
      `)
      .eq('id', userId)
      .single();

    if (error) throw error;
    return data;
  }

  /**
   * Get all users for a tenant
   */
  static async getUsersByTenant(tenantId: string) {
    const supabase = await createClient();

    const { data, error } = await supabase
      .from('users')
      .select(`
        *,
        branch:branches(*)
      `)
      .eq('tenant_id', tenantId)
      .is('deleted_at', null)
      .order('created_at', { ascending: false });

    if (error) throw error;
    return data;
  }

  /**
   * Get users by branch
   */
  static async getUsersByBranch(branchId: string) {
    const supabase = await createClient();

    const { data, error } = await supabase
      .from('users')
      .select('*')
      .eq('branch_id', branchId)
      .is('deleted_at', null)
      .order('full_name');

    if (error) throw error;
    return data;
  }

  /**
   * Update user information
   */
  static async updateUser(userId: string, updates: UserUpdate) {
    const supabase = await createClient();

    const { data, error } = await supabase
      .from('users')
      .update(updates)
      .eq('id', userId)
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  /**
   * Update user role
   */
  static async updateUserRole(userId: string, role: UserRole) {
    return this.updateUser(userId, { role });
  }

  /**
   * Assign user to branch
   */
  static async assignUserToBranch(userId: string, branchId: string) {
    return this.updateUser(userId, { branch_id: branchId });
  }

  /**
   * Soft delete a user
   */
  static async deleteUser(userId: string) {
    const supabase = await createClient(); // RLS should handle this if caller has permission

    const { error } = await supabase
      .from('users')
      .update({ deleted_at: new Date().toISOString() })
      .eq('id', userId);

    if (error) throw error;

    // Also disable auth user? 
    // We might want to do this via admin client to prevent login
    try {
      const adminAuth = await createAdminClient();
      await adminAuth.auth.admin.updateUserById(userId, { ban_duration: '876600h' }); // Ban for ~100 years
    } catch (e) {
      console.error('Failed to ban auth user:', e);
    }

    return { success: true };
  }

  /**
   * Update last login time
   */
  static async updateLastLogin(userId: string) {
    const supabase = await createClient();

    const { error } = await supabase
      .from('users')
      .update({ last_login_at: new Date().toISOString() })
      .eq('id', userId);

    if (error) {
      console.error('Failed to update last login:', error);
      // Don't throw - this is not critical
    }
  }

  /**
   * Get current authenticated user with full details
   */
  static async getCurrentUser() {
    const supabase = await createClient();

    const { data: { user: authUser }, error: authError } = await supabase.auth.getUser();

    if (authError) throw authError;
    if (!authUser) return null;

    return this.getUser(authUser.id);
  }

  /**
   * Check if user has required role
   */
  static async hasRole(userId: string, requiredRoles: UserRole[]): Promise<boolean> {
    const user = await this.getUser(userId);
    return requiredRoles.includes(user.role);
  }
}
