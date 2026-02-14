# Tasks: Multi-Tenant POS-First Super App Platform

**Feature Branch**: `001-multi-tenant-pos`
**Input**: Design documents from `/specs/001-multi-tenant-pos/`
**Prerequisites**: ✅ plan.md, ✅ spec.md, ✅ research.md, ✅ data-model.md, ✅ contracts/

**Tests**: Tests are OPTIONAL - tasks below do NOT include test tasks since tests were not explicitly requested in the specification.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `- [ ] [ID] [P?] [Story?] Description with file path`

- **Checkbox**: `- [ ]` for pending, `- [x]` for completed
- **ID**: Sequential task number (T001, T002, T003...)
- **[P]**: Parallelizable task (different files, no dependencies)
- **[Story]**: User story label (US1, US2, etc.) - only for user story phases
- **File paths**: Absolute paths using Windows format

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure - no dependencies

- [x] T001 Verify Next.js 16 project structure matches plan.md (app router, TypeScript strict mode)
- [x] T002 [P] Install core dependencies: PowerSync SDK, wa-sqlite, Termii SDK, Paystack SDK
- [x] T003 [P] Install UI dependencies: shadcn/ui CLI, Radix UI primitives, Lucide icons
- [x] T004 [P] Configure next-pwa in next.config.ts with Workbox caching strategies
- [x] T005 [P] Create PWA manifest in public/manifest.json with app icons and metadata
- [x] T006 [P] Setup environment variables in .env.example (Supabase, PowerSync, Termii, Paystack)
- [x] T007 Create project folder structure: lib/supabase, lib/offline, lib/auth, lib/pos, lib/integrations, lib/utils, tests/

**Checkpoint**: ✅ Basic project structure ready

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

### Database & Supabase Setup

- [x] T008 Setup Supabase project and configure connection in lib/supabase/client.ts
- [x] T009 Create Supabase database schema using contracts/supabase-schema.sql (19 tables, RLS policies, triggers)
- [ ] T010 Generate TypeScript types from Supabase schema using supabase gen types (User needs to run this manually: npx supabase login)
- [x] T011 [P] Create RLS helper functions: current_tenant_id(), current_user_role(), current_user_branch_id() in Supabase
- [x] T012 [P] Enable Row Level Security on all tenant-scoped tables in Supabase
- [x] T013 Create database migration system using Supabase migrations

### Offline Sync Infrastructure

- [x] T014 Setup PowerSync account and configure sync rules for tenant/branch filtering
- [x] T015 Integrate wa-sqlite with IndexedDB-batch VFS in lib/offline/sqlite-adapter.ts
- [x] T016 Configure PowerSync SDK in lib/offline/sync-engine.ts with Supabase connection
- [x] T017 Implement sync status tracking in lib/offline/sync-engine.ts (online/offline/syncing states)
- [x] T018 Create sync metadata schema (_sync_version, _sync_modified_at, _sync_client_id) in local SQLite
- [x] T019 Implement conflict resolution using PowerSync CRDT for inventory operations in lib/offline/conflict-resolver.ts
- [x] T020 Create offline transaction queue manager in lib/offline/queue-manager.ts

### Authentication Framework

- [x] T021 Integrate Termii SDK for SMS OTP delivery in lib/auth/otp.ts
- [x] T022 [P] Configure Supabase Auth for email OTP in lib/supabase/client.ts
- [x] T023 Create OTP generation and validation logic in lib/auth/otp.ts (6-digit code, 5-minute expiration)
- [x] T024 Implement session management in lib/auth/session.ts with tenant/branch context
- [x] T025 Create authentication middleware for Next.js API routes in app/api/middleware.ts

### UI Foundation

- [x] T026 Initialize shadcn/ui with `npx shadcn@latest init` and configure components.json
- [x] T027 [P] Add core shadcn/ui components: Button, Input, Label, Form, Card, Table, Dialog, Sheet, Toast, Badge
- [x] T028 [P] Create global styles in app/globals.css with Tailwind CSS 4 variables for theming
- [x] T029 [P] Create reusable layout components in app/components/layout/ (Header, Sidebar, Footer)
- [x] T030 Create offline status indicator component in app/components/offline/SyncStatus.tsx

### Payment Integration

- [x] T031 Integrate Paystack SDK in lib/integrations/paystack.ts with API keys from environment
- [x] T032 [P] Integrate Flutterwave SDK in lib/integrations/flutterwave.ts as fallback
- [x] T033 Create payment abstraction layer in lib/integrations/payment-provider.ts (primary/fallback pattern)
- [x] T034 Implement webhook handler for Paystack at app/api/webhooks/paystack/route.ts with signature verification
- [x] T035 [P] Implement webhook handler for Flutterwave at app/api/webhooks/flutterwave/route.ts

### Utilities & Helpers

- [x] T036 [P] Create Zod validation schemas in lib/utils/validation.ts for all entities
- [x] T037 [P] Create currency formatting utilities in lib/utils/formatting.ts (Naira, dates, phone numbers)
- [x] T038 [P] Create distance calculation utility in lib/utils/distance.ts for delivery threshold (25km)
- [x] T039 Create error handling utilities in lib/utils/errors.ts
- [x] T040 Setup logging infrastructure in lib/utils/logger.ts

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Offline-First POS Operations (Priority: P1) 🎯 MVP

**Goal**: Cashiers can process sales, manage inventory, apply discounts, and generate receipts offline. System syncs to cloud automatically when internet is available.

**Independent Test**: Simulate offline environment, process multiple sales with various products and payment methods, verify local storage persistence, reconnect to internet, confirm automatic sync to Supabase.

### Models for US1

- [x] T041 [P] [US1] Create Product model with sync metadata in lib/types/pos.ts
- [x] T042 [P] [US1] Create Sale model with SaleItem relationship in lib/types/pos.ts
- [x] T043 [P] [US1] Create InventoryTransaction model in lib/types/pos.ts
- [x] T044 [P] [US1] Create Receipt model in lib/types/pos.ts

### Services for US1

- [x] T045 [US1] Implement product management service in lib/pos/product.ts (create, update, search, bulk CSV import)
- [x] T046 [US1] Implement inventory service in lib/pos/inventory.ts (stock updates, expiry alerts, low stock alerts)
- [x] T047 [US1] Implement sales transaction service in lib/pos/transaction.ts (create sale, calculate totals, process payment)
- [x] T048 [US1] Implement tax calculation service in lib/pos/tax-calculator.ts (configurable tax rates per tenant)
- [x] T049 [US1] Implement receipt generation service in lib/pos/receipt.ts (digital and printable formats with tenant branding)

### API Endpoints for US1

- [x] T050 [P] [US1] Create product endpoints in app/api/products/route.ts (GET, POST, PUT, DELETE)
- [x] T051 [P] [US1] Create product bulk import endpoint in app/api/products/import/route.ts (CSV upload)
- [x] T052 [P] [US1] Create sales endpoints in app/api/sales/route.ts (GET, POST with offline sync support)
- [x] T053 [P] [US1] Create inventory endpoints in app/api/inventory/route.ts (GET stock levels, POST adjustments)
- [x] T054 [P] [US1] Create receipt endpoint in app/api/receipts/[saleId]/route.ts (GET receipt by sale ID)

### UI Components for US1

- [x] T055 [US1] Create POS cart component in app/components/pos/Cart.tsx with product selection and quantity
- [x] T056 [US1] Create product selector component in app/components/pos/ProductSelector.tsx with search and barcode scan
- [x] T057 [US1] Create payment method selector in app/components/pos/PaymentMethod.tsx (cash, card, transfer, mobile money)
- [x] T058 [US1] Create discount/tax calculator UI in app/components/pos/DiscountTax.tsx
- [x] T059 [US1] Create receipt preview component in app/components/pos/ReceiptPreview.tsx
- [x] T060 [US1] Create inventory management UI in app/(pos)/inventory/page.tsx with product CRUD
- [x] T061 [US1] Create CSV import UI in app/(pos)/inventory/import/page.tsx with drag-drop upload
- [x] T062 [US1] Create expiry alerts dashboard in app/(pos)/inventory/expiry/page.tsx (products expiring within 30 days)
- [x] T063 [US1] Create POS sales screen in app/(pos)/sales/page.tsx integrating cart, product selector, payment
- [x] T064 [US1] Implement offline sync queue UI in app/components/offline/SyncQueue.tsx showing pending transactions

### Integration for US1

- [x] T065 [US1] Connect POS UI to SQLite for offline product catalog access
- [x] T066 [US1] Implement automatic sync trigger when internet connection restored
- [x] T067 [US1] Add void/refund functionality to sales transactions in lib/pos/transaction.ts
- [x] T068 [US1] Test offline sale creation, inventory deduction, and cloud sync with PowerSync

**Checkpoint**: User Story 1 should be fully functional and testable independently (complete MVP!)

---

## Phase 4: User Story 2 - Multi-Tenant Authentication and Onboarding (Priority: P2)

**Goal**: Business owners register using email/password or Google Sign-In, complete guided onboarding (profile setup + company setup), and invite staff via email with role assignments. Each tenant operates with complete data isolation and role-based access.

**Independent Test**: Register new owner with email/password, complete profile setup (photo, name, gender, phone), complete company setup (business details, location, logo), verify navigation to dashboard, invite staff with roles, confirm data isolation.

### Models for US2

- [x] T069 [P] [US2] Create Tenant model in lib/types/database.ts
- [x] T070 [P] [US2] Create User model with role enum in lib/types/database.ts
- [x] T071 [P] [US2] Create Branch model in lib/types/database.ts
- [x] T071a [P] [US2] Create StaffInvitation model in lib/types/database.ts (id, tenant_id, email, full_name, role, branch_id, invitation_token, status, expires_at)
- [ ] T071b [P] [US2] Add profile fields to User model (profile_picture_url, gender, onboarding_completed_at)
- [ ] T071c [P] [US2] Add company fields to Tenant model (business_type enum, address, country, city, office_address, latitude, longitude, logo_url)
- [x] T071d [P] [US2] Add passcode_hash field to User model for passcode/biometric authentication

### Services for US2

- [x] T072 [US2] Implement tenant registration service in lib/auth/tenant.ts (create tenant, assign admin)
- [x] T073 [US2] Implement user management service in lib/auth/user.ts (create staff, assign roles, permissions)
- [x] T074 [US2] Implement tenant branding service in lib/auth/branding.ts (logo upload, color customization)
- [ ] T074a [US2] Implement onboarding service in lib/auth/onboarding.ts (save profile step, save company step, mark onboarding complete)
- [ ] T074b [US2] Implement geocoding service in lib/utils/geocoding.ts (get lat/long from address using Google Maps API or alternative)
- [x] T074c [US2] Implement staff invitation service in lib/auth/invitation.ts (create invitation, send email, verify token, accept invitation)
- [ ] T074d [US2] Implement passcode service in lib/auth/passcode.ts (hash passcode, verify passcode, check biometric support)

### API Endpoints for US2

- [ ] T075 [P] [US2] Create registration endpoint in app/api/auth/register/route.ts (email/password signup)
- [ ] T075a [P] [US2] Configure Google OAuth provider in Supabase Auth dashboard
- [ ] T076 [P] [US2] Create login endpoint in app/api/auth/login/route.ts (email/password login)
- [x] T077 [US2] Create tenant endpoints in app/api/tenants/route.ts (GET tenant, PUT update tenant with company info)
- [x] T078 [US2] Create staff management endpoints in app/api/staff/route.ts (GET, POST, PUT staff)
- [x] T079 [US2] Create branding endpoint in app/api/tenants/branding/route.ts (PUT logo, colors)
- [ ] T079a [P] [US2] Create onboarding endpoints in app/api/onboarding/profile/route.ts (POST profile step)
- [ ] T079b [P] [US2] Create company setup endpoint in app/api/onboarding/company/route.ts (POST company step, create tenant + branch)
- [x] T079c [P] [US2] Create staff invitation endpoints in app/api/staff/invite/route.ts (POST create invitation, GET list invitations, PUT resend/revoke)
- [ ] T079d [P] [US2] Update invitation acceptance endpoint in app/api/staff/invite/accept/route.ts (create account, redirect to staff onboarding)
- [ ] T079e [P] [US2] Create passcode setup endpoint in app/api/auth/setup-passcode/route.ts (POST hash and save passcode)
- [ ] T079f [P] [US2] Create passcode verification endpoint in app/api/auth/verify-passcode/route.ts (POST verify passcode during login)
- [ ] T079g [P] [US2] Create staff profile endpoint in app/api/onboarding/staff/profile/route.ts (POST save staff profile during onboarding)

### UI Components for US2

- [ ] T080 [US2] Create registration page in app/(auth)/register/page.tsx (email, password, confirm password, Google Sign-In button)
- [ ] T081 [US2] Create login page in app/(auth)/login/page.tsx (email/password fields, Google Sign-In button)
- [ ] T082 [US2] Create onboarding layout in app/(onboarding)/layout.tsx (progress indicator, step navigation)
- [ ] T083 [US2] Create profile setup page in app/(onboarding)/profile/page.tsx (profile pic upload, full name, gender dropdown, phone number)
- [ ] T084 [US2] Create company setup page in app/(onboarding)/company/page.tsx (company name, business type dropdown, address fields, country select, logo upload)
- [x] T085 [US2] Create staff management UI in app/(admin)/staff/page.tsx (staff list, invite modal with email/role/branch)
- [x] T086 [US2] Create branding configuration UI in app/(admin)/settings/branding/page.tsx (logo upload, brand colors)
- [x] T087 [US2] Create role selector component in app/components/admin/RoleSelector.tsx
- [x] T088 [US2] Create branch selector component in app/components/admin/BranchSelector.tsx
- [ ] T089 [US2] Update invitation acceptance page in app/accept-invitation/[token]/page.tsx (password setup form, redirect to staff profile)
- [ ] T089a [P] [US2] Create business type dropdown component in app/components/onboarding/BusinessTypeSelect.tsx
- [ ] T089b [P] [US2] Create country selector component in app/components/onboarding/CountrySelect.tsx (alphabetical list)
- [ ] T089c [P] [US2] Create gender selector component in app/components/onboarding/GenderSelect.tsx (Male/Female)
- [ ] T089d [P] [US2] Create profile picture upload component in app/components/onboarding/ProfilePictureUpload.tsx
- [ ] T089e [US2] Create staff profile setup page in app/(onboarding)/staff/profile/page.tsx (full name, profile pic, phone number)
- [x] T089f [US2] Create passcode setup page in app/(onboarding)/setup-passcode/page.tsx (6-digit PIN or biometric)
- [ ] T089g [US2] Create verify passcode page in app/(auth)/verify-passcode/page.tsx (passcode entry after login)
- [ ] T089h [P] [US2] Create inactivity lock component in app/components/auth/InactivityLock.tsx (lock screen after 10 min idle)

### Integration for US2

- [ ] T090 [US2] Configure Supabase Auth with email/password provider and Google OAuth provider
- [ ] T091 [US2] Implement auth state management with multi-step redirect logic:
  - Unauthenticated → login
  - Authenticated without onboarding_completed_at → onboarding (owner or staff profile)
  - Authenticated with onboarding but no passcode_hash → passcode setup
  - Authenticated with onboarding and passcode → verify passcode → dashboard
- [ ] T092 [US2] Integrate geocoding API to auto-populate latitude/longitude from address in company setup
- [ ] T093 [US2] Implement image upload to Supabase Storage for profile pictures and company logos
- [x] T094 [US2] Implement email sending service for staff invitations (using Resend or Supabase built-in)
- [ ] T095 [US2] Create database migration for new fields (profile_picture_url, gender, business_type, address, latitude, longitude, etc.)
- [x] T095a [US2] Create database migration for passcode_hash field in users table
- [ ] T096 [US2] Implement RLS policy enforcement at API layer (verify tenant_id matches auth user)
- [ ] T097 [US2] Implement inactivity detection (10 minutes idle → lock screen requiring passcode)
- [ ] T098 [US2] Implement WebAuthn biometric authentication (fingerprint/face recognition) as passcode alternative
- [ ] T099 [US2] Test complete owner registration flow (signup → profile → company → passcode → dashboard)
- [ ] T100 [US2] Test complete staff invitation flow (invite → email → accept → password → profile → passcode → dashboard)
- [ ] T101 [US2] Test staff login flow (email/password → passcode verification → dashboard)
- [ ] T102 [US2] Test inactivity lock and re-authentication flow
- [ ] T103 [US2] Test cross-tenant data isolation (tenant A cannot access tenant B data)
- [ ] T104 [US2] Test role-based permissions (Branch Manager vs Cashier/Staff vs Delivery Rider)
- [ ] T105 [US2] Test Google OAuth registration and login flow
- [ ] T106 [US2] Test biometric authentication setup and verification

**Checkpoint**: Multi-tenant authentication, onboarding, and staff invitation system should be fully functional

---

## Phase 5: User Story 3 - Customer Management and Marketplace Storefront (Priority: P3)

**Goal**: Business creates digital storefront accessible to nearby customers. Customers browse products, place orders for delivery or pickup, view purchase history, and earn loyalty points.

**Independent Test**: Create tenant storefront, publish products, have test customer browse and place order, process order, verify customer profile shows purchase history and loyalty points.

### Models for US3

- [ ] T091 [P] [US3] Create Customer model with loyalty points in lib/types/database.ts
- [ ] T092 [P] [US3] Create CustomerAddress model in lib/types/database.ts
- [ ] T093 [P] [US3] Create Order model with OrderItem relationship in lib/types/database.ts

### Services for US3

- [ ] T094 [US3] Implement customer management service in lib/pos/customer.ts (create, update, search customers)
- [ ] T095 [US3] Implement loyalty points service in lib/pos/loyalty.ts (calculate points: 1 per ₦100 spent)
- [ ] T096 [US3] Implement order management service in lib/pos/order.ts (create, update status, fulfillment)
- [ ] T097 [US3] Implement marketplace service in lib/pos/marketplace.ts (publish products, storefront generation)

### API Endpoints for US3

- [ ] T098 [P] [US3] Create customer endpoints in app/api/customers/route.ts (GET, POST, PUT customer profiles)
- [ ] T099 [P] [US3] Create order endpoints in app/api/orders/route.ts (GET, POST, PUT orders)
- [ ] T100 [P] [US3] Create marketplace storefront endpoint in app/api/marketplace/[tenantId]/products/route.ts (public product listing)
- [ ] T101 [P] [US3] Create customer authentication endpoint in app/api/customers/auth/route.ts (phone/email OTP for customers)

### UI Components for US3

- [ ] T102 [US3] Create customer management UI in app/(pos)/customers/page.tsx (customer list, details, history)
- [ ] T103 [US3] Create order management UI in app/(pos)/orders/page.tsx (order list, status updates)
- [ ] T104 [US3] Create marketplace storefront in app/(marketplace)/[tenantId]/page.tsx (customer-facing product browse)
- [ ] T105 [US3] Create product detail page in app/(marketplace)/[tenantId]/products/[productId]/page.tsx
- [ ] T106 [US3] Create shopping cart in app/(marketplace)/[tenantId]/cart/page.tsx
- [ ] T107 [US3] Create order tracking page in app/(marketplace)/track/[orderId]/page.tsx (public, no auth)
- [ ] T108 [US3] Create customer profile page in app/(marketplace)/[tenantId]/profile/page.tsx (purchase history, loyalty points)

### Integration for US3

- [ ] T109 [US3] Integrate loyalty points auto-calculation on sale completion (trigger on Sale INSERT)
- [ ] T110 [US3] Connect marketplace storefront to real-time inventory (show out-of-stock products)
- [ ] T111 [US3] Test customer registration, order placement, and loyalty point earning

**Checkpoint**: Customer marketplace and loyalty program should be fully functional

---

## Phase 6: User Story 4 - Staff Management with Time Tracking (Priority: P4)

**Goal**: Business owner manages staff accounts, assigns roles and permissions, and tracks employee attendance. Staff members clock in/out for shifts, and system maintains attendance records.

**Independent Test**: Create multiple staff accounts with different roles, have staff members clock in/out during shifts, process sales under different staff IDs, verify attendance reports show accurate clock in/out times.

### Models for US4

- [ ] T112 [P] [US4] Create StaffAttendance model in lib/types/database.ts

### Services for US4

- [ ] T113 [US4] Implement staff attendance service in lib/pos/attendance.ts (clock in/out, calculate hours)
- [ ] T114 [US4] Implement staff reporting service in lib/pos/reports.ts (attendance reports, sales attribution)

### API Endpoints for US4

- [ ] T115 [P] [US4] Create attendance endpoints in app/api/staff/attendance/route.ts (POST clock in, PUT clock out)
- [ ] T116 [P] [US4] Create attendance reports endpoint in app/api/staff/reports/route.ts (GET attendance by date range)

### UI Components for US4

- [ ] T117 [US4] Create clock in/out UI in app/(pos)/attendance/page.tsx (quick clock in/out buttons)
- [ ] T118 [US4] Create attendance reports in app/(admin)/staff/attendance/page.tsx (staff hours, payroll data)
- [ ] T119 [US4] Create open clock-in alerts in app/components/admin/OpenClockInAlert.tsx (staff who forgot to clock out)

### Integration for US4

- [ ] T120 [US4] Integrate sales attribution to logged-in staff (link Sale.cashier_id to User)
- [ ] T121 [US4] Implement auto-alert for open clock-in sessions (>12 hours without clock out)
- [ ] T122 [US4] Test staff clock in/out workflow and attendance reporting

**Checkpoint**: Staff management and time tracking should be fully functional

---

## Phase 7: User Story 11 - Multi-Branch and Multi-Business Management (Priority: P11)

**Goal**: Business owner operates multiple branches with different business types. Each branch operates independently with its own staff, inventory, and sales, but owner admin can view consolidated analytics.

**Independent Test**: Create tenant company account, add three branches with different business types, configure each branch with separate staff and inventory, process sales in each branch, verify owner admin can view consolidated analytics.

### Models for US11

- [ ] T123 [P] [US11] Create InterBranchTransfer model with TransferItem in lib/types/database.ts

### Services for US11

- [ ] T124 [US11] Implement branch management service in lib/pos/branch.ts (create, update, branch-specific config)
- [ ] T125 [US11] Implement inter-branch transfer service in lib/pos/transfer.ts (create transfer, update status)
- [ ] T126 [US11] Implement consolidated analytics service in lib/pos/analytics.ts (aggregate across branches)

### API Endpoints for US11

- [ ] T127 [P] [US11] Create branch endpoints in app/api/branches/route.ts (GET, POST, PUT branches)
- [ ] T128 [P] [US11] Create inter-branch transfer endpoints in app/api/transfers/route.ts (POST transfer, PUT status)
- [ ] T129 [P] [US11] Create consolidated analytics endpoint in app/api/analytics/consolidated/route.ts (tenant-wide metrics)

### UI Components for US11

- [ ] T130 [US11] Create branch management UI in app/(admin)/branches/page.tsx (create, edit branches)
- [ ] T131 [US11] Create inter-branch transfer UI in app/(admin)/transfers/page.tsx (initiate transfer, track status)
- [ ] T132 [US11] Create consolidated dashboard in app/(admin)/dashboard/page.tsx (all-branch analytics with drill-down)
- [ ] T133 [US11] Create branch selector component in app/components/admin/BranchSelector.tsx

### Integration for US11

- [ ] T134 [US11] Update RLS policies to support branch-level isolation (branch managers see own branch only)
- [ ] T135 [US11] Implement inventory transfer workflow (deduct from source, add to destination)
- [ ] T136 [US11] Test multi-branch isolation and consolidated analytics
- [ ] T137 [US11] Update PowerSync sync rules to filter by user's assigned branch

**Checkpoint**: Multi-branch management should be fully functional

---

## Phase 8: User Story 5 - Delivery Management (Priority: P5)

**Goal**: Merchant fulfills customer orders through two delivery options: local delivery using bike/bicycle riders for nearby areas, or platform-provided inter-city delivery for distant locations. Customers track deliveries in real-time.

**Independent Test**: Create delivery orders, assign local orders to bike riders, assign inter-city orders to platform delivery service, update delivery status, verify customer receives tracking updates via public link.

### Models for US5

- [ ] T138 [P] [US5] Create Delivery model in lib/types/database.ts
- [ ] T139 [P] [US5] Create Rider model in lib/types/database.ts

### Services for US5

- [ ] T140 [US5] Implement delivery management service in lib/pos/delivery.ts (create, assign rider, update status)
- [ ] T141 [US5] Implement delivery routing service in lib/pos/delivery-routing.ts (suggest local vs intercity based on distance)
- [ ] T142 [US5] Implement rider management service in lib/pos/rider.ts (create rider, track performance)

### API Endpoints for US5

- [ ] T143 [P] [US5] Create delivery endpoints in app/api/deliveries/route.ts (GET, POST, PUT deliveries)
- [ ] T144 [P] [US5] Create public tracking endpoint in app/api/deliveries/track/[trackingNumber]/route.ts (no auth)
- [ ] T145 [P] [US5] Create rider endpoints in app/api/riders/route.ts (GET, POST riders)

### UI Components for US5

- [ ] T146 [US5] Create delivery management UI in app/(pos)/deliveries/page.tsx (list, assign, update status)
- [ ] T147 [US5] Create public tracking page in app/(marketplace)/track/[orderId]/page.tsx (delivery status, ETA)
- [ ] T148 [US5] Create rider management UI in app/(admin)/riders/page.tsx (rider list, performance metrics)
- [ ] T149 [US5] Create delivery dashboard in app/(admin)/deliveries/dashboard/page.tsx (active deliveries, rider performance)

### Integration for US5

- [ ] T150 [US5] Integrate distance calculation to suggest delivery type (25km threshold)
- [ ] T151 [US5] Implement delivery status notification (SMS/email to customer on status change)
- [ ] T152 [US5] Test local delivery assignment and inter-city delivery handoff

**Checkpoint**: Delivery management should be fully functional

---

## Phase 9: User Story 6 - E-Commerce Platform Integrations (Priority: P6)

**Goal**: Merchant connects WooCommerce, Shopify, or other e-commerce platforms to sync products, inventory, and orders bidirectionally. Prevents overselling and eliminates manual data entry.

**Independent Test**: Connect test WooCommerce store via API credentials, sync products and inventory, place order on WooCommerce, verify it appears in POS system, make POS sale, confirm WooCommerce inventory updates.

### Models for US6

- [ ] T153 [P] [US6] Create ECommerceConnection model in lib/types/database.ts

### Services for US6

- [ ] T154 [US6] Implement WooCommerce integration in lib/integrations/woocommerce.ts (auth, product sync, order sync)
- [ ] T155 [US6] Implement Shopify integration in lib/integrations/shopify.ts (auth, product sync, order sync)
- [ ] T156 [US6] Implement e-commerce sync scheduler in lib/integrations/sync-scheduler.ts (configurable interval)

### API Endpoints for US6

- [ ] T157 [P] [US6] Create e-commerce connection endpoints in app/api/integrations/ecommerce/route.ts (GET, POST, DELETE connections)
- [ ] T158 [P] [US6] Create manual sync trigger endpoint in app/api/integrations/ecommerce/sync/route.ts (POST trigger sync)
- [ ] T159 [P] [US6] Create webhook receiver for WooCommerce in app/api/webhooks/woocommerce/route.ts
- [ ] T160 [P] [US6] Create webhook receiver for Shopify in app/api/webhooks/shopify/route.ts

### UI Components for US6

- [ ] T161 [US6] Create e-commerce connections UI in app/(admin)/integrations/ecommerce/page.tsx (connect, disconnect)
- [ ] T162 [US6] Create sync status dashboard in app/(admin)/integrations/sync-status/page.tsx (last sync, errors)
- [ ] T163 [US6] Create sync conflict resolution UI in app/(admin)/integrations/conflicts/page.tsx

### Integration for US6

- [ ] T164 [US6] Test WooCommerce product sync (bidirectional inventory updates)
- [ ] T165 [US6] Test Shopify order import and fulfillment
- [ ] T166 [US6] Implement conflict resolution (POS priority, last-write-wins, manual resolution)

**Checkpoint**: E-commerce integrations should be fully functional

---

## Phase 10: User Story 7 - AI Chat Agent for Remote Purchases (Priority: P7)

**Goal**: Customer interacts with AI-powered chat agent to browse products, check stock availability, place orders, modify orders, or cancel orders using natural language. AI agent has real-time access to inventory.

**Independent Test**: Initiate chat session as customer, ask AI about product availability, request to purchase specific items, modify quantities via chat, confirm order is created in system, verify inventory updates.

### Models for US7

- [ ] T167 [P] [US7] Create ChatConversation model with ChatMessage in lib/types/database.ts

### Services for US7

- [ ] T168 [US7] Implement AI chat service in lib/integrations/ai-chat.ts (OpenAI or Anthropic SDK)
- [ ] T169 [US7] Implement chat intent detection in lib/integrations/chat-intent.ts (browse, check_stock, create_order)
- [ ] T170 [US7] Implement chat-to-order conversion in lib/integrations/chat-order.ts (parse intent, create order)

### API Endpoints for US7

- [ ] T171 [P] [US7] Create chat endpoints in app/api/chat/route.ts (POST message, GET conversation history)
- [ ] T172 [P] [US7] Create chat escalation endpoint in app/api/chat/escalate/route.ts (handoff to human)

### UI Components for US7

- [ ] T173 [US7] Create AI chat widget in app/components/marketplace/ChatWidget.tsx (customer-facing)
- [ ] T174 [US7] Create merchant chat inbox in app/(admin)/chat/page.tsx (view conversations, escalated chats)

### Integration for US7

- [ ] T175 [US7] Integrate AI chat with real-time inventory queries
- [ ] T176 [US7] Test AI agent order creation and modification workflow
- [ ] T177 [US7] Implement fallback to human merchant for complex requests

**Checkpoint**: AI chat agent should be fully functional

---

## Phase 11: User Story 8 - Analytics and Sales Insights (Priority: P8)

**Goal**: Business owner accesses comprehensive analytics dashboards showing product sales history, sales graphs, category comparisons, sales patterns, top-selling products, revenue trends, and inventory turnover.

**Independent Test**: Process diverse sales transactions over time, access analytics dashboard, view product sales graphs, compare products in same category, verify sales pattern analysis shows accurate trends.

### Services for US8

- [ ] T178 [US8] Implement analytics service in lib/pos/analytics.ts (revenue trends, top products, sales patterns)
- [ ] T179 [US8] Implement inventory analytics in lib/pos/inventory-analytics.ts (turnover, slow-moving products)
- [ ] T180 [US8] Implement sales pattern analysis in lib/pos/sales-patterns.ts (peak hours, day-of-week trends)

### API Endpoints for US8

- [ ] T181 [P] [US8] Create analytics dashboard endpoint in app/api/analytics/dashboard/route.ts (key metrics)
- [ ] T182 [P] [US8] Create product sales history endpoint in app/api/analytics/products/route.ts (sales by product)
- [ ] T183 [P] [US8] Create category comparison endpoint in app/api/analytics/categories/route.ts
- [ ] T184 [P] [US8] Create sales patterns endpoint in app/api/analytics/patterns/route.ts (hourly, daily, seasonal)

### UI Components for US8

- [ ] T185 [US8] Create analytics dashboard in app/(admin)/analytics/page.tsx (total revenue, transactions, top products)
- [ ] T186 [US8] Create product sales graphs in app/(admin)/analytics/products/page.tsx (line charts, bar charts)
- [ ] T187 [US8] Create category comparison UI in app/(admin)/analytics/categories/page.tsx (side-by-side performance)
- [ ] T188 [US8] Create sales patterns visualization in app/(admin)/analytics/patterns/page.tsx (heat maps, trend lines)
- [ ] T189 [US8] Create inventory turnover report in app/(admin)/analytics/inventory/page.tsx

### Integration for US8

- [ ] T190 [US8] Create materialized views for analytics performance (daily_sales_summary)
- [ ] T191 [US8] Test analytics dashboard with 10,000+ transactions dataset
- [ ] T192 [US8] Implement data export (CSV, PDF) for all analytics reports

**Checkpoint**: Analytics and reporting should be fully functional

---

## Phase 12: User Story 9 - WhatsApp Customer Communication (Priority: P9)

**Goal**: Merchant sends order confirmations, delivery updates, and promotional messages to customers via WhatsApp. Customers can also initiate inquiries through WhatsApp.

**Independent Test**: Process sale with customer WhatsApp number, trigger automated confirmation message, update order status, verify customer receives WhatsApp notification, test merchant inbox receives customer messages.

### Models for US9

- [ ] T193 [P] [US9] Create WhatsAppMessage model in lib/types/database.ts

### Services for US9

- [ ] T194 [US9] Implement WhatsApp Business API integration in lib/integrations/whatsapp.ts
- [ ] T195 [US9] Implement WhatsApp template messaging in lib/integrations/whatsapp-templates.ts
- [ ] T196 [US9] Implement WhatsApp message queue in lib/integrations/whatsapp-queue.ts (retry logic, fallback to SMS)

### API Endpoints for US9

- [ ] T197 [P] [US9] Create WhatsApp configuration endpoint in app/api/integrations/whatsapp/config/route.ts
- [ ] T198 [P] [US9] Create WhatsApp send message endpoint in app/api/integrations/whatsapp/send/route.ts
- [ ] T199 [P] [US9] Create WhatsApp webhook receiver in app/api/webhooks/whatsapp/route.ts (inbound messages)

### UI Components for US9

- [ ] T200 [US9] Create WhatsApp configuration UI in app/(admin)/integrations/whatsapp/page.tsx
- [ ] T201 [US9] Create unified inbox in app/(admin)/inbox/page.tsx (WhatsApp messages, customer inquiries)
- [ ] T202 [US9] Create promotional messaging UI in app/(admin)/marketing/whatsapp/page.tsx

### Integration for US9

- [ ] T203 [US9] Integrate WhatsApp order confirmation on sale completion
- [ ] T204 [US9] Integrate WhatsApp delivery status updates
- [ ] T205 [US9] Test WhatsApp message delivery and fallback to SMS

**Checkpoint**: WhatsApp integration should be fully functional

---

## Phase 13: User Story 10 - Payments and Monetization (Priority: P10)

**Goal**: Platform monetizes through subscription plans and commission on marketplace sales. Merchants manage subscriptions, view billing history, and platform tracks commission earnings.

**Independent Test**: Create subscription plans, enroll tenant in plan, process marketplace sales, calculate commissions, generate invoices, verify subscription limits are enforced.

### Models for US10

- [ ] T206 [P] [US10] Create Subscription model in lib/types/database.ts
- [ ] T207 [P] [US10] Create Commission model in lib/types/database.ts

### Services for US10

- [ ] T208 [US10] Implement subscription management service in lib/pos/subscription.ts (create plan, enroll, upgrade/downgrade)
- [ ] T209 [US10] Implement commission calculation service in lib/pos/commission.ts (auto-calculate on marketplace orders)
- [ ] T210 [US10] Implement billing service in lib/pos/billing.ts (generate invoices, payment reminders)

### API Endpoints for US10

- [ ] T211 [P] [US10] Create subscription endpoints in app/api/subscriptions/route.ts (GET, POST, PUT subscriptions)
- [ ] T212 [P] [US10] Create commission tracking endpoint in app/api/commissions/route.ts (GET commission reports)
- [ ] T213 [P] [US10] Create billing endpoints in app/api/billing/route.ts (GET invoices, billing history)

### UI Components for US10

- [ ] T214 [US10] Create subscription management UI in app/(admin)/billing/subscription/page.tsx
- [ ] T215 [US10] Create billing history in app/(admin)/billing/history/page.tsx
- [ ] T216 [US10] Create plan upgrade prompt in app/components/admin/UpgradePrompt.tsx (when limits exceeded)

### Integration for US10

- [ ] T217 [US10] Integrate Paystack subscription billing (recurring charges)
- [ ] T218 [US10] Implement commission auto-calculation trigger on Order completion
- [ ] T219 [US10] Enforce subscription limits (branches, staff, products, transactions)
- [ ] T220 [US10] Test subscription lifecycle (create, renew, upgrade, cancel)

**Checkpoint**: Payments and monetization should be fully functional

---

## Phase 14: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [ ] T221 [P] Optimize bundle size with code splitting and lazy loading
- [ ] T222 [P] Add loading states and skeleton screens for all async operations
- [ ] T223 [P] Implement error boundaries for graceful error handling
- [ ] T224 [P] Add audit logging for all critical operations (sales, refunds, transfers, user changes)
- [ ] T225 [P] Create quickstart validation script to verify setup in quickstart.md
- [ ] T226 [P] Add keyboard shortcuts for POS operations (F1-F12 for quick actions)
- [ ] T227 [P] Implement progressive disclosure for advanced features (hide based on subscription tier)
- [ ] T228 [P] Add haptic feedback for mobile touch interactions
- [ ] T229 [P] Optimize Lighthouse Core Web Vitals (LCP <2.5s, FID <100ms, CLS <0.1)
- [ ] T230 [P] Security audit: Review RLS policies, input validation, API authentication
- [ ] T231 [P] Performance testing: Load test with 1000+ concurrent users, 10,000+ products
- [ ] T232 [P] Browser compatibility testing (Chrome 90+, Safari 14+, Firefox 88+)
- [ ] T233 [P] Low-end device testing (2GB RAM Android with 3G throttling)
- [ ] T234 Create deployment documentation in docs/deployment.md
- [ ] T235 Create user guide for merchants in docs/user-guide.md

---

## Dependencies & Execution Order

### Phase Dependencies

1. **Setup (Phase 1)**: No dependencies - can start immediately
2. **Foundational (Phase 2)**: Depends on Setup completion - **BLOCKS ALL USER STORIES**
3. **User Stories (Phase 3-13)**: All depend on Foundational phase completion
   - User stories CAN proceed in parallel (if team capacity allows)
   - OR sequentially in priority order: US1 → US2 → US3 → US4 → US11 → US5 → US6 → US7 → US8 → US9 → US10
4. **Polish (Phase 14)**: Depends on all desired user stories being complete

### User Story Dependencies

- **US1 (POS)**: No dependencies on other stories - can start after Foundational
- **US2 (Auth)**: No dependencies - can start after Foundational (should be early for multi-tenancy)
- **US3 (Customers)**: Integrates with US1 (products) but independently testable
- **US4 (Staff)**: Depends on US2 (user accounts) - extend user model
- **US11 (Multi-Branch)**: Depends on US1, US2 - extends tenant/branch model
- **US5 (Delivery)**: Depends on US3 (orders) - fulfillment for orders
- **US6 (E-Commerce)**: Depends on US1 (products) - sync with external platforms
- **US7 (AI Chat)**: Depends on US1 (products), US3 (orders) - AI creates orders
- **US8 (Analytics)**: Depends on US1 (sales data) - analyze transactions
- **US9 (WhatsApp)**: Depends on US3 (orders) - notify customers about orders
- **US10 (Payments)**: Depends on US3 (marketplace orders) - commission on sales

### Within Each User Story

1. Models first (can run in parallel if different files)
2. Services after models (may depend on models)
3. API endpoints (can run in parallel if different routes)
4. UI components (can run in parallel if different pages)
5. Integration tasks last (connect all pieces)

### Parallel Opportunities

- All Setup tasks marked [P] can run in parallel
- All Foundational tasks marked [P] can run in parallel (within each subsection)
- Once Foundational completes, multiple user stories can be worked on in parallel by different team members
- Within each user story, tasks marked [P] can run in parallel

---

## Parallel Example: Foundational Phase

```bash
# Database setup (sequential due to dependencies)
T008 → T009 → T010 → T013

# Then run these in parallel:
T011 [P] Create RLS helper functions
T012 [P] Enable RLS on all tables

# Offline sync (sequential due to dependencies)
T014 → T015 → T016 → T017 → T018 → T019 → T020

# Auth (sequential due to dependencies)
T021 → T023 → T024 → T025
T022 [P] Configure Supabase Auth (parallel with T021)

# UI Foundation (can all run in parallel)
T026, T027 [P], T028 [P], T029 [P], T030

# Payment (sequential setup, then parallel integration)
T033 → (T031 [P] Paystack, T032 [P] Flutterwave, T034, T035 [P])

# Utilities (all parallel)
T036 [P], T037 [P], T038 [P], T039, T040
```

---

## Parallel Example: User Story 1

```bash
# Models (all parallel - different files)
T041 [P], T042 [P], T043 [P], T044 [P]

# Services (sequential - may depend on each other)
T045 → T046 → T047 → T048 → T049

# API Endpoints (all parallel - different routes)
T050 [P], T051 [P], T052 [P], T053 [P], T054 [P]

# UI Components (sequential due to integration dependencies)
T055 → T056 → T057 → T058 → T059 → T060 → T061 → T062 → T063 → T064

# Integration (sequential - test end-to-end)
T065 → T066 → T067 → T068
```

---

## Implementation Strategy

### MVP First (User Stories 1 + 2 Only)

**Recommended Approach**: Focus on core POS functionality with multi-tenant authentication

1. Complete Phase 1: Setup (T001-T007)
2. Complete Phase 2: Foundational (T008-T040) - **CRITICAL BLOCKING PHASE**
3. Complete Phase 3: US1 - POS Operations (T041-T068)
4. Complete Phase 4: US2 - Authentication & Multi-Tenancy (T069-T090)
5. **STOP and VALIDATE**: Test independently
6. Deploy/demo MVP

**Why this MVP**: US1 + US2 = Complete offline POS with multi-tenant isolation. Merchants can onboard, process sales offline, and sync to cloud. This is the minimum viable product.

### Incremental Delivery (Recommended Production Rollout)

1. **Foundation** (Setup + Foundational) → Infrastructure ready
2. **Add US1 + US2** → Deploy/Demo (MVP! Merchants can use POS with multi-tenancy)
3. **Add US11** (Multi-Branch) → Deploy/Demo (Merchants with multiple locations can use)
4. **Add US3** (Customers/Marketplace) → Deploy/Demo (Enable online orders)
5. **Add US5** (Delivery) → Deploy/Demo (Fulfill online orders)
6. **Add US4** (Staff Attendance) → Deploy/Demo (Time tracking for payroll)
7. **Add US8** (Analytics) → Deploy/Demo (Business intelligence)
8. **Add US6** (E-Commerce) → Deploy/Demo (Integrate existing stores)
9. **Add US10** (Payments/Monetization) → Deploy/Demo (Start charging customers)
10. **Add US7** (AI Chat) + US9 (WhatsApp) → Deploy/Demo (Advanced features)

Each deployment adds value without breaking previous features.

### Parallel Team Strategy

With 3-4 developers:

1. **Week 1-2**: Entire team on Setup + Foundational (pair programming on complex parts like PowerSync, RLS)
2. **Week 3-4**: Once Foundational is done:
   - Dev A: US1 (POS Operations)
   - Dev B: US2 (Authentication)
   - Dev C: US11 (Multi-Branch)
   - Dev D: US3 (Customers/Marketplace)
3. **Week 5**: Integration testing, polish, MVP deployment
4. **Week 6+**: Continue with remaining user stories in priority order

---

## Total Task Count

- **Setup**: 7 tasks
- **Foundational**: 33 tasks (BLOCKS all user stories)
- **US1 (POS)**: 28 tasks
- **US2 (Auth)**: 22 tasks
- **US3 (Customers)**: 21 tasks
- **US4 (Staff)**: 11 tasks
- **US11 (Multi-Branch)**: 15 tasks
- **US5 (Delivery)**: 15 tasks
- **US6 (E-Commerce)**: 14 tasks
- **US7 (AI Chat)**: 11 tasks
- **US8 (Analytics)**: 15 tasks
- **US9 (WhatsApp)**: 13 tasks
- **US10 (Payments)**: 15 tasks
- **Polish**: 15 tasks

**Grand Total**: 235 tasks

**MVP (US1 + US2)**: 7 (Setup) + 33 (Foundational) + 28 (US1) + 22 (US2) = **90 tasks**

**Parallel Opportunities**: 68 tasks marked [P] can run in parallel

**Suggested MVP Scope**: US1 + US2 (90 tasks) = Offline POS with multi-tenant authentication

---

## Notes

- [P] tasks = different files, can run in parallel
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Tests NOT included (not explicitly requested in specification)
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Phase 2 (Foundational) is CRITICAL - no user story work can begin until it's complete
- Avoid: vague tasks, same file conflicts, cross-story dependencies that break independence
- Security: Always verify tenant_id in API routes, never trust client-provided tenant_id
- Performance: Monitor Core Web Vitals, optimize for low-end devices, test with 3G throttling

---

**Status**: ✅ Tasks Generated | **Total Tasks**: 235 | **MVP Tasks**: 90 (Setup + Foundational + US1 + US2)

**Next Command**: `/speckit.implement` to begin executing tasks sequentially

**Generated**: 2026-01-17
