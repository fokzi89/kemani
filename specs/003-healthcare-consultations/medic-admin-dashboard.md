# Medic Admin Dashboard Specification
## Flutter Kemani_Medic App - Admin Features

**Date**: 2026-02-22 | **Feature**: 003-healthcare-consultations
**Reference**: Kemani Medic Spec v2 PDF + Commission Tables PDF

---

## Dashboard Overview

The Flutter kemani_medic app serves as the complete admin dashboard for healthcare providers (doctors and pharmacists). It handles all provider-facing functionality with offline-first architecture via PowerSync.

### Key Dashboard Sections

#### 1. Home Dashboard (`/dashboard`)
**Today's Snapshot**:
- Active consultations count
- Pending bookings (requires action)
- Today's earnings (consultation + drug commission)
- Wallet balance (available + pending)

**Quick Actions**:
- Start new consultation (chat/video/audio)
- View booking calendar
- Check prescription queue
- Access patient list

**Recent Activity Feed**:
- New booking requests
- Consultation completions
- Prescription fills (drug commission earned)
- Payout confirmations

---

#### 2. Consultation Management (`/consultations`)

**Queue View** (3 tabs):
1. **Active** - Ongoing consultations
   - Type badge (chat/video/audio/office)
   - Patient name + photo
   - Duration timer (for video/audio)
   - "Resume" button

2. **Pending** - Awaiting medic action
   - Booking requests
   - Scheduled upcoming consultations
   - Accept/Decline actions

3. **History** - Completed/cancelled
   - Filterable by date range, type, patient
   - Commission earned per consultation
   - View transcript (chat) or notes

**Consultation Detail Screen**:
- Patient health profile (allergies, current meds)
- Consultation type and fee
- Start time, duration
- Chat transcript or call summary
- Prescription issued (if any)
- Commission breakdown
- Referral source (direct/branch/doctor_list)

---

#### 3. Video/Audio Call Interface (`/consultation/:id/call`)

**Agora RTC Integration**:
- Video feed (local + remote)
- Mute/unmute microphone
- Enable/disable camera
- Switch camera (front/back)
- Speaker/earpiece toggle
- End call button

**Call Features**:
- Duration counter
- Network quality indicator
- Chat sidebar (send text during call)
- Quick prescription writer access
- Screen brightness lock (prevent auto-dim)

**Call End Flow**:
- Auto-save call duration
- Prompt for consultation notes
- Trigger commission calculation
- Option to issue prescription immediately

---

#### 4. Chat Consultation (`/consultation/:id/chat`)

**Real-time Messaging** (Supabase Realtime):
- Message bubbles (medic vs patient)
- File/image attachments (Supabase Storage)
- Typing indicators
- Read receipts
- Offline message queue (PowerSync)

**Chat Actions**:
- Send prescription
- Request photo (e.g., "show me the rash")
- Share location (for office visit directions)
- End consultation button

**Message History**:
- Infinite scroll pagination
- Search within consultation
- Export transcript (PDF)

---

#### 5. Prescription Writer (`/consultation/:id/rx`)

**Drug Autocomplete** (NAFDAC Database):
- Search by brand name or generic
- NAFDAC number auto-fill
- Dosage suggestions based on drug
- Controlled substance warning flag

**Prescription Form**:
- Drug name (autocomplete)
- Generic name
- NAFDAC number
- Quantity
- Dosage (e.g., "1 cap 3x daily")
- Duration (days)
- Special instructions ("Take with food")

**Smart Pharmacy Routing**:
- Enter patient location (lat/lng or address)
- Call `bridge-prescription-router` Edge Function
- Display routing strategy:
  - **Single**: One pharmacy has all items
  - **Split**: Multiple pharmacies needed
  - **Partial**: Some items unavailable
  - **None**: No pharmacy has stock
- Show matched pharmacies with distances

**Prescription Actions**:
- Generate QR code (patient scans at pharmacy)
- Send via SMS/WhatsApp
- Print PDF
- Track status (issued → sent → dispensed)

**Drug Commission Preview**:
- Show estimated 5% commission if patient is direct
- Show ₦0 if referred by branch/business
- Show 5% to referring medic if Growth clinic referral

---

#### 6. Booking & Availability Management (`/bookings`, `/settings/availability`)

**Calendar View** (`table_calendar` package):
- Week/month views
- Color-coded slot status:
  - **Green**: Available
  - **Yellow**: Pending confirmation
  - **Blue**: Confirmed
  - **Red**: Cancelled/no-show
  - **Grey**: Blocked/unavailable

**Booking Request Cards**:
- Patient name + photo
- Requested type (chat/video/audio/office)
- Requested slot
- Fee patient will pay
- Accept/Decline buttons
- Auto-confirm toggle

**Availability Setup** (`/settings/availability`):
- Day of week checkboxes
- Start/end time pickers per day
- Slot duration dropdown (15/30/45/60 min)
- Buffer time between slots
- Block specific dates (vacation mode)

---

#### 7. Patient Management (`/patients`)

**Patient List**:
- Search by name/phone
- Filter by source:
  - **Direct**: Medic invited
  - **Branch**: Came via pharmacy/lab
  - **Doctor List**: Came via Growth clinic
- Sort by: last consultation, total consultations, date added

**Patient Profile** (`/patients/:id`):
- Basic info (name, phone, DOB, gender)
- Health summary:
  - Allergies
  - Current medications
  - Medical history notes
- Consultation history (all past consultations)
- Prescriptions issued
- Total revenue generated
- Commission earned (direct patients only)

**Invite New Patient**:
- Enter phone/email
- Generate unique invite link: `medic.kemani.com/c/{slug}?invite={token}`
- Send via SMS/WhatsApp
- Track invite status (sent/opened/registered)

---

#### 8. Earnings & Commission Dashboard (`/earnings`)

**Wallet Summary Card**:
- **Available Balance**: Ready for payout (₦)
- **Pending Balance**: Within 24h hold period
- **Total Earned**: Lifetime earnings
- **Total Paid Out**: Lifetime payouts

**Earnings Breakdown Chart** (`fl_chart`):
- Pie chart: Consultation vs Drug Commission vs Referral Earnings (Growth+)
- Bar chart: Earnings per day/week/month
- Line chart: Trend over time

**Period Filters**:
- Today
- This Week (Mon-Sun)
- This Month
- Custom Date Range

**Commission Types**:
1. **Consultation Earnings**:
   - Base fee minus 10% platform cut
   - Minus Agora cost (video/audio only)

2. **Drug Commissions**:
   - 5% of prescription value when own patient fills
   - ₦0 when branch-referred patient fills

3. **Referral Earnings** (Growth+ only):
   - 10% of consultation fee when listed medic sees your patient
   - 5% drug commission when your patient fills prescription

**Ledger Table** (from `bridge_commission_ledger`):
| Date | Type | Source | Amount | Status |
|------|------|---------|--------|--------|
| 2026-02-20 | Consultation | Paul (patient) | ₦4,500 | Confirmed |
| 2026-02-20 | Drug Commission | Paul @ Fokz | ₦540 | Confirmed |
| 2026-02-19 | Referral | Fejiro → Dr Afoke | ₦500 | Confirmed |

**Payout Settings**:
- Bank account details (encrypted in `bridge_partner_wallets`)
- Payout schedule:
  - **Starter**: Weekly (Fridays)
  - **Growth**: Daily or Weekly
  - **Custom**: Instant, Daily, or Weekly
- Minimum payout threshold (₦5,000 default)
- Flutterwave auto-transfer setup

**Payout History** (`/earnings/history`):
- Date processed
- Amount
- Bank account (last 4 digits)
- Flutterwave reference
- Status (pending/completed/failed)
- Receipt PDF download

---

#### 9. Clinic Settings (`/clinic/settings`)

**Basic Info** (All Plans):
- Clinic name
- Display name
- Specialties (multi-select)
- Bio (500 char)
- Profile photo
- MDCN/PCN number (verified)
- Consultation fee (₦ - patient pays +10%)

**Clinic Branding** (Growth+ and Custom):
- Clinic logo
- Primary color (hex picker)
- Accent color
- Office address
- Office location (map pin)
- Is accepting new patients toggle

**White-Label Domain** (Custom Plan Only):
- Custom domain field: `clinic.example.com`
- DNS instructions (CNAME record)
- SSL certificate auto-provisioned
- Domain verification status

---

#### 10. Doctor List Management (`/clinic/doctors`) — Growth+ Only

**Listed Doctors View**:
| Photo | Name | Specialty | Status | Earnings This Month | Actions |
|-------|------|-----------|--------|---------------------|---------|
| 👤 | Dr Afoke | General Practice | Active | ₦12,400 | View · Remove |

**Add New Doctor**:
1. Search verified medics (by name, specialty, location)
2. View medic profile (rating, consultation fee, bio)
3. Send invite with commission terms:
   - **Consultation referral**: 10% of base fee
   - **Drug commission**: 5% of prescription value
4. Medic receives notification, accepts/declines

**Earnings Per Listed Doctor**:
- Consultations referred (count)
- Consultation commissions earned (₦)
- Drug commissions earned (₦)
- Total revenue generated

**Display Order**:
- Drag-to-reorder listed doctors
- Top doctors appear first on public clinic page
- Save order

---

#### 11. Subscription & Plan Management (`/settings/plan`)

**Current Plan Card**:
- Plan name (Starter/Growth/Custom)
- Price (₦0 / ₦15,000/mo / Custom)
- Renewal date
- Active features list

**Plan Comparison Table**:
| Feature | Starter | Growth | Custom |
|---------|---------|--------|--------|
| Active patients | 20 | Unlimited | Unlimited |
| Chat consultations | Unlimited | Unlimited | Unlimited |
| Video/Audio | 30 min/mo | Unlimited | Unlimited |
| Office visits | ✗ | ✓ | ✓ |
| Doctor List | ✗ | ✓ | ✓ |
| Earn referral commission | ✗ | ✓ (10%+5%) | ✓ Custom |
| Custom branding | ✗ | ✓ | ✓ |
| White-label domain | ✗ | ✗ | ✓ |
| SOAP AI | ✗ | ✗ | ✓ |
| Multi-branch | ✗ | ✗ | ✓ |
| Staff accounts | 1 | 3 | Unlimited |

**Upgrade Flow**:
1. Select plan (Growth or Custom)
2. Review features
3. Payment (Flutterwave/Paystack)
4. Instant activation
5. Unlock gated features

**Custom Plan Contact**:
- "Contact Sales" button
- WhatsApp link to sales team
- Custom pricing form (expected revenue, staff count, white-label domain)

---

#### 12. Analytics Dashboard (`/admin/analytics`) — Platform Admin Only

**Platform-Level Metrics** (`platform_admin` role):
- Total medics registered
- Total consultations completed
- Total prescriptions issued
- Total commission paid out
- Active medics (consulted in last 7 days)
- Verification queue (pending medic approvals)

**Revenue Analytics**:
- Platform earnings (10% surcharge + 1% drug commission)
- Growth plan subscriptions (₦15k/mo × subscriber count)
- Custom plan subscriptions
- Total GMV (Gross Merchandise Value)

**Top Medics Leaderboard**:
| Rank | Medic | Consultations | Earnings | Rating |
|------|-------|--------------|----------|--------|
| 1 | Dr Kate | 342 | ₦1,245,000 | 4.9 |
| 2 | Dr Afoke | 287 | ₦987,600 | 4.8 |

---

## Offline Behavior (PowerSync)

**Synced Locally**:
- All past consultations
- Patient list
- Prescription history
- Earnings cache (last sync)
- Draft messages (unsent)

**Requires Online**:
- Start new video/audio call (Agora token generation)
- Create new prescription (pharmacy routing)
- Accept/decline bookings (real-time availability check)
- View live commission ledger

**Offline Draft Queue**:
- Chat messages queued locally
- Synced on reconnect
- Deduplication via UUID

---

## Notifications (Firebase Cloud Messaging)

**Push Notification Triggers**:
1. **New Booking Request**: "Fejiro wants to book a video consultation for Feb 22, 2PM"
2. **Consultation Starting Soon**: "Your consultation with Paul starts in 10 minutes"
3. **Prescription Dispensed**: "Paul picked up prescription at Fokz Pharmacy - ₦540 commission earned"
4. **Payout Completed**: "₦45,000 paid out to your bank account"
5. **Doctor List Invite**: "Dr Kate invited you to join her clinic's doctor list"

**In-App Notification Center** (`/notifications`):
- Unread count badge
- Categorized tabs (Bookings, Earnings, System)
- Mark as read
- Deep links to relevant screens

---

## Key Differentiators from POS

| Feature | POS (web_client) | Medic (kemani_medic) |
|---------|------------------|----------------------|
| Primary user | Cashier, Branch Manager | Doctor, Pharmacist |
| Main function | Sales, Inventory | Consultations, Prescriptions |
| Offline focus | Full POS offline | Consultation history offline |
| Real-time | Product sync | Chat + Agora RTC |
| Commission | Not applicable | Dual-stream (consult + drug) |
| Plan gating | Basic/Pro for POS features | Starter/Growth/Custom for medic features |

---

**End of Admin Dashboard Specification**
