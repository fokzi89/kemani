import { createClient } from '@/lib/supabase/server';
import { StaffAttendanceWithUser } from '@/lib/types/database';

export class StaffReportingService {
    /**
     * Get attendance report for a date range
     */
    static async getAttendanceReport(
        tenantId: string,
        dateFrom: string,
        dateTo: string
    ): Promise<StaffAttendanceWithUser[]> {
        const supabase = await createClient();

        const { data: attendanceData, error } = await supabase
            .from('staff_attendance')
            .select('*, user:users(id, full_name, email, role, branch_id)')
            .eq('tenant_id', tenantId)
            .gte('clock_in_at', dateFrom)
            .lte('clock_in_at', dateTo)
            .order('clock_in_at', { ascending: false });

        if (error) {
            console.error('Error fetching attendance report:', error);
            throw error;
        }

        return attendanceData || [];
    }

    /**
     * Get total hours per staff member in a date range
     */
    static async getStaffHoursSummary(
        tenantId: string,
        dateFrom: string,
        dateTo: string
    ): Promise<{ userId: string; userName: string; totalHours: number; shifts: number }[]> {
        const attendanceData = await this.getAttendanceReport(tenantId, dateFrom, dateTo);

        const summaryMap = new Map<string, { userId: string; userName: string; totalHours: number; shifts: number }>();

        attendanceData.forEach((record) => {
            const userId = record.staff_id; // Correct column name
            const userName = record.user?.full_name || 'Unknown Staff';

            const current = summaryMap.get(userId) || { userId, userName, totalHours: 0, shifts: 0 };

            current.shifts += 1;
            current.totalHours += record.total_hours || 0;

            summaryMap.set(userId, current);
        });

        return Array.from(summaryMap.values());
    }

    /**
     * Get sales attribution per staff member (POS Sales)
     */
    static async getSalesAttribution(
        tenantId: string,
        dateFrom: string,
        dateTo: string
    ): Promise<{ userId: string; userName: string; totalSales: number; saleCount: number }[]> {
        const supabase = await createClient();

        // Fetch sales in range
        const { data: sales, error } = await supabase
            .from('sales')
            .select('id, total_amount, cashier_id, status, created_at') // Assuming sales has cashier_id
            .eq('tenant_id', tenantId)
            .eq('status', 'completed')
            .gte('created_at', dateFrom)
            .lte('created_at', dateTo);

        if (error) {
            console.error('Error fetching sales attribution:', error);
            throw error;
        }

        // Since we need staff names, we might need a separate query or join if RLS/perf allows.
        // For now, let's fetch users to map names.
        const { data: users } = await supabase
            .from('users')
            .select('id, full_name')
            .eq('tenant_id', tenantId);

        const userMap = new Map<string, string>();
        users?.forEach(u => userMap.set(u.id, u.full_name));

        const attributionMap = new Map<string, { userId: string; userName: string; totalSales: number; saleCount: number }>();

        sales?.forEach((sale) => {
            const userId = sale.cashier_id;
            if (!userId) return; // Should not happen for POS sales

            const userName = userMap.get(userId) || 'Unknown Staff';
            const current = attributionMap.get(userId) || { userId, userName, totalSales: 0, saleCount: 0 };

            current.saleCount += 1;
            current.totalSales += sale.total_amount;

            attributionMap.set(userId, current);
        });

        return Array.from(attributionMap.values()).sort((a, b) => b.totalSales - a.totalSales);
    }
}
