# Storefront API Contract
## Healthcare Provider Directory & Telemedicine (Patient-Facing)

**Base URL**: `https://store.tenant.com/api/healthcare` (SvelteKit API routes)
**Authentication**: Session-based (Supabase Auth)
**Date**: 2026-02-21

---

## Provider Directory

### GET /providers
List healthcare providers filtered by tenant's country.

**Query Params**:
- `specialization` (optional): Filter by specialization
- `consultation_type` (optional): Filter by offered type (chat/video/audio/office_visit)
- `page` (default: 1): Pagination
- `limit` (default: 20, max: 50): Results per page

**Response 200**:
```json
{
  "providers": [{
    "id": "uuid",
    "full_name": "Dr. Jane Smith",
    "specialization": "General Practitioner",
    "credentials": "MD, MBBS",
    "years_of_experience": 15,
    "profile_photo_url": "https://...",
    "average_rating": 4.75,
    "total_consultations": 342,
    "consultation_types": ["chat", "video", "audio", "office_visit"],
    "fees": { "chat": 5000, "video": 10000, "audio": 8000, "office_visit": 15000 },
    "clinic_address": { "city": "Lagos", "country": "Nigeria" }
  }],
  "pagination": { "page": 1, "limit": 20, "total": 150, "pages": 8 }
}
```

### GET /providers/:id
Get provider details and availability.

**Response 200**:
```json
{
  "id": "uuid",
  "full_name": "Dr. Jane Smith",
  "specialization": "General Practitioner",
  "credentials": "MD, MBBS",
  "bio": "15 years of experience...",
  "years_of_experience": 15,
  "profile_photo_url": "https://...",
  "average_rating": 4.75,
  "total_consultations": 342,
  "consultation_types": ["chat", "video", "audio", "office_visit"],
  "fees": { "chat": 5000, "video": 10000, "audio": 8000, "office_visit": 15000 },
  "clinic_address": { "street": "123 Main St", "city": "Lagos", "postal_code": "100001", "country": "Nigeria" },
  "next_available": "2026-02-22T10:00:00Z"
}
```

---

## Availability & Booking

### GET /providers/:id/availability
Get available time slots for a provider.

**Query Params**:
- `consultation_type` (required): video, audio, or office_visit
- `start_date` (required): YYYY-MM-DD
- `end_date` (optional, default: start_date + 7 days): YYYY-MM-DD

**Response 200**:
```json
{
  "slots": [{
    "id": "uuid",
    "date": "2026-02-22",
    "start_time": "10:00:00",
    "end_time": "10:30:00",
    "slot_duration": 30,
    "consultation_type": "video",
    "available": true
  }],
  "timezone": "Africa/Lagos"
}
```

### POST /consultations/book
Book a consultation (creates pending consultation, redirects to payment).

**Request Body**:
```json
{
  "provider_id": "uuid",
  "consultation_type": "video", // chat, video, audio, office_visit
  "slot_id": "uuid" // Required for video/audio/office_visit, null for chat
}
```

**Response 201**:
```json
{
  "consultation_id": "uuid",
  "payment_url": "https://checkout.stripe.com/...",
  "expires_at": "2026-02-21T23:30:00Z" // 5-minute hold on slot
}
```

**Error 409** (Slot unavailable):
```json
{
  "code": "SLOT_UNAVAILABLE",
  "message": "This time slot is no longer available",
  "action": "Please refresh and choose another slot"
}
```

---

## Consultations

### GET /consultations
List patient's consultations.

**Query Params**:
- `status` (optional): pending, in_progress, completed, cancelled
- `type` (optional): chat, video, audio, office_visit
- `page`, `limit`

**Response 200**:
```json
{
  "consultations": [{
    "id": "uuid",
    "type": "video",
    "provider_name": "Dr. Jane Smith",
    "provider_photo_url": "https://...",
    "status": "pending",
    "scheduled_time": "2026-02-22T10:00:00Z",
    "slot_duration": 30,
    "consultation_fee": 10000,
    "payment_status": "paid",
    "created_at": "2026-02-21T22:00:00Z"
  }],
  "pagination": {...}
}
```

### GET /consultations/:id
Get consultation details.

**Response 200**:
```json
{
  "id": "uuid",
  "type": "video",
  "provider_id": "uuid",
  "provider_name": "Dr. Jane Smith",
  "provider_photo_url": "https://...",
  "status": "pending",
  "scheduled_time": "2026-02-22T10:00:00Z",
  "slot_duration": 30,
  "consultation_fee": 10000,
  "payment_status": "paid",
  "location_address": { /* for office visits */ },
  "agora_channel_name": "consultation_uuid", // video/audio only
  "created_at": "2026-02-21T22:00:00Z"
}
```

### POST /consultations/:id/join
Join a video/audio consultation (generates Agora token).

**Response 200**:
```json
{
  "agora_token": "006abc...",
  "channel_name": "consultation_uuid",
  "uid": 12345,
  "expires_at": "2026-02-22T10:40:00Z", // slot_duration + 10 min
  "duration_warning_at": "2026-02-22T10:25:00Z" // 5 min before end
}
```

**Error 403** (Too early/late):
```json
{
  "code": "CONSULTATION_NOT_READY",
  "message": "Consultation starts at 2026-02-22T10:00:00Z",
  "action": "Please wait until the scheduled time"
}
```

### POST /consultations/:id/cancel
Cancel a consultation (triggers refund if applicable).

**Request Body**:
```json
{
  "reason": "Scheduling conflict"
}
```

**Response 200**:
```json
{
  "cancelled": true,
  "refund_status": "full", // full, none, partial
  "refund_amount": 10000,
  "message": "Consultation cancelled. Full refund will be processed within 5-7 business days."
}
```

### POST /consultations/:id/rate
Rate a completed consultation.

**Request Body**:
```json
{
  "rating": 5, // 1-5
  "feedback": "Excellent consultation, very helpful!"
}
```

**Response 200**:
```json
{
  "rated": true
}
```

---

## Chat Messaging

### GET /consultations/:id/messages
Get chat messages (real-time via Supabase Realtime subscription recommended).

**Query Params**:
- `limit` (default: 50): Messages per page
- `before` (optional): Cursor for pagination (message ID)

**Response 200**:
```json
{
  "messages": [{
    "id": "uuid",
    "sender_type": "patient", // or "provider"
    "content": "Hello, I have a question about...",
    "attachment_url": null,
    "read_status": true,
    "created_at": "2026-02-21T22:05:00Z"
  }],
  "consultation_status": "in_progress"
}
```

### POST /consultations/:id/messages
Send a chat message.

**Request Body**:
```json
{
  "content": "Thank you for your help!",
  "attachment_url": "https://..." // optional
}
```

**Response 201**:
```json
{
  "id": "uuid",
  "created_at": "2026-02-21T22:10:00Z"
}
```

---

## Prescriptions

### GET /prescriptions
List patient's prescriptions.

**Query Params**:
- `status` (optional): active, expired, fulfilled
- `page`, `limit`

**Response 200**:
```json
{
  "prescriptions": [{
    "id": "uuid",
    "provider_name": "Dr. Jane Smith",
    "issue_date": "2026-02-21",
    "expiration_date": "2026-05-22", // 90 days
    "status": "active",
    "medication_count": 2
  }],
  "pagination": {...}
}
```

### GET /prescriptions/:id
Get prescription details.

**Response 200**:
```json
{
  "id": "uuid",
  "consultation_id": "uuid",
  "provider_name": "Dr. Jane Smith",
  "provider_credentials": "MD, MBBS",
  "issue_date": "2026-02-21",
  "expiration_date": "2026-05-22",
  "status": "active",
  "diagnosis": "Bacterial infection",
  "medications": [{
    "name": "Amoxicillin",
    "dosage": "500mg",
    "frequency": "3 times daily",
    "duration": "7 days",
    "special_instructions": "Take with food"
  }],
  "notes": "Follow up if symptoms persist after 3 days"
}
```

---

## Favorites

### GET /favorites
List favorited providers.

**Response 200**:
```json
{
  "favorites": [{
    "id": "uuid",
    "provider_id": "uuid",
    "provider_name": "Dr. Jane Smith",
    "provider_photo_url": "https://...",
    "specialization": "General Practitioner",
    "notes": "My primary care doctor",
    "created_at": "2026-01-15T10:00:00Z"
  }]
}
```

### POST /favorites
Add provider to favorites.

**Request Body**:
```json
{
  "provider_id": "uuid",
  "notes": "Recommended by friend"
}
```

**Response 201**:
```json
{
  "id": "uuid",
  "created_at": "2026-02-21T22:15:00Z"
}
```

### DELETE /favorites/:id
Remove from favorites.

**Response 204**: No content

---

## Error Codes

| Code | HTTP | Description |
|------|------|-------------|
| `SLOT_UNAVAILABLE` | 409 | Time slot no longer available |
| `PAYMENT_FAILED` | 402 | Payment processing failed |
| `CONSULTATION_NOT_READY` | 403 | Too early/late to join |
| `PRESCRIPTION_EXPIRED` | 410 | Prescription has expired |
| `UNAUTHORIZED` | 401 | Authentication required |
| `FORBIDDEN` | 403 | Access denied (wrong tenant, etc.) |
| `NOT_FOUND` | 404 | Resource not found |
| `VALIDATION_ERROR` | 422 | Invalid request data |

---

**Total Endpoints**: 15
**Real-time Features**: Chat messaging via Supabase Realtime subscriptions
**Payment Integration**: Redirects to existing storefront payment gateway
