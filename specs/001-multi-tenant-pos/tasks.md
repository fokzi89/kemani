# Tasks: Multi-Tenant POS-First Super App Platform (Flutter Migration)

**Feature Branch**: `001-multi-tenant-pos`
**Input**: Migration Plan from `flutter-migration-plan.md`
**Target Framework**: Flutter (POS), SvelteKit (Marketing)

**Organization**: Tasks are grouped by user story/phase clearly mapping to the migration plan.

## Format: `- [ ] [ID] [P?] [Story?] Description with file path`

- **Checkbox**: `- [ ]` for pending, `- [x]` for completed
- **ID**: Sequential task number (T001, T002...)
- **[P]**: Parallelizable task
- **File paths**: Relative to `apps/web_client/` unless specified (e.g. `apps/marketing_sveltekit/`)

---

## Phase 1: Setup & Core Infrastructure

**Purpose**: Initialize Flutter environment, project structure, and core architecture.

- [x] T001 Verify Flutter SDK 3.38.9+ and Dart 3.10.8+ environment
- [x] T002 Create/Verify Flutter project structure in `apps/web_client`
- [x] T003 [P] Install core dependencies: `flutter_riverpod`, `go_router`, `freezed`, `json_serializable`
- [x] T004 [P] Install Supabase & Sync dependencies: `supabase_flutter`, `powersync`, `sqlite3`
- [x] T005 [P] Install UI dependencies: `google_fonts`, `flutter_svg`, `lucide_icons` (or equivalent)
- [x] T006 [P] Setup `analysis_options.yaml` with strict linting rules
- [x] T007 Configure `pubspec.yaml` assets and fonts
- [x] T008 Setup environment variables logic (using `flutter_dotenv` or `--dart-define`)

### Architecture Foundations

- [x] T009 Create State Management structure: `lib/providers/{auth,tenant,cart}.dart`
- [x] T010 Configure GoRouter in `lib/router/app_router.dart` with auth guards
- [x] T011 Create Supabase Service in `lib/services/supabase_service.dart`
- [x] T012 Integrate PowerSync SDK in `lib/database/powersync.dart`
- [x] T013 Define SQLite schema in `lib/database/schema.dart` matching Supabase
- [x] T014 Implement Offline Status Monitor in `lib/services/connectivity_service.dart`
- [x] T015 Create UI Design System (Theme, Colors, Typography) in `lib/theme/app_theme.dart`
- [x] T016 Create shared widgets: `POSButton`, `POSInput`, `POSCard` in `lib/widgets/common/`


**Checkpoint**: Core Flutter infrastructure ready.

---

## Phase 2: User Story 2 - Authentication & Multi-Tenancy (Migration)

**Goal**: Port authentication, onboarding, and tenant management to Flutter.

### Services & State
- [x] T017 [US2] Implement Auth Provider in `lib/providers/auth_provider.dart` (Login, Register, Logout)
- [x] T018 [US2] Implement Tenant Service in `lib/services/tenant_service.dart` (Profile, Company Setup)
- [x] T019 [US2] Implement OTP Service using Supabase Auth in `lib/services/auth_service.dart`

### UI Screens
- [x] T020 [US2] Create Login Screen in `lib/screens/auth/login_screen.dart`
- [x] T021 [US2] Create Registration Screen in `lib/screens/auth/register_screen.dart`
- [x] T022 [US2] Create OTP Verification Screen in `lib/screens/auth/otp_screen.dart`
- [x] T023 [US2] Create Onboarding Profile Screen in `lib/screens/onboarding/profile_screen.dart`
- [x] T024 [US2] Create Onboarding Company Screen in `lib/screens/onboarding/company_screen.dart`
- [x] T025 [US2] Create Passcode Setup Screen in `lib/screens/auth/passcode_setup_screen.dart`
- [x] T026 [US2] Create Inactivity Lock Screen in `lib/screens/auth/lock_screen.dart`

**Checkpoint**: Authentication & Onboarding fully functional in Flutter.

---

## Phase 3: User Story 1 - Offline-First POS Operations (Migration)

**Goal**: Port core POS sales, inventory, and offline sync.

### Models & Database
- [x] T027 [P] [US1] Define Product Model (Freezed) in `lib/models/product.dart`
- [x] T028 [P] [US1] Define Sale/Cart Models (Freezed) in `lib/models/sale.dart`
- [x] T029 [P] [US1] Define InventoryTransaction Model in `lib/models/inventory.dart`

### Services & Logic
- [x] T030 [US1] Implement Product Service (CRUD, Search) in `lib/services/product_service.dart`
- [x] T031 [US1] Implement Cart Notifier/Provider in `lib/providers/cart_provider.dart`
- [x] T032 [US1] Implement Transaction Service (Process Sale, Sync) in `lib/services/transaction_service.dart`
- [x] T033 [US1] Implement Conflict Resolution logic for PowerSync

### UI Screens
- [x] T034 [US1] Create Inventory List Screen in `lib/screens/pos/inventory_list_screen.dart`
- [x] T035 [US1] Create Product Edit/Add Screen in `lib/screens/pos/product_edit_screen.dart`
- [x] T036 [US1] Create POS Sales Screen (Grid) in `lib/screens/pos/sales_screen.dart`
- [x] T037 [US1] Create Cart Widget/Drawer in `lib/widgets/pos/cart_drawer.dart`
- [x] T038 [US1] Create Payment Method Selector in `lib/widgets/pos/payment_selector.dart`
- [x] T039 [US1] Create Receipt Preview Screen in `lib/screens/pos/receipt_screen.dart`
- [x] T040 [US1] Implement Barcode Scanner using `mobile_scanner` in `lib/widgets/pos/scanner_widget.dart`

**Checkpoint**: Complete Offline POS working in Flutter.

---

## Phase 4: User Story 4 & 11 - Staff & Branch Management

**Goal**: Port staff management and multi-branch features.

- [x] T041 [US4] Create Staff Model & Service in `lib/models/staff.dart`
- [x] T042 [US4] Create Staff List & Invite Screen in `lib/screens/admin/staff_screen.dart`
- [x] T043 [US4] Create Attendance/Clock-In Screen in `lib/screens/pos/attendance_screen.dart`
- [x] T044 [US11] Create Branch Model & Service in `lib/services/branch_service.dart`
- [x] T045 [US11] Create Branch Management Screen in `lib/screens/admin/branch_screen.dart`

---

## Phase 5: User Story 3 - Customers & Marketplace Orders

**Goal**: Port customer management and order handling.

- [x] T046 [US3] Create Customer Model & Service in `lib/models/customer.dart`
- [x] T047 [US3] Create Customer List Screen in `lib/screens/pos/customer_list_screen.dart`
- [x] T048 [US3] Create Order Model & Service in `lib/services/order_service.dart`
- [x] T049 [US3] Create Order Management Screen in `lib/screens/pos/orders_screen.dart`

---

## Phase 6: User Story 5 & 8 - Delivery & Analytics

**Goal**: Port delivery management and dashboards.

- [x] T050 [US5] Create Delivery Service & Models in `lib/services/delivery_service.dart`
- [x] T051 [US5] Create Delivery Management Screen in `lib/screens/admin/delivery_screen.dart`
- [x] T052 [US8] Integrate `fl_chart` for Analytics
- [x] T053 [US8] Create Analytics Dashboard Screen in `lib/screens/admin/analytics_dashboard.dart`
- [x] T054 [US8] Create Sales Report Screen in `lib/screens/admin/sales_report_screen.dart`

---

## Phase 7: Integrations (US6, US7, US9)

**Goal**: Port e-commerce sync, WhatsApp, and AI Chat.

- [x] T055 [US6] Implement WooCommerce Service in `lib/services/integrations/woocommerce_service.dart`
- [ ] T056 [US9] Implement WhatsApp Service in `lib/services/integrations/whatsapp_service.dart`
- [x] T057 [US7] Implement AI Chat Service in `lib/services/integrations/ai_chat_service.dart`
- [x] T058 [US7] Create AI Chat Widget/Screen in `lib/screens/chat/ai_chat_screen.dart`

---

## Phase 8: SvelteKit Marketing & Storefront

**Goal**: Create the SEO-optimized web front (separate app).

- [x] T059 Setup SvelteKit project in `apps/marketing_sveltekit`
- [x] T060 Implement Landing Page in `apps/marketing_sveltekit/src/routes/+page.svelte`
- [x] T061 Implement Pricing Page in `apps/marketing_sveltekit/src/routes/pricing/+page.svelte`
- [x] T062 Implement Public Storefront in `apps/marketing_sveltekit/src/routes/shop/+page.svelte`

---

## Phase 9: Deployment & Polish

- [x] T063 Configure Flutter Build flavors (Dev/Prod)
- [x] T064 Setup CI/CD for Flutter Web & Android (GitHub Actions)
- [x] T065 Perform Release Build (APK/Web)
- [x] T066 Verify SvelteKit deployment configuration (Vercel/Netlify)
