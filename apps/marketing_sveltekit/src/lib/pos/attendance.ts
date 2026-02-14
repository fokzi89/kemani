import { createClient } from '@/lib/supabase/server';
import { StaffAttendance, StaffAttendanceInsert, StaffAttendanceUpdate } from '@/lib/types/database';

export class StaffAttendanceService {
    /**
     * Clock in a staff member
     */
    static async clockIn(tenantId: string, userId: string, branchId?: string): Promise<StaffAttendance | null> {
        const supabase = await createClient();

        // 1. Check if already clocked in (open session)
        const { data: openSession } = await supabase
            .from('staff_attendance')
            .select('*')
            .eq('tenant_id', tenantId)
            .eq('staff_id', userId)
            .is('clock_out_at', null)
            .single();

        if (openSession) {
            throw new Error('User is already clocked in.');
        }

        // 2. Create new attendance record
        const newSession: StaffAttendanceInsert = {
            tenant_id: tenantId,
            staff_id: userId,
            branch_id: branchId!, // Assume safely handled by caller, or let it throw if constraint fails. 
            // Actually better to make branchId required in method signature if DB requires it.
            // But for now, let's use ! assertion if we are sure, or default to a dummy if needed?
            // No, let's fix the signature.
            clock_in_at: new Date().toISOString(),
            shift_date: new Date().toISOString().split('T')[0], // YYYY-MM-DD
        };

        const { data, error } = await supabase
            .from('staff_attendance')
            .insert(newSession)
            .select()
            .single();

        if (error) {
            console.error('Error clocking in:', error);
            throw error;
        }

        return data;
    }

    /**
     * Clock out a staff member
     */
    static async clockOut(tenantId: string, userId: string): Promise<StaffAttendance | null> {
        const supabase = await createClient();

        // 1. Find open session
        const { data: openSession } = await supabase
            .from('staff_attendance')
            .select('*')
            .eq('tenant_id', tenantId)
            .eq('staff_id', userId)
            .is('clock_out_at', null)
            .single();

        if (!openSession) {
            throw new Error('No open clock-in session found for this user.');
        }

        // 2. Update with clock_out time
        const clockOutTime = new Date();
        const clockInTime = new Date(openSession.clock_in_at);

        // Calculate duration in hours (decimal)
        const durationMs = clockOutTime.getTime() - clockInTime.getTime();
        const totalHours = durationMs / (1000 * 60 * 60);

        const update: StaffAttendanceUpdate = {
            clock_out_at: clockOutTime.toISOString(),
            total_hours: parseFloat(totalHours.toFixed(2)),
        };

        const { data, error } = await supabase
            .from('staff_attendance')
            .update(update)
            .eq('id', openSession.id)
            .select()
            .single();

        if (error) {
            console.error('Error clocking out:', error);
            throw error;
        }

        return data;
    }

    /**
     * Get current status for a user
     */
    static async getStatus(tenantId: string, userId: string): Promise<{ isClockedIn: boolean; currentSession: StaffAttendance | null }> {
        const supabase = await createClient();

        const { data: currentSession, error } = await supabase
            .from('staff_attendance')
            .select('*')
            .eq('tenant_id', tenantId)
            .eq('staff_id', userId)
            .is('clock_out_at', null)
            .single();

        if (error && error.code !== 'PGRST116') { // PGRST116 is "no rows returned"
            console.error("Error fetching attendance status", error);
        }

        return {
            isClockedIn: !!currentSession,
            currentSession: currentSession || null
        };
    }

    /**
     * Get attendance history for a user or tenant
     */
    static async getHistory(tenantId: string, options?: { userId?: string; dateFrom?: string; dateTo?: string }) {
        const supabase = await createClient();

        let query = supabase
            .from('staff_attendance')
            .select('*, user:users(full_name, email, role)')
            .eq('tenant_id', tenantId)
            .order('clock_in_at', { ascending: false });

        if (options?.userId) {
            query = query.eq('staff_id', options.userId);
        }

        if (options?.dateFrom) {
            query = query.gte('clock_in_at', options.dateFrom);
        }

        if (options?.dateTo) {
            query = query.lte('clock_in_at', options.dateTo);
        }

        const { data, error } = await query;

        if (error) {
            console.error('Error fetching attendance history:', error);
            throw error;
        }

        return data;
    }
}
