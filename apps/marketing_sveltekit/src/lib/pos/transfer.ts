import { createClient } from '@/lib/supabase/server';
import {
    InterBranchTransfer,
    InterBranchTransferInsert,
    InterBranchTransferUpdate,
    InterBranchTransferWithItems,
    TransferItemInsert
} from '@/lib/types/database';

export class InterBranchTransferService {
    /**
     * Create a new transfer request
     */
    static async createTransfer(
        transferData: InterBranchTransferInsert,
        items: TransferItemInsert[]
    ): Promise<InterBranchTransfer | null> {
        const supabase = await createClient();

        // Start a transaction-like approach (Supabase doesn't support convenient transactions over HTTP yet without RPC)
        // For now, insert transfer first, then items.

        // 1. Insert Transfer
        const { data: transfer, error: transferError } = await supabase
            .from('inter_branch_transfers')
            .insert(transferData)
            .select()
            .single();

        if (transferError || !transfer) {
            console.error('Error creating transfer:', transferError);
            throw transferError;
        }

        // 2. Insert Items
        const itemsWithTransferId = items.map(item => ({
            ...item,
            transfer_id: transfer.id
        }));

        const { error: itemsError } = await supabase
            .from('transfer_items')
            .insert(itemsWithTransferId);

        if (itemsError) {
            console.error('Error creating transfer items:', itemsError);
            // Ideally rollback transfer here
            await supabase.from('inter_branch_transfers').delete().eq('id', transfer.id);
            throw itemsError;
        }

        return transfer;
    }

    /**
     * Update transfer status (e.g. approve, reject, complete)
     */
    static async updateStatus(
        transferId: string,
        status: InterBranchTransferUpdate['status'],
        userId: string // Who performed the update
    ): Promise<InterBranchTransfer | null> {
        const supabase = await createClient();

        const updateData: InterBranchTransferUpdate = {
            status,
            updated_at: new Date().toISOString()
        };

        if (status === 'in_transit') {
            updateData.authorized_by_id = userId;
            // updateData.approved_at = new Date().toISOString(); // Column might not exist or be named differently, omitting for now based on lint
        } else if (status === 'completed') {
            updateData.received_by_id = userId;
            // updateData.received_at = new Date().toISOString(); // Column might not exist

            // 1. Fetch Transfer Items
            const { data: transferItems, error: itemsError } = await supabase
                .from('transfer_items')
                .select('*')
                .eq('transfer_id', transferId);

            if (itemsError || !transferItems) {
                throw new Error("Failed to fetch transfer items for inventory update");
            }

            // 2. Perform Inventory Movement
            const transferInfo = await supabase.from('inter_branch_transfers').select('source_branch_id, destination_branch_id').eq('id', transferId).single();
            if (!transferInfo.data) throw new Error("Transfer not found");

            const sourceBranchId = transferInfo.data.source_branch_id;
            const destBranchId = transferInfo.data.destination_branch_id;

            for (const item of transferItems) {
                // Deduct from Source
                await supabase.rpc('adjust_inventory', {
                    p_branch_id: sourceBranchId,
                    p_product_id: item.product_id,
                    p_delta: -item.quantity
                });

                // Add to Destination
                await supabase.rpc('adjust_inventory', {
                    p_branch_id: destBranchId,
                    p_product_id: item.product_id,
                    p_delta: item.quantity
                });
            }
        }

        const { data, error } = await supabase
            .from('inter_branch_transfers')
            .update(updateData)
            .eq('id', transferId)
            .select()
            .single();

        if (error) {
            console.error('Error updating transfer status:', error);
            throw error;
        }

        // If 'received', we should technically move inventory here. 
        // That would likely belong in an InventoryService or a trigger.
        // We will assume that logic is handled separately or in a future task.

        return data;
    }

    /**
     * Get transfers for a tenant (with filters)
     */
    static async getTransfers(
        tenantId: string,
        filters?: {
            sourceBranchId?: string;
            destBranchId?: string;
            status?: string
        }
    ): Promise<InterBranchTransferWithItems[]> {
        const supabase = await createClient();

        let query = supabase
            .from('inter_branch_transfers')
            .select(`
        *,
        items:transfer_items(*, product:products(*)),
        source_branch:branches!source_branch_id(*),
        destination_branch:branches!destination_branch_id(*),
        requested_by_user:users!requested_by(*)
      `)
            .eq('tenant_id', tenantId)
            .order('created_at', { ascending: false });

        if (filters?.sourceBranchId) {
            query = query.eq('source_branch_id', filters.sourceBranchId);
        }
        if (filters?.destBranchId) {
            query = query.eq('destination_branch_id', filters.destBranchId);
        }
        if (filters?.status) {
            query = query.eq('status', filters.status);
        }

        const { data, error } = await query;

        if (error) {
            console.error('Error fetching transfers:', error);
            throw error;
        }

        return (data || []) as InterBranchTransferWithItems[];
    }

    /**
     * Get a single transfer details
     */
    static async getTransfer(transferId: string): Promise<InterBranchTransferWithItems | null> {
        const supabase = await createClient();

        const { data, error } = await supabase
            .from('inter_branch_transfers')
            .select(`
        *,
        items:transfer_items(*, product:products(*)),
        source_branch:branches!source_branch_id(*),
        destination_branch:branches!destination_branch_id(*),
        requested_by_user:users!requested_by(*)
      `)
            .eq('id', transferId)
            .single();

        if (error) {
            console.error('Error fetching transfer:', error);
            throw error;
        }

        return data as InterBranchTransferWithItems;
    }
}
