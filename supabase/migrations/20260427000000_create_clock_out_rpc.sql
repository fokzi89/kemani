-- ============================================================
-- Migration 20260427000000: Create Clock Out RPC and Attendance RLS
-- ============================================================

-- RLS Policies for staff_attendance
CREATE POLICY "Staff can view own attendance" ON staff_attendance
    FOR SELECT USING (staff_id = auth.uid());

CREATE POLICY "Managers can view branch attendance" ON staff_attendance
    FOR SELECT USING (
        current_user_role() IN ('tenant_admin', 'branch_manager') AND
        tenant_id = current_tenant_id() AND 
        (current_user_role() = 'tenant_admin' OR branch_id = current_user_branch_id())
    );

CREATE POLICY "Staff can insert own attendance" ON staff_attendance
    FOR INSERT WITH CHECK (
        staff_id = auth.uid() AND
        tenant_id = current_tenant_id()
    );

CREATE POLICY "Staff can update own attendance" ON staff_attendance
    FOR UPDATE USING (
        staff_id = auth.uid()
    ) WITH CHECK (
        staff_id = auth.uid()
    );

-- Clock Out RPC
CREATE OR REPLACE FUNCTION clock_out_staff(p_attendance_id UUID)
RETURNS staff_attendance AS $$
DECLARE
    v_attendance staff_attendance;
BEGIN
    UPDATE staff_attendance
    SET 
        clock_out_at = NOW(),
        total_hours = EXTRACT(EPOCH FROM (NOW() - clock_in_at)) / 3600
    WHERE id = p_attendance_id
      AND clock_out_at IS NULL
    RETURNING * INTO v_attendance;

    RETURN v_attendance;
END;
$$ LANGUAGE plpgsql SECURITY INVOKER;
