-- ============================================================
-- Migration 20260427000001: Create Branch Shifts and Update Attendance
-- ============================================================

CREATE TABLE branch_shifts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
    shift_name VARCHAR(255) NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    grace_period_minutes INTEGER DEFAULT 0 CHECK (grace_period_minutes >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT valid_shift_times CHECK (start_time != end_time)
);

-- RLS policies for branch_shifts
ALTER TABLE branch_shifts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Staff can view branch shifts" ON branch_shifts
    FOR SELECT USING (tenant_id = current_tenant_id());

CREATE POLICY "Managers can manage branch shifts" ON branch_shifts
    FOR ALL USING (
        current_user_role() IN ('tenant_admin', 'branch_manager') AND
        tenant_id = current_tenant_id()
    );

-- Alter staff_attendance
ALTER TABLE staff_attendance
ADD COLUMN IF NOT EXISTS shift_id UUID REFERENCES branch_shifts(id) ON DELETE SET NULL,
ADD COLUMN IF NOT EXISTS shift_status VARCHAR(50) DEFAULT 'on_time' CHECK (shift_status IN ('on_time', 'late', 'out_of_schedule'));

-- Update trigger for updated_at
CREATE TRIGGER set_updated_at BEFORE UPDATE ON branch_shifts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
