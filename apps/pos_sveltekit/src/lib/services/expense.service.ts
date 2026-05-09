import { supabase } from '../supabase';

export type ExpenseStatus = 'pending' | 'approved' | 'rejected' | 'paid' | 'cancelled';
export type RecurrenceInterval = 'none' | 'weekly' | 'monthly' | 'quarterly' | 'yearly';

export interface ExpenseType {
    id: string;
    name: string;
    is_auto_approve: boolean;
    is_default: boolean;
}

export interface Expense {
    id: string;
    tenant_id: string;
    branch_id: string;
    expense_type_id: string;
    amount: number;
    description: string;
    expense_date: string;
    status: ExpenseStatus;
    raised_by: string;
    approved_by?: string;
    paid_by?: string;
    rejection_reason?: string;
    supplier_id?: string;
    po_id?: string;
    invoice_number?: string;
    raised_date?: string;
    due_date?: string;
    payment_terms?: string;
    payment_collected_by?: string;
    bank_name?: string;
    bank_account_number?: string;
    receipt_url?: string;
    payment_evidence_url?: string;
    is_recurring: boolean;
    recur_interval: RecurrenceInterval;
    next_recur_date?: string;
    parent_recurring_id?: string;
    created_at: string;
    expense_types?: ExpenseType;
}

export class ExpenseService {
    static async getExpenseTypes() {
        const { data, error } = await supabase
            .from('expense_types')
            .select('*')
            .order('name');
        
        if (error) throw error;
        return data as ExpenseType[];
    }

    static async getExpenses(filters?: {
        status?: ExpenseStatus;
        branch_id?: string;
        startDate?: string;
        endDate?: string;
    }) {
        let query = supabase
            .from('expenses')
            .select(`
                *,
                expense_types(name, is_auto_approve),
                supplier:suppliers(name),
                raiser:users!raised_by(full_name),
                approver:users!approved_by(full_name),
                payer:users!paid_by(full_name)
            `)
            .order('expense_date', { ascending: false });

        if (filters?.status) query = query.eq('status', filters.status);
        if (filters?.branch_id) query = query.eq('branch_id', filters.branch_id);
        if (filters?.startDate) query = query.gte('expense_date', filters.startDate);
        if (filters?.endDate) query = query.lte('expense_date', filters.endDate);

        const { data, error } = await query;
        if (error) throw error;
        return data;
    }

    static async createExpense(expense: Partial<Expense>, receiptFile?: File) {
        let receipt_url = null;

        if (receiptFile) {
            const { data: { session } } = await supabase.auth.getSession();
            if (!session) throw new Error('Not authenticated');

            const { data: user } = await supabase.from('users').select('tenant_id').eq('id', session.user.id).single();
            if (!user) throw new Error('User not found');

            const fileExt = receiptFile.name.split('.').pop();
            const fileName = `${Math.random()}.${fileExt}`;
            const filePath = `${user.tenant_id}/${session.user.id}/${fileName}`;

            const { error: uploadError } = await supabase.storage
                .from('expense-documents')
                .upload(filePath, receiptFile);

            if (uploadError) throw uploadError;
            receipt_url = filePath;
        }

        const { data, error } = await supabase
            .from('expenses')
            .insert([{ ...expense, receipt_url }])
            .select()
            .single();

        if (error) throw error;
        return data;
    }

    static async updateStatus(id: string, status: ExpenseStatus, details: {
        rejection_reason?: string;
        paid_by?: string;
        payment_evidence_file?: File;
        payment_collected_by?: string;
    }) {
        const { data: { session } } = await supabase.auth.getSession();
        if (!session) throw new Error('Not authenticated');

        const updates: any = { status, updated_at: new Date().toISOString() };

        if (status === 'approved') {
            updates.approved_by = session.user.id;
        } else if (status === 'rejected') {
            updates.approved_by = session.user.id;
            updates.rejection_reason = details.rejection_reason;
        } else if (status === 'paid') {
            updates.paid_by = details.paid_by || session.user.id;
            updates.payment_collected_by = details.payment_collected_by;

            if (details.payment_evidence_file) {
                const { data: user } = await supabase.from('users').select('tenant_id').eq('id', session.user.id).single();
                if (!user) throw new Error('User not found');

                const fileExt = details.payment_evidence_file.name.split('.').pop();
                const fileName = `pay-evidence-${Math.random()}.${fileExt}`;
                const filePath = `${user.tenant_id}/${session.user.id}/${fileName}`;

                const { error: uploadError } = await supabase.storage
                    .from('expense-documents')
                    .upload(filePath, details.payment_evidence_file);

                if (uploadError) throw uploadError;
                updates.payment_evidence_url = filePath;
            }
        }

        const { data, error } = await supabase
            .from('expenses')
            .update(updates)
            .eq('id', id)
            .select()
            .single();

        if (error) throw error;
        return data;
    }

    static async getPublicUrl(path: string) {
        const { data } = supabase.storage.from('expense-documents').getPublicUrl(path);
        return data.publicUrl;
    }
}
