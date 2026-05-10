-- Migration to track overtime/extra hours in staff_attendance

-- 1. Add overtime_minutes column
ALTER TABLE staff_attendance 
ADD COLUMN IF NOT EXISTS overtime_minutes INTEGER DEFAULT 0;

-- 2. Update the clock_out_staff function to calculate overtime
CREATE OR REPLACE FUNCTION clock_out_staff(p_attendance_id UUID)
RETURNS staff_attendance AS $$
DECLARE
    v_attendance staff_attendance;
    v_shift branch_shifts;
    v_shift_start TIMESTAMPTZ;
    v_shift_end TIMESTAMPTZ;
    v_overtime_sec FLOAT := 0;
BEGIN
    -- Update clock out time and total hours first
    UPDATE staff_attendance
    SET 
        clock_out_at = NOW(),
        total_hours = ROUND((EXTRACT(EPOCH FROM (NOW() - clock_in_at)) / 3600)::numeric, 2),
        updated_at = NOW()
    WHERE id = p_attendance_id
      AND clock_out_at IS NULL
    RETURNING * INTO v_attendance;

    IF v_attendance.id IS NULL THEN
        RETURN NULL;
    END IF;

    -- Calculate overtime if shift is assigned
    IF v_attendance.shift_id IS NOT NULL THEN
        SELECT * INTO v_shift FROM branch_shifts WHERE id = v_attendance.shift_id;
        
        IF FOUND THEN
            -- Construct shift start and end timestamps using shift_date
            -- We assume the shift starts on the shift_date
            v_shift_start := (v_attendance.shift_date::text || ' ' || v_shift.start_time::text)::TIMESTAMPTZ;
            v_shift_end := (v_attendance.shift_date::text || ' ' || v_shift.end_time::text)::TIMESTAMPTZ;
            
            -- Handle night shifts (spanning across midnight)
            IF v_shift.end_time < v_shift.start_time THEN
                v_shift_end := v_shift_end + INTERVAL '1 day';
            END IF;
            
            -- 1. Time worked before shift start
            IF v_attendance.clock_in_at < v_shift_start THEN
                v_overtime_sec := v_overtime_sec + EXTRACT(EPOCH FROM (v_shift_start - v_attendance.clock_in_at));
            END IF;
            
            -- 2. Time worked after shift end
            IF v_attendance.clock_out_at > v_shift_end THEN
                v_overtime_sec := v_overtime_sec + EXTRACT(EPOCH FROM (v_attendance.clock_out_at - v_shift_end));
            END IF;
            
            -- Update the record with calculated overtime
            UPDATE staff_attendance 
            SET overtime_minutes = ROUND(v_overtime_sec / 60)
            WHERE id = v_attendance.id;
            
            -- Refresh v_attendance to return updated values
            SELECT * INTO v_attendance FROM staff_attendance WHERE id = v_attendance.id;
        END IF;
    END IF;

    RETURN v_attendance;
END;
$$ LANGUAGE plpgsql SECURITY INVOKER;
