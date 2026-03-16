# Tasks: Multi-Tenant Referral Commission System

**Input**: Design documents from `/specs/004-tenant-referral-commissions/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: Tests are included for critical commission calculation accuracy (constitutional requirement: SC-002 demands 100% accuracy)

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

Multi-platform monorepo structure:
- **SvelteKit apps**: `apps/storefront/src/`, `apps/healthcare_customer/src/`
- **Flutter apps**: `apps/pos_admin/lib/`
- **Supabase**: `supabase/migrations/`, `supabase/functions/`
- **Tests**: `apps/storefront/tests/`, `apps/pos_admin/test/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and database foundation

- [X] T001 Create Supabase migration file `supabase/migrations/20260313_referral_commissions.sql`
- [X] T002 [P] Create commission types TypeScript definitions in `apps/storefront/src/lib/types/commission.ts`
- [X] T003 [P] Create commission models for Flutter in `apps/pos_admin/lib/features/commissions/models/commission_record.dart`
- [X] T004 [P] Install Hive dependency in Flutter app `apps/pos_admin/pubspec.yaml`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core database schema and security policies that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

### Database Schema

- [ ] T005 Create enum types in migration: `commission_status`, transaction types
- [ ] T006 Create `referral_sessions` table with indexes in `supabase/migrations/20260313_referral_commissions.sql`
- [ ] T007 Create `transactions` table with indexes in `supabase/migrations/20260313_referral_commissions.sql`
- [ ] T008 Create `commissions` table with indexes and constraints in `supabase/migrations/20260313_referral_commissions.sql`
- [ ] T009 Create `fulfillment_routing` table with indexes in `supabase/migrations/20260313_referral_commissions.sql`
- [ ] T010 Add new columns to `prescriptions` table (fulfilling_pharmacy_id, referring_tenant_id)
- [ ] T011 Add new columns to `test_requests` table (fulfilling_diagnostic_center_id, referring_tenant_id)
- [ ] T012 Add new columns to `consultations` table (referring_tenant_id, commission_calculated)
- [ ] T013 Add new columns to `orders` table (referring_tenant_id, commission_calculated)

### Database Functions & Triggers

- [ ] T014 Create `calculate_service_commission` PostgreSQL function in migration
- [ ] T015 Create `calculate_product_commission` PostgreSQL function in migration
- [ ] T016 Create `route_prescription_to_referrer` trigger function in migration
- [ ] T017 Create `route_test_to_referrer` trigger function in migration
- [ ] T018 Attach `prescription_auto_route` trigger to prescriptions table
- [ ] T019 Attach `test_auto_route` trigger to test_requests table

### Security & Analytics

- [ ] T020 Create RLS policies for `referral_sessions` table (customer read, platform manage)
- [ ] T021 Create RLS policies for `transactions` table (customer/provider/referrer read, platform manage)
- [ ] T022 Create RLS policies for `commissions` table (tenant referrer/provider read, platform write)
- [ ] T023 Create RLS policies for `fulfillment_routing` table (tenant fulfiller read, platform write)
- [ ] T024 Create `commission_daily_summary` materialized view in migration
- [ ] T025 Create `refresh_commission_summary` function for nightly refresh
- [ ] T026 Apply database migration to local Supabase instance

### Tests for Database Functions (Critical for Accuracy Requirement)

- [ ] T027 [P] Create pgTAP test for `calculate_service_commission` with referrer in `supabase/tests/commission_calc_service.sql`
- [ ] T028 [P] Create pgTAP test for `calculate_service_commission` without referrer in `supabase/tests/commission_calc_service.sql`
- [ ] T029 [P] Create pgTAP test for `calculate_product_commission` with referrer in `supabase/tests/commission_calc_product.sql`
- [ ] T030 [P] Create pgTAP test for `calculate_product_commission` without referrer in `supabase/tests/commission_calc_product.sql`
- [ ] T031 Run pgTAP tests and verify 100% accuracy for all commission formulas

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Session-Based Referral Attribution (Priority: P1) 🎯 MVP

**Goal**: Track customer browsing sessions to determine referring tenant for commission attribution

**Independent Test**: Customer visits `fokz.localhost:5173`, browses medic directory, books consultation with Dr. Kome (₦1,000 base), system records Fokz Pharmacy as referrer and calculates ₦100 commission

### Implementation for User Story 1

**SvelteKit Session Tracking**

- [ ] T032 [P] [US1] Create `ReferralSessionService` class in `apps/storefront/src/lib/services/referralSession.ts`
- [ ] T033 [P] [US1] Implement session creation method (generate token, insert to DB, return token)
- [ ] T034 [P] [US1] Implement session retrieval method (by token, check active/expiry)
- [ ] T035 [US1] Update `apps/storefront/src/hooks.server.ts` to extract subdomain and create/refresh session cookie
- [ ] T036 [US1] Implement cookie setting logic (HTTP-only, secure, 24h expiry) in hooks.server.ts
- [ ] T037 [US1] Add `referringTenantId` to `event.locals` for use in routes

**Session Tracking Component**

- [ ] T038 [P] [US1] Create `ReferralSessionTracker.svelte` component in `apps/storefront/src/lib/components/referral/`
- [ ] T039 [US1] Implement session validation on component mount (check cookie exists and active)
- [ ] T040 [US1] Add session refresh logic on user activity (update last_activity_at)

**Integration Tests**

- [ ] T041 [P] [US1] Create Playwright test for session creation via subdomain in `apps/storefront/tests/referral-session.spec.ts`
- [ ] T042 [P] [US1] Create Playwright test for session persistence across page navigation
- [ ] T043 [P] [US1] Create Playwright test for session expiry after 24 hours
- [ ] T044 [P] [US1] Create Playwright test for session isolation (different subdomains = different referrers)

**Checkpoint**: At this point, User Story 1 should be fully functional - session tracking works independently

---

## Phase 4: User Story 2 - Accurate Commission Calculation (Priority: P1)

**Goal**: Calculate and distribute commissions accurately based on transaction type (service vs product, with/without referrer)

**Independent Test**: Process consultation (₦1,000 base) and drug purchase (₦5,000) transactions, verify exact amounts match formulas: service 90/10/10 split with 10% markup, product 94/4.5/1.5 split no markup

### Implementation for User Story 2

**Commission Calculation Service**

- [ ] T045 [P] [US2] Create `CommissionCalculator` service in `apps/storefront/src/lib/services/commissionCalculator.ts`
- [ ] T046 [P] [US2] Implement `calculateServiceCommission` method (call Supabase function, return breakdown)
- [ ] T047 [P] [US2] Implement `calculateProductCommission` method (call Supabase function, return breakdown)
- [ ] T048 [P] [US2] Add type guards for commission calculation results
- [ ] T049 [US2] Implement currency rounding helper (round to 2 decimal places) to avoid float precision errors

**Supabase Edge Function for Payment Processing**

- [ ] T050 [P] [US2] Create Edge Function scaffold in `supabase/functions/process-referral-payment/index.ts`
- [ ] T051 [US2] Implement webhook handler (parse Paystack/Flutterwave payload, extract transaction details)
- [ ] T052 [US2] Implement commission calculation logic (get active session, determine has_referrer, call DB function)
- [ ] T053 [US2] Insert commission record to `commissions` table with all amounts and metadata
- [ ] T054 [US2] Update transaction status to 'completed' and set commission_calculated flag
- [ ] T055 [US2] Add error handling and idempotency check (prevent duplicate commission records)

**Commission Preview Component**

- [ ] T056 [P] [US2] Create `CommissionPreview.svelte` in `apps/storefront/src/lib/components/referral/`
- [ ] T057 [US2] Implement real-time calculation preview (call /api/commissions/calculate before checkout)
- [ ] T058 [US2] Display breakdown: customer pays, provider gets, referrer gets, platform gets
- [ ] T059 [US2] Add formatting for currency display (₦ symbol, thousand separators)

**Integration Tests for Accuracy**

- [ ] T060 [P] [US2] Create Vitest test for service commission with referrer in `apps/storefront/tests/commission-calculation.test.ts`
- [ ] T061 [P] [US2] Create Vitest test for service commission without referrer
- [ ] T062 [P] [US2] Create Vitest test for product commission with referrer
- [ ] T063 [P] [US2] Create Vitest test for product commission without referrer (₦100 fixed charge)
- [ ] T064 [P] [US2] Create property-based test (fast-check) to verify totals always balance
- [ ] T065 [US2] Run all commission calculation tests and verify 100% pass rate (critical requirement)

**Checkout Integration**

- [ ] T066 [US2] Update checkout flow in `apps/storefront/src/routes/checkout/+page.svelte` to include commission calculation
- [ ] T067 [US2] Display commission preview to customer before payment
- [ ] T068 [US2] Pass transaction details to payment webhook after successful payment

**Checkpoint**: At this point, User Story 2 should be fully functional - commissions calculate accurately for all scenarios

---

## Phase 5: User Story 3 - Multi-Service Commission (Priority: P2)

**Goal**: Referrer earns commission on ALL services purchased in a single browsing session (consultation + drugs + test)

**Independent Test**: Customer accesses through Fokz Pharmacy, books consultation (₦1,100), buys drugs (₦5,000), orders test (₦5,500), verify Fokz receives ₦100 + ₦225 + ₦500 = ₦825 total commission

### Implementation for User Story 3

**Transaction Grouping**

- [ ] T069 [P] [US3] Create `TransactionGroup` service in `apps/storefront/src/lib/services/transactionGroup.ts`
- [ ] T070 [US3] Implement group ID generation (UUID for checkout session)
- [ ] T071 [US3] Update checkout to assign same group_id to all transactions in cart

**Multi-Transaction Processing**

- [ ] T072 [US3] Modify `process-referral-payment` Edge Function to handle transaction groups
- [ ] T073 [US3] Implement batch commission calculation (iterate all transactions in group, calculate each)
- [ ] T074 [US3] Ensure same `referring_tenant_id` for all transactions in group (from session)
- [ ] T075 [US3] Insert multiple commission records in single database transaction (atomic)

**Session Persistence Across Services**

- [ ] T076 [US3] Update session tracker to maintain active session during navigation between service types
- [ ] T077 [US3] Add session validation to prevent expiry during multi-service checkout
- [ ] T078 [US3] Implement session refresh on each service addition to cart

**Integration Tests**

- [ ] T079 [P] [US3] Create Playwright E2E test for multi-service checkout in `apps/storefront/tests/multi-service-commission.spec.ts`
- [ ] T080 [P] [US3] Test scenario: consultation + drugs + test all attribute to same referrer
- [ ] T081 [P] [US3] Test scenario: verify total commission = sum of individual commissions
- [ ] T082 [US3] Test edge case: session expires mid-checkout (should maintain referrer or fail gracefully)

**Checkpoint**: At this point, User Story 3 should be fully functional - multi-service sessions correctly attribute all commissions

---

## Phase 6: User Story 4 - Guaranteed Fulfillment Routing (Priority: P2)

**Goal**: Automatically route prescriptions/test requests to referring pharmacy/diagnostic center (when applicable)

**Independent Test**: Customer accesses through `fokz.kemani.com`, consults Dr. Kome who issues prescription, verify prescription auto-routes to Fokz Pharmacy (customer doesn't choose)

### Implementation for User Story 4

**Fulfillment Router Service**

- [ ] T083 [P] [US4] Create `FulfillmentRouter` service in `apps/storefront/src/lib/services/fulfillmentRouter.ts`
- [ ] T084 [US4] Implement prescription routing logic (check referrer type, auto-assign if pharmacy)
- [ ] T085 [US4] Implement test request routing logic (check referrer type, auto-assign if diagnostic center)
- [ ] T086 [US4] Implement directory display logic (show filtered list if no applicable referrer)

**City-Filtered Directory**

- [ ] T087 [P] [US4] Create pharmacy directory route in `apps/storefront/src/routes/pharmacy-directory/+page.svelte`
- [ ] T088 [P] [US4] Create diagnostic directory route in `apps/storefront/src/routes/diagnostic-directory/+page.svelte`
- [ ] T089 [US4] Implement city filter component (extract customer city from profile, filter tenants)
- [ ] T090 [US4] Add customer selection handling (record selection in fulfillment_routing with reason='customer_selected')

**Prescription/Test Request Integration**

- [ ] T091 [US4] Update prescription creation to check for pharmacy referrer (via database trigger - already in Phase 2)
- [ ] T092 [US4] Update test request creation to check for diagnostic center referrer (via database trigger - already in Phase 2)
- [ ] T093 [US4] Add UI logic to show/hide directory based on `fulfilling_pharmacy_id` or `fulfilling_diagnostic_center_id`

**Fulfillment Router Component**

- [ ] T094 [P] [US4] Create `FulfillmentRouter.svelte` component in `apps/storefront/src/lib/components/referral/`
- [ ] T095 [US4] Implement conditional rendering (auto-route message if referrer, directory if not)
- [ ] T096 [US4] Add success message for auto-routed fulfillment

**Integration Tests**

- [ ] T097 [P] [US4] Create Playwright test for auto-routing to pharmacy referrer in `apps/storefront/tests/fulfillment-routing.spec.ts`
- [ ] T098 [P] [US4] Create Playwright test for auto-routing to diagnostic center referrer
- [ ] T099 [P] [US4] Create Playwright test for customer directory selection (no referrer)
- [ ] T100 [P] [US4] Test edge case: referrer is doctor (not pharmacy/lab), should show directory
- [ ] T101 [US4] Verify fulfillment_routing records created with correct routing_reason

**Checkpoint**: At this point, User Story 4 should be fully functional - fulfillment routing works automatically and correctly

---

## Phase 7: User Story 5 - Commission Tracking & Reporting (Priority: P3)

**Goal**: Tenants view earned commissions, pending amounts, and commission history in dashboard with detailed breakdowns

**Independent Test**: Generate 10 sample transactions for Fokz Pharmacy (mix of pending/processed/paid_out), open Flutter dashboard, verify accurate totals and breakdowns by transaction type

### Implementation for User Story 5

**Flutter Commission Service**

- [ ] T102 [P] [US5] Create `CommissionService` class in `apps/pos_admin/lib/features/commissions/services/commission_service.dart`
- [ ] T103 [P] [US5] Implement `getCommissions` method (query Supabase with filters: status, date range, transaction type)
- [ ] T104 [P] [US5] Implement `getSummary` method (call materialized view or aggregate query)
- [ ] T105 [P] [US5] Implement offline sync service in `apps/pos_admin/lib/features/commissions/services/offline_commission_sync.dart`
- [ ] T106 [US5] Add Hive storage for offline commission data (cache commissions locally)
- [ ] T107 [US5] Implement background sync (sync new commissions when connection restored)

**Flutter Dashboard Screens**

- [ ] T108 [P] [US5] Create `commission_dashboard.dart` screen in `apps/pos_admin/lib/features/commissions/screens/`
- [ ] T109 [P] [US5] Create `commission_history.dart` screen in `apps/pos_admin/lib/features/commissions/screens/`
- [ ] T110 [P] [US5] Create `commission_details.dart` screen in `apps/pos_admin/lib/features/commissions/screens/`
- [ ] T111 [US5] Implement navigation between screens (dashboard → history → details)

**Dashboard Widgets**

- [ ] T112 [P] [US5] Create `commission_summary_card.dart` widget in `apps/pos_admin/lib/features/commissions/widgets/`
- [ ] T113 [P] [US5] Display total earned, pending, processed, paid_out amounts
- [ ] T114 [P] [US5] Create `commission_chart.dart` widget using fl_chart package
- [ ] T115 [P] [US5] Implement daily/weekly/monthly earnings chart (line chart)
- [ ] T116 [P] [US5] Create `commission_filters.dart` widget for date range and status filters
- [ ] T117 [US5] Wire up filters to refresh commission list

**Commission Data Models**

- [ ] T118 [P] [US5] Create `commission_record.dart` model in `apps/pos_admin/lib/features/commissions/models/`
- [ ] T119 [P] [US5] Add Hive type adapter for offline storage
- [ ] T120 [P] [US5] Create `referral_stats.dart` model for aggregated statistics
- [ ] T121 [US5] Implement JSON serialization/deserialization methods

**API Endpoints (SvelteKit)**

- [ ] T122 [P] [US5] Create `/api/commissions` GET endpoint in `apps/storefront/src/routes/api/commissions/+server.ts`
- [ ] T123 [P] [US5] Implement pagination, filtering, sorting logic
- [ ] T124 [P] [US5] Create `/api/commissions/[id]` GET endpoint for commission details
- [ ] T125 [P] [US5] Create `/api/commissions/summary` GET endpoint for aggregated data
- [ ] T126 [P] [US5] Create `/api/commissions/export` GET endpoint for CSV export
- [ ] T127 [US5] Add authorization checks (tenant can only see their own commissions)

**Integration Tests**

- [ ] T128 [P] [US5] Create Flutter widget test for commission dashboard in `apps/pos_admin/test/commission_dashboard_test.dart`
- [ ] T129 [P] [US5] Test commission list rendering with mock data
- [ ] T130 [P] [US5] Test filters (date range, status, transaction type)
- [ ] T131 [P] [US5] Test offline mode (display cached data when no connection)
- [ ] T132 [US5] Test sync functionality (verify new commissions appear after sync)

**Checkpoint**: At this point, User Story 5 should be fully functional - tenants can view and track all commissions

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories and final QA

**Accessibility & UX**

- [ ] T133 [P] Add ARIA labels to commission dashboard tables and charts
- [ ] T134 [P] Ensure keyboard navigation works for all commission components
- [ ] T135 [P] Add currency formatting semantic markup (`<data value="900">₦900</data>`)
- [ ] T136 [P] Test screen reader compatibility for commission dashboard

**Performance Optimization**

- [ ] T137 [P] Add database indexes for common commission queries (tenant_id, created_at, status)
- [ ] T138 [P] Implement pagination for commission history (50 items per page)
- [ ] T139 [P] Lazy load commission charts (dynamic import in SvelteKit)
- [ ] T140 Optimize materialized view refresh (scheduled nightly cron job)

**Security Hardening**

- [ ] T141 [P] Review RLS policies for any potential cross-tenant data leaks
- [ ] T142 [P] Add rate limiting to commission query endpoints (100 req/min per tenant)
- [ ] T143 [P] Add input validation for commission calculation (Zod schemas)
- [ ] T144 Audit commission calculation logs for any suspicious patterns

**Documentation**

- [ ] T145 [P] Update quickstart.md with actual implementation notes from development
- [ ] T146 [P] Add inline code documentation (JSDoc/Dartdoc) for commission services
- [ ] T147 [P] Create commission troubleshooting guide in docs/
- [ ] T148 Document commission dispute resolution process

**Final Validation**

- [ ] T149 Run all commission calculation tests (pgTAP, Vitest, Flutter) - must achieve 100% pass
- [ ] T150 Execute complete user journey from quickstart.md (end-to-end validation)
- [ ] T151 Verify commission accuracy with manual spot checks (compare DB amounts to expected formulas)
- [ ] T152 Test offline dashboard functionality (disconnect network, verify cached data)
- [ ] T153 Load test commission queries (simulate 10,000 concurrent sessions)
- [ ] T154 Run TypeScript type checking (`tsc --noEmit`) - must pass
- [ ] T155 Run ESLint on all new/modified files - must pass
- [ ] T156 Build production bundles (SvelteKit + Flutter) - must succeed

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-7)**: All depend on Foundational phase completion
  - US1 (Session Tracking): Can start after Foundational - No dependencies on other stories
  - US2 (Commission Calculation): Can start after Foundational - No dependencies on other stories
  - US3 (Multi-Service): Depends on US1 + US2 (needs session tracking and calculation logic)
  - US4 (Fulfillment Routing): Depends on US1 (needs session to determine referrer type)
  - US5 (Dashboard): Can start after Foundational - Displays commissions created by US2
- **Polish (Phase 8)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - INDEPENDENT ✓
- **User Story 2 (P1)**: Can start after Foundational (Phase 2) - INDEPENDENT ✓
- **User Story 3 (P2)**: Depends on US1 + US2 (multi-service needs session + calculation)
- **User Story 4 (P2)**: Depends on US1 (routing needs session to check referrer type)
- **User Story 5 (P3)**: Can start after Foundational - INDEPENDENT ✓ (dashboard displays existing data)

### Suggested MVP Scope

**Minimum Viable Product = User Story 1 + User Story 2**

1. Complete Phase 1: Setup (T001-T004)
2. Complete Phase 2: Foundational (T005-T031) - **CRITICAL CHECKPOINT**
3. Complete Phase 3: User Story 1 (T032-T044) - Session tracking works
4. Complete Phase 4: User Story 2 (T045-T068) - Commission calculation accurate
5. **STOP and VALIDATE**: Test end-to-end flow (session → checkout → commission calculated)
6. **MVP COMPLETE**: Platform can track referrals and calculate commissions accurately

### Parallel Opportunities

**Phase 1 (Setup)**: All tasks can run in parallel (T001-T004)

**Phase 2 (Foundational)**:
- Database tables (T005-T013) can be done sequentially in migration
- Functions (T014-T015) can run parallel after tables
- Triggers (T016-T019) can run parallel after functions
- RLS policies (T020-T023) can run parallel after tables
- Tests (T027-T030) can all run in parallel

**User Story 1**: Tasks T032-T040 can run in parallel (different files), tests T041-T044 all parallel

**User Story 2**:
- Services (T045-T049) parallel
- Edge Function (T050-T055) sequential within story
- Component (T056-T059) parallel with tests
- Tests (T060-T065) all parallel

**User Story 3**: Services (T069-T071) parallel, tests (T079-T082) all parallel

**User Story 4**: Services (T083-T086) parallel, routes (T087-T088) parallel, tests (T097-T101) all parallel

**User Story 5**:
- Services (T102-T107) parallel
- Screens (T108-T110) parallel
- Widgets (T112-T117) all parallel
- Models (T118-T121) all parallel
- API endpoints (T122-T127) all parallel
- Tests (T128-T132) all parallel

**Phase 8 (Polish)**: Most tasks can run in parallel (grouped by type)

---

## Parallel Example: User Story 2 (Commission Calculation)

```bash
# Launch all services in parallel:
Task: "Create CommissionCalculator service in apps/storefront/src/lib/services/commissionCalculator.ts"
Task: "Implement calculateServiceCommission method"
Task: "Implement calculateProductCommission method"

# Launch all tests in parallel:
Task: "Create Vitest test for service commission with referrer"
Task: "Create Vitest test for service commission without referrer"
Task: "Create Vitest test for product commission with referrer"
Task: "Create Vitest test for product commission without referrer"
Task: "Create property-based test to verify totals balance"
```

---

## Implementation Strategy

### MVP First (User Stories 1 + 2 Only) - RECOMMENDED

1. Complete Phase 1: Setup (4 tasks)
2. Complete Phase 2: Foundational (27 tasks) - **CRITICAL - blocks all stories**
3. Complete Phase 3: User Story 1 (13 tasks)
4. Complete Phase 4: User Story 2 (24 tasks)
5. **STOP and VALIDATE**: Test MVP independently (session tracking + commission calculation)
6. **MVP READY**: Deploy and demo core value (referral tracking with accurate commissions)

### Incremental Delivery (Add Stories Progressively)

1. Setup + Foundational → Foundation ready (31 tasks)
2. Add User Story 1 → Test independently → Deploy (MVP Core)
3. Add User Story 2 → Test independently → Deploy (MVP Complete - 100% commission accuracy)
4. Add User Story 3 → Test independently → Deploy (Multi-service support)
5. Add User Story 4 → Test independently → Deploy (Guaranteed fulfillment)
6. Add User Story 5 → Test independently → Deploy (Full dashboard)
7. Polish phase → Final QA → Production release

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together (31 tasks)
2. Once Foundational is done:
   - **Developer A**: User Story 1 (13 tasks) + User Story 4 (19 tasks) - Related: session + routing
   - **Developer B**: User Story 2 (24 tasks) + User Story 3 (14 tasks) - Related: calculation + multi-service
   - **Developer C**: User Story 5 (31 tasks) - Independent: dashboard
3. Stories complete and integrate independently

---

## Summary

**Total Tasks**: 156 tasks
- **Phase 1 (Setup)**: 4 tasks
- **Phase 2 (Foundational)**: 27 tasks
- **Phase 3 (US1)**: 13 tasks
- **Phase 4 (US2)**: 24 tasks
- **Phase 5 (US3)**: 14 tasks
- **Phase 6 (US4)**: 19 tasks
- **Phase 7 (US5)**: 31 tasks
- **Phase 8 (Polish)**: 24 tasks

**MVP Scope**: 68 tasks (Setup + Foundational + US1 + US2)

**Critical Success Factors**:
1. ✅ Foundational phase MUST complete before user stories (blocks everything)
2. ✅ Commission calculation tests MUST achieve 100% accuracy (SC-002 requirement)
3. ✅ RLS policies MUST prevent cross-tenant data leaks (constitutional requirement)
4. ✅ Each user story MUST be independently testable (per spec requirements)

**Parallel Opportunities**: 78 tasks marked [P] can run in parallel within their phase

---

## Notes

- [P] tasks = different files, no dependencies within phase
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Tests for commission accuracy are REQUIRED (constitutional + spec requirement)
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- **CRITICAL**: Do not skip Foundational phase - it blocks all user story work
