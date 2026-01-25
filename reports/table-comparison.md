# Database Tables Comparison Report

**Date:** 2026-01-25
**Comparison:** Supabase Database vs. Data Model Specification

---

## Summary

**Total Tables in Data Model:** 28 tables
**Tables Currently in Supabase:** 7 tables
**Missing Tables:** 21 tables
**Completion Rate:** 25%

---

## ✅ Tables Present in Supabase (7)

| # | Table Name | Status | Notes |
|---|------------|--------|-------|
| 1 | `tenants` | ✅ Partial | Simplified schema - missing many fields |
| 2 | `users` | ✅ Partial | Simplified schema - missing role, permissions, etc. |
| 3 | `products` | ✅ Partial | Some fields differ from spec |
| 4 | `sales` | ✅ Good | Most fields match spec |
| 5 | `sale_items` | ✅ Good | Matches spec well |
| 6 | `inventory_transactions` | ✅ Good | Matches spec well |
| 7 | `subscriptions` | ✅ Good | Matches spec well |

---

## ❌ Tables Missing from Supabase (21)

### Core Entities
| # | Table Name | Priority | User Story |
|---|------------|----------|------------|
| 1 | `staff_invites` | P2 | US2 - Multi-Tenant Auth |
| 2 | `branches` | P4/P11 | US4/US11 - Multi-Branch |

### Product Management
| # | Table Name | Priority | User Story |
|---|------------|----------|------------|
| 3 | `product_variants` | P1 | US1 - POS Operations |
| 4 | `product_categories` | P1 | US1 - POS Operations |

### Customer Management
| # | Table Name | Priority | User Story |
|---|------------|----------|------------|
| 5 | `customers` | P3 | US3 - Customers & Marketplace |
| 6 | `customer_addresses` | P3 | US3 - Customers & Marketplace |

### Order Management
| # | Table Name | Priority | User Story |
|---|------------|----------|------------|
| 7 | `orders` | P3 | US3 - Customers & Marketplace |
| 8 | `order_items` | P3 | US3 - Customers & Marketplace |

### Delivery Management
| # | Table Name | Priority | User Story |
|---|------------|----------|------------|
| 9 | `deliveries` | P5 | US5 - Delivery Management |
| 10 | `riders` | P5 | US5 - Delivery Management |

### Staff Management
| # | Table Name | Priority | User Story |
|---|------------|----------|------------|
| 11 | `staff_attendance` | P4 | US4 - Staff Management |

### E-Commerce Integrations
| # | Table Name | Priority | User Story |
|---|------------|----------|------------|
| 12 | `ecommerce_connections` | P6 | US6 - E-Commerce Integrations |
| 13 | `sync_logs` | P6 | US6 - E-Commerce Integrations |

### AI Chat Agent
| # | Table Name | Priority | User Story |
|---|------------|----------|------------|
| 14 | `chat_conversations` | P7 | US7 - AI Chat Agent |
| 15 | `chat_messages` | P7 | US7 - AI Chat Agent |

### WhatsApp Integration
| # | Table Name | Priority | User Story |
|---|------------|----------|------------|
| 16 | `whatsapp_messages` | P9 | US9 - WhatsApp Communication |

### Monetization
| # | Table Name | Priority | User Story |
|---|------------|----------|------------|
| 17 | `commissions` | P10 | US10 - Payments & Monetization |
| 18 | `invoices` | P10 | US10 - Payments & Monetization |

### Utility Tables
| # | Table Name | Priority | User Story |
|---|------------|----------|------------|
| 19 | `receipts` | P1 | US1 - POS Operations |
| 20 | `sync_queue` | P1 | Foundational (Offline Sync) |
| 21 | `audit_logs` | P1 | Foundational (Security) |

---

## 🔍 Schema Differences in Existing Tables

### 1. `tenants` Table

**In Supabase (Simplified):**
```typescript
{
  id: string
  name: string
  subscription_id: string | null
}
```

**In Data Model (Full):**
Should have 20+ fields including:
- business_name, business_type, subdomain
- phone_number, email, address
- logo_url, primary_color, secondary_color
- currency_code, timezone, tax_rate
- business_hours, payment_methods, delivery_zones
- subscription_status, status, onboarding_completed
- created_at, updated_at, deleted_at

**Status:** ⚠️ Major schema gap - only 3 of 20+ fields present

---

### 2. `users` Table

**In Supabase (Simplified):**
```typescript
{
  id: string
  tenant_id: string | null
  branch_id: string | null
  full_name: string | null
}
```

**In Data Model (Full):**
Should have 15+ fields including:
- phone_number, email
- role (enum), permissions (jsonb)
- employee_id, hire_date
- phone_verified, email_verified, last_login_at
- status
- created_at, updated_at, deleted_at

**Status:** ⚠️ Major schema gap - only 4 of 15+ fields present

---

### 3. `products` Table

**Differences:**
- Supabase has: `stock_quantity`, `unit_price`, `is_active`
- Data Model has: `current_stock`, `selling_price`, `cost_price`, `status`
- Missing fields: `description`, `category_id` (references product_categories), `variants`, `expiry_date`, `has_expiry`, `track_inventory`, etc.

**Status:** ⚠️ Moderate schema differences

---

## 📋 Recommended Actions

### Phase 1: Critical Missing Tables (MVP - User Story 1 & 2)
Priority: Immediate

1. **Create `product_categories`** - Required for product organization
2. **Create `receipts`** - Required for POS receipts
3. **Create `sync_queue`** - Required for offline sync
4. **Create `audit_logs`** - Required for security/compliance
5. **Enhance `tenants`** - Add all missing fields
6. **Enhance `users`** - Add role, permissions, authentication fields
7. **Create `staff_invites`** - Required for User Story 2

### Phase 2: Customer & Marketplace (User Story 3)
Priority: High

8. **Create `customers`**
9. **Create `customer_addresses`**
10. **Create `orders`**
11. **Create `order_items`**

### Phase 3: Staff Management (User Story 4)
Priority: Medium

12. **Create `staff_attendance`**
13. **Create `branches`** (or enhance existing if present)

### Phase 4: Delivery (User Story 5)
Priority: Medium

14. **Create `deliveries`**
15. **Create `riders`**

### Phase 5: Integrations (User Stories 6, 7, 9)
Priority: Lower

16. **Create `ecommerce_connections`**
17. **Create `sync_logs`**
18. **Create `chat_conversations`**
19. **Create `chat_messages`**
20. **Create `whatsapp_messages`**

### Phase 6: Monetization (User Story 10)
Priority: Lower

21. **Create `commissions`**
22. **Create `invoices`**

---

## 🛠️ Migration Strategy

### Option 1: Generate from Data Model (Recommended)
Use the complete SQL schema in `specs/001-multi-tenant-pos/contracts/supabase-schema.sql` to create all tables at once.

**Pros:**
- All tables created with correct schema
- RLS policies included
- Triggers and functions included

**Cons:**
- May conflict with existing simplified tables
- Requires backup and careful migration

### Option 2: Incremental Migration
Create missing tables one phase at a time, starting with critical MVP tables.

**Pros:**
- Less disruptive
- Can test each phase
- Existing data preserved

**Cons:**
- Slower rollout
- More migration files to manage

---

## 🚨 Critical Issues

1. **Row Level Security (RLS):** Need to verify if RLS policies are enabled on existing tables
2. **Enums:** Only 2 enums present (`plan_tier`, `subscription_status`) - many more defined in data model
3. **Indexes:** Unknown if proper indexes exist for performance
4. **Triggers:** Unknown if triggers are set up (e.g., auto-increment sale_number)
5. **Foreign Key Constraints:** Unknown if FK relationships are enforced

---

## Next Steps

1. **Backup existing database** before any schema changes
2. **Choose migration strategy** (all-at-once vs incremental)
3. **Create Supabase migrations** for missing tables
4. **Update TypeScript types** after migrations
5. **Test thoroughly** in development environment
6. **Deploy to production** with rollback plan

---

**Generated:** 2026-01-25T02:20:00Z
