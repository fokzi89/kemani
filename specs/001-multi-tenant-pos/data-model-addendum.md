# Data Model Addendum: Extra Tables in Supabase

**Date:** 2026-01-25
**Purpose:** Document tables found in Supabase but not in original data-model.md

---

## Overview

During database analysis, **17 additional tables** were discovered in the Supabase database that are not documented in the original data-model.md specification. This addendum documents these tables.

---

## Extra Business Tables (3)

### 1. brands

**Purpose:** Product brand management

```sql
CREATE TABLE brands (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  branch_id UUID REFERENCES branches(id),

  name VARCHAR(255) NOT NULL,
  description TEXT,
  logo_url TEXT,

  -- Status
  is_active BOOLEAN DEFAULT true,

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

**RLS:** ✅ Enabled with tenant isolation

**Use Case:** Organize products by manufacturer/brand (e.g., "Panadol", "Coca-Cola", "Samsung")

**Relationships:**
- Belongs to: `tenants`, `branches`
- Referenced by: `products` (via brand_id)

---

### 2. product_price_history

**Purpose:** Track price changes over time

```sql
CREATE TABLE product_price_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  product_id UUID NOT NULL REFERENCES products(id),

  old_price DECIMAL(15, 2),
  new_price DECIMAL(15, 2) NOT NULL,

  change_reason VARCHAR(255), -- "seasonal discount", "supplier price increase", etc.
  changed_by_user_id UUID REFERENCES users(id),

  effective_date TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

**RLS:** ✅ Enabled with tenant isolation

**Use Case:**
- Audit trail for price changes
- Historical pricing analysis
- Compliance and transparency

**Relationships:**
- Belongs to: `tenants`, `products`, `users`

---

### 3. transfer_items

**Purpose:** Line items for inter-branch transfers

```sql
CREATE TABLE transfer_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  transfer_id UUID NOT NULL REFERENCES inter_branch_transfers(id),

  product_id UUID NOT NULL REFERENCES products(id),
  product_name VARCHAR(255) NOT NULL, -- snapshot
  quantity INTEGER NOT NULL,
  unit_cost DECIMAL(15, 2),

  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

**RLS:** ⚠️ Was UNRESTRICTED - now fixed with migration

**Use Case:** Detail which products and quantities are transferred between branches

**Relationships:**
- Belongs to: `inter_branch_transfers`, `products`

---

## Analytics Data Warehouse (10 tables)

A complete analytics data warehouse was implemented using star schema design with fact and dimension tables.

### Fact Tables (5)

Fact tables store measurable, quantitative data for analysis.

#### 1. fact_brand_sales

**Purpose:** Aggregate sales by brand

```sql
CREATE TABLE fact_brand_sales (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  branch_id UUID REFERENCES branches(id),
  brand_id UUID REFERENCES brands(id),

  date_key INTEGER REFERENCES dim_date(date_key),
  time_key INTEGER REFERENCES dim_time(time_key),

  -- Metrics
  total_quantity INTEGER DEFAULT 0,
  total_revenue DECIMAL(15, 2) DEFAULT 0,
  total_cost DECIMAL(15, 2) DEFAULT 0,
  total_profit DECIMAL(15, 2) DEFAULT 0,
  transaction_count INTEGER DEFAULT 0,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

**RLS:** ✅ Enabled with tenant isolation

**Use Case:** Answer questions like "Which brands generated the most revenue this month?"

---

#### 2. fact_daily_sales

**Purpose:** Daily sales summary

```sql
CREATE TABLE fact_daily_sales (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  branch_id UUID REFERENCES branches(id),

  date_key INTEGER REFERENCES dim_date(date_key),
  sale_date DATE NOT NULL,

  -- Metrics
  total_sales_count INTEGER DEFAULT 0,
  total_revenue DECIMAL(15, 2) DEFAULT 0,
  total_cost DECIMAL(15, 2) DEFAULT 0,
  total_profit DECIMAL(15, 2) DEFAULT 0,
  total_tax DECIMAL(15, 2) DEFAULT 0,
  total_discount DECIMAL(15, 2) DEFAULT 0,

  average_sale_amount DECIMAL(15, 2) DEFAULT 0,
  largest_sale_amount DECIMAL(15, 2) DEFAULT 0,

  unique_customers INTEGER DEFAULT 0,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

**RLS:** ✅ Enabled with tenant isolation

**Use Case:** Daily performance dashboards, trend analysis

---

#### 3. fact_hourly_sales

**Purpose:** Sales by hour of day (for peak hour analysis)

```sql
CREATE TABLE fact_hourly_sales (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  branch_id UUID REFERENCES branches(id),

  date_key INTEGER REFERENCES dim_date(date_key),
  time_key INTEGER REFERENCES dim_time(time_key),
  sale_hour INTEGER NOT NULL, -- 0-23

  -- Metrics
  transaction_count INTEGER DEFAULT 0,
  total_revenue DECIMAL(15, 2) DEFAULT 0,
  average_sale_amount DECIMAL(15, 2) DEFAULT 0,

  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

**RLS:** ✅ Enabled with tenant isolation

**Use Case:** Identify peak hours for staffing optimization

---

#### 4. fact_product_sales

**Purpose:** Sales performance by product

```sql
CREATE TABLE fact_product_sales (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  branch_id UUID REFERENCES branches(id),
  product_id UUID REFERENCES products(id),

  date_key INTEGER REFERENCES dim_date(date_key),

  -- Metrics
  quantity_sold INTEGER DEFAULT 0,
  total_revenue DECIMAL(15, 2) DEFAULT 0,
  total_cost DECIMAL(15, 2) DEFAULT 0,
  total_profit DECIMAL(15, 2) DEFAULT 0,

  times_sold INTEGER DEFAULT 0, -- number of transactions

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

**RLS:** ✅ Enabled with tenant isolation

**Use Case:** Identify best-selling products, slow-moving inventory

---

#### 5. fact_staff_sales

**Purpose:** Sales performance by staff member

```sql
CREATE TABLE fact_staff_sales (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  branch_id UUID REFERENCES branches(id),
  staff_id UUID REFERENCES users(id),

  date_key INTEGER REFERENCES dim_date(date_key),

  -- Metrics
  transaction_count INTEGER DEFAULT 0,
  total_revenue DECIMAL(15, 2) DEFAULT 0,
  average_sale_amount DECIMAL(15, 2) DEFAULT 0,

  largest_sale_amount DECIMAL(15, 2) DEFAULT 0,
  smallest_sale_amount DECIMAL(15, 2) DEFAULT 0,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

**RLS:** ✅ Enabled with tenant isolation

**Use Case:** Staff performance tracking, commission calculation

---

### Dimension Tables (2)

Dimension tables provide descriptive context for fact tables.

#### 6. dim_date

**Purpose:** Date dimension for time-based analysis

```sql
CREATE TABLE dim_date (
  date_key INTEGER PRIMARY KEY, -- YYYYMMDD format (e.g., 20260125)

  full_date DATE NOT NULL UNIQUE,

  -- Date parts
  year INTEGER NOT NULL,
  quarter INTEGER NOT NULL, -- 1-4
  month INTEGER NOT NULL, -- 1-12
  month_name VARCHAR(20) NOT NULL, -- "January"
  day_of_month INTEGER NOT NULL, -- 1-31
  day_of_week INTEGER NOT NULL, -- 1-7 (Monday=1)
  day_name VARCHAR(20) NOT NULL, -- "Monday"
  week_of_year INTEGER NOT NULL, -- 1-53

  -- Business calendar
  is_weekend BOOLEAN NOT NULL,
  is_holiday BOOLEAN DEFAULT false,
  holiday_name VARCHAR(100),

  -- Fiscal calendar (if different from calendar year)
  fiscal_year INTEGER,
  fiscal_quarter INTEGER,
  fiscal_month INTEGER,

  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

**RLS:** ⚠️ Was UNRESTRICTED - now fixed (shared dimension, readable by all)

**Use Case:**
- Time-based filtering and grouping
- Calendar calculations (quarter-over-quarter, year-over-year)
- Identify weekends, holidays

---

#### 7. dim_time

**Purpose:** Time of day dimension for hourly analysis

```sql
CREATE TABLE dim_time (
  time_key INTEGER PRIMARY KEY, -- HHMMSS format (e.g., 143000 for 2:30 PM)

  full_time TIME NOT NULL UNIQUE,

  -- Time parts
  hour INTEGER NOT NULL, -- 0-23
  minute INTEGER NOT NULL, -- 0-59
  second INTEGER NOT NULL, -- 0-59

  -- 12-hour format
  hour_12 INTEGER NOT NULL, -- 1-12
  am_pm VARCHAR(2) NOT NULL, -- "AM" or "PM"

  -- Time periods
  time_of_day VARCHAR(20), -- "Morning", "Afternoon", "Evening", "Night"
  business_hours BOOLEAN, -- Within operating hours

  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

**RLS:** ⚠️ Was UNRESTRICTED - now fixed (shared dimension, readable by all)

**Use Case:**
- Hour-of-day analysis
- Peak time identification
- Business hours vs off-hours comparison

---

### PostGIS Tables (3)

PostGIS extension tables for geographic/spatial data support.

#### 8. geography_columns

**Purpose:** PostGIS metadata for geography columns

**Type:** System table (PostGIS extension)

**RLS:** ✅ Enabled

**Use Case:** PostGIS internal use for geography-type columns

---

#### 9. geometry_columns

**Purpose:** PostGIS metadata for geometry columns

**Type:** System table (PostGIS extension)

**RLS:** ✅ Enabled

**Use Case:** PostGIS internal use for geometry-type columns

---

#### 10. spatial_ref_sys

**Purpose:** Spatial reference systems catalog

**Type:** System table (PostGIS extension)

**RLS:** ⚠️ Was UNRESTRICTED - now fixed (readable by all)

**Use Case:**
- Coordinate system definitions
- Map projection transformations

---

## Implementation Notes

### Analytics Data Warehouse

The analytics tables follow **star schema** design:
- **Fact tables** contain metrics (sales, revenue, profit)
- **Dimension tables** contain descriptive attributes (date, time)
- **Foreign keys** link facts to dimensions (date_key, time_key)

**ETL Process** (assumed):
- Nightly batch job aggregates sales data into fact tables
- Pre-calculated metrics for fast dashboard queries
- Reduces load on operational tables

**Benefits:**
- Fast analytics queries (pre-aggregated)
- Historical trend analysis
- Supports OLAP operations (slice, dice, drill-down)

**Data Flow:**
```
sales (OLTP) → ETL Job → fact_* tables (OLAP) → Analytics Dashboard
```

---

### PostGIS Extension

PostGIS is enabled for geographic features:
- **Geography columns:** Store delivery locations, branch locations
- **Geometry columns:** Store service areas, delivery zones
- **Spatial queries:** Calculate distances, find nearby customers

**Use Cases:**
- Delivery routing (find nearest rider to customer)
- Service area mapping (customers within 5km radius)
- Multi-location analysis (branch coverage map)

---

## Schema Alignment

### Tables Not in Original Spec

These 17 tables were added beyond the original 28-table spec:

**Business Logic (3):**
1. brands
2. product_price_history
3. transfer_items

**Analytics (10):**
4. fact_brand_sales
5. fact_daily_sales
6. fact_hourly_sales
7. fact_product_sales
8. fact_staff_sales
9. dim_date
10. dim_time

**PostGIS (3):**
11. geography_columns
12. geometry_columns
13. spatial_ref_sys

**Total Tables:** 28 (original spec) + 17 (extras) - 5 (missing) = 40 tables in Supabase

---

## Recommendations

### 1. Update Main Data Model

Incorporate these tables into `data-model.md` for complete documentation.

### 2. ETL Job Documentation

Document the analytics ETL process:
- When does it run?
- How are fact tables populated?
- What's the aggregation logic?

### 3. PostGIS Documentation

Document geographic features:
- Which columns use geography/geometry types?
- What coordinate systems are used?
- How are distances calculated?

### 4. Dimension Table Seeding

Ensure dim_date and dim_time are pre-populated:
- dim_date: 10 years of dates (past 5 + future 5)
- dim_time: All 86,400 seconds in a day (or just business hours)

---

## Next Steps

1. ✅ Document these tables (this file)
2. Merge into main data-model.md
3. Update ER diagram to include extra tables
4. Document ETL processes
5. Update TypeScript types to include all 40 tables

---

**Generated:** 2026-01-25T02:40:00Z
