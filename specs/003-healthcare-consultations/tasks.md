# Tasks: Healthcare Provider Directory and Telemedicine Consultations

**Input**: Design documents from `/specs/003-healthcare-consultations/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: Not explicitly requested in feature specification - implementation tasks only

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

This is a monorepo with SvelteKit storefront at `apps/storefront/`. Database migrations at repository root `supabase/migrations/`.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure for healthcare feature

- [ ] T001 Create healthcare feature directory structure in apps/storefront/src/routes/healthcare/
- [ ] T002 Install Agora Web SDK 4.x dependency in apps/storefront/package.json
- [ ] T003 [P] Configure environment variables for Agora (PUBLIC_AGORA_APP_ID) in apps/storefront/.env
- [ ] T004 [P] Create healthcare TypeScript types in apps/storefront/src/lib/types/healthcare.ts
- [ ] T005 [P] Add healthcare routes to SvelteKit routing structure (providers/, consultations/, prescriptions/)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core database and infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [ ] T006 Create database migration file supabase/migrations/[timestamp]_healthcare_consultation.sql
- [ ] T007 Implement healthcare_providers entity with RLS policies in migration
- [ ] T008 [P] Implement provider_availability_templates entity with RLS policies in migration
- [ ] T009 [P] Implement provider_time_slots entity with optimistic locking and RLS policies in migration
- [ ] T010 Implement consultations entity with Agora fields and RLS policies in migration
- [ ] T011 [P] Implement consultation_messages entity with RLS policies in migration
- [ ] T012 [P] Implement prescriptions entity with auto-expiration trigger and RLS policies in migration
- [ ] T013 [P] Implement consultation_transactions entity with commission tracking and RLS policies in migration
- [ ] T014 [P] Implement favorite_providers entity with RLS policies in migration
- [ ] T015 Add all 35 database indexes per data-model.md to migration
- [ ] T016 Add data integrity constraints (7 constraints) to migration
- [ ] T017 Create prescription auto-expiration trigger function in migration
- [ ] T018 Seed platform commission rate config (healthcare_commission_rate = 0.15) in migration
- [ ] T019 Run database migration on local Supabase instance
- [ ] T020 Generate TypeScript types from Supabase schema for healthcare entities
- [ ] T021 [P] Create base healthcare layout component in apps/storefront/src/lib/components/healthcare/HealthcareLayout.svelte
- [ ] T022 [P] Create shared error handling component in apps/storefront/src/lib/components/healthcare/ErrorDisplay.svelte
- [ ] T023 [P] Create loading state component in apps/storefront/src/lib/components/healthcare/LoadingSpinner.svelte
- [ ] T024 Create Supabase client wrapper for healthcare queries in apps/storefront/src/lib/services/supabase-healthcare.ts
- [ ] T025 Implement subscription plan check middleware in apps/storefront/src/lib/middleware/healthcare-access.ts
- [ ] T026 Implement business type check (pharmacy/diagnostic centre only) in apps/storefront/src/lib/middleware/healthcare-access.ts

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Browse and View Healthcare Providers (Priority: P1) 🎯 MVP

**Goal**: Customers can browse a directory of healthcare providers filtered by country, view detailed provider profiles with qualifications and fees, and save providers to favorites for quick access.

**Independent Test**: Visit pharmacy/diagnostic centre storefront, access healthcare provider directory, browse provider listings with filters (specialization, consultation type), view individual provider detail pages with full profile information, add/remove providers from favorites list. Verify country filtering works and feature is hidden on non-healthcare storefronts or free plan businesses.

### Implementation for User Story 1

- [ ] T027 [P] [US1] Create ProviderCard component in apps/storefront/src/lib/components/healthcare/ProviderCard.svelte
- [ ] T028 [P] [US1] Create ProviderProfile component in apps/storefront/src/lib/components/healthcare/ProviderProfile.svelte
- [ ] T029 [P] [US1] Create ProviderFilters component in apps/storefront/src/lib/components/healthcare/ProviderFilters.svelte
- [ ] T030 [P] [US1] Create FavoriteButton component in apps/storefront/src/lib/components/healthcare/FavoriteButton.svelte
- [ ] T031 [US1] Implement GET /api/healthcare/providers endpoint in apps/storefront/src/routes/api/healthcare/providers/+server.ts
- [ ] T032 [US1] Implement GET /api/healthcare/providers/:id endpoint in apps/storefront/src/routes/api/healthcare/providers/[id]/+server.ts
- [ ] T033 [P] [US1] Implement GET /api/healthcare/favorites endpoint in apps/storefront/src/routes/api/healthcare/favorites/+server.ts
- [ ] T034 [P] [US1] Implement POST /api/healthcare/favorites endpoint in apps/storefront/src/routes/api/healthcare/favorites/+server.ts
- [ ] T035 [P] [US1] Implement DELETE /api/healthcare/favorites/:id endpoint in apps/storefront/src/routes/api/healthcare/favorites/[id]/+server.ts
- [ ] T036 [US1] Create provider directory page in apps/storefront/src/routes/healthcare/providers/+page.svelte (Client Component for search)
- [ ] T037 [US1] Create provider directory server load in apps/storefront/src/routes/healthcare/providers/+page.server.ts
- [ ] T038 [US1] Create provider detail page in apps/storefront/src/routes/healthcare/providers/[id]/+page.svelte
- [ ] T039 [US1] Create provider detail server load in apps/storefront/src/routes/healthcare/providers/[id]/+page.server.ts
- [ ] T040 [US1] Add country-based provider filtering logic to GET /providers endpoint
- [ ] T041 [US1] Add specialization and consultation_type filter support to GET /providers endpoint
- [ ] T042 [US1] Add pagination support (page, limit) to GET /providers endpoint
- [ ] T043 [US1] Implement RLS policy enforcement for provider queries (country filtering)
- [ ] T044 [US1] Add subscription plan check to healthcare routes using middleware
- [ ] T045 [US1] Add business type check (pharmacy/diagnostic centre) to healthcare routes
- [ ] T046 [US1] Handle free plan restriction with upgrade prompt UI

**Checkpoint**: At this point, User Story 1 should be fully functional - customers can browse providers, view profiles, and manage favorites

---

## Phase 4: User Story 2 - Book and Pay for Text-Based Consultations (Priority: P2)

**Goal**: Customers can book text-based chat consultations with providers, pay consultation fees through checkout, and communicate via real-time secure messaging interface.

**Independent Test**: Select a provider from directory, choose chat consultation option, complete payment checkout, receive confirmation, access chat interface, exchange messages with provider in real-time, provider marks consultation complete, view completed chat transcript in consultation history.

### Implementation for User Story 2

- [ ] T047 [P] [US2] Create ConsultationBooking component in apps/storefront/src/lib/components/healthcare/ConsultationBooking.svelte
- [ ] T048 [P] [US2] Create ChatInterface component (Client Component) in apps/storefront/src/lib/components/healthcare/ChatInterface.svelte
- [ ] T049 [P] [US2] Create ConsultationCard component in apps/storefront/src/lib/components/healthcare/ConsultationCard.svelte
- [ ] T050 [US2] Implement POST /api/healthcare/consultations/book endpoint in apps/storefront/src/routes/api/healthcare/consultations/book/+server.ts
- [ ] T051 [US2] Integrate payment gateway for consultation fee processing in booking endpoint
- [ ] T052 [US2] Implement consultation creation logic (status: pending, payment redirect)
- [ ] T053 [P] [US2] Implement GET /api/healthcare/consultations endpoint in apps/storefront/src/routes/api/healthcare/consultations/+server.ts
- [ ] T054 [P] [US2] Implement GET /api/healthcare/consultations/:id endpoint in apps/storefront/src/routes/api/healthcare/consultations/[id]/+server.ts
- [ ] T055 [US2] Implement GET /api/healthcare/consultations/:id/messages endpoint in apps/storefront/src/routes/api/healthcare/consultations/[id]/messages/+server.ts
- [ ] T056 [US2] Implement POST /api/healthcare/consultations/:id/messages endpoint in apps/storefront/src/routes/api/healthcare/consultations/[id]/messages/+server.ts
- [ ] T057 [US2] Create Supabase Realtime subscription service in apps/storefront/src/lib/services/chat.ts
- [ ] T058 [US2] Implement real-time message delivery using Supabase Realtime channels
- [ ] T059 [US2] Add typing indicator support to chat interface
- [ ] T060 [US2] Add read receipts tracking to chat messages
- [ ] T061 [US2] Create chat consultation page in apps/storefront/src/routes/healthcare/consultations/chat/[id]/+page.svelte
- [ ] T062 [US2] Create chat consultation server load in apps/storefront/src/routes/healthcare/consultations/chat/[id]/+page.server.ts
- [ ] T063 [US2] Create consultations history page in apps/storefront/src/routes/healthcare/consultations/+page.svelte
- [ ] T064 [US2] Create consultations history server load in apps/storefront/src/routes/healthcare/consultations/+page.server.ts
- [ ] T065 [US2] Add status filtering (pending/in_progress/completed/cancelled) to consultations list
- [ ] T066 [US2] Add consultation type filtering to consultations list
- [ ] T067 [US2] Implement commission calculation on consultation completion (backend trigger or API)
- [ ] T068 [US2] Create consultation_transactions record when payment completes
- [ ] T069 [US2] Add RLS policies for consultations (patients see own, providers see assigned)
- [ ] T070 [US2] Add RLS policies for consultation_messages
- [ ] T071 [US2] Handle payment callback/webhook to update consultation payment_status
- [ ] T072 [US2] Add file attachment support to chat messages (Supabase Storage integration)

**Checkpoint**: At this point, User Stories 1 AND 2 work independently - customers can book and complete chat consultations

---

## Phase 5: User Story 3 - Schedule Office Visit Appointments (Priority: P3)

**Goal**: Customers can book in-person office visit appointments by viewing provider availability calendar, selecting time slots, completing payment at booking, and receiving confirmation with location details.

**Independent Test**: View provider profile, select office visit option, browse availability calendar showing available time slots, select preferred date/time, complete payment checkout, receive booking confirmation with appointment details and provider's clinic address, view appointment in upcoming consultations list with reminder notifications.

### Implementation for User Story 3

- [ ] T073 [P] [US3] Create AvailabilityCalendar component in apps/storefront/src/lib/components/healthcare/AvailabilityCalendar.svelte
- [ ] T074 [P] [US3] Create TimeSlotPicker component in apps/storefront/src/lib/components/healthcare/TimeSlotPicker.svelte
- [ ] T075 [P] [US3] Create AppointmentConfirmation component in apps/storefront/src/lib/components/healthcare/AppointmentConfirmation.svelte
- [ ] T076 [US3] Implement GET /api/healthcare/providers/:id/availability endpoint in apps/storefront/src/routes/api/healthcare/providers/[id]/availability/+server.ts
- [ ] T077 [US3] Implement time slot materialization logic (generate slots from templates for next 30 days)
- [ ] T078 [US3] Add consultation_type filtering to availability endpoint (video/audio/office_visit)
- [ ] T079 [US3] Add date range filtering (start_date, end_date) to availability endpoint
- [ ] T080 [US3] Update POST /api/healthcare/consultations/book to handle scheduled consultations (slot_id required)
- [ ] T081 [US3] Implement optimistic locking for slot booking (version field check)
- [ ] T082 [US3] Add slot status transition logic (available → held_for_payment → booked)
- [ ] T083 [US3] Implement 5-minute hold timeout for unpaid bookings (slot release)
- [ ] T084 [US3] Add double-booking prevention (UNIQUE constraint on provider_id, date, start_time)
- [ ] T085 [US3] Create office visit booking page in apps/storefront/src/routes/healthcare/consultations/office/[id]/+page.svelte
- [ ] T086 [US3] Create office visit booking server load in apps/storefront/src/routes/healthcare/consultations/office/[id]/+page.server.ts
- [ ] T087 [US3] Add provider clinic/office address display to booking confirmation
- [ ] T088 [US3] Add timezone conversion support for scheduled consultations
- [ ] T089 [US3] Implement appointment reminder notification (24h before scheduled time)
- [ ] T090 [US3] Add cancellation flow with refund policy (24h+ = full refund, <24h = no refund)
- [ ] T091 [US3] Implement POST /api/healthcare/consultations/:id/cancel endpoint in apps/storefront/src/routes/api/healthcare/consultations/[id]/cancel/+server.ts
- [ ] T092 [US3] Add refund processing integration for cancelled appointments
- [ ] T093 [US3] Update consultation status and transaction records on cancellation

**Checkpoint**: At this point, User Stories 1, 2, AND 3 work independently - office visit scheduling is fully functional

---

## Phase 6: User Story 4 - Conduct Video and Audio Consultations (Priority: P4)

**Goal**: Customers can join real-time video or audio consultations at scheduled times using Agora SDK, with call quality controls, duration warnings, and automatic disconnection after grace period.

**Independent Test**: Schedule video/audio consultation with provider, complete payment at booking, receive scheduled time confirmation, join consultation at scheduled time via "Join Consultation" link, conduct live video/audio session with clear quality, see 5-minute warning before time expires, call continues for 5-minute grace period, automatic disconnection after grace period, view completed consultation record.

### Implementation for User Story 4

- [ ] T094 [P] [US4] Create Agora service wrapper in apps/storefront/src/lib/services/agora.ts
- [ ] T095 [P] [US4] Create VideoRoom component (Client Component) in apps/storefront/src/lib/components/healthcare/VideoRoom.svelte
- [ ] T096 [P] [US4] Create CallControls component in apps/storefront/src/lib/components/healthcare/CallControls.svelte
- [ ] T097 [P] [US4] Create DurationWarning component in apps/storefront/src/lib/components/healthcare/DurationWarning.svelte
- [ ] T098 [US4] Implement Agora token generation utility in apps/storefront/src/lib/healthcare/agora-token-generator.ts
- [ ] T099 [US4] Implement POST /api/healthcare/consultations/:id/join endpoint in apps/storefront/src/routes/api/healthcare/consultations/[id]/join/+server.ts
- [ ] T100 [US4] Add Agora RTC token generation in join endpoint (patient side)
- [ ] T101 [US4] Add consultation time validation (can't join too early or too late)
- [ ] T102 [US4] Create video consultation page in apps/storefront/src/routes/healthcare/consultations/video/[id]/+page.svelte
- [ ] T103 [US4] Create video consultation server load in apps/storefront/src/routes/healthcare/consultations/video/[id]/+page.server.ts
- [ ] T104 [US4] Implement Agora SDK initialization in VideoRoom component
- [ ] T105 [US4] Add local video/audio track creation and publishing
- [ ] T106 [US4] Add remote video/audio track subscription and display
- [ ] T107 [US4] Add mute/unmute microphone control
- [ ] T108 [US4] Add enable/disable camera control
- [ ] T109 [US4] Add camera switch (front/back) for mobile
- [ ] T110 [US4] Add speaker/earpiece toggle
- [ ] T111 [US4] Implement duration countdown timer (from slot_duration)
- [ ] T112 [US4] Implement 5-minute warning modal before time expires
- [ ] T113 [US4] Implement grace period logic (5 minutes after allocated time)
- [ ] T114 [US4] Implement automatic call disconnection after grace period expires
- [ ] T115 [US4] Add network quality indicator display
- [ ] T116 [US4] Add video quality degradation handling (suggest audio-only)
- [ ] T117 [US4] Add end call button with confirmation
- [ ] T118 [US4] Update consultation status to completed when call ends
- [ ] T119 [US4] Trigger commission calculation on consultation completion
- [ ] T120 [US4] Add call duration tracking to consultation record
- [ ] T121 [US4] Handle Agora SDK errors and connection failures gracefully
- [ ] T122 [US4] Add audio-only mode support (same flow, no video tracks)

**Checkpoint**: At this point, all consultation types work - chat, office visit, video, and audio

---

## Phase 7: User Story 5 - Receive and View Prescriptions (Priority: P5)

**Goal**: Patients receive digital prescriptions from providers after consultations, view prescription details including medications, dosages, and instructions, access prescription history, and manually search pharmacy catalog for prescribed medications.

**Independent Test**: Complete consultation with provider, receive prescription notification with 90-day expiration, view prescription details showing medication names, dosages, frequency, duration, special instructions, prescribing doctor details, access prescription history with filtering and search, manually search pharmacy catalog for prescribed medications and add to cart, verify expired prescriptions (>90 days) are marked and cannot be used.

### Implementation for User Story 5

- [ ] T123 [P] [US5] Create PrescriptionView component in apps/storefront/src/lib/components/healthcare/PrescriptionView.svelte
- [ ] T124 [P] [US5] Create PrescriptionCard component in apps/storefront/src/lib/components/healthcare/PrescriptionCard.svelte
- [ ] T125 [P] [US5] Create MedicationList component in apps/storefront/src/lib/components/healthcare/MedicationList.svelte
- [ ] T126 [US5] Implement GET /api/healthcare/prescriptions endpoint in apps/storefront/src/routes/api/healthcare/prescriptions/+server.ts
- [ ] T127 [US5] Add prescription status filtering (active/expired/fulfilled) to prescriptions endpoint
- [ ] T128 [US5] Add pagination support to prescriptions endpoint
- [ ] T129 [US5] Implement GET /api/healthcare/prescriptions/:id endpoint in apps/storefront/src/routes/api/healthcare/prescriptions/[id]/+server.ts
- [ ] T130 [US5] Create prescriptions list page in apps/storefront/src/routes/healthcare/prescriptions/+page.svelte
- [ ] T131 [US5] Create prescriptions list server load in apps/storefront/src/routes/healthcare/prescriptions/+page.server.ts
- [ ] T132 [US5] Create prescription detail page in apps/storefront/src/routes/healthcare/prescriptions/[id]/+page.svelte
- [ ] T133 [US5] Create prescription detail server load in apps/storefront/src/routes/healthcare/prescriptions/[id]/+page.server.ts
- [ ] T134 [US5] Add prescription expiration date display (90 days from issue)
- [ ] T135 [US5] Add expired prescription indicator (visual styling)
- [ ] T136 [US5] Add "Search Catalog" link from prescription detail to pharmacy product search
- [ ] T137 [US5] Add provider credentials and signature to prescription display
- [ ] T138 [US5] Add prescription PDF export functionality (optional)
- [ ] T139 [US5] Add RLS policies for prescriptions (patients see own, providers see issued)
- [ ] T140 [US5] Add search/filter functionality to prescription history page
- [ ] T141 [US5] Add prescription notification when issued by provider

**Checkpoint**: All user stories complete - full healthcare consultation workflow from discovery to prescription

---

## Phase 8: Additional Consultation Features

**Purpose**: Remaining consultation management features across all types

- [ ] T142 [P] Implement POST /api/healthcare/consultations/:id/rate endpoint in apps/storefront/src/routes/api/healthcare/consultations/[id]/rate/+server.ts
- [ ] T143 [P] Create RatingForm component in apps/storefront/src/lib/components/healthcare/RatingForm.svelte
- [ ] T144 [P] Add rating prompt after consultation completion
- [ ] T145 [P] Update provider average_rating calculation when new rating submitted
- [ ] T146 Add notification system integration for consultation events (booking, reminders, completion)
- [ ] T147 Create email notification templates for consultations
- [ ] T148 Create SMS notification templates for appointment reminders
- [ ] T149 Add consultation status real-time updates using Supabase Realtime
- [ ] T150 Implement consultation history export (PDF/CSV)

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [ ] T151 [P] Add loading states to all consultation booking flows
- [ ] T152 [P] Add error boundaries to healthcare components
- [ ] T153 [P] Implement retry logic for failed API calls
- [ ] T154 [P] Add success notifications for bookings, payments, prescription received
- [ ] T155 [P] Add empty states for consultation history, prescriptions, favorites
- [ ] T156 Optimize provider directory query performance (caching, pagination)
- [ ] T157 Optimize consultation history query performance (denormalized provider data)
- [ ] T158 Add responsive design for all healthcare pages (mobile/tablet)
- [ ] T159 [P] Add keyboard navigation support for healthcare UI
- [ ] T160 [P] Add screen reader support (ARIA labels) for consultation controls
- [ ] T161 [P] Add alt text for provider profile photos
- [ ] T162 [P] Ensure color is not sole indicator for consultation status
- [ ] T163 Add security audit for healthcare data encryption (transport + at-rest)
- [ ] T164 Add logging for all healthcare operations (audit trail)
- [ ] T165 Verify RLS policies prevent cross-tenant data access
- [ ] T166 Add performance monitoring for video/audio quality
- [ ] T167 Add analytics tracking for consultation funnel (browse → book → complete)
- [ ] T168 Validate all 8 quickstart.md implementation phases
- [ ] T169 Create user documentation for healthcare features
- [ ] T170 Add admin documentation for commission tracking

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-7)**: All depend on Foundational phase completion
  - User stories can proceed in parallel (if staffed)
  - Or sequentially in priority order (P1 → P2 → P3 → P4 → P5)
- **Additional Features (Phase 8)**: Can start after any user story completion
- **Polish (Phase 9)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P2)**: Can start after Foundational (Phase 2) - Builds on US1 provider directory but independently testable
- **User Story 3 (P3)**: Can start after Foundational (Phase 2) - Builds on US1 provider directory, shares booking flow with US2, independently testable
- **User Story 4 (P4)**: Can start after Foundational (Phase 2) - Builds on US3 scheduling infrastructure, independently testable
- **User Story 5 (P5)**: Can start after US2/US4 (requires consultation completion) - Independently testable

### Within Each User Story

- Components can be built in parallel (marked [P])
- API routes can be built in parallel with components (marked [P])
- Pages depend on both components and API routes
- Integration tasks come after core implementation

### Parallel Opportunities

- All Setup tasks marked [P] can run in parallel
- All Foundational entity implementations (T007-T014) can run in parallel
- All Foundational components (T021-T023) can run in parallel
- Once Foundational phase completes, US1 can start immediately (MVP path)
- Components within each user story marked [P] can run in parallel
- API routes within each user story marked [P] can run in parallel
- Different user stories can be worked on in parallel by different team members (after Foundational)

---

## Parallel Example: User Story 1

```bash
# Launch all components for User Story 1 together:
Task: T027 - ProviderCard component
Task: T028 - ProviderProfile component
Task: T029 - ProviderFilters component
Task: T030 - FavoriteButton component

# Launch all API routes for User Story 1 together:
Task: T031 - GET /providers endpoint
Task: T032 - GET /providers/:id endpoint
Task: T033 - GET /favorites endpoint
Task: T034 - POST /favorites endpoint
Task: T035 - DELETE /favorites/:id endpoint
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001-T005)
2. Complete Phase 2: Foundational (T006-T026) - CRITICAL
3. Complete Phase 3: User Story 1 (T027-T046)
4. **STOP and VALIDATE**: Test provider directory, favorites, access restrictions
5. Deploy/demo if ready

**MVP Deliverable**: Customers on paid pharmacy/diagnostic centre storefronts can browse country-wide provider directory, view provider profiles, and save favorites.

### Incremental Delivery

1. Setup + Foundational → Database and infrastructure ready
2. Add User Story 1 → Test independently → Deploy/Demo (MVP!)
3. Add User Story 2 → Test chat consultations → Deploy/Demo
4. Add User Story 3 → Test office visit booking → Deploy/Demo
5. Add User Story 4 → Test video/audio calls → Deploy/Demo
6. Add User Story 5 → Test prescriptions → Deploy/Demo
7. Each story adds value without breaking previous stories

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together (T001-T026)
2. Once Foundational is done:
   - **Developer A**: User Story 1 (Provider Directory) - T027-T046
   - **Developer B**: User Story 2 (Chat Consultations) - T047-T072 (after US1 API routes)
   - **Developer C**: Database optimization and monitoring
3. After US1 and US2 complete:
   - **Developer A**: User Story 3 (Office Visits) - T073-T093
   - **Developer B**: User Story 4 (Video/Audio) - T094-T122
   - **Developer C**: User Story 5 (Prescriptions) - T123-T141
4. Stories complete and integrate independently

---

## Critical Success Factors

1. **Database Foundation First**: All 8 entities with RLS policies MUST be complete before ANY user story work (Phase 2)
2. **MVP Focus**: User Story 1 delivers immediate value - prioritize for early feedback
3. **Independent Testing**: Each user story should work standalone - test before moving to next priority
4. **Agora Integration**: User Story 4 is highest risk - allocate experienced developer
5. **Payment Gateway**: Existing storefront payment integration must support healthcare consultation fees
6. **Commission Accuracy**: Financial calculations (15% commission) MUST be unit-tested
7. **Security First**: RLS policies prevent data leaks - validate with different user roles
8. **Performance Goals**: Meet SC-001 through SC-012 benchmarks from spec.md

---

## Notes

- [P] tasks = different files, no dependencies, can run in parallel
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- SvelteKit uses +page.svelte (Client Components for interactivity) and +page.server.ts (Server Components for data loading)
- Avoid: vague tasks, same file conflicts, cross-story dependencies that break independence
- Flutter medic app backend (separate repository) handles provider-side API - not included in these tasks
