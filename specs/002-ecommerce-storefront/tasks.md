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

- [ ] T005 [P] Implement validation schema for database entities (Zod) in `apps/storefront/src/lib/types/`
- [ ] T006 [P] Create Supabase client and auth helpers in `apps/storefront/src/lib/services/supabase.ts`
- [ ] T007 Apply database migration `20260211_storefront_schema.sql` (Tables, RLS, Indices)
- [ ] T008 Generate TypeScript types from Supabase schema
- [ ] T009 [P] Create shared pricing utilities in `apps/storefront/src/lib/storefront/pricing.ts` (Fees calculation)
- [ ] T010 [P] Create plan-based feature gates in `apps/storefront/src/lib/storefront/plans.ts`
- [ ] T010a [P] Implement Product Count Limit enforcement (100 for Free)
- [ ] T010b [P] Implement Staff Count Limit enforcement (3 for Growth)

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Guest Product Browsing & Checkout (Priority: P1) 🎯 MVP

**Goal**: Guests can browse products, search, add to cart, and complete checkout with Paystack payment.

**Independent Test**: Visit storefront URL, browse, add to cart, checkout as guest using Paystack.

### Implementation for User Story 1

- [ ] T011 [P] [US1] Create Product Card & Grid components in `apps/storefront/src/lib/components/`
- [ ] T012 [P] [US1] Implement Product List page `routes/+page.svelte` (Fetch & Display)
- [ ] T013 [P] [US1] Implement Product Detail page `routes/[slug]/+page.svelte` (Details & Variants)
- [ ] T014 [US1] Implement Shopping Cart state store `stores/cart.ts`
- [ ] T015 [US1] Implement Cart page `routes/cart/+page.svelte` (View, Update, Remove)
- [ ] T016 [US1] Implement Checkout Form component `components/CheckoutForm.svelte` (Delivery Info)
- [ ] T017 [US1] Implement Delivery Method selection logic (with fee calculation) in Checkout
- [ ] T018 [US1] Integrate Paystack Payment flow in `routes/checkout/+page.svelte`
- [ ] T019 [US1] Implement Order Confirmation page `routes/order/[id]/+page.svelte`
- [ ] T020 [US1] Implement Paystack Webhook handler `routes/api/payment/callback/+server.ts`

**Checkpoint**: At this point, User Story 1 should be fully functional and testable independently

---

## Phase 4: User Story 2 - Customer Authentication (Priority: P2)

**Goal**: Returning customers can sign in (Google/Apple) to save delivery info and view order history.

**Independent Test**: Sign in via Google/Apple, verify session persistence, checkout with auto-filled info.

### Implementation for User Story 2

- [ ] T021 [P] [US2] Configure Google & Apple OAuth providers in Supabase
- [ ] T022 [P] [US2] Implement Auth Store `stores/auth.ts` inside SvelteKit
- [ ] T023 [US2] Implement Sign In / Sign Up UI components
- [ ] T024 [US2] Update Checkout flow to auto-fill authenticated user data
- [ ] T025 [US2] Implement Order History page `routes/orders/+page.svelte`
- [ ] T026 [US2] Implement auto-linking of guest orders to account by phone number

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently

---

## Phase 5: User Story 3 - Product Search and Filtering (Priority: P3)

**Goal**: Customers can filter products by category, price, and (for Business plans) branch location.

**Independent Test**: Use search bar and filters, verify product list updates correctly.

### Implementation for User Story 3

- [ ] T027 [P] [US3] Implement Search Bar component `components/SearchBar.svelte`
- [ ] T028 [P] [US3] Implement Filter Sidebar component (Category, Price)
- [ ] T029 [US3] Update Product List API to support filter parameters
- [ ] T030 [US3] Implement optimized text search query in Supabase (RPC or index)
- [ ] T031 [US3] Add Branch Location filter logic (Business Plan only)

**Checkpoint**: All user stories should now be independently functional

---

## Phase 6: User Story 4 - Live Chat Support (Priority: P4)

**Goal**: Real-time chat with rich media support (Images, Voice, PDF).

**Independent Test**: Open chat, send text/media, receive response from agent.

### Implementation for User Story 4

- [ ] T032 [P] [US4] Implement Chat Widget component `components/ChatWidget.svelte`
- [ ] T033 [P] [US4] Implement WebSocket client in `services/chat.ts`
- [ ] T034 [US4] Implement Chat API routes `routes/api/chat/+server.ts`
- [ ] T035 [US4] Implement File Upload API for chat attachments `routes/api/chat/upload/+server.ts`
- [ ] T036 [US4] Implement Media rendering in chat (Image, Audio Player, PDF link)
- [ ] T037 [US4] Implement Plan-based chat access logic (Owner-only vs Agent)

---

## Phase 7: User Story 5 - AI Agent Chat (Business Plan Only) (Priority: P5)

**Goal**: Automated AI support when agents are busy.

**Independent Test**: Chat with AI on Business plan store, test product questions and image recognition.

### Implementation for User Story 5

- [ ] T038 [P] [US5] Implement AI Agent Edge Function `supabase/functions/chat-ai-agent/`
- [ ] T039 [US5] Integrate AI Agent with Chat WebSocket service
- [ ] T040 [US5] Implement Image Recognition logic in AI Agent
- [ ] T041 [US5] Implement "Handover to Human" flow

---

## Phase 8: User Story 6 - Multi-Branch Customer Affiliation (Priority: P6)

**Goal**: Unified account across multiple branches of the same tenant.

**Independent Test**: Sign in on Branch A, switch to Branch B, verify session and order history.

### Implementation for User Story 6

- [ ] T042 [P] [US6] Review and verify Session handling for multi-branch access
- [ ] T043 [US6] Update Order History to show branch context
- [ ] T044 [US6] Implement Branch Switcher UI (if applicable for Business plan)

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [ ] T045 [P] Setup PWA Manifest and Service Worker
- [ ] T046 Perform Accessibility Audit (Keyboard nav, ARIA)
- [ ] T047 Optimize Image Loading and Bundle Size
- [ ] T048 Verify Security RLS policies
- [ ] T049 Write Documentation (User Guide updates)
- [ ] T050 [P] Implement Dormancy/Hibernation Protocol (Edge Function/Cron)
- [ ] T051 [P] Implement Notification Restrictions (No SMS/WhatsApp for Free Plan)

---
