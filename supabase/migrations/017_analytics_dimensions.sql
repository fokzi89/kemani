-- ============================================
-- Migration: Analytics Dimension Tables
-- Description: Create dim_date and dim_time for analytics
-- Created: 2026-01-23
-- ============================================

-- ============================================
-- DATE DIMENSION TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS dim_date (
    date_key INTEGER PRIMARY KEY,
    date_value DATE NOT NULL UNIQUE,

    -- Date components
    day INTEGER NOT NULL,
    day_of_week INTEGER NOT NULL,
    day_of_week_name VARCHAR(10) NOT NULL,
    day_of_year INTEGER NOT NULL,

    -- Week
    week_of_year INTEGER NOT NULL,
    week_start_date DATE NOT NULL,
    week_end_date DATE NOT NULL,

    -- Month
    month INTEGER NOT NULL,
    month_name VARCHAR(10) NOT NULL,
    month_abbr VARCHAR(3) NOT NULL,
    month_start_date DATE NOT NULL,
    month_end_date DATE NOT NULL,

    -- Quarter
    quarter INTEGER NOT NULL,
    quarter_name VARCHAR(10) NOT NULL,
    quarter_start_date DATE NOT NULL,
    quarter_end_date DATE NOT NULL,

    -- Year
    year INTEGER NOT NULL,
    year_start_date DATE NOT NULL,
    year_end_date DATE NOT NULL,

    -- Fiscal periods
    fiscal_year INTEGER,
    fiscal_quarter INTEGER,
    fiscal_month INTEGER,

    -- Business flags
    is_weekend BOOLEAN NOT NULL,
    is_holiday BOOLEAN DEFAULT false,
    holiday_name VARCHAR(100),
    is_business_day BOOLEAN NOT NULL,

    -- Prior period references
    prior_day_key INTEGER,
    prior_week_key INTEGER,
    prior_month_key INTEGER,
    prior_quarter_key INTEGER,
    prior_year_key INTEGER,

    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for dim_date
CREATE INDEX IF NOT EXISTS idx_dim_date_value ON dim_date(date_value);
CREATE INDEX IF NOT EXISTS idx_dim_date_month ON dim_date(year, month);
CREATE INDEX IF NOT EXISTS idx_dim_date_quarter ON dim_date(year, quarter);
CREATE INDEX IF NOT EXISTS idx_dim_date_year ON dim_date(year);
CREATE INDEX IF NOT EXISTS idx_dim_date_day_of_week ON dim_date(day_of_week);
CREATE INDEX IF NOT EXISTS idx_dim_date_is_business_day ON dim_date(is_business_day);
CREATE INDEX IF NOT EXISTS idx_dim_date_is_weekend ON dim_date(is_weekend);

COMMENT ON TABLE dim_date IS 'Calendar dimension for time-based analysis';
COMMENT ON COLUMN dim_date.date_key IS 'Primary key in YYYYMMDD format';
COMMENT ON COLUMN dim_date.is_business_day IS 'True if not weekend and not holiday';

-- ============================================
-- TIME DIMENSION TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS dim_time (
    time_key INTEGER PRIMARY KEY,
    time_value TIME NOT NULL UNIQUE,

    -- Time components
    hour INTEGER NOT NULL,
    hour_12 INTEGER NOT NULL,
    am_pm VARCHAR(2) NOT NULL,
    minute INTEGER NOT NULL,
    second INTEGER NOT NULL,

    -- Time periods
    time_period VARCHAR(20) NOT NULL,
    business_hour VARCHAR(20) NOT NULL,

    -- Analytics groupings
    hour_bucket INTEGER NOT NULL,
    minute_bucket INTEGER NOT NULL,

    is_peak_hour BOOLEAN DEFAULT false,

    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for dim_time
CREATE INDEX IF NOT EXISTS idx_dim_time_hour ON dim_time(hour);
CREATE INDEX IF NOT EXISTS idx_dim_time_period ON dim_time(time_period);
CREATE INDEX IF NOT EXISTS idx_dim_time_peak ON dim_time(is_peak_hour) WHERE is_peak_hour = true;

COMMENT ON TABLE dim_time IS 'Time dimension for hourly pattern analysis';
COMMENT ON COLUMN dim_time.time_key IS 'Primary key in HHMMSS format';
COMMENT ON COLUMN dim_time.time_period IS 'Time period: morning, afternoon, evening, night';
COMMENT ON COLUMN dim_time.business_hour IS 'Business hour category: pre-open, business, lunch, post-close';
