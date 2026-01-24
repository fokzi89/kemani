-- ============================================
-- Migration: Seed Analytics Dimension Tables
-- Description: Populate dim_date and dim_time with data
-- Created: 2026-01-22
-- ============================================

-- ============================================
-- 1. POPULATE DIM_DATE (2020-2030)
-- ============================================

CREATE OR REPLACE FUNCTION populate_dim_date(
    p_start_date DATE DEFAULT '2020-01-01',
    p_end_date DATE DEFAULT '2030-12-31'
)
RETURNS void AS $$
DECLARE
    v_current_date DATE;
    v_date_key INTEGER;
    v_day_of_week INTEGER;
    v_is_weekend BOOLEAN;
BEGIN
    v_current_date := p_start_date;

    WHILE v_current_date <= p_end_date LOOP
        -- Calculate date key (YYYYMMDD format)
        v_date_key := TO_CHAR(v_current_date, 'YYYYMMDD')::INTEGER;

        -- Calculate day of week (1=Monday, 7=Sunday)
        v_day_of_week := EXTRACT(ISODOW FROM v_current_date);

        -- Check if weekend
        v_is_weekend := v_day_of_week IN (6, 7);

        INSERT INTO dim_date (
            date_key,
            date_value,
            day,
            day_of_week,
            day_of_week_name,
            day_of_year,
            week_of_year,
            week_start_date,
            week_end_date,
            month,
            month_name,
            month_abbr,
            month_start_date,
            month_end_date,
            quarter,
            quarter_name,
            quarter_start_date,
            quarter_end_date,
            year,
            year_start_date,
            year_end_date,
            fiscal_year,
            fiscal_quarter,
            fiscal_month,
            is_weekend,
            is_holiday,
            is_business_day,
            prior_day_key,
            prior_week_key,
            prior_month_key,
            prior_quarter_key,
            prior_year_key
        )
        VALUES (
            v_date_key,
            v_current_date,
            EXTRACT(DAY FROM v_current_date),
            v_day_of_week,
            TO_CHAR(v_current_date, 'Day'),
            EXTRACT(DOY FROM v_current_date),
            EXTRACT(WEEK FROM v_current_date),
            DATE_TRUNC('week', v_current_date)::DATE,
            (DATE_TRUNC('week', v_current_date) + INTERVAL '6 days')::DATE,
            EXTRACT(MONTH FROM v_current_date),
            TO_CHAR(v_current_date, 'Month'),
            TO_CHAR(v_current_date, 'Mon'),
            DATE_TRUNC('month', v_current_date)::DATE,
            (DATE_TRUNC('month', v_current_date) + INTERVAL '1 month' - INTERVAL '1 day')::DATE,
            EXTRACT(QUARTER FROM v_current_date),
            'Q' || EXTRACT(QUARTER FROM v_current_date),
            DATE_TRUNC('quarter', v_current_date)::DATE,
            (DATE_TRUNC('quarter', v_current_date) + INTERVAL '3 months' - INTERVAL '1 day')::DATE,
            EXTRACT(YEAR FROM v_current_date),
            DATE_TRUNC('year', v_current_date)::DATE,
            (DATE_TRUNC('year', v_current_date) + INTERVAL '1 year' - INTERVAL '1 day')::DATE,
            EXTRACT(YEAR FROM v_current_date), -- Fiscal year same as calendar year
            EXTRACT(QUARTER FROM v_current_date), -- Fiscal quarter same as calendar quarter
            EXTRACT(MONTH FROM v_current_date), -- Fiscal month same as calendar month
            v_is_weekend,
            false, -- is_holiday (populate separately)
            NOT v_is_weekend, -- is_business_day (weekdays only, adjust for holidays)
            TO_CHAR(v_current_date - INTERVAL '1 day', 'YYYYMMDD')::INTEGER,
            TO_CHAR(v_current_date - INTERVAL '7 days', 'YYYYMMDD')::INTEGER,
            TO_CHAR(v_current_date - INTERVAL '1 month', 'YYYYMMDD')::INTEGER,
            TO_CHAR(v_current_date - INTERVAL '3 months', 'YYYYMMDD')::INTEGER,
            TO_CHAR(v_current_date - INTERVAL '1 year', 'YYYYMMDD')::INTEGER
        )
        ON CONFLICT (date_key) DO NOTHING;

        v_current_date := v_current_date + INTERVAL '1 day';
    END LOOP;

    RAISE NOTICE 'Populated dim_date from % to %', p_start_date, p_end_date;
END;
$$ LANGUAGE plpgsql;

-- Execute the population
SELECT populate_dim_date('2020-01-01', '2030-12-31');

-- ============================================
-- 2. POPULATE NIGERIAN HOLIDAYS
-- ============================================

-- Function to mark holidays in dim_date
CREATE OR REPLACE FUNCTION mark_holidays()
RETURNS void AS $$
BEGIN
    -- Nigerian Public Holidays (Fixed dates)

    -- New Year's Day (January 1)
    UPDATE dim_date
    SET is_holiday = true,
        holiday_name = 'New Year''s Day',
        is_business_day = false
    WHERE month = 1 AND day = 1;

    -- Workers' Day (May 1)
    UPDATE dim_date
    SET is_holiday = true,
        holiday_name = 'Workers'' Day',
        is_business_day = false
    WHERE month = 5 AND day = 1;

    -- Democracy Day (June 12)
    UPDATE dim_date
    SET is_holiday = true,
        holiday_name = 'Democracy Day',
        is_business_day = false
    WHERE month = 6 AND day = 12;

    -- Independence Day (October 1)
    UPDATE dim_date
    SET is_holiday = true,
        holiday_name = 'Independence Day',
        is_business_day = false
    WHERE month = 10 AND day = 1;

    -- Christmas Day (December 25)
    UPDATE dim_date
    SET is_holiday = true,
        holiday_name = 'Christmas Day',
        is_business_day = false
    WHERE month = 12 AND day = 25;

    -- Boxing Day (December 26)
    UPDATE dim_date
    SET is_holiday = true,
        holiday_name = 'Boxing Day',
        is_business_day = false
    WHERE month = 12 AND day = 26;

    -- Note: Eid al-Fitr, Eid al-Adha, and Mawlid vary by lunar calendar
    -- These should be updated annually based on Islamic calendar
    -- Example for 2024:
    -- Eid al-Fitr 2024 (April 10)
    UPDATE dim_date
    SET is_holiday = true,
        holiday_name = 'Eid al-Fitr',
        is_business_day = false
    WHERE date_value = '2024-04-10';

    -- Eid al-Adha 2024 (June 16)
    UPDATE dim_date
    SET is_holiday = true,
        holiday_name = 'Eid al-Adha',
        is_business_day = false
    WHERE date_value = '2024-06-16';

    -- Mawlid 2024 (September 15)
    UPDATE dim_date
    SET is_holiday = true,
        holiday_name = 'Mawlid (Prophet''s Birthday)',
        is_business_day = false
    WHERE date_value = '2024-09-15';

    -- 2025 Islamic holidays (approximate)
    UPDATE dim_date
    SET is_holiday = true,
        holiday_name = 'Eid al-Fitr',
        is_business_day = false
    WHERE date_value = '2025-03-30';

    UPDATE dim_date
    SET is_holiday = true,
        holiday_name = 'Eid al-Adha',
        is_business_day = false
    WHERE date_value = '2025-06-06';

    UPDATE dim_date
    SET is_holiday = true,
        holiday_name = 'Mawlid (Prophet''s Birthday)',
        is_business_day = false
    WHERE date_value = '2025-09-04';

    -- 2026 Islamic holidays (approximate)
    UPDATE dim_date
    SET is_holiday = true,
        holiday_name = 'Eid al-Fitr',
        is_business_day = false
    WHERE date_value = '2026-03-20';

    UPDATE dim_date
    SET is_holiday = true,
        holiday_name = 'Eid al-Adha',
        is_business_day = false
    WHERE date_value = '2026-05-27';

    UPDATE dim_date
    SET is_holiday = true,
        holiday_name = 'Mawlid (Prophet''s Birthday)',
        is_business_day = false
    WHERE date_value = '2026-08-25';

    RAISE NOTICE 'Nigerian holidays marked in dim_date';
END;
$$ LANGUAGE plpgsql;

-- Execute the holiday marking
SELECT mark_holidays();

-- ============================================
-- 3. POPULATE DIM_TIME (24-hour, every hour)
-- ============================================

CREATE OR REPLACE FUNCTION populate_dim_time()
RETURNS void AS $$
DECLARE
    v_hour INTEGER;
    v_minute INTEGER;
    v_second INTEGER;
    v_time_key INTEGER;
    v_time_value TIME;
    v_time_period VARCHAR(20);
    v_business_hour VARCHAR(20);
    v_hour_12 INTEGER;
    v_am_pm VARCHAR(2);
    v_is_peak_hour BOOLEAN;
BEGIN
    -- Generate time entries for every hour of the day
    FOR v_hour IN 0..23 LOOP
        FOR v_minute IN 0..59 BY 15 LOOP -- 15-minute intervals
            v_second := 0;

            -- Calculate time key (HHMMSS format)
            v_time_key := (v_hour * 10000) + (v_minute * 100) + v_second;

            -- Create time value
            v_time_value := (v_hour || ':' || v_minute || ':' || v_second)::TIME;

            -- Determine time period
            v_time_period := CASE
                WHEN v_hour >= 5 AND v_hour < 12 THEN 'morning'
                WHEN v_hour >= 12 AND v_hour < 17 THEN 'afternoon'
                WHEN v_hour >= 17 AND v_hour < 21 THEN 'evening'
                ELSE 'night'
            END;

            -- Determine business hour
            v_business_hour := CASE
                WHEN v_hour < 8 THEN 'pre-open'
                WHEN v_hour >= 8 AND v_hour < 12 THEN 'business'
                WHEN v_hour >= 12 AND v_hour < 14 THEN 'lunch'
                WHEN v_hour >= 14 AND v_hour < 18 THEN 'business'
                ELSE 'post-close'
            END;

            -- 12-hour format
            v_hour_12 := CASE WHEN v_hour = 0 THEN 12
                             WHEN v_hour > 12 THEN v_hour - 12
                             ELSE v_hour
                        END;

            v_am_pm := CASE WHEN v_hour < 12 THEN 'AM' ELSE 'PM' END;

            -- Peak hours (configurable: 11am-2pm, 5pm-8pm)
            v_is_peak_hour := v_hour IN (11, 12, 13, 17, 18, 19);

            INSERT INTO dim_time (
                time_key,
                time_value,
                hour,
                hour_12,
                am_pm,
                minute,
                second,
                time_period,
                business_hour,
                hour_bucket,
                minute_bucket,
                is_peak_hour
            )
            VALUES (
                v_time_key,
                v_time_value,
                v_hour,
                v_hour_12,
                v_am_pm,
                v_minute,
                v_second,
                v_time_period,
                v_business_hour,
                v_hour,
                v_minute,
                v_is_peak_hour
            )
            ON CONFLICT (time_key) DO NOTHING;
        END LOOP;
    END LOOP;

    RAISE NOTICE 'Populated dim_time with 96 time entries (15-minute intervals)';
END;
$$ LANGUAGE plpgsql;

-- Execute the population
SELECT populate_dim_time();

-- ============================================
-- 4. HELPER VIEWS FOR EASY ACCESS
-- ============================================

-- View to get current period keys
CREATE OR REPLACE VIEW v_current_period_keys AS
SELECT
    dd_today.date_key as today_key,
    dd_yesterday.date_key as yesterday_key,
    dd_last_week.date_key as last_week_key,
    dd_last_month.date_key as last_month_key,
    dd_last_quarter.date_key as last_quarter_key,
    dd_last_year.date_key as last_year_key,
    dd_today.date_value as today,
    dd_today.week_start_date as this_week_start,
    dd_today.week_end_date as this_week_end,
    dd_today.month_start_date as this_month_start,
    dd_today.month_end_date as this_month_end,
    dd_today.quarter_start_date as this_quarter_start,
    dd_today.quarter_end_date as this_quarter_end,
    dd_today.year_start_date as this_year_start,
    dd_today.year_end_date as this_year_end
FROM dim_date dd_today
LEFT JOIN dim_date dd_yesterday ON dd_yesterday.date_key = dd_today.prior_day_key
LEFT JOIN dim_date dd_last_week ON dd_last_week.date_key = dd_today.prior_week_key
LEFT JOIN dim_date dd_last_month ON dd_last_month.date_key = dd_today.prior_month_key
LEFT JOIN dim_date dd_last_quarter ON dd_last_quarter.date_key = dd_today.prior_quarter_key
LEFT JOIN dim_date dd_last_year ON dd_last_year.date_key = dd_today.prior_year_key
WHERE dd_today.date_value = CURRENT_DATE;

-- View to easily get date ranges
CREATE OR REPLACE VIEW v_common_date_ranges AS
SELECT
    CURRENT_DATE as today,
    CURRENT_DATE - INTERVAL '1 day' as yesterday,
    DATE_TRUNC('week', CURRENT_DATE)::DATE as this_week_start,
    (DATE_TRUNC('week', CURRENT_DATE) + INTERVAL '6 days')::DATE as this_week_end,
    DATE_TRUNC('month', CURRENT_DATE)::DATE as this_month_start,
    (DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month' - INTERVAL '1 day')::DATE as this_month_end,
    DATE_TRUNC('quarter', CURRENT_DATE)::DATE as this_quarter_start,
    (DATE_TRUNC('quarter', CURRENT_DATE) + INTERVAL '3 months' - INTERVAL '1 day')::DATE as this_quarter_end,
    DATE_TRUNC('year', CURRENT_DATE)::DATE as this_year_start,
    (DATE_TRUNC('year', CURRENT_DATE) + INTERVAL '1 year' - INTERVAL '1 day')::DATE as this_year_end,
    (DATE_TRUNC('week', CURRENT_DATE) - INTERVAL '7 days')::DATE as last_week_start,
    (DATE_TRUNC('week', CURRENT_DATE) - INTERVAL '1 day')::DATE as last_week_end,
    (DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '1 month')::DATE as last_month_start,
    (DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '1 day')::DATE as last_month_end,
    (DATE_TRUNC('quarter', CURRENT_DATE) - INTERVAL '3 months')::DATE as last_quarter_start,
    (DATE_TRUNC('quarter', CURRENT_DATE) - INTERVAL '1 day')::DATE as last_quarter_end,
    (DATE_TRUNC('year', CURRENT_DATE) - INTERVAL '1 year')::DATE as last_year_start,
    (DATE_TRUNC('year', CURRENT_DATE) - INTERVAL '1 day')::DATE as last_year_end,
    CURRENT_DATE - INTERVAL '7 days' as last_7_days_start,
    CURRENT_DATE - INTERVAL '30 days' as last_30_days_start,
    CURRENT_DATE - INTERVAL '90 days' as last_90_days_start,
    CURRENT_DATE - INTERVAL '365 days' as last_365_days_start;

-- ============================================
-- 5. MAINTENANCE FUNCTIONS
-- ============================================

-- Function to extend dim_date into the future
CREATE OR REPLACE FUNCTION extend_dim_date(p_years_ahead INTEGER DEFAULT 1)
RETURNS void AS $$
DECLARE
    v_max_date DATE;
    v_new_end_date DATE;
BEGIN
    -- Get current max date in dim_date
    SELECT MAX(date_value) INTO v_max_date FROM dim_date;

    -- Calculate new end date
    v_new_end_date := v_max_date + (p_years_ahead || ' years')::INTERVAL;

    -- Populate new dates
    PERFORM populate_dim_date(v_max_date + INTERVAL '1 day', v_new_end_date);

    -- Mark holidays in new dates
    PERFORM mark_holidays();

    RAISE NOTICE 'Extended dim_date by % years to %', p_years_ahead, v_new_end_date;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 6. VERIFICATION QUERIES
-- ============================================

-- Verify dim_date population
DO $$
DECLARE
    v_count INTEGER;
    v_min_date DATE;
    v_max_date DATE;
BEGIN
    SELECT COUNT(*), MIN(date_value), MAX(date_value)
    INTO v_count, v_min_date, v_max_date
    FROM dim_date;

    RAISE NOTICE 'dim_date populated with % records from % to %', v_count, v_min_date, v_max_date;
END $$;

-- Verify dim_time population
DO $$
DECLARE
    v_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_count FROM dim_time;
    RAISE NOTICE 'dim_time populated with % records', v_count;
END $$;

-- ============================================
-- 7. COMMENTS FOR DOCUMENTATION
-- ============================================

COMMENT ON FUNCTION populate_dim_date IS 'Populates dim_date table with calendar data for a date range';
COMMENT ON FUNCTION mark_holidays IS 'Marks Nigerian public holidays in dim_date';
COMMENT ON FUNCTION populate_dim_time IS 'Populates dim_time table with 15-minute interval time data';
COMMENT ON FUNCTION extend_dim_date IS 'Extends dim_date table into the future';
COMMENT ON VIEW v_current_period_keys IS 'Helper view to get current period date keys for comparisons';
COMMENT ON VIEW v_common_date_ranges IS 'Helper view to get common date ranges (this week, last month, etc.)';
