# Quickstart Implementation Guide
## Healthcare Provider Directory & Telemedicine Consultations

**Date**: 2026-02-21 | **Feature**: 003-healthcare-consultations

This guide provides the implementation sequence for building the healthcare consultation feature across SvelteKit storefront (patient-facing, this repo) and Flutter medic app with backend API (provider-facing, separate repo).

---

## Prerequisites

- [ ] Supabase project with existing multi-tenant schema
- [ ] Agora.io account with App ID and App Certificate
- [ ] Existing payment gateway integration
- [ ] Flutter medic app repository access (separate repo with backend API)

---

## Implementation Phases

### Phase 1: Database Foundation (Week 1)

**Goal**: Establish all 8 healthcare entities with relationships and RLS policies.

**Tasks**:
1. Create migration file: `supabase/migrations/[timestamp]_healthcare_consultation.sql`
2. Implement entities in order (resolve FK dependencies):
   - `healthcare_providers`
   - `provider_availability_templates`
   - `provider_time_slots`
   - `consultations`
   - `consultation_messages`
   - `prescriptions`
   - `consultation_transactions`
   - `favorite_providers`
3. Add all indexes (35 total - see data-model.md)
4. Configure RLS policies (22 policies)
5. Create trigger for prescription status auto-update
6. Seed platform config: `healthcare_commission_rate = 0.15`
7. Test RLS policies with different user roles (patient, provider, anonymous)

**Acceptance**:
- All entities created without errors
- RLS prevents cross-tenant/cross-user data access
- Prescription status auto-updates on expiration

---

### Phase 2: Provider Directory (Storefront) (Week 2)

**Goal**: Patients can browse and view healthcare providers.

**Implementation Order**:

1. **API Routes** (`apps/storefront/src/routes/api/healthcare/`):
   - `providers/+server.ts`: GET /providers (list with filters)
   - `providers/[id]/+server.ts`: GET /providers/:id (details)
   - `favorites/+server.ts`: POST /favorites, GET /favorites
   - `favorites/[id]/+server.ts`: DELETE /favorites/:id

2. **Types** (`apps/storefront/src/lib/types/healthcare.ts`):
   ```typescript
   export interface HealthcareProvider {
     id: string;
     full_name: string;
     specialization: string;
     credentials: string;
     years_of_experience: number;
     profile_photo_url: string;
     average_rating: number;
     total_consultations: number;
     consultation_types: ConsultationType[];
     fees: Record<ConsultationType, number>;
     clinic_address?: Address;
   }

   export type ConsultationType = 'chat' | 'video' | 'audio' | 'office_visit';
   ```

3. **Components** (`apps/storefront/src/lib/components/healthcare/`):
   - `ProviderCard.svelte`: Grid/list item display
   - `ProviderProfile.svelte`: Detailed provider view
   - `ProviderFilters.svelte`: Specialization/type filters

4. **Pages** (`apps/storefront/src/routes/healthcare/providers/`):
   - `+page.svelte`: Provider directory (Client Component for search)
   - `+page.server.ts`: Load providers from API (Server Component)
   - `[id]/+page.svelte`: Provider detail page
   - `[id]/+page.server.ts`: Load provider details + availability

**Acceptance**:
- Provider directory loads and displays providers from tenant's country
- Filters work (specialization, consultation type)
- Provider detail page shows full profile
- Add/remove favorites works

---

### Phase 3: Chat Consultations (Week 3)

**Goal**: Complete chat consultation flow (booking → payment → messaging → completion).

**Implementation Order**:

1. **API Routes**:
   - `consultations/book/+server.ts`: POST /consultations/book (chat type)
   - `consultations/[id]/messages/+server.ts`: GET/POST messages

2. **Components**:
   - `ChatInterface.svelte`: Real-time messaging UI (Client Component)
   - `ConsultationBooking.svelte`: Booking form

3. **Supabase Realtime Integration** (`apps/storefront/src/lib/services/chat.ts`):
   ```typescript
   export function subscribeToMessages(consultationId: string, callback: (message: Message) => void) {
     const channel = supabase
       .channel(`consultation:${consultationId}`)
       .on('postgres_changes', {
         event: 'INSERT',
         schema: 'public',
         table: 'consultation_messages',
         filter: `consultation_id=eq.${consultationId}`
       }, (payload) => callback(payload.new as Message))
       .subscribe();

     return () => channel.unsubscribe();
   }
   ```

4. **Pages**:
   - `consultations/chat/[id]/+page.svelte`: Chat UI with real-time updates
   - `consultations/chat/[id]/+page.server.ts`: Load initial messages

**Acceptance**:
- Patient can book chat consultation and pay
- Real-time messaging works (both directions)
- Provider can mark consultation complete
- Completed consultations show full transcript

**Flutter Medic App Backend** (separate repository):
- Implements `/api/medic/consultations/:id` endpoint (PATCH to mark complete)
- Implements `/api/medic/messages` endpoint (GET/POST messages)

---

### Phase 4: Scheduling & Availability (Week 4)

**Goal**: Providers set availability, patients book time slots.

**Implementation Order**:

1. **Flutter Medic App Backend** (separate repository):
   - Implements `/api/medic/availability` endpoint (GET/PUT templates)
   - Implements `/api/medic/bookings` endpoint (GET/POST bookings)
   - Includes business logic for slot materialization and optimistic locking

2. **API Routes (Storefront - this repo)**:
   - `providers/[id]/availability/+server.ts`: GET available slots

3. **Components**:
   - `AvailabilityCalendar.svelte`: Calendar view with bookable slots

**Acceptance**:
- Providers create availability templates via Flutter app
- Slots materialize correctly for next 30 days
- Double-booking prevented (concurrent requests handled)
- Patients see available slots and can book

---

### Phase 5: Video/Audio Consultations (Week 5-6)

**Goal**: Real-time video/audio consultations with Agora SDK.

**Implementation Order**:

1. **Agora Token Generation** (`lib/healthcare/agora-token-generator.ts`):
   ```typescript
   import { RtcTokenBuilder, RtcRole } from 'agora-access-token';

   export function generateAgoraToken(
     channelName: string,
     uid: number,
     durationInMinutes: number
   ): string {
     const appId = process.env.AGORA_APP_ID!;
     const appCertificate = process.env.AGORA_APP_CERTIFICATE!;
     const expirationTimeInSeconds = Math.floor(Date.now() / 1000) + (durationInMinutes * 60);

     return RtcTokenBuilder.buildTokenWithUid(
       appId,
       appCertificate,
       channelName,
       uid,
       RtcRole.PUBLISHER,
       expirationTimeInSeconds
     );
   }
   ```

2. **API Routes**:
   - **Storefront (this repo)**: `consultations/[id]/join/+server.ts` - POST (patient generates Agora token)
   - **Flutter Backend (separate repo)**: `/api/medic/agora-token` endpoint (provider generates Agora token)

3. **Agora Service** (`apps/storefront/src/lib/services/agora.ts`):
   ```typescript
   import AgoraRTC from 'agora-rtc-sdk-ng';

   export async function joinVideoCall(
     token: string,
     channel: string,
     uid: number
   ) {
     const client = AgoraRTC.createClient({ mode: 'rtc', codec: 'vp8' });
     await client.join(process.env.PUBLIC_AGORA_APP_ID!, channel, token, uid);

     const localVideoTrack = await AgoraRTC.createCameraVideoTrack();
     const localAudioTrack = await AgoraRTC.createMicrophoneAudioTrack();

     await client.publish([localVideoTrack, localAudioTrack]);

     return { client, localVideoTrack, localAudioTrack };
   }
   ```

4. **Components**:
   - `VideoRoom.svelte`: Full video consultation UI (Client Component)
     - Local/remote video display
     - Duration countdown timer
     - 5-minute warning modal
     - Mute/camera controls

5. **Pages**:
   - `consultations/video/[id]/+page.svelte`: Video consultation room
   - `consultations/video/[id]/+page.server.ts`: Load consultation details

**Acceptance**:
- Patient and provider can join video/audio call
- Video/audio quality meets 480p minimum
- Duration warning shows at 5 minutes remaining
- Call disconnects after grace period (slot_duration + 10 min)
- Network quality gracefully degrades

---

### Phase 6: Prescriptions (Week 7)

**Goal**: Providers issue prescriptions, patients view and use them.

**Implementation Order**:

1. **Flutter Medic App Backend** (separate repository):
   - Implements `/api/medic/prescriptions` endpoint (POST to issue, GET to list)
   - Implements `/api/medic/prescriptions/:id` endpoint (GET details)
   - Includes business logic for prescription issuance, expiration calculation, notifications

2. **API Routes (Storefront - this repo)**:
   - `prescriptions/+server.ts`: GET (list patient's prescriptions)
   - `prescriptions/[id]/+server.ts`: GET (prescription details)

3. **Components**:
   - `PrescriptionView.svelte`: Display prescription details
   - Integration with existing product search (manual medication lookup)

4. **Pages**:
   - `prescriptions/+page.svelte`: Prescription history
   - `prescriptions/[id]/+page.svelte`: Prescription detail with "Search Catalog" link

**Acceptance**:
- Providers issue prescriptions via Flutter app
- Patients see prescriptions with 90-day expiration
- Expired prescriptions marked automatically
- Patients can manually search pharmacy catalog for medications

---

### Phase 7: Payments & Commissions (Week 8)

**Goal**: Commission calculation and provider payout tracking.

**Implementation Order**:

1. **Commission Calculator** (`lib/healthcare/commission-calculator.ts`):
   ```typescript
   export function calculateCommission(
     consultationFee: number,
     platformRate: number = 0.15
   ): { commissionAmount: number; netProviderAmount: number } {
     const commissionAmount = Math.round(consultationFee * platformRate);
     const netProviderAmount = consultationFee - commissionAmount;

     return { commissionAmount, netProviderAmount };
   }
   ```

2. **Transaction Creation** (triggered on consultation completion):
   - Insert into `consultation_transactions` table
   - Status: `pending_payout`

3. **Flutter Medic App Backend** (separate repository):
   - Implements `/api/medic/earnings` endpoint (GET wallet balance, commission summary, ledger from bridge tables)

4. **Flutter App Integration**:
   - Commission dashboard screen
   - Earnings summary by period
   - Payout status tracking

**Acceptance**:
- Commission calculated correctly (2 decimal places)
- Transactions created on consultation completion
- Providers see commission breakdown
- Refunds reverse commission (cancellations)

---

### Phase 8: Testing & Polish (Week 9)

**Goal**: Comprehensive testing and UX refinement.

**Testing Checklist**:
- [ ] Integration tests: Booking flow (all consultation types)
- [ ] E2E tests: Video call join flow (Playwright)
- [ ] Unit tests: Commission calculator
- [ ] RLS policy tests: Cross-tenant access denied
- [ ] Performance tests: 50 concurrent video calls
- [ ] Accessibility audit: Keyboard navigation, screen readers
- [ ] Mobile responsiveness: All consultation types
- [ ] Error handling: Payment failures, network issues
- [ ] Edge cases: Late joins, cancellations, double-bookings

**Polish Tasks**:
- [ ] Loading states for all async operations
- [ ] Error messages user-friendly and actionable
- [ ] Success notifications for bookings, prescriptions
- [ ] Empty states for consultation history, prescriptions
- [ ] Responsive design for mobile/tablet
- [ ] Dark mode support (if applicable)

---

## Environment Variables

### Storefront (SvelteKit)
```env
PUBLIC_AGORA_APP_ID=your_agora_app_id
PUBLIC_SUPABASE_URL=https://your-project.supabase.co
PUBLIC_SUPABASE_ANON_KEY=your_anon_key
```

### Flutter Medic App Backend (separate repository)
```env
AGORA_APP_ID=your_agora_app_id
AGORA_APP_CERTIFICATE=your_agora_app_certificate
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
HEALTHCARE_COMMISSION_RATE=0.15
```
*Note: Flutter backend implementation and configuration in separate repository*

---

## Deployment Checklist

- [ ] Run database migration on production Supabase (shared database)
- [ ] Seed platform commission rate config
- [ ] Deploy storefront with Agora SDK (this repo)
- [ ] Deploy Flutter medic app with backend API (separate repo)
- [ ] Configure environment variables (both repos)
- [ ] Test RLS policies in production (both apps)
- [ ] Monitor Agora usage/billing
- [ ] Set up error tracking (Sentry, etc.) for both apps
- [ ] Configure performance monitoring for both apps
- [ ] Coordinate deployment timing (database migration before app deployments)

---

## Critical Success Factors

1. **RLS Security**: Multi-tenancy isolation MUST be tested thoroughly
2. **Payment Integration**: Ensure existing gateway handles consultation fees
3. **Agora Quality**: Test video/audio on various networks before launch
4. **Commission Accuracy**: Financial calculations MUST be unit-tested
5. **Slot Booking**: Double-booking prevention via optimistic locking

---

## Next Steps After Implementation

1. Run `/speckit.tasks` to generate task breakdown from this plan
2. Implement in sequence (database → directory → chat → scheduling → video → prescriptions → commissions)
3. Test each phase independently before proceeding
4. Deploy incrementally (feature flags for gradual rollout)

**Estimated Timeline**: 9 weeks (with 2-person team)
**Complexity**: High (real-time video, multi-tenant security, financial transactions)
**Risk Areas**: Agora integration, commission accuracy, RLS policy correctness
