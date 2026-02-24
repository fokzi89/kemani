# Flutter Medic App API Contract
## Healthcare Provider Management - Based on Kemani Medic Spec v2

**Base URL**: `https://api.kemani.com/api/medic`
**Authentication**: Bearer token (Supabase Auth)
**Date**: 2026-02-21
**Reference**: Kemani Medic Spec v2 PDF - Section 15 (API Contracts)
**Implementation**: Backend API handled by Flutter app (separate repository)

---

## Medic Profile

### GET /api/medic/profile
Get authenticated medic's profile.

**Response 200**:
```json
{
  "id": "uuid",
  "auth_user_id": "uuid",
  "type": "doctor", // or "pharmacist"
  "display_name": "Dr Afoke",
  "slug": "dr-afoke-lagos",
  "mdcn_number": "MDCN/12345",
  "specialties": ["general_practice", "telemedicine"],
  "bio": "15 years of experience in general practice...",
  "photo_url": "https://storage.supabase.co/...",
  "plan": "free", // free, pro, enterprise_custom (maps to plan_tier enum)
  "consultation_fee": 5000,
  "verified_at": "2026-02-20T10:00:00Z",
  "clinic_settings": {
    "clinic_name": "Dr Afoke Clinic",
    "logo_url": "https://...",
    "primary_color": "#0066CC",
    "office_address": "123 Main Street, Lagos",
    "office_lat": 6.4281,
    "office_lng": 3.4219,
    "is_accepting_patients": true
  }
}
```

### POST /api/medic/profile
Register new medic (onboarding).

**Request Body**:
```json
{
  "display_name": "Dr Afoke",
  "type": "doctor",
  "mdcn_number": "MDCN/12345",
  "specialties": ["general_practice", "telemedicine"],
  "bio": "Experienced general practitioner...",
  "consultation_fee": 5000,
  "plan": "free"
}
```

**Response 201**:
```json
{
  "medic_id": "uuid",
  "clinic_slug": "dr-afoke-lagos",
  "verification_status": "pending"
}
```

### PATCH /api/medic/profile
Update medic profile.

**Request Body**: Same fields as POST (partial update)

**Response 200**:
```json
{
  "updated": true
}
```

---

## Consultations

### POST /api/medic/consultations
Start a new consultation.

**Request Body**:
```json
{
  "patient_id": "uuid", // from medic_patients table
  "type": "video", // chat, audio, video, office
  "base_fee": 5000,
  "scheduled_at": "2026-03-01T10:00:00Z" // null for chat (immediate)
}
```

**Response 201**:
```json
{
  "consultation_id": "uuid",
  "agora_channel": "consultation_abc123", // if video/audio
  "status": "pending"
}
```

### GET /api/medic/consultations
Get medic's consultations.

**Query Params**:
- `status` (optional): pending, active, ended, cancelled
- `type` (optional): chat, audio, video, office
- `limit` (default: 20), `offset`

**Response 200**:
```json
{
  "consultations": [{
    "id": "uuid",
    "patient_id": "uuid",
    "patient_name": "Paul",
    "type": "video",
    "status": "active",
    "base_fee": 5000,
    "scheduled_at": "2026-03-01T10:00:00Z",
    "started_at": "2026-03-01T10:02:00Z",
    "ended_at": null,
    "agora_channel": "consultation_abc123",
    "created_at": "2026-02-28T15:00:00Z"
  }]
}
```

### GET /api/medic/consultations/:id
Get single consultation details.

**Response 200**:
```json
{
  "id": "uuid",
  "patient_id": "uuid",
  "patient_name": "Paul",
  "patient_phone": "+234...",
  "type": "video",
  "status": "active",
  "base_fee": 5000,
  "scheduled_at": "2026-03-01T10:00:00Z",
  "started_at": "2026-03-01T10:02:00Z",
  "agora_channel": "consultation_abc123",
  "agora_token_medic": "006abc...",
  "referral_id": "uuid", // link to bridge_network_referrals
  "commission_calculated_at": null
}
```

### PATCH /api/medic/consultations/:id
Update consultation (e.g., mark as ended).

**Request Body**:
```json
{
  "status": "ended",
  "ended_at": "2026-03-01T10:32:00Z"
}
```

**Response 200**:
```json
{
  "updated": true,
  "commission_triggered": true // triggers bridge commission calculation
}
```

---

## Chat Messages

### GET /api/medic/messages
Get chat messages for a consultation.

**Query Params**:
- `consultation_id` (required): uuid
- `limit` (default: 50), `offset`

**Response 200**:
```json
{
  "messages": [{
    "id": "uuid",
    "consultation_id": "uuid",
    "sender_id": "uuid",
    "sender_type": "medic", // or "patient"
    "content": "Hello, how can I help you today?",
    "attachments": null, // or JSONB array
    "read_at": null,
    "created_at": "2026-03-01T10:05:00Z"
  }]
}
```

### POST /api/medic/messages
Send a chat message.

**Request Body**:
```json
{
  "consultation_id": "uuid",
  "content": "Please take the medication with food.",
  "attachments": [] // optional JSONB array of file URLs
}
```

**Response 201**:
```json
{
  "id": "uuid",
  "created_at": "2026-03-01T10:15:00Z"
}
```

**Note**: Real-time delivery via Supabase Realtime subscriptions (client-side).

---

## Prescriptions

### POST /api/medic/prescriptions
Create and route a prescription.

**Request Body**:
```json
{
  "consultation_id": "uuid",
  "items": [{
    "drug_name": "Amoxicillin 500mg",
    "generic_name": "Amoxicillin",
    "nafdac_number": "NAFDAC/12345",
    "quantity": 30,
    "dosage": "1 cap 3x daily",
    "duration": "7 days",
    "instructions": "Take with food"
  }],
  "patient_lat": 6.4281,
  "patient_lng": 3.4219
}
```

**Server Action**: Calls `bridge-prescription-router` Edge Function internally.

**Response 201**:
```json
{
  "prescription_id": "uuid",
  "routing": {
    "strategy": "single", // single, split, partial, none
    "primary_pharmacy_id": "uuid",
    "routing_details": { /* pharmacy inventory matches */ }
  },
  "issued_at": "2026-03-01T10:30:00Z",
  "valid_until": "2026-03-31T23:59:59Z"
}
```

### GET /api/medic/prescriptions
Get prescriptions issued by medic.

**Query Params**:
- `patient_id` (optional): filter by patient
- `consultation_id` (optional): filter by consultation
- `status` (optional): issued, sent, dispensed
- `limit`, `offset`

**Response 200**:
```json
{
  "prescriptions": [{
    "id": "uuid",
    "consultation_id": "uuid",
    "patient_id": "uuid",
    "patient_name": "Paul",
    "status": "sent",
    "items": [{ /* prescription items */ }],
    "routing_strategy": "single",
    "primary_pharmacy_id": "uuid",
    "issued_at": "2026-03-01T10:30:00Z",
    "valid_until": "2026-03-31T23:59:59Z"
  }]
}
```

### GET /api/medic/prescriptions/:id
Get prescription details.

**Response 200**: Same structure as list item above, with full details.

---

## Bookings

### GET /api/medic/bookings
Get appointment bookings for medic.

**Query Params**:
- `status` (optional): pending, confirmed, cancelled, no_show
- `consultation_type` (optional): chat, audio, video, office
- `date_from`, `date_to` (optional): YYYY-MM-DD
- `limit`, `offset`

**Response 200**:
```json
{
  "bookings": [{
    "id": "uuid",
    "medic_id": "uuid",
    "patient_id": "uuid",
    "patient_name": "Fejiro",
    "consultation_type": "office",
    "slot_start": "2026-03-05T14:00:00Z",
    "slot_end": "2026-03-05T14:30:00Z",
    "status": "pending",
    "payment_status": "paid",
    "payment_reference": "FLW_REF_123",
    "confirmation_code": "ABC123",
    "created_at": "2026-03-01T09:00:00Z"
  }]
}
```

### POST /api/medic/bookings
Create a booking (manual booking by medic).

**Request Body**:
```json
{
  "patient_id": "uuid",
  "consultation_type": "office",
  "slot_start": "2026-03-05T14:00:00Z",
  "slot_end": "2026-03-05T14:30:00Z"
}
```

**Response 201**:
```json
{
  "booking_id": "uuid",
  "confirmation_code": "ABC123"
}
```

### PATCH /api/medic/bookings/:id
Update booking status (accept/decline/cancel).

**Request Body**:
```json
{
  "status": "confirmed",
  "cancellation_reason": null
}
```

**Response 200**:
```json
{
  "updated": true
}
```

---

## Availability

### GET /api/medic/availability
Get medic's weekly availability schedule.

**Response 200**:
```json
{
  "availability": [{
    "id": "uuid",
    "medic_id": "uuid",
    "day_of_week": 1, // 0=Sunday, 6=Saturday
    "start_time": "09:00:00",
    "end_time": "17:00:00",
    "slot_duration_min": 30,
    "buffer_min": 10,
    "is_active": true
  }]
}
```

### PUT /api/medic/availability
Update weekly availability (full replace).

**Request Body**:
```json
{
  "availability": [{
    "day_of_week": 1,
    "start_time": "09:00:00",
    "end_time": "17:00:00",
    "slot_duration_min": 30,
    "buffer_min": 10,
    "is_active": true
  }]
}
```

**Response 200**:
```json
{
  "updated": true
}
```

---

## Patients

### GET /api/medic/patients
Get medic's patient list.

**Query Params**:
- `source` (optional): direct, branch, doctor_list
- `is_active` (optional): true, false
- `limit`, `offset`

**Response 200**:
```json
{
  "patients": [{
    "id": "uuid",
    "medic_id": "uuid",
    "universal_customer_id": "uuid", // FK to customers table
    "patient_name": "Paul",
    "patient_phone": "+234...",
    "source": "direct", // direct, branch, doctor_list
    "referrer_entity_id": null, // branch_id or medic_id if referred
    "joined_at": "2026-02-15T10:00:00Z",
    "is_active": true,
    "total_consultations": 5
  }]
}
```

### POST /api/medic/patients
Invite a new patient (generate invite link).

**Request Body**:
```json
{
  "patient_email": "paul@example.com",
  "patient_phone": "+234..."
}
```

**Response 201**:
```json
{
  "patient_id": "uuid",
  "invite_url": "https://medic.kemani.com/c/dr-afoke-lagos?invite=token123",
  "referral_token": "token123"
}
```

---

## Earnings & Commission

### GET /api/medic/earnings
Get wallet balance and commission summary.

**Query Params**:
- `period` (optional): today, 7d, 30d, custom
- `date_from`, `date_to` (if period=custom): YYYY-MM-DD

**Response 200**:
```json
{
  "wallet": {
    "available_balance": 45000,
    "pending_balance": 8500,
    "total_earned": 312000,
    "total_paid_out": 258500
  },
  "this_month": {
    "consultation_earnings": 38000,
    "drug_commissions": 12400,
    "referral_earnings": 6000
  },
  "recent_ledger": [{
    "id": "uuid",
    "date": "2026-03-01",
    "type": "consultation_fee", // or "drug_commission", "referral_fee"
    "source": "Paul (patient)",
    "amount": 4500, // net after platform cut
    "status": "confirmed",
    "consultation_id": "uuid"
  }]
}
```

**Data Source**: Reads from `bridge_partner_wallets` and `bridge_commission_ledger` tables.

---

## Doctor List (Growth+ Plan Only)

### GET /api/medic/doctor-list
Get medic's listed doctors (Growth+ feature).

**Response 200**:
```json
{
  "listed_doctors": [{
    "id": "uuid",
    "host_medic_id": "uuid",
    "listed_medic_id": "uuid",
    "listed_medic_name": "Dr Afoke",
    "listed_medic_specialty": "General Practice",
    "listed_medic_photo": "https://...",
    "display_order": 1,
    "status": "active", // pending, active, declined, removed
    "commission_consultation_pct": 10,
    "commission_drug_pct": 5,
    "added_at": "2026-02-20T10:00:00Z",
    "earnings_this_month": {
      "consultations_referred": 12,
      "consultation_commissions": 6000,
      "drug_commissions": 3600
    }
  }]
}
```

### POST /api/medic/doctor-list
Invite a medic to your clinic's doctor list.

**Request Body**:
```json
{
  "listed_medic_id": "uuid",
  "display_order": 1
}
```

**Response 201**:
```json
{
  "id": "uuid",
  "status": "pending", // listed medic must accept
  "commission_terms": {
    "consultation_pct": 10,
    "drug_pct": 5
  }
}
```

### DELETE /api/medic/doctor-list/:id
Remove a medic from your doctor list.

**Response 204**: No content

---

## Agora Token Generation

### POST /api/medic/agora-token
Generate Agora RTC token for video/audio consultation.

**Request Body**:
```json
{
  "consultation_id": "uuid",
  "uid": 12345, // Unique int ID for this user in the channel
  "role": "publisher" // or "subscriber"
}
```

**Server-Side**: Generates token using Agora App ID + App Certificate from env vars.

**Response 200**:
```json
{
  "token": "006abc...",
  "channel_name": "consultation_abc123",
  "uid": 12345,
  "expires_at": "2026-03-01T11:30:00Z" // 1 hour from generation
}
```

**Stored in**: `medic_agora_tokens` table for caching.

---

## Public Clinic Profile (No Auth)

### GET /api/medic/clinic/:slug
Get public clinic profile (used by medic_web SvelteKit app).

**Response 200**:
```json
{
  "medic_id": "uuid",
  "display_name": "Dr Kate",
  "slug": "dr-kate-clinic",
  "specialties": ["pediatrics", "family_medicine"],
  "bio": "Experienced pediatrician...",
  "photo_url": "https://...",
  "consultation_fee": 7500,
  "clinic_settings": {
    "clinic_name": "Dr Kate Family Clinic",
    "logo_url": "https://...",
    "office_address": "456 Park Ave, Abuja",
    "is_accepting_patients": true
  },
  "doctor_list": [
    {
      "id": "uuid",
      "name": "Dr Afoke",
      "specialty": "General Practice",
      "photo_url": "https://...",
      "consultation_fee": 5000
    }
  ],
  "verified": true
}
```

---

## Error Codes

| Code | HTTP | Description |
|------|------|-------------|
| `MEDIC_NOT_VERIFIED` | 403 | Medic account pending verification |
| `PLAN_REQUIRED` | 403 | Feature requires Growth+ plan upgrade |
| `PATIENT_NOT_FOUND` | 404 | Patient not linked to this medic |
| `INVALID_CONSULTATION_TYPE` | 422 | Type must be: chat, audio, video, office |
| `BOOKING_CONFLICT` | 409 | Time slot already booked |
| `UNAUTHORIZED` | 401 | Authentication required |
| `NOT_FOUND` | 404 | Resource not found |

---

**Total Endpoints**: 23
**Integration**: Uses existing `bridge_*` tables for commission/wallets/prescriptions
**Agora Integration**: Server-side token generation for secure RTC access
**PowerSync**: Flutter app syncs tables locally for offline access
