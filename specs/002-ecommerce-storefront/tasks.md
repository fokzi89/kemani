---
description: "Task list for Feature 002: Ecommerce Storefront"
---

# Tasks: Ecommerce Storefront for Tenant Branches

**Input**: Design documents from `/specs/002-ecommerce-storefront/`
**Prerequisites**: plan.md, spec.md, data-model.md

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [x] T001 Create SvelteKit project structure in `apps/storefront/`
- [x] T002 Initialize `apps/storefront/` with TailwindCSS and Shadcn UI
- [x] T003 [P] Configure SvelteKit alias/paths and environment variables
- [x] T004 Install dependencies (Supabase, Paystack, OAuth, Socket.io client)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T005 [P] Implement validation schema for database entities (Zod) in `apps/storefront/src/lib/types/`
- [x] T006 [P] Create Supabase client and auth helpers in `apps/storefront/src/lib/services/supabase.ts`
- [x] T007 Apply database migration `20260213_storefront_schema.sql` (Tables, RLS, Indices)
- [x] T008 Generate TypeScript types from Supabase schema
- [x] T009 [P] Create shared pricing utilities in `apps/storefront/src/lib/storefront/pricing.ts` (Fees calculation)
- [x] T010 [P] Create plan-based feature gates in `apps/storefront/src/lib/storefront/plans.ts`
- [x] T010a [P] Implement Product Count Limit enforcement (100 for Free)
- [x] T010b [P] Implement Staff Count Limit enforcement (3 for Growth)

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Guest Product Browsing & Checkout (Priority: P1) 🎯 MVP

**Goal**: Guests can browse products, search, add to cart, and complete checkout with Paystack payment.

**Independent Test**: Visit storefront URL, browse, add to cart, checkout as guest using Paystack.

### Implementation for User Story 1

- [x] T011 [P] [US1] Create Product Card & Grid components in `apps/storefront/src/lib/components/`
- [x] T012 [P] [US1] Implement Product List page `routes/+page.svelte` (Fetch & Display)
- [x] T013 [P] [US1] Implement Product Detail page `routes/[slug]/+page.svelte` (Details & Variants)
- [x] T014 [US1] Implement Shopping Cart state store `stores/cart.ts`
- [x] T015 [US1] Implement Cart page `routes/cart/+page.svelte` (View, Update, Remove)
- [x] T016 [US1] Implement Checkout Form component `components/CheckoutForm.svelte` (Delivery Info)
- [x] T017 [US1] Implement Delivery Method selection logic (with fee calculation) in Checkout
- [x] T018 [US1] Integrate Paystack Payment flow in `routes/checkout/+page.svelte`
- [x] T019 [US1] Implement Order Confirmation page `routes/order/[id]/+page.svelte`
- [x] T020 [US1] Implement Paystack Webhook handler `routes/api/payment/callback/+server.ts`

**Checkpoint**: At this point, User Story 1 should be fully functional and testable independently

---

## Phase 4: User Story 2 - Customer Authentication (Priority: P2)

**Goal**: Returning customers can sign in (Google/Apple) to save delivery info and view order history.

**Independent Test**: Sign in via Google/Apple, verify session persistence, checkout with auto-filled info.

### Implementation for User Story 2

- [x] T021 [P] [US2] Configure Google & Apple OAuth providers in Supabase (code ready; enable in Supabase Dashboard)
- [x] T022 [P] [US2] Implement Auth Store `stores/auth.ts` inside SvelteKit
- [x] T023 [US2] Implement Sign In / Sign Up UI components
- [x] T024 [US2] Update Checkout flow to auto-fill authenticated user data
- [x] T025 [US2] Implement Order History page `routes/orders/+page.svelte`
- [x] T026 [US2] Implement auto-linking of guest orders to account by phone number (via phone/email query in orders page)

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently

---

## Phase 5: User Story 3 - Product Search and Filtering (Priority: P3)

**Goal**: Customers can filter products by category, price, and (for Business plans) branch location.

**Independent Test**: Use search bar and filters, verify product list updates correctly.

### Implementation for User Story 3

- [x] T027 [P] [US3] Implement Search Bar component `components/SearchBar.svelte`
- [x] T028 [P] [US3] Implement Filter Sidebar component (Category, Price)
- [x] T029 [US3] Update Product List API to support filter parameters
- [x] T030 [US3] Implement optimized text search query in Supabase (RPC or index)
- [x] T031 [US3] Add Branch Location filter logic (Business Plan only)

**Checkpoint**: All user stories should now be independently functional

---

## Phase 6: User Story 4 - Live Chat Support (Priority: P4)

**Goal**: Real-time chat with rich media support (Images, Voice, PDF).

**Independent Test**: Open chat, send text/media, receive response from agent.

### Implementation for User Story 4

- [x] T032 [P] [US4] Implement Chat Widget component `components/ChatWidget.svelte`
- [x] T033 [P] [US4] Implement WebSocket client in `services/chat.ts`
- [x] T034 [US4] Implement Chat API routes `routes/api/chat/+server.ts`
- [x] T035 [US4] Implement File Upload API for chat attachments `routes/api/chat/upload/+server.ts`
- [x] T036 [US4] Implement Media rendering in chat (Image, Audio Player, PDF link)
- [x] T037 [US4] Implement Plan-based chat access logic (Owner-only vs Agent)

---

## Phase 7: User Story 5 - AI Agent Chat (Business Plan Only) (Priority: P5)

**Goal**: Automated AI support when agents are busy.

**Independent Test**: Chat with AI on Business plan store, test product questions and image recognition.

### Implementation for User Story 5

- [x] T038 [P] [US5] Implement AI Agent Edge Function `supabase/functions/chat-ai-agent/`
- [x] T039 [US5] Integrate AI Agent with Chat WebSocket service
- [x] T040 [US5] Implement Image Recognition logic in AI Agent
- [x] T041 [US5] Implement "Handover to Human" flow

---

## Phase 8: User Story 6 - Multi-Branch Customer Affiliation (Priority: P6)

**Goal**: Unified account across multiple branches of the same tenant.

**Independent Test**: Sign in on Branch A, switch to Branch B, verify session and order history.

### Implementation for User Story 6

- [x] T042 [P] [US6] Review and verify Session handling for multi-branch access
- [x] T043 [US6] Update Order History to show branch context
- [x] T044 [US6] Implement Branch Switcher UI (Covered by FilterSidebar T031)

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [x] T045 [P] Setup PWA Manifest and Service Worker
- [x] T046 Perform Accessibility Audit (Keyboard nav, ARIA labels verified)
- [x] T047 Optimize Image Loading and Bundle Size (Lazy loading implemented)
- [x] T048 Verify Security RLS policies (Migration `20260214_storefront_rls.sql` created)
- [x] T049 Write Documentation (User Guide updates)
- [x] T050 [P] Implement Dormancy/Hibernation Protocol (Edge Function/Cron)
- [x] T051 [P] Implement Notification Restrictions (No SMS/WhatsApp for Free Plan)

---
