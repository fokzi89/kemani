# Database Schema Reference

Complete reference for all database tables in the Kemani multi-platform system.

## Table of Contents

- [Multi-Tenant POS System](#multi-tenant-pos-system)
- [Healthcare Consultation System](#healthcare-consultation-system)
- [Analytics & Reporting](#analytics--reporting)
- [Row-Level Security (RLS)](#row-level-security-rls)

---

## Multi-Tenant POS System

### Core Tables

#### `tenants`
Business/tenant information for multi-tenant POS.

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `business_name` | TEXT | Business name |
| `email` | TEXT | Contact email |
| `phone` | TEXT | Contact phone |
| `country` | TEXT | Operating country |
| `plan_tier` | TEXT | Subscription tier (free, pro, enterprise) |
| `is_active` | BOOLEAN | Active status |
| `created_at` | TIMESTAMPTZ | Creation timestamp |
| `updated_at` | TIMESTAMPTZ | Last update timestamp |

**RLS:** Enabled. Users can only access their own tenant's data.

#### `users`
User accounts linked to Supabase auth.users.

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key (references auth.users) |
| `tenant_id` | UUID | References tenants(id) |
| `email` | TEXT | Email address |
| `full_name` | TEXT | Full name |
| `role` | TEXT | User role (owner, manager, staff) |
| `created_at` | TIMESTAMPTZ | Creation timestamp |

**RLS:** Enabled. Users can only see users in their tenant.

#### `staff`
Staff members per tenant.

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `tenant_id` | UUID | References tenants(id) |
| `user_id` | UUID | References users(id) |
| `position` | TEXT | Job position |
| `hourly_rate` | DECIMAL | Pay rate |
| `is_active` | BOOLEAN | Active status |

**RLS:** Enabled. Tenant scoped.

### Product Management

#### `products`
Global product catalog across all tenants.

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `name` | TEXT | Product name |
| `description` | TEXT | Product description |
| `sku` | TEXT | Stock keeping unit |
| `barcode` | TEXT | Barcode/UPC |
| `category_id` | UUID | References categories(id) |
| `brand_id` | UUID | References brands(id) |
| `unit_price` | DECIMAL | Base selling price |
| `cost_price` | DECIMAL | Base cost price |
| `tax_rate` | DECIMAL | Tax rate (%) |
| `image_url` | TEXT | Product image |
| `is_active` | BOOLEAN | Active status |
| `created_at` | TIMESTAMPTZ | Creation timestamp |

**RLS:** Read access broadly, mutation scoped.

**Indexes:**
- `idx_products_tenant_id`
- `idx_products_sku`
- `idx_products_barcode`
- `idx_products_category`

#### `brands`
Product brands.

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `tenant_id` | UUID | References tenants(id) |
| `name` | TEXT | Brand name |
| `logo_url` | TEXT | Brand logo |

**RLS:** Enabled. Tenant scoped.

#### `categories`
Product categories with hierarchy support.

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `tenant_id` | UUID | References tenants(id) |
| `name` | TEXT | Category name |
| `parent_id` | UUID | Parent category (for hierarchy) |
| `description` | TEXT | Category description |

**RLS:** Enabled. Tenant scoped.

#### `branch_inventory`
Extensive per-branch stock level and product metadata tracking.

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `tenant_id` | UUID | References tenants(id) |
| `branch_id` | UUID | References branches(id) |
| `product_id` | UUID | References products(id) |
| `stock_quantity` | INTEGER | Current stock level |
| `reserved_quantity` | INTEGER | Reserved quantity |
| `low_stock_threshold`| INTEGER | Low stock alert threshold |
| `expiry_date` | DATE | Expiry date |
| `unit_cost` | DOUBLE | Unit selling cost |
| `cost_price` | DOUBLE | Unit acquiring cost |
| `batch_no` | TEXT | Batch number |
| `barcode` | TEXT | Branch-specific barcode |
| `sku` | TEXT | Branch-specific SKU |
| `product_name` | TEXT | Denormalized product name |
| `image_url` | TEXT | Denormalized product image |
| `supplier_id` | UUID | References suppliers(id) |

**RLS:** Enabled. Tenant scoped.

#### `product_stock_balance`
Aggregated stock levels per product and branch (rollup table).

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `tenant_id` | UUID | References tenants(id) |
| `branch_id` | UUID | References branches(id) |
| `product_id` | UUID | References products(id) |
| `stock_balance` | DECIMAL | Sum of quantities from branch_inventory |
| `low_stock_threshold` | DECIMAL | Overrides product-level threshold |
| `last_updated` | TIMESTAMPTZ | Automated timestamp |

**Sync:** Kept in sync via `trg_sync_stock_balance` triggers on `branch_inventory`.

**Triggers:**
- Auto-update from branch inventory batches
- Low stock alerts 
- Sync to marketplace channels
- Auto-update on completed sales

### Sales & Transactions

#### `sales`
Transaction headers.

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `tenant_id` | UUID | References tenants(id) |
| `sale_number` | TEXT | Unique sale number |
| `customer_id` | UUID | References customers(id) (optional) |
| `staff_id` | UUID | References staff(id) |
| `subtotal` | DECIMAL | Subtotal before tax |
| `tax_amount` | DECIMAL | Total tax |
| `discount_amount` | DECIMAL | Total discount |
| `total_amount` | DECIMAL | Final amount |
| `payment_method` | TEXT | Payment type (cash, card, transfer) |
| `sale_status` | TEXT | Status (pending, completed, refunded) |
| `cash_received` | NUMERIC | Amount of cash received |
| `change_given` | NUMERIC | Amount of change given back |
| `customer_name` | TEXT | Name of the customer (optional) |
| `customer_type` | TEXT | walk-in or loyalty |
| `sales_attendant_id` | UUID | References users(id) |
| `channel` | TEXT | in-store or online |
| `sale_date` | DATE | Date of sale |
| `sale_time` | TIME | Time of sale |
| `completed_at` | TIMESTAMPTZ | Full completion timestamp |
| `notes` | TEXT | Sale notes |
| `created_at` | TIMESTAMPTZ | Sale timestamp |

**RLS:** Enabled. Tenant scoped.

**Indexes:**
- `idx_sales_tenant_id`
- `idx_sales_sale_number`
- `idx_sales_created_at`

#### `sale_items`
Transaction line items.

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `tenant_id` | UUID | References tenants(id) |
| `sale_id` | UUID | References sales(id) |
| `product_id` | UUID | References products(id) |
| `quantity` | INTEGER | Quantity sold |
| `unit_price` | DECIMAL | Price per unit |
| `discount_percent` | DECIMAL | Discount % |
| `tax_rate` | DECIMAL | Tax rate |
| `line_total` | DECIMAL | Line total |

**RLS:** Enabled. Tenant scoped.

#### `receipts`
Printable receipt records.

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `tenant_id` | UUID | References tenants(id) |
| `sale_id` | UUID | References sales(id) |
| `receipt_number` | TEXT | Receipt number |
| `receipt_data` | JSONB | Receipt content |
| `created_at` | TIMESTAMPTZ | Print timestamp |

**RLS:** Enabled. Tenant scoped.

---

## Healthcare Consultation System

### Provider Management

#### `healthcare_providers`
Medical professionals (doctors, pharmacists, specialists).

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `user_id` | UUID | References auth.users(id) |
| `full_name` | TEXT | Provider name |
| `slug` | TEXT | URL slug (unique) |
| `email` | TEXT | Contact email |
| `phone` | TEXT | Contact phone |
| `profile_photo_url` | TEXT | Profile photo |
| `type` | TEXT | Provider type (doctor, pharmacist, diagnostician, specialist) |
| `specialization` | TEXT | Medical specialization |
| `credentials` | TEXT | Credentials (e.g., "MD, MBBS") |
| `license_number` | TEXT | Medical license number |
| `years_of_experience` | INTEGER | Years practicing |
| `bio` | TEXT | Professional bio |
| `country` | TEXT | Operating country |
| `region` | TEXT | Region/state |
| `clinic_address` | JSONB | Clinic location {street, city, postal_code, lat, lng} |
| `consultation_types` | TEXT[] | Available types ['chat', 'video', 'audio', 'office_visit'] |
| `fees` | JSONB | Pricing {chat: 5000, video: 10000, ...} |
| `average_rating` | DECIMAL(3,2) | Average rating (0.00-5.00) |
| `total_consultations` | INTEGER | Total consultations completed |
| `total_reviews` | INTEGER | Total reviews received |
| `plan_tier` | TEXT | Subscription tier (free, pro, enterprise_custom) |
| `custom_domain` | TEXT | Custom domain (enterprise) |
| `clinic_settings` | JSONB | Branding {clinic_name, logo_url, colors, ...} |
| `is_verified` | BOOLEAN | Verified status |
| `is_active` | BOOLEAN | Active status |
| `verified_at` | TIMESTAMPTZ | Verification date |
| `created_at` | TIMESTAMPTZ | Registration date |
| `updated_at` | TIMESTAMPTZ | Last update |

**RLS:**
- Public read for active/verified providers
- Providers can update their own profile

**Indexes:**
- `idx_providers_country_specialization`
- `idx_providers_region`
- `idx_providers_rating`
- `idx_providers_slug`
- `idx_providers_user_id`

### Patient Management

#### `patients`
Patient records.

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `user_id` | UUID | References auth.users(id) |
| `full_name` | TEXT | Patient name |
| `email` | TEXT | Contact email |
| `phone` | TEXT | Contact phone |
| `date_of_birth` | DATE | Birth date |
| `gender` | TEXT | Gender |
| `blood_type` | TEXT | Blood type |
| `allergies` | TEXT[] | Known allergies |
| `country` | TEXT | Country |
| `emergency_contact` | JSONB | Emergency contact {name, phone, relationship} |
| `created_at` | TIMESTAMPTZ | Registration date |
| `updated_at` | TIMESTAMPTZ | Last update |

**RLS:** Patients can only view/edit their own records.

### Consultations

#### `consultations`
Consultation sessions.

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `patient_id` | UUID | References patients(id) |
| `provider_id` | UUID | References healthcare_providers(id) |
| `consultation_type` | TEXT | Type (chat, video, audio, office_visit) |
| `scheduled_at` | TIMESTAMPTZ | Scheduled time |
| `started_at` | TIMESTAMPTZ | Actual start time |
| `ended_at` | TIMESTAMPTZ | Actual end time |
| `status` | TEXT | Status (scheduled, in_progress, completed, cancelled) |
| `fee_amount` | DECIMAL | Consultation fee |
| `payment_status` | TEXT | Payment status (pending, paid, refunded) |
| `payment_reference` | TEXT | Payment reference |
| `referral_code` | TEXT | Referral code used (for commission) |
| `symptoms` | TEXT | Patient-reported symptoms |
| `diagnosis` | TEXT | Provider diagnosis |
| `created_at` | TIMESTAMPTZ | Booking date |
| `updated_at` | TIMESTAMPTZ | Last update |

**RLS:**
- Patients can view their own consultations
- Providers can view consultations where they're the provider

**Indexes:**
- `idx_consultations_patient_id`
- `idx_consultations_provider_id`
- `idx_consultations_scheduled_at`
- `idx_consultations_status`

#### `consultation_notes`
Provider notes for consultations.

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `consultation_id` | UUID | References consultations(id) |
| `provider_id` | UUID | References healthcare_providers(id) |
| `note_type` | TEXT | Type (diagnosis, prescription, lab_order, referral) |
| `content` | TEXT | Note content |
| `created_at` | TIMESTAMPTZ | Creation date |

**RLS:** Only the consultation provider can add/view notes.

#### `appointments`
Scheduled appointments.

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `patient_id` | UUID | References patients(id) |
| `provider_id` | UUID | References healthcare_providers(id) |
| `time_slot_id` | UUID | References provider_time_slots(id) |
| `scheduled_at` | TIMESTAMPTZ | Appointment time |
| `consultation_type` | TEXT | Type (chat, video, audio, office_visit) |
| `status` | TEXT | Status (scheduled, confirmed, cancelled, completed) |
| `created_at` | TIMESTAMPTZ | Booking date |

**RLS:** Scoped to patient and provider.

### Scheduling

#### `provider_availability_templates`
Recurring availability schedules.

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `provider_id` | UUID | References healthcare_providers(id) |
| `day_of_week` | INTEGER | Day (0=Sunday, 6=Saturday) |
| `start_time` | TIME | Start time |
| `end_time` | TIME | End time |
| `slot_duration_minutes` | INTEGER | Slot length |
| `is_active` | BOOLEAN | Active status |

**RLS:** Providers manage their own templates.

#### `provider_time_slots`
Bookable time slots.

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `provider_id` | UUID | References healthcare_providers(id) |
| `start_time` | TIMESTAMPTZ | Slot start |
| `end_time` | TIMESTAMPTZ | Slot end |
| `is_booked` | BOOLEAN | Booking status |
| `version` | INTEGER | Optimistic locking version |

**RLS:** Public read. Provider update.

**Optimistic Locking:** Prevents double-booking.

### Health Records

#### `patient_health_records`
Patient health history.

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `patient_id` | UUID | References patients(id) |
| `consultation_id` | UUID | References consultations(id) (optional) |
| `record_type` | TEXT | Type (vital_signs, lab_result, imaging, prescription) |
| `record_data` | JSONB | Record details |
| `recorded_at` | TIMESTAMPTZ | Record date |
| `created_at` | TIMESTAMPTZ | Creation date |

**RLS:** Patient and their providers can access.

---

## Analytics & Reporting

### Dimension Tables

- `dim_date` - Date dimensions for time-series analysis
- `dim_product` - Product dimensions
- `dim_customer` - Customer dimensions
- `dim_staff` - Staff dimensions

### Fact Tables

- `fact_sales` - Sales transactions for analytics
- `fact_inventory` - Inventory snapshots
- `fact_performance` - Staff performance metrics

**Note:** Analytics tables are populated via ETL functions that run periodically.

---

## Row-Level Security (RLS)

### Multi-Tenant POS

All POS tables have RLS policies that enforce tenant isolation:

```sql
-- Example policy for products table
CREATE POLICY "Users can only view their tenant's products"
  ON products FOR SELECT
  USING (tenant_id = (SELECT raw_user_meta_data->>'tenant_id' FROM auth.users WHERE id = auth.uid())::uuid);
```

### Healthcare System

Healthcare tables have privacy-focused RLS:

```sql
-- Patients can view their own consultations
CREATE POLICY "Patients can view own consultations"
  ON consultations FOR SELECT
  USING (patient_id = (SELECT id FROM patients WHERE user_id = auth.uid()));

-- Providers can view consultations where they're the provider
CREATE POLICY "Providers can view their consultations"
  ON consultations FOR SELECT
  USING (provider_id = (SELECT id FROM healthcare_providers WHERE user_id = auth.uid()));
```

### Helper Functions

Several helper functions assist with RLS:

- `auth.tenant_id()` - Get current user's tenant ID
- `auth.user_role()` - Get current user's role
- Custom functions for complex authorization logic

---

## Database Indexes

### Performance Indexes

All tables have appropriate indexes on:
- Primary keys (auto-indexed)
- Foreign keys
- Frequently queried columns (tenant_id, created_at, status)
- Composite indexes for common query patterns

**Total Indexes:** 35+ performance indexes

### Partitioning

Analytics tables use partitioning for improved query performance:
- Partitioned by date (monthly/yearly)
- Automatic partition creation via triggers

---

## Triggers

### Automated Triggers

1. **Inventory Updates** - Auto-decrement on sale
2. **Timestamp Updates** - Auto-update `updated_at` fields
3. **Denormalization** - Update aggregate fields (ratings, counts)
4. **Analytics ETL** - Populate fact tables
5. **Audit Logging** - Track changes for compliance

---

## Best Practices

### When Querying

1. **Always filter by tenant_id first** for POS tables
2. **Use indexes** - Check EXPLAIN ANALYZE for query plans
3. **Limit results** - Use pagination for large datasets
4. **Use prepared statements** - Prevent SQL injection

### When Inserting

1. **Include tenant_id** for all POS records
2. **Validate foreign keys** before insert
3. **Use transactions** for multi-table operations
4. **Check RLS policies** - Ensure user has permission

### Security

1. **Never use service_role key in client code**
2. **Always use anon key for client apps**
3. **Trust RLS policies** - Don't rely on client-side filtering
4. **Validate user permissions** before sensitive operations

---

## Migration Files

Migrations are located in `supabase/migrations/` and should be applied in order:

1. Extensions & Enums
2. Core Tables
3. Product/Inventory Tables
4. Sales Tables
5. Indexes
6. RLS Policies
7. Triggers
8. Analytics Schema
9. Healthcare Tables (latest)
10. Tenant-scoped Products (latest)

See [SUPABASE_SETUP.md](./SUPABASE_SETUP.md) for detailed migration instructions.

---

## Additional Resources

- [Supabase RLS Documentation](https://supabase.com/docs/guides/auth/row-level-security)
- [PostgreSQL Indexes](https://www.postgresql.org/docs/current/indexes.html)
- [Database Partitioning](https://www.postgresql.org/docs/current/ddl-partitioning.html)
