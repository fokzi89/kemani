-- Fix the valid_total_hours constraint on staff_attendance
-- The previous constraint was too strict and failed due to precision issues
-- with floating point division and decimal casting.

ALTER TABLE staff_attendance 
DROP CONSTRAINT IF EXISTS valid_total_hours;

ALTER TABLE staff_attendance
ADD CONSTRAINT valid_total_hours CHECK (
    (clock_out_at IS NULL AND total_hours IS NULL) OR
    (clock_out_at IS NOT NULL AND ABS(total_hours - (EXTRACT(EPOCH FROM (clock_out_at - clock_in_at)) / 3600)) < 0.01)
);
