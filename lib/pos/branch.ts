import { createClient } from '@/lib/supabase/server';
import { Branch, BranchInsert, BranchUpdate } from '@/lib/types/database';

export class BranchService {
    /**
     * Create a new branch
     */
    static async createBranch(branchData: BranchInsert): Promise<Branch | null> {
        const supabase = await createClient();

        const { data, error } = await supabase
            .from('branches')
            .insert(branchData)
            .select()
            .single();

        if (error) {
            console.error('Error creating branch:', error);
            throw error;
        }

        return data;
    }

    /**
     * Update an existing branch
     */
    static async updateBranch(branchId: string, updates: BranchUpdate): Promise<Branch | null> {
        const supabase = await createClient();

        const { data, error } = await supabase
            .from('branches')
            .update(updates)
            .eq('id', branchId)
            .select()
            .single();

        if (error) {
            console.error('Error updating branch:', error);
            throw error;
        }

        return data;
    }

    /**
     * Get all branches for a tenant
     */
    static async getBranches(tenantId: string): Promise<Branch[]> {
        const supabase = await createClient();

        const { data, error } = await supabase
            .from('branches')
            .select('*')
            .eq('tenant_id', tenantId)
            .is('deleted_at', null)
            .order('name');

        if (error) {
            console.error('Error fetching branches:', error);
            throw error;
        }

        return data || [];
    }

    /**
     * Get a single branch by ID
     */
    static async getBranch(branchId: string): Promise<Branch | null> {
        const supabase = await createClient();

        const { data, error } = await supabase
            .from('branches')
            .select('*')
            .eq('id', branchId)
            .single();

        if (error) {
            console.error('Error fetching branch:', error);
            throw error;
        }

        return data;
    }

    /**
     * Delete a branch (soft delete)
     */
    static async deleteBranch(branchId: string): Promise<boolean> {
        const supabase = await createClient();

        const { error } = await supabase
            .from('branches')
            .update({ deleted_at: new Date().toISOString() })
            .eq('id', branchId);

        if (error) {
            console.error('Error deleting branch:', error);
            throw error;
        }

        return true;
    }
}
