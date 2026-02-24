# Feature Specification: Healthcare Provider Directory and Telemedicine Consultations

**Feature Branch**: `003-healthcare-consultations`
**Created**: 2026-02-21
**Status**: Draft
**Input**: User description: "Healthcare Provider Directory and Telemedicine Consultations - Add doctor directory listing, doctor detail pages, multi-modal consultations (chat, video, audio, office visit booking), patient prescriptions, and checkout flow. Feature restricted to pharmacy and diagnostic centre business types on paid plans only. Includes commission system for healthcare provider transactions. Uses Agora for video/audio conferencing in SvelteKit storefront."

## Clarifications

### Session 2026-02-21

- Q: How are healthcare providers filtered for display on specific storefronts? → A: Filter providers by the business's country/region only - all provider types visible on all eligible storefronts within that country
- Q: Where do office visit appointments occur and how is location data managed? → A: Office visits occur at the healthcare provider's own clinic/office location (provider maintains their office address in their profile)
- Q: When/how does a chat consultation transition from "in-progress" to "completed" status? → A: Provider-initiated completion (healthcare provider marks the consultation as complete when they determine the case is resolved)
- Q: What is the scope of commission rate configuration - uniform or variable? → A: Single platform-wide rate (one commission percentage applies to all consultations across all providers and consultation types)
- Q: What level of encryption is required for consultation communications? → A: Transport-level encryption (all chat, video, audio communications encrypted in transit via HTTPS/TLS and Agora SDK's built-in security; messages encrypted at rest in database)
- Q: How are prescribed medications matched to pharmacy catalog products for cart addition? → A: Manual patient search (patient views prescription then manually searches pharmacy catalog to find and add the matching medications)
- Q: When do patients pay for scheduled consultations (video/audio/office visits) - at booking or after completion? → A: Payment at booking time (patient pays when reserving the time slot; refund policy applies if cancelled per FR-015)
- Q: What is the time slot granularity for provider availability scheduling? → A: Provider-configurable from standard options (providers choose slot duration from predefined options: 15, 30, 45, or 60 minutes)
- Q: What is the expiration timeframe for prescriptions issued by providers? → A: 90 days from issue date (prescriptions expire three months after being issued by provider)
- Q: How are video/audio call duration limits enforced when reaching the provider's selected slot duration? → A: Warning + grace period (5-minute warning before expiration; call continues for 5 more minutes grace period, then disconnects)

### Session 2026-02-22

- Q: When a healthcare provider cancels a scheduled consultation (video/audio/office visit), what happens to the patient? → A: Automatic full refund issued regardless of timing, patient receives notification with option to rebook
- Q: How should the system handle notification delivery failures (email/SMS not delivered for booking confirmations or reminders)? → A: Retry notification delivery 3 times with exponential backoff, log all failures for manual follow-up, allow consultation to proceed
- Q: What should happen when a patient joins a video/audio consultation late (after the scheduled start time)? → A: Allow patient to join but only for remaining time in the slot (including grace period); show warning about reduced duration
- Q: What is the URL structure and branding continuity for healthcare consultations accessed through different entry points (storefront vs medic clinic page)? → A: Three patterns: (1) Storefront referral: customer stays in storefront domain (store.fokz.com/healthcare/*), sees storefront branding, referral commission to business; (2) Medic clinic referral (Growth+ Doctor List): customer stays in host medic domain (medic.kemani.com/c/dr-kate/* or custom domain), sees host medic branding, referral commission (10% consult + 5% drug) to host medic; (3) Direct access: customer on medic's own domain, sees medic branding, no referral commission. Custom domains supported for both storefronts and medics (Custom plan)

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Browse and View Healthcare Providers (Priority: P1)

Customers visiting a pharmacy or diagnostic centre storefront can browse a directory of available healthcare providers (doctors, specialists, diagnosticians), view their profiles including qualifications, specializations, availability, consultation fees, and ratings.

**Why this priority**: This is the foundation of the feature - users must be able to discover providers before booking consultations. Delivers immediate value by providing transparency and helping users make informed decisions.

**Independent Test**: Can be fully tested by visiting a pharmacy/diagnostic centre storefront, accessing the healthcare provider directory, browsing provider listings, and viewing individual provider detail pages. Delivers value by connecting patients with healthcare professionals.

**Acceptance Scenarios**:

1. **Given** I am a customer on a pharmacy storefront with a paid plan, **When** I navigate to the healthcare providers section, **Then** I see a list of available doctors and pharmacists from the country-wide provider pool with their names, photos, specializations, and consultation fees
2. **Given** I am viewing the provider directory, **When** I click on a specific doctor's profile, **Then** I see detailed information including qualifications, years of experience, available consultation types, patient ratings, and availability schedule
3. **Given** I am on a diagnostic centre storefront with a paid plan, **When** I access the healthcare section, **Then** I see the same country-wide pool of healthcare providers (doctors, specialists, pharmacists)
4. **Given** I am viewing a provider's profile, **When** I click "Add to Favorites", **Then** the provider is saved to my favorites list for quick access in future visits
5. **Given** I have favorited providers, **When** I access my favorites, **Then** I see all my favorited providers with quick access to book consultations with them
6. **Given** I am on a storefront that is not a pharmacy or diagnostic centre, **When** I try to access healthcare providers, **Then** I do not see this option (feature is hidden)
7. **Given** I am on a pharmacy storefront with a free plan, **When** I try to access healthcare providers, **Then** I see a message indicating this feature is only available on paid plans
8. **Given** I access healthcare providers from Fokz Pharmacy storefront (store.fokz.com), **When** I browse providers and view a provider profile, **Then** I remain in the Fokz domain (store.fokz.com/healthcare/*) and see Fokz branding throughout, ensuring branding continuity
9. **Given** I access a medic's clinic page with Doctor List (Growth+ plan), **When** I select a listed doctor to consult, **Then** I remain in the host medic's domain and see the host medic's branding, creating the impression the listed doctor is part of the host medic's practice

---

### User Story 2 - Book and Pay for Text-Based Consultations (Priority: P2)

Customers can initiate a text-based chat consultation with a healthcare provider, pay the consultation fee through the checkout process, and communicate with the provider through a secure messaging interface.

**Why this priority**: Text consultations are the simplest consultation type to implement and test independently. Provides immediate value for non-urgent medical advice and follow-ups. Tests the core booking and payment flow.

**Independent Test**: Can be tested by selecting a provider, choosing the chat consultation option, completing checkout, and exchanging messages with the provider. Delivers value as a complete consultation experience.

**Acceptance Scenarios**:

1. **Given** I am viewing a doctor's profile, **When** I select "Chat Consultation" and proceed to checkout, **Then** I see the consultation fee and can complete payment
2. **Given** I have paid for a chat consultation, **When** the payment is confirmed, **Then** I am directed to a messaging interface where I can chat with the provider
3. **Given** I am in an active chat consultation, **When** I send a message, **Then** the provider receives it in real-time and can respond
4. **Given** the provider has marked a chat consultation as complete, **When** I view my consultation history, **Then** I can access the full chat transcript and see the consultation marked as completed
5. **Given** a provider marks a chat consultation as complete, **When** the status changes to completed, **Then** the appropriate commission is calculated and recorded for the healthcare provider

---

### User Story 3 - Schedule Office Visit Appointments (Priority: P3)

Customers can book in-person office visit appointments with healthcare providers by viewing the provider's available time slots, selecting a preferred date and time, completing payment, and receiving confirmation.

**Why this priority**: Office visits complement virtual consultations and are essential for diagnostic centres. Can be tested independently as a scheduling and payment workflow.

**Independent Test**: Can be tested by viewing a provider's availability calendar, booking a time slot, completing checkout, and receiving confirmation. Delivers value by enabling in-person healthcare access.

**Acceptance Scenarios**:

1. **Given** I am viewing a doctor's profile, **When** I select "Book Office Visit", **Then** I see their available time slots organized by date and time
2. **Given** I have selected a time slot, **When** I proceed to checkout and complete payment at booking time, **Then** the appointment is reserved, my payment is processed, and I receive confirmation details
3. **Given** I have a confirmed office visit, **When** I view my appointments, **Then** I see the date, time, provider details, and location information
4. **Given** an office visit is booked, **When** the appointment time approaches (e.g., 24 hours before), **Then** I receive a reminder notification
5. **Given** an office visit appointment is completed, **When** the consultation is marked as completed, **Then** the commission is calculated and recorded for the already-processed payment

---

### User Story 4 - Conduct Video and Audio Consultations (Priority: P4)

Customers can join real-time video or audio consultations with healthcare providers at scheduled times, using secure conferencing technology that ensures privacy and quality communication.

**Why this priority**: Real-time consultations provide high-value telemedicine experiences but depend on scheduling and payment infrastructure. Builds on earlier stories.

**Independent Test**: Can be tested by scheduling a video/audio consultation, completing payment, joining the call at the scheduled time, and conducting a live session. Delivers value through remote face-to-face medical consultations.

**Acceptance Scenarios**:

1. **Given** I am viewing a doctor's profile, **When** I select "Video Consultation" or "Audio Consultation", **Then** I can choose an available time slot, see the consultation fee, and proceed to checkout
2. **Given** I have selected a time slot and completed payment at booking time, **When** the scheduled time arrives, **Then** I receive a notification with a "Join Consultation" link
3. **Given** I click "Join Consultation", **When** the video/audio call loads, **Then** I can see/hear the provider and they can see/hear me with clear audio and video quality
4. **Given** I am in a video/audio consultation, **When** either party ends the call, **Then** the consultation is marked as completed and I can access the consultation record
5. **Given** I am in a video/audio consultation and the allocated time is approaching, **When** 5 minutes remain in the slot duration, **Then** both participants see a warning; the call continues for up to 5 more minutes past the allocated time, then automatically disconnects
6. **Given** network connectivity is poor, **When** I am in a video/audio call, **Then** the system gracefully degrades quality or suggests switching to audio-only mode
7. **Given** I join a video/audio consultation after the scheduled start time, **When** I click "Join Consultation", **Then** I see a warning about reduced duration and can only use the remaining time in the allocated slot (including grace period)

---

### User Story 5 - Receive and View Prescriptions (Priority: P5)

Patients can receive digital prescriptions from healthcare providers after consultations, view prescription details including medication names, dosages, instructions, and duration, and access their prescription history.

**Why this priority**: Prescriptions are the output of many consultations and complete the healthcare journey. Essential for pharmacy storefronts. Can be tested after consultation features are in place.

**Independent Test**: Can be tested by completing a consultation, having a provider issue a prescription, viewing the prescription details, and accessing prescription history. Delivers value by providing medical documentation and enabling pharmacy fulfillment.

**Acceptance Scenarios**:

1. **Given** I have completed a consultation with a provider, **When** the provider issues a prescription, **Then** I receive a notification about the new prescription with an expiration date of 90 days from issue date
2. **Given** I have a prescription, **When** I view it, **Then** I see medication name(s), dosage, frequency, duration, special instructions, the prescribing doctor's details, and the expiration date
3. **Given** I am on a pharmacy storefront and viewing a prescription, **When** I search the pharmacy catalog for the prescribed medication, **Then** I can find matching products and add them to my cart for purchase
4. **Given** I have multiple prescriptions, **When** I access my prescription history, **Then** I see all prescriptions organized by date with filtering and search options, with expired prescriptions clearly marked
5. **Given** a prescription is 90 days old, **When** the prescription expires, **Then** it is marked as expired and cannot be used for new purchases

---

### Edge Cases

- **Provider cancellation**: When a healthcare provider cancels a scheduled consultation, the system automatically issues a full refund to the patient regardless of timing and sends a notification with option to rebook with the same or a different provider (per FR-015)
- **Late patient join**: When a patient joins a video/audio consultation after the scheduled start time, they are allowed to join but receive only the remaining time in the allocated slot (including grace period); system displays a warning about the reduced duration (per FR-008b)
- What happens if both patient and provider want to continue beyond the 5-minute grace period after the allocated slot duration expires?
- What happens if payment fails during the checkout/booking process for a consultation (before time slot is reserved)?
- How does the system manage timezone differences for scheduled consultations?
- What happens if network connectivity is lost during a live video/audio consultation?
- How does the system prevent unauthorized access to consultation chat rooms or video sessions?
- What happens when a healthcare provider tries to issue a prescription for controlled substances?
- How are consultations managed when a patient has multiple pending sessions with different providers?
- What happens if a patient has follow-up questions after a provider marks a chat consultation as complete?
- What happens when a pharmacy storefront doesn't stock a medication that was prescribed to a patient?
- What happens when a patient tries to use an expired prescription (>90 days old) to purchase medications?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST display a healthcare provider directory only on storefronts with business type "pharmacy" or "diagnostic centre"
- **FR-002**: System MUST restrict healthcare provider features to storefronts with active paid subscription plans
- **FR-002a**: System MUST display healthcare providers from a shared country-wide pool, filtered by the business's country/region only (all provider types - doctors, specialists, pharmacists, diagnosticians - are visible on all eligible storefronts within that country regardless of the storefront's business type)
- **FR-002b**: System MUST allow customers to add healthcare providers to their favorites list for quick access
- **FR-002c**: System MUST maintain branding continuity and domain context throughout the healthcare consultation workflow based on entry point: (1) Storefront referral: all healthcare URLs under storefront domain (store.tenant.com/healthcare/*), storefront branding displayed, referral commission tracked to business; (2) Medic clinic referral (Growth+ Doctor List feature): all healthcare URLs under host medic domain (medic.kemani.com/c/{slug}/* or custom domain), host medic branding displayed, referral commission (10% consultation + 5% drug) tracked to host medic; (3) Direct medic access: medic's own domain, medic branding, no referral commission
- **FR-002d**: System MUST support custom domains for both pharmacy/diagnostic centre storefronts and medic clinic pages (Custom plan medics only)
- **FR-003**: System MUST display provider profiles with name, photo, specialization, qualifications, years of experience, consultation types offered, fees per consultation type, average rating, and availability
- **FR-003a**: System MUST display provider's clinic/office address on provider profiles and in office visit appointment confirmations
- **FR-004**: System MUST support four consultation types: text chat, video call, audio call, and office visit
- **FR-005**: System MUST integrate with the existing storefront payment gateway configured for the business
- **FR-005a**: System MUST process payment for all consultation types at booking/checkout time (before consultation begins); scheduled consultations (video/audio/office visits) are paid at time slot reservation, chat consultations are paid before chat access
- **FR-006**: System MUST calculate and record commission for each completed consultation transaction based on referral source: (1) Storefront referral: commission to referring business; (2) Medic clinic referral (Growth+ Doctor List): 10% consultation fee + 5% drug commission to host medic; (3) Direct access: no referral commission (full commission to consulting medic minus platform cut)
- **FR-007**: System MUST provide real-time text messaging for chat consultations with message history persistence
- **FR-007a**: System MUST allow healthcare providers to mark chat consultations as complete when they determine the case is resolved; completed chat transcripts remain accessible to both patient and provider
- **FR-008**: System MUST enable video and audio consultations using Agora SDK with support for call quality adjustment
- **FR-008a**: System MUST enforce video/audio consultation duration limits by displaying a 5-minute warning before the allocated time expires, allowing a 5-minute grace period after expiration, then automatically disconnecting the call
- **FR-008b**: System MUST allow patients to join video/audio consultations after the scheduled start time; patient receives only the remaining time in the allocated slot (including grace period); system displays warning about reduced duration upon late entry
- **FR-009**: System MUST allow patients to view provider availability calendars and book time slots for video, audio, and office visit consultations
- **FR-009a**: System MUST support provider-configurable time slot durations with predefined options: 15, 30, 45, or 60 minutes (providers choose their preferred slot duration when setting availability)
- **FR-010**: System MUST send confirmation notifications when consultations are booked, reminders before scheduled consultations, and notifications when consultations begin; notification delivery failures MUST be retried 3 times with exponential backoff, all failures logged for manual follow-up, consultation workflow continues regardless of delivery status
- **FR-011**: System MUST allow healthcare providers to issue digital prescriptions with medication details, dosage, frequency, duration, and special instructions
- **FR-011a**: System MUST automatically set prescription expiration date to 90 days from issue date; expired prescriptions are marked as expired and cannot be used for new purchases
- **FR-012**: System MUST display prescription history to patients with filtering and search capabilities
- **FR-013**: System MUST allow patients to view their prescriptions and manually search the pharmacy catalog to add prescribed medications to their shopping cart (no automatic SKU matching; patient is responsible for finding the correct products)
- **FR-014**: System MUST enforce data privacy and compliance with healthcare regulations for all patient-provider communications and records
- **FR-014a**: System MUST encrypt all consultation communications in transit using HTTPS/TLS for chat messages and Agora SDK's built-in encryption for video/audio calls
- **FR-014b**: System MUST encrypt consultation messages, prescriptions, and sensitive patient data at rest in the database
- **FR-015**: System MUST handle consultation cancellations and refunds with the following policies: (Patient cancellations) full refund if cancelled 24 or more hours before the scheduled consultation time, no refund if cancelled within 24 hours of the consultation; (Provider cancellations) automatic full refund issued to patient regardless of timing, patient receives notification with option to rebook with same or different provider
- **FR-016**: System MUST track consultation status (pending, in-progress, completed, cancelled) and update in real-time
- **FR-017**: System MUST restrict prescription issuance to licensed healthcare providers only
- **FR-018**: System MUST maintain consultation records including type, date, duration, participants, and any associated prescriptions
- **FR-019**: System MUST calculate commission as a flat percentage of the consultation fee using a single platform-wide commission rate (configured at the system level; applies uniformly to all consultations regardless of type, provider, or storefront)
- **FR-020**: System MUST display commission information on business owner admin dashboards
- **FR-021**: System MUST handle timezone conversions for scheduled consultations between patients and providers in different timezones
- **FR-022**: System MUST prevent double-booking of provider time slots for scheduled consultations

### Key Entities

- **Healthcare Provider**: Represents doctors, specialists, pharmacists, or diagnosticians in a shared country-wide pool. Attributes include country/region, name, credentials, specialization, years of experience, profile photo, bio, clinic/office address (for in-person visits), consultation types offered, fees per type, availability schedule, average rating, and total consultations completed. Providers are not tied to any specific pharmacy or diagnostic centre. All providers in a country are visible on all eligible storefronts within that country
- **Consultation**: Represents a healthcare consultation session between a patient and provider. Attributes include type (chat/video/audio/office visit), status (pending/in-progress/completed/cancelled), scheduled time (for video/audio/office visits), duration, participants, consultation fee, commission amount, payment status (payment is processed at booking time for all consultation types), referral source (storefront, medic_clinic, direct), and referrer entity ID (business ID or host medic ID for commission tracking)
- **Consultation Message**: Represents individual messages in text-based consultations. Attributes include sender, recipient, message content, timestamp, read status, and associated consultation
- **Prescription**: Represents medical prescriptions issued by providers. Attributes include issuing provider, patient, consultation reference, issue date, expiration date (automatically set to 90 days from issue date), medications (each with name, dosage, frequency, duration, special instructions), and fulfillment status
- **Appointment**: Represents scheduled office visit appointments. Attributes include patient, provider, date, time, location (references provider's clinic/office address), status (confirmed/completed/cancelled), and payment details
- **Consultation Transaction**: Represents payment and commission details for consultations. Attributes include consultation reference, patient, provider, gross amount, commission amount, net provider payment, payment method, transaction status, and timestamp
- **Provider Availability**: Represents healthcare provider availability schedules. Attributes include provider, day of week, time slots, slot duration (15/30/45/60 minutes chosen by provider), consultation types available per slot, and booked/available status
- **Favorite Provider**: Represents a customer's favorited/bookmarked healthcare providers for quick access. Attributes include customer, provider, date added, and notes/tags for organization

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Patients can complete the entire process from browsing providers to booking a consultation in under 5 minutes
- **SC-002**: Video and audio consultation calls maintain acceptable quality (minimum 480p video, clear audio) for 95% of sessions
- **SC-003**: Text-based chat messages are delivered in real-time with less than 2 seconds latency for 99% of messages
- **SC-004**: Patients can view and understand provider profiles without needing additional support or clarification
- **SC-005**: 90% of scheduled consultations start within 2 minutes of the scheduled time
- **SC-006**: Prescription details are clear and complete, reducing pharmacy fulfillment errors to less than 1%
- **SC-007**: Commission calculations are accurate to 2 decimal places for 100% of transactions
- **SC-008**: The system successfully handles at least 50 concurrent video/audio consultations without performance degradation
- **SC-009**: Patients can access their consultation history and prescriptions within 3 seconds of requesting them
- **SC-010**: The checkout process has a completion rate of at least 85% (percentage of users who start checkout and complete payment)
- **SC-011**: Healthcare providers receive commission payouts accurately and on schedule with less than 0.1% error rate
- **SC-012**: The feature increases customer engagement on pharmacy and diagnostic centre storefronts by at least 40% compared to non-healthcare storefronts
- **SC-013**: Notification delivery succeeds on first attempt for at least 95% of all booking confirmations and reminders; failed deliveries are logged for operational monitoring
- **SC-014**: 100% of consultation workflows maintain branding continuity (customer never leaves referring domain/branding context throughout provider browsing, booking, consultation, and prescription viewing)
- **SC-015**: Commission attribution is accurate to referral source (storefront, medic_clinic, direct) for 100% of completed consultations

## Assumptions

- Healthcare providers exist in a shared country-wide pool and are managed separately from individual pharmacy/diagnostic centre businesses (providers are not onboarded by business owners)
- Healthcare providers will be verified and credentialed through a separate system before appearing in the directory
- The platform is responsible for ensuring healthcare providers have valid licenses and credentials before they appear in the directory
- The platform will use standard timezone handling practices (UTC storage, local display)
- Video and audio consultations will have duration limits based on provider-selected time slot size (providers choose from standard options: 15, 30, 45, or 60 minutes when creating availability)
- Patients must create customer accounts on the storefront to book consultations
- Commission payments to healthcare providers will be processed through existing payment infrastructure on a defined schedule (e.g., weekly, bi-weekly, monthly)
- Prescription fulfillment on pharmacy storefronts will use existing product catalog and inventory systems
- The system will maintain consultation records for a minimum of 5 years for compliance purposes
- Healthcare providers will access their schedules, consultations, and prescription tools through the Flutter admin app (medic.kemani.com for admin access, not slug-based routing)
- Medics can have public clinic pages (medic.kemani.com/c/{slug}) for patient-facing information, separate from their admin dashboard access
- Branding continuity is maintained throughout consultation workflows: customers entering through a storefront remain in that storefront's domain and branding; customers entering through a medic clinic page remain in that medic's domain and branding
- Referral source tracking (storefront, medic_clinic, direct) is essential for accurate commission attribution in the bridge commission system
- Network quality issues during video/audio calls are primarily the responsibility of users (patient and provider) to resolve
- The platform will comply with relevant healthcare data privacy regulations (HIPAA, GDPR, or local equivalents)

## Out of Scope

- Integration with external electronic health record (EHR) systems
- Automated diagnosis or AI-powered medical advice
- Insurance claim processing and billing
- Laboratory test result integration
- Pharmacy inventory management changes (uses existing system)
- Multi-party consultations (more than one provider or patient in a session)
- Automated prescription verification or drug interaction checking
- Medical device integration (blood pressure monitors, glucometers, etc.)
- Provider credentialing and license verification automation
- Patient medical history management beyond consultation records
- Appointment rescheduling workflow (patients must cancel and rebook)
- Custom branding for individual healthcare providers

## Dependencies

- Agora SDK integration for video and audio conferencing capabilities
- Existing storefront payment gateway for consultation fee processing
- Existing Supabase database schema must be extended to support healthcare entities
- Separate healthcare provider management system for provider onboarding, verification, and profile management (providers manage their own profiles, schedules, and availability)
- Email/SMS notification system for consultation reminders and confirmations (must support retry logic and delivery status tracking)
- Logging and monitoring infrastructure for notification delivery failures and operational metrics
- Existing customer account and authentication system on storefronts
- Business subscription plan management system to enforce paid plan restrictions
- File storage system for provider profile photos and prescription documents
- URL routing and domain management system to support: (1) Storefront healthcare routes (store.tenant.com/healthcare/*), (2) Medic public clinic pages (medic.kemani.com/c/{slug}/*), (3) Custom domains for storefronts and medic clinics (Custom plan)
- Referral tracking system to identify consultation entry point (storefront, medic_clinic, direct) for commission attribution

## Risks and Mitigations

- **Risk**: Healthcare data privacy compliance complexity
  - **Mitigation**: Conduct thorough compliance review, implement transport-level encryption (HTTPS/TLS for chat, Agora SDK encryption for video/audio) with at-rest database encryption, and maintain detailed audit logs

- **Risk**: Poor video/audio quality due to network issues impacting user experience
  - **Mitigation**: Implement quality monitoring, provide network requirement guidance, and offer fallback to audio-only or chat

- **Risk**: Provider availability management and scheduling conflicts
  - **Mitigation**: Implement robust double-booking prevention, real-time availability updates, and clear cancellation policies

- **Risk**: Commission calculation errors leading to financial disputes
  - **Mitigation**: Implement automated testing for commission logic, provide transparent calculation breakdowns, and maintain comprehensive transaction logs

- **Risk**: Scope creep into complex medical features beyond platform capabilities
  - **Mitigation**: Clearly define and communicate out-of-scope features, focus on core telemedicine consultation workflows
