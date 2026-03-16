# Healthcare Medic App - Complete Build Guide

**Project:** Kemani Healthcare Platform
**Platform:** Flutter (Native Mobile/Web)
**Database:** Supabase
**Architecture:** Multi-provider Healthcare Telemedicine System
**Last Updated:** March 9, 2026

---

## Table of Contents

1. [Overview](#overview)
2. [App Architecture](#app-architecture)
3. [Healthcare RPC Functions](#healthcare-rpc-functions)
4. [Authentication Flow](#authentication-flow)
5. [Page Directory](#page-directory)
6. [Detailed Page Specifications](#detailed-page-specifications)
7. [Navigation Map](#navigation-map)
8. [State Management](#state-management)
9. [Real-time Features](#real-time-features)
10. [Integration Requirements](#integration-requirements)

---

## Overview

This guide provides complete specifications for building a healthcare medic/provider application. The app enables healthcare professionals to:

- **Manage their medical practice** - Profile, availability, pricing
- **Accept consultations** - Chat, video, audio, office visits
- **Provide medical care** - Diagnoses, prescriptions, notes
- **Track earnings** - Commission-based revenue model
- **Build their practice** - Patient reviews, ratings, referrals

### Key Features

- **Multi-modal consultations**: Chat, video, audio, in-person
- **Appointment scheduling**: Time slot management with optimistic locking
- **Video/Audio calls**: Agora RTC integration
- **Digital prescriptions**: With auto-expiration and pharmacy routing
- **Revenue tracking**: Consultation fees and commission transparency
- **Patient management**: Health records and consultation history
- **Referral system**: Track referrals from storefront or other clinics

---

## App Architecture

### Healthcare Data Model

```
healthcare_providers (Medics/Doctors)
  ├── provider_availability_templates (Recurring schedules)
  ├── provider_time_slots (Bookable slots)
  ├── consultations (Sessions with patients)
  │   ├── consultation_messages (Chat messages)
  │   ├── prescriptions (Digital prescriptions)
  │   └── consultation_notes (Provider notes)
  ├── consultation_transactions (Payments & commissions)
  └── favorite_providers (Patient bookmarks)
```

### Provider Types

- **doctor** - General practitioners, specialists
- **pharmacist** - Medication experts
- **diagnostician** - Lab/imaging specialists
- **specialist** - Cardiologists, dermatologists, etc.

### Consultation Types

- **chat** - Text-based consultation (instant)
- **video** - Video call consultation (scheduled)
- **audio** - Audio call consultation (scheduled)
- **office_visit** - In-person appointment (scheduled)

### Subscription Tiers

- **free** - Basic profile, limited features
- **pro** - Enhanced profile, analytics, priority support
- **enterprise_custom** - Custom domain, white-label clinic

---

## Healthcare RPC Functions

### Complete Function List

All functions use tenant isolation and role-based access control.

#### Provider Management Functions

##### 1. `get_provider_profile`

**Purpose**: Get complete provider profile with stats.

**SQL Definition**:
```sql
CREATE OR REPLACE FUNCTION get_provider_profile(
    p_provider_id UUID
)
RETURNS TABLE (
    id UUID,
    full_name TEXT,
    slug TEXT,
    email TEXT,
    phone TEXT,
    profile_photo_url TEXT,
    type TEXT,
    specialization TEXT,
    credentials TEXT,
    license_number TEXT,
    years_of_experience INTEGER,
    bio TEXT,
    country TEXT,
    region TEXT,
    clinic_address JSONB,
    consultation_types TEXT[],
    fees JSONB,
    average_rating DECIMAL,
    total_consultations INTEGER,
    total_reviews INTEGER,
    plan_tier TEXT,
    is_verified BOOLEAN,
    is_active BOOLEAN,
    verified_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        hp.id, hp.full_name, hp.slug, hp.email, hp.phone,
        hp.profile_photo_url, hp.type, hp.specialization,
        hp.credentials, hp.license_number, hp.years_of_experience,
        hp.bio, hp.country, hp.region, hp.clinic_address,
        hp.consultation_types, hp.fees, hp.average_rating,
        hp.total_consultations, hp.total_reviews, hp.plan_tier,
        hp.is_verified, hp.is_active, hp.verified_at, hp.created_at
    FROM healthcare_providers hp
    WHERE hp.id = p_provider_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

**Parameters**:
- `p_provider_id` (UUID) - Provider ID

**Returns**: Provider profile record

**Usage in Flutter**:
```dart
final result = await Supabase.instance.client
    .rpc('get_provider_profile', params: {
      'p_provider_id': providerId,
    });
```

---

##### 2. `update_provider_profile`

**Purpose**: Update provider profile information.

**SQL Definition**:
```sql
CREATE OR REPLACE FUNCTION update_provider_profile(
    p_provider_id UUID,
    p_full_name TEXT DEFAULT NULL,
    p_bio TEXT DEFAULT NULL,
    p_specialization TEXT DEFAULT NULL,
    p_credentials TEXT DEFAULT NULL,
    p_phone TEXT DEFAULT NULL,
    p_profile_photo_url TEXT DEFAULT NULL,
    p_consultation_types TEXT[] DEFAULT NULL,
    p_fees JSONB DEFAULT NULL,
    p_clinic_address JSONB DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
    v_result JSONB;
BEGIN
    UPDATE healthcare_providers
    SET
        full_name = COALESCE(p_full_name, full_name),
        bio = COALESCE(p_bio, bio),
        specialization = COALESCE(p_specialization, specialization),
        credentials = COALESCE(p_credentials, credentials),
        phone = COALESCE(p_phone, phone),
        profile_photo_url = COALESCE(p_profile_photo_url, profile_photo_url),
        consultation_types = COALESCE(p_consultation_types, consultation_types),
        fees = COALESCE(p_fees, fees),
        clinic_address = COALESCE(p_clinic_address, clinic_address),
        updated_at = NOW()
    WHERE id = p_provider_id
    AND user_id = auth.uid();

    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'message', 'Unauthorized or provider not found');
    END IF;

    RETURN jsonb_build_object('success', true, 'message', 'Profile updated successfully');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

**Parameters**:
- All parameters optional (only updates provided fields)

**Returns**: Success/error JSONB

---

#### Availability & Scheduling Functions

##### 3. `create_availability_template`

**Purpose**: Create recurring availability schedule.

**SQL Definition**:
```sql
CREATE OR REPLACE FUNCTION create_availability_template(
    p_provider_id UUID,
    p_day_of_week INTEGER,
    p_start_time TIME,
    p_end_time TIME,
    p_slot_duration INTEGER,
    p_buffer_minutes INTEGER DEFAULT 0,
    p_consultation_types TEXT[] DEFAULT ARRAY['chat', 'video', 'audio', 'office_visit']
)
RETURNS UUID AS $$
DECLARE
    v_template_id UUID;
BEGIN
    -- Verify provider owns this
    IF NOT EXISTS (
        SELECT 1 FROM healthcare_providers
        WHERE id = p_provider_id AND user_id = auth.uid()
    ) THEN
        RAISE EXCEPTION 'Unauthorized';
    END IF;

    INSERT INTO provider_availability_templates (
        provider_id, day_of_week, start_time, end_time,
        slot_duration, buffer_minutes, consultation_types
    ) VALUES (
        p_provider_id, p_day_of_week, p_start_time, p_end_time,
        p_slot_duration, p_buffer_minutes, p_consultation_types
    )
    RETURNING id INTO v_template_id;

    RETURN v_template_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

**Parameters**:
- `p_day_of_week` (INTEGER) - 0=Sunday, 6=Saturday
- `p_start_time` (TIME) - Start time (e.g., '09:00')
- `p_end_time` (TIME) - End time (e.g., '17:00')
- `p_slot_duration` (INTEGER) - Duration in minutes (15, 30, 45, 60)
- `p_buffer_minutes` (INTEGER) - Buffer between appointments

**Returns**: Template ID

---

##### 4. `generate_time_slots`

**Purpose**: Generate bookable slots from templates for date range.

**SQL Definition**:
```sql
CREATE OR REPLACE FUNCTION generate_time_slots(
    p_provider_id UUID,
    p_start_date DATE,
    p_end_date DATE
)
RETURNS INTEGER AS $$
DECLARE
    v_slots_created INTEGER := 0;
    v_template RECORD;
    v_current_date DATE;
    v_current_time TIME;
    v_slot_end_time TIME;
BEGIN
    -- Verify provider
    IF NOT EXISTS (
        SELECT 1 FROM healthcare_providers
        WHERE id = p_provider_id AND user_id = auth.uid()
    ) THEN
        RAISE EXCEPTION 'Unauthorized';
    END IF;

    -- Loop through templates
    FOR v_template IN
        SELECT * FROM provider_availability_templates
        WHERE provider_id = p_provider_id AND is_active = TRUE
    LOOP
        -- Loop through dates
        v_current_date := p_start_date;
        WHILE v_current_date <= p_end_date LOOP
            -- Check if day matches template
            IF EXTRACT(DOW FROM v_current_date)::INTEGER = v_template.day_of_week THEN
                -- Generate slots for this day
                v_current_time := v_template.start_time;
                WHILE v_current_time < v_template.end_time LOOP
                    v_slot_end_time := v_current_time + (v_template.slot_duration || ' minutes')::INTERVAL;

                    -- Skip if slot already exists
                    IF NOT EXISTS (
                        SELECT 1 FROM provider_time_slots
                        WHERE provider_id = p_provider_id
                        AND date = v_current_date
                        AND start_time = v_current_time
                    ) THEN
                        -- Create slot for each consultation type
                        INSERT INTO provider_time_slots (
                            provider_id, template_id, date, start_time, end_time,
                            slot_duration, consultation_type, status
                        )
                        SELECT
                            p_provider_id, v_template.id, v_current_date,
                            v_current_time, v_slot_end_time::TIME,
                            v_template.slot_duration,
                            unnest(v_template.consultation_types),
                            'available';

                        v_slots_created := v_slots_created + array_length(v_template.consultation_types, 1);
                    END IF;

                    -- Move to next slot
                    v_current_time := v_slot_end_time::TIME + (v_template.buffer_minutes || ' minutes')::INTERVAL;
                END LOOP;
            END IF;

            v_current_date := v_current_date + 1;
        END LOOP;
    END LOOP;

    RETURN v_slots_created;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

**Parameters**:
- `p_start_date` (DATE) - Start date
- `p_end_date` (DATE) - End date

**Returns**: Number of slots created

---

##### 5. `get_provider_available_slots`

**Purpose**: Get available slots for booking.

**SQL Definition**:
```sql
CREATE OR REPLACE FUNCTION get_provider_available_slots(
    p_provider_id UUID,
    p_consultation_type TEXT,
    p_start_date DATE,
    p_end_date DATE
)
RETURNS TABLE (
    slot_id UUID,
    date DATE,
    start_time TIME,
    end_time TIME,
    slot_duration INTEGER,
    consultation_type TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        pts.id, pts.date, pts.start_time, pts.end_time,
        pts.slot_duration, pts.consultation_type
    FROM provider_time_slots pts
    WHERE pts.provider_id = p_provider_id
    AND pts.consultation_type = p_consultation_type
    AND pts.date BETWEEN p_start_date AND p_end_date
    AND pts.status = 'available'
    AND pts.date >= CURRENT_DATE
    ORDER BY pts.date, pts.start_time;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

---

#### Consultation Management Functions

##### 6. `get_provider_consultations`

**Purpose**: Get provider's consultation list with filters.

**SQL Definition**:
```sql
CREATE OR REPLACE FUNCTION get_provider_consultations(
    p_provider_id UUID,
    p_status TEXT DEFAULT NULL,
    p_start_date DATE DEFAULT NULL,
    p_end_date DATE DEFAULT NULL,
    p_limit INTEGER DEFAULT 50,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    consultation_id UUID,
    patient_name TEXT,
    patient_photo TEXT,
    consultation_type TEXT,
    status TEXT,
    scheduled_time TIMESTAMPTZ,
    started_at TIMESTAMPTZ,
    ended_at TIMESTAMPTZ,
    consultation_fee DECIMAL,
    payment_status TEXT,
    referral_source TEXT,
    created_at TIMESTAMPTZ,
    unread_messages INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        c.id,
        u.full_name,
        u.avatar_url,
        c.type,
        c.status,
        c.scheduled_time,
        c.started_at,
        c.ended_at,
        c.consultation_fee,
        c.payment_status,
        c.referral_source,
        c.created_at,
        (SELECT COUNT(*)::INTEGER
         FROM consultation_messages cm
         WHERE cm.consultation_id = c.id
         AND cm.sender_type = 'patient'
         AND cm.read_at IS NULL) as unread_messages
    FROM consultations c
    JOIN users u ON c.patient_id = u.id
    WHERE c.provider_id = p_provider_id
    AND (p_status IS NULL OR c.status = p_status)
    AND (p_start_date IS NULL OR c.created_at::DATE >= p_start_date)
    AND (p_end_date IS NULL OR c.created_at::DATE <= p_end_date)
    ORDER BY
        CASE WHEN c.status = 'in_progress' THEN 1
             WHEN c.status = 'pending' THEN 2
             ELSE 3 END,
        c.scheduled_time DESC NULLS LAST,
        c.created_at DESC
    LIMIT p_limit OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

**Parameters**:
- `p_status` (TEXT) - Filter by status (pending, in_progress, completed, cancelled)
- `p_start_date`, `p_end_date` (DATE) - Date range filter
- `p_limit`, `p_offset` (INTEGER) - Pagination

**Returns**: Consultation list with patient details

---

##### 7. `start_consultation`

**Purpose**: Start a consultation session.

**SQL Definition**:
```sql
CREATE OR REPLACE FUNCTION start_consultation(
    p_consultation_id UUID
)
RETURNS JSONB AS $$
DECLARE
    v_consultation RECORD;
    v_channel_name TEXT;
    v_token_patient TEXT;
    v_token_provider TEXT;
    v_token_expiry TIMESTAMPTZ;
BEGIN
    -- Get consultation
    SELECT * INTO v_consultation
    FROM consultations
    WHERE id = p_consultation_id
    AND provider_id IN (
        SELECT id FROM healthcare_providers WHERE user_id = auth.uid()
    );

    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'message', 'Consultation not found');
    END IF;

    -- Check if payment is confirmed
    IF v_consultation.payment_status != 'paid' THEN
        RETURN jsonb_build_object('success', false, 'message', 'Payment not confirmed');
    END IF;

    -- Generate Agora tokens for video/audio
    IF v_consultation.type IN ('video', 'audio') THEN
        v_channel_name := 'consultation_' || p_consultation_id::TEXT;
        v_token_expiry := NOW() + INTERVAL '2 hours';

        -- These would be generated by your backend Agora token generator
        -- For now, placeholder values
        v_token_patient := 'patient_token_' || gen_random_uuid()::TEXT;
        v_token_provider := 'provider_token_' || gen_random_uuid()::TEXT;

        UPDATE consultations
        SET
            status = 'in_progress',
            started_at = NOW(),
            agora_channel_name = v_channel_name,
            agora_token_patient = v_token_patient,
            agora_token_provider = v_token_provider,
            agora_token_expiry = v_token_expiry
        WHERE id = p_consultation_id;

        RETURN jsonb_build_object(
            'success', true,
            'channel_name', v_channel_name,
            'token', v_token_provider,
            'token_expiry', v_token_expiry
        );
    ELSE
        -- For chat/office visits
        UPDATE consultations
        SET status = 'in_progress', started_at = NOW()
        WHERE id = p_consultation_id;

        RETURN jsonb_build_object('success', true);
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

**Returns**: Success with Agora credentials (for video/audio)

---

##### 8. `complete_consultation`

**Purpose**: Mark consultation as completed.

**SQL Definition**:
```sql
CREATE OR REPLACE FUNCTION complete_consultation(
    p_consultation_id UUID,
    p_diagnosis TEXT DEFAULT NULL,
    p_notes TEXT DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
    v_provider_id UUID;
BEGIN
    -- Verify provider owns this consultation
    SELECT provider_id INTO v_provider_id
    FROM consultations
    WHERE id = p_consultation_id
    AND provider_id IN (
        SELECT id FROM healthcare_providers WHERE user_id = auth.uid()
    );

    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'message', 'Unauthorized');
    END IF;

    -- Update consultation
    UPDATE consultations
    SET
        status = 'completed',
        ended_at = NOW()
    WHERE id = p_consultation_id;

    -- Add completion note if provided
    IF p_diagnosis IS NOT NULL OR p_notes IS NOT NULL THEN
        INSERT INTO consultation_notes (
            consultation_id, provider_id, note_type, content
        ) VALUES (
            p_consultation_id, v_provider_id, 'completion',
            jsonb_build_object(
                'diagnosis', p_diagnosis,
                'notes', p_notes
            )::TEXT
        );
    END IF;

    RETURN jsonb_build_object('success', true, 'message', 'Consultation completed');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

---

#### Prescription Functions

##### 9. `create_prescription`

**Purpose**: Create digital prescription after consultation.

**SQL Definition**:
```sql
CREATE OR REPLACE FUNCTION create_prescription(
    p_consultation_id UUID,
    p_diagnosis TEXT,
    p_medications JSONB,
    p_notes TEXT DEFAULT NULL,
    p_routing_strategy TEXT DEFAULT 'patient_choice'
)
RETURNS UUID AS $$
DECLARE
    v_prescription_id UUID;
    v_provider RECORD;
    v_patient_id UUID;
BEGIN
    -- Get provider info
    SELECT hp.id, hp.full_name, hp.credentials, c.patient_id
    INTO v_provider
    FROM consultations c
    JOIN healthcare_providers hp ON c.provider_id = hp.id
    WHERE c.id = p_consultation_id
    AND hp.user_id = auth.uid();

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Unauthorized or consultation not found';
    END IF;

    -- Validate medications JSONB structure
    -- Expected: [{"name": "Medication", "dosage": "500mg", "frequency": "twice daily", "duration": "7 days"}]

    -- Create prescription
    INSERT INTO prescriptions (
        consultation_id, provider_id, patient_id,
        diagnosis, medications, notes,
        routing_strategy, provider_name, provider_credentials,
        status, issue_date, expiration_date
    ) VALUES (
        p_consultation_id, v_provider.id, v_provider.patient_id,
        p_diagnosis, p_medications, p_notes,
        p_routing_strategy, v_provider.full_name, v_provider.credentials,
        'active', CURRENT_DATE, CURRENT_DATE + INTERVAL '90 days'
    )
    RETURNING id INTO v_prescription_id;

    RETURN v_prescription_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

**Parameters**:
- `p_medications` (JSONB) - Array of medication objects

**Medications JSONB Example**:
```json
[
  {
    "name": "Amoxicillin",
    "dosage": "500mg",
    "frequency": "3 times daily",
    "duration": "7 days",
    "instructions": "Take with food"
  },
  {
    "name": "Ibuprofen",
    "dosage": "400mg",
    "frequency": "As needed for pain",
    "duration": "5 days",
    "instructions": "Do not exceed 3 doses per day"
  }
]
```

---

#### Messaging Functions

##### 10. `send_consultation_message`

**Purpose**: Send message in consultation chat.

**SQL Definition**:
```sql
CREATE OR REPLACE FUNCTION send_consultation_message(
    p_consultation_id UUID,
    p_content TEXT,
    p_attachments JSONB DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_message_id UUID;
    v_sender_id UUID;
BEGIN
    -- Get provider user_id
    SELECT user_id INTO v_sender_id
    FROM healthcare_providers
    WHERE id IN (
        SELECT provider_id FROM consultations WHERE id = p_consultation_id
    )
    AND user_id = auth.uid();

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Unauthorized';
    END IF;

    -- Insert message
    INSERT INTO consultation_messages (
        consultation_id, sender_id, sender_type,
        content, attachments
    ) VALUES (
        p_consultation_id, v_sender_id, 'provider',
        p_content, p_attachments
    )
    RETURNING id INTO v_message_id;

    RETURN v_message_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

---

##### 11. `get_consultation_messages`

**Purpose**: Get messages for a consultation.

**SQL Definition**:
```sql
CREATE OR REPLACE FUNCTION get_consultation_messages(
    p_consultation_id UUID,
    p_limit INTEGER DEFAULT 100,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    message_id UUID,
    sender_name TEXT,
    sender_type TEXT,
    content TEXT,
    attachments JSONB,
    read_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ
) AS $$
BEGIN
    -- Verify access
    IF NOT EXISTS (
        SELECT 1 FROM consultations c
        WHERE c.id = p_consultation_id
        AND (
            c.provider_id IN (SELECT id FROM healthcare_providers WHERE user_id = auth.uid())
            OR c.patient_id = auth.uid()
        )
    ) THEN
        RAISE EXCEPTION 'Unauthorized';
    END IF;

    RETURN QUERY
    SELECT
        cm.id,
        u.full_name,
        cm.sender_type,
        cm.content,
        cm.attachments,
        cm.read_at,
        cm.created_at
    FROM consultation_messages cm
    JOIN users u ON cm.sender_id = u.id
    WHERE cm.consultation_id = p_consultation_id
    ORDER BY cm.created_at ASC
    LIMIT p_limit OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

---

#### Revenue & Analytics Functions

##### 12. `get_provider_earnings_summary`

**Purpose**: Get earnings summary for date range.

**SQL Definition**:
```sql
CREATE OR REPLACE FUNCTION get_provider_earnings_summary(
    p_provider_id UUID,
    p_start_date DATE,
    p_end_date DATE
)
RETURNS TABLE (
    total_consultations INTEGER,
    gross_earnings DECIMAL,
    total_commission DECIMAL,
    net_earnings DECIMAL,
    pending_payout DECIMAL,
    paid_out DECIMAL,
    by_consultation_type JSONB
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        COUNT(*)::INTEGER as total_consultations,
        SUM(ct.gross_amount) as gross_earnings,
        SUM(ct.commission_amount) as total_commission,
        SUM(ct.net_provider_amount) as net_earnings,
        SUM(CASE WHEN ct.payout_status = 'pending_payout' THEN ct.net_provider_amount ELSE 0 END) as pending_payout,
        SUM(CASE WHEN ct.payout_status = 'paid_out' THEN ct.net_provider_amount ELSE 0 END) as paid_out,
        jsonb_object_agg(
            c.type,
            jsonb_build_object(
                'count', COUNT(*),
                'earnings', SUM(ct.net_provider_amount)
            )
        ) as by_consultation_type
    FROM consultation_transactions ct
    JOIN consultations c ON ct.consultation_id = c.id
    WHERE ct.provider_id = p_provider_id
    AND c.created_at::DATE BETWEEN p_start_date AND p_end_date
    AND ct.payment_status = 'completed';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

**Returns**: Earnings breakdown with totals

---

##### 13. `get_provider_dashboard_stats`

**Purpose**: Get dashboard overview statistics.

**SQL Definition**:
```sql
CREATE OR REPLACE FUNCTION get_provider_dashboard_stats(
    p_provider_id UUID
)
RETURNS JSONB AS $$
DECLARE
    v_stats JSONB;
BEGIN
    SELECT jsonb_build_object(
        'today_consultations', (
            SELECT COUNT(*) FROM consultations
            WHERE provider_id = p_provider_id
            AND created_at::DATE = CURRENT_DATE
        ),
        'pending_consultations', (
            SELECT COUNT(*) FROM consultations
            WHERE provider_id = p_provider_id
            AND status = 'pending'
        ),
        'active_consultation', (
            SELECT jsonb_build_object(
                'id', id,
                'patient_name',
                    (SELECT full_name FROM users WHERE id = patient_id),
                'type', type,
                'started_at', started_at
            )
            FROM consultations
            WHERE provider_id = p_provider_id
            AND status = 'in_progress'
            ORDER BY started_at DESC
            LIMIT 1
        ),
        'this_week_earnings', (
            SELECT COALESCE(SUM(net_provider_amount), 0)
            FROM consultation_transactions
            WHERE provider_id = p_provider_id
            AND created_at >= date_trunc('week', CURRENT_DATE)
            AND payment_status = 'completed'
        ),
        'this_month_consultations', (
            SELECT COUNT(*) FROM consultations
            WHERE provider_id = p_provider_id
            AND created_at >= date_trunc('month', CURRENT_DATE)
            AND status = 'completed'
        ),
        'average_rating', (
            SELECT average_rating FROM healthcare_providers
            WHERE id = p_provider_id
        ),
        'unread_messages', (
            SELECT COUNT(*)
            FROM consultation_messages cm
            JOIN consultations c ON cm.consultation_id = c.id
            WHERE c.provider_id = p_provider_id
            AND cm.sender_type = 'patient'
            AND cm.read_at IS NULL
        )
    ) INTO v_stats;

    RETURN v_stats;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

**Returns**: Dashboard stats JSONB

---

## Detailed Page Specifications

---

## 1. Provider Dashboard

### Purpose
Overview of provider's practice with key metrics and quick actions.

### User Access
Healthcare providers (logged in)

### Data Sources

**Table**: `consultations`, `consultation_transactions`, `healthcare_providers`

**RPC Function**: `get_provider_dashboard_stats`

### UI Components

#### Header Section
- Provider photo and name
- Specialization badge
- Rating display (stars + count)
- "Edit Profile" button

#### Stats Cards (Row of 4)
1. **Today's Consultations**
   - Count of consultations today
   - Icon: calendar

2. **Pending Requests**
   - Count of pending consultations
   - Icon: clock
   - Badge if > 0

3. **This Week Earnings**
   - Net earnings for current week
   - Icon: money
   - Format: Currency

4. **Average Rating**
   - Current rating out of 5
   - Icon: star
   - Color: gold

#### Active Consultation Card (if any)
- Shows current in-progress consultation
- Patient name and photo
- Consultation type badge
- "Continue" button → Navigate to consultation detail
- Timer showing duration

#### Quick Actions (Grid 2x2)
1. **New Consultation** → Start chat consultation
2. **My Schedule** → Availability management
3. **Earnings** → Revenue tracking
4. **Patients** → Patient list

#### Upcoming Appointments (List)
- Next 5 scheduled appointments
- Each item shows:
  - Patient name
  - Time
  - Consultation type
  - "Start" button (if time is now)

#### Recent Activity (List)
- Last 10 consultations
- Status badges
- Patient names
- Quick view button

### Button Actions

| Button | Action | Navigation |
|--------|--------|------------|
| Edit Profile | Navigate to profile edit | → Profile Edit Page |
| Pending Badge | Show pending consultations | → Consultations (filtered) |
| Continue (Active) | Resume consultation | → Consultation Detail |
| New Consultation | Start instant chat | → Chat Consultation |
| My Schedule | Manage availability | → Availability Page |
| Earnings | View revenue details | → Earnings Page |
| Patients | View patient list | → Patients List |
| Start (Appointment) | Start scheduled consultation | → Consultation Detail |

### Data Fetching
```dart
// On page load
final stats = await Supabase.instance.client.rpc(
  'get_provider_dashboard_stats',
  params: {'p_provider_id': currentProviderId},
);

setState(() {
  todayConsultations = stats['today_consultations'];
  pendingCount = stats['pending_consultations'];
  weekEarnings = stats['this_week_earnings'];
  averageRating = stats['average_rating'];
  activeConsultation = stats['active_consultation'];
  unreadMessages = stats['unread_messages'];
});

// Fetch upcoming appointments
final appointments = await Supabase.instance.client
  .from('consultations')
  .select('*, users!inner(full_name, avatar_url)')
  .eq('provider_id', currentProviderId)
  .eq('status', 'pending')
  .gte('scheduled_time', DateTime.now().toIso8601String())
  .order('scheduled_time')
  .limit(5);
```

### Real-time Subscriptions
```dart
// Listen for new consultation requests
final subscription = Supabase.instance.client
  .from('consultations')
  .stream(primaryKey: ['id'])
  .eq('provider_id', currentProviderId)
  .listen((data) {
    // Refresh dashboard stats
    loadDashboardData();

    // Show notification for new consultation
    if (data.any((c) => c['status'] == 'pending')) {
      showNotification('New consultation request');
    }
  });
```

### FlutterFlow AI Prompt
```
Create a healthcare provider dashboard with:
- Header with circular avatar (120px), provider name (heading 4), specialization chip, and star rating
- Edit profile button (top right)
- Grid of 4 stat cards with icons, numbers, and labels
- Highlighted card for active consultation (if exists) with gradient background
- 2x2 grid of action buttons with icons
- "Upcoming Appointments" section with list of 5 items
- "Recent Activity" feed with consultation history
- Pull-to-refresh functionality
- Bottom navigation bar with: Home, Consultations, Schedule, Earnings, Profile
- Use primary color: teal, accent: orange
- Modern card shadows and rounded corners (16px)
- Responsive layout for mobile and tablet
```

---

## 2. Consultations List

### Purpose
View all consultations with filtering and status management.

### User Access
Healthcare providers

### Data Sources

**Table**: `consultations`, `users`, `consultation_messages`

**RPC Function**: `get_provider_consultations`

### UI Components

#### Top Filter Bar
- Tabs for status filter:
  - All
  - Pending (badge with count)
  - In Progress (badge if any)
  - Completed
  - Cancelled
- Date range picker
- Search by patient name

#### Consultation List
Each list item shows:
- Patient avatar and name
- Consultation type badge (Chat, Video, Audio, Office)
- Status badge with color coding:
  - Pending: orange
  - In Progress: green
  - Completed: blue
  - Cancelled: red
- Scheduled time (if applicable)
- Fee amount
- Unread message count badge (if chat)
- Payment status indicator

#### Empty State
- Icon and message when no consultations
- "Start New Consultation" button

### Button Actions

| Button | Action | Navigation |
|--------|--------|------------|
| Consultation Item | View details | → Consultation Detail |
| Filter Tab | Filter list | Update list |
| Date Range | Set date filter | Update list |
| Start New | Create consultation | → New Consultation |

### Data Fetching
```dart
Future<void> loadConsultations() async {
  final result = await Supabase.instance.client.rpc(
    'get_provider_consultations',
    params: {
      'p_provider_id': currentProviderId,
      'p_status': selectedStatus, // null for 'All'
      'p_start_date': dateRange?.start.toIso8601String(),
      'p_end_date': dateRange?.end.toIso8601String(),
      'p_limit': 50,
      'p_offset': page * 50,
    },
  );

  setState(() {
    consultations = result;
  });
}

// Search filter (client-side)
List<dynamic> get filteredConsultations {
  if (searchQuery.isEmpty) return consultations;
  return consultations.where((c) =>
    c['patient_name'].toLowerCase().contains(searchQuery.toLowerCase())
  ).toList();
}
```

### Real-time Updates
```dart
// Listen for consultation updates
Supabase.instance.client
  .from('consultations')
  .stream(primaryKey: ['id'])
  .eq('provider_id', currentProviderId)
  .listen((data) {
    loadConsultations(); // Refresh list
  });
```

### FlutterFlow AI Prompt
```
Create a consultations list page with:
- Top tab bar with status filters (All, Pending, In Progress, Completed, Cancelled)
- Badge counters on tabs
- Search bar with icon
- Date range picker button
- ListView with consultation cards
- Each card has: patient avatar (left), name, type badge, time, fee, status badge, unread count
- Color-coded status badges
- Pull-to-refresh
- Infinite scroll pagination
- Floating action button for "New Consultation"
- Empty state illustration when no results
- Shimmer loading placeholders
```

---

## 3. Consultation Detail

### Purpose
View and manage a specific consultation session.

### User Access
Provider assigned to the consultation

### Data Sources

**Table**: `consultations`, `users`, `consultation_messages`, `prescriptions`

**RPC Functions**:
- `start_consultation`
- `complete_consultation`
- `send_consultation_message`
- `get_consultation_messages`

### UI Components

#### Header
- Back button
- Consultation ID
- Status badge
- More options menu (Cancel, Refund, etc.)

#### Patient Info Card
- Avatar and name
- Age, gender, blood type
- Contact: phone, email
- Medical history button
- Emergency contact button

#### Consultation Details Card
- Type (with icon)
- Scheduled time
- Duration (if in progress/completed)
- Fee amount
- Payment status
- Referral source

#### Action Buttons (Based on Status)

**If Pending:**
- "Start Consultation" (primary button)
- "Reschedule"
- "Cancel"

**If In Progress:**
- Chat area (if type = chat)
- Video call controls (if type = video/audio)
- "Write Prescription" button
- "Complete Consultation" button

**If Completed:**
- View chat history
- View prescription (if exists)
- "Create Follow-up"

#### Chat Interface (for chat consultations)
- Message list (scrollable)
- Message bubbles (provider: right, patient: left)
- Image/file attachments
- Message input field
- Send button
- Attachment button

#### Video/Audio Call (for video/audio consultations)
- Agora video container
- Call controls:
  - Mute/Unmute
  - Camera on/off (video only)
  - End call
- Timer display
- Network quality indicator

### Button Actions

| Button | Action | API Call | Navigation |
|--------|--------|----------|------------|
| Start Consultation | Begin session | `start_consultation` | Update status |
| Send Message | Send chat message | `send_consultation_message` | Update chat |
| Complete Consultation | Finish session | `complete_consultation` | → Completion Form |
| Write Prescription | Create prescription | Modal | → Prescription Form |
| Reschedule | Change time | Update | → Schedule Picker |
| Cancel | Cancel consultation | Update | Back |

### Data Fetching
```dart
// Load consultation details
Future<void> loadConsultation() async {
  final consultation = await Supabase.instance.client
    .from('consultations')
    .select('''
      *,
      users!inner(full_name, avatar_url, phone, email),
      prescriptions(*)
    ''')
    .eq('id', consultationId)
    .single();

  setState(() {
    consultationData = consultation;
  });

  // If chat type, load messages
  if (consultation['type'] == 'chat') {
    loadMessages();
  }
}

// Load messages
Future<void> loadMessages() async {
  final messages = await Supabase.instance.client.rpc(
    'get_consultation_messages',
    params: {
      'p_consultation_id': consultationId,
      'p_limit': 100,
    },
  );

  setState(() {
    chatMessages = messages;
  });
}

// Start consultation
Future<void> startConsultation() async {
  final result = await Supabase.instance.client.rpc(
    'start_consultation',
    params: {'p_consultation_id': consultationId},
  );

  if (result['success']) {
    if (consultationData['type'] == 'video' || consultationData['type'] == 'audio') {
      // Initialize Agora
      initializeAgora(
        channelName: result['channel_name'],
        token: result['token'],
      );
    }

    setState(() {
      consultationData['status'] = 'in_progress';
    });
  }
}

// Send message
Future<void> sendMessage(String content) async {
  await Supabase.instance.client.rpc(
    'send_consultation_message',
    params: {
      'p_consultation_id': consultationId,
      'p_content': content,
    },
  );

  // Message will appear via real-time subscription
}

// Complete consultation
Future<void> completeConsultation(String diagnosis, String notes) async {
  final result = await Supabase.instance.client.rpc(
    'complete_consultation',
    params: {
      'p_consultation_id': consultationId,
      'p_diagnosis': diagnosis,
      'p_notes': notes,
    },
  );

  if (result['success']) {
    showSuccessSnackbar('Consultation completed');
    Navigator.pop(context);
  }
}
```

### Real-time Subscriptions
```dart
// Listen for new messages
Supabase.instance.client
  .from('consultation_messages')
  .stream(primaryKey: ['id'])
  .eq('consultation_id', consultationId)
  .listen((messages) {
    setState(() {
      chatMessages = messages;
    });
    scrollToBottom();
  });

// Listen for consultation status changes
Supabase.instance.client
  .from('consultations')
  .stream(primaryKey: ['id'])
  .eq('id', consultationId)
  .listen((data) {
    if (data.isNotEmpty) {
      setState(() {
        consultationData = data.first;
      });
    }
  });
```

### FlutterFlow AI Prompt
```
Create a consultation detail page with:
- App bar with back button, consultation ID, status badge
- Patient info card with avatar, name, vital stats, contact buttons
- Consultation details card with type icon, time, fee, payment badge
- Dynamic action buttons based on status
- For chat: WhatsApp-style chat interface with message bubbles
- For video/audio: full-screen video container with floating controls
- Prescription section (if exists) with medication list
- Completion form modal with diagnosis and notes fields
- Real-time message updates
- Network status indicator
- Professional medical UI theme with white/blue color scheme
```

---

## 4. Create Prescription

### Purpose
Write digital prescription after consultation.

### User Access
Provider during/after consultation

### Data Sources

**Table**: `prescriptions`, `consultations`

**RPC Function**: `create_prescription`

### UI Components

#### Header
- "Write Prescription" title
- Close button
- Save draft button

#### Consultation Context
- Patient name
- Consultation date
- Consultation type

#### Form Fields

**Diagnosis** (Required)
- Multi-line text input
- Character limit: 500
- Hint: "Primary diagnosis or condition"

**Medications** (Dynamic List)
- Add medication button
- Each medication has:
  - Medication name (searchable dropdown with common drugs)
  - Dosage (text field with units)
  - Frequency (dropdown: once daily, twice daily, three times daily, as needed)
  - Duration (number field + unit selector: days, weeks, months)
  - Instructions (optional text)
  - Remove button

**Additional Notes** (Optional)
- Multi-line text input
- Hint: "Lifestyle recommendations, follow-up instructions"

**Pharmacy Routing**
- Radio buttons:
  - Patient choice (default)
  - Specific pharmacy (with search)
  - Auto-route to nearest

### Button Actions

| Button | Action | API Call | Result |
|--------|--------|----------|--------|
| Add Medication | Add form row | - | Add to list |
| Remove Medication | Remove row | - | Update list |
| Save Draft | Save without submitting | Insert draft | Close modal |
| Create Prescription | Submit prescription | `create_prescription` | Success → Close |
| Cancel | Discard | - | Confirm → Close |

### Data Fetching
```dart
// Create prescription
Future<void> createPrescription() async {
  // Validate form
  if (!_formKey.currentState!.validate()) {
    return;
  }

  // Build medications JSONB
  final medicationsJson = medications.map((med) => {
    'name': med.name,
    'dosage': med.dosage,
    'frequency': med.frequency,
    'duration': med.duration,
    'instructions': med.instructions,
  }).toList();

  // Call RPC function
  try {
    final prescriptionId = await Supabase.instance.client.rpc(
      'create_prescription',
      params: {
        'p_consultation_id': consultationId,
        'p_diagnosis': diagnosisController.text,
        'p_medications': medicationsJson,
        'p_notes': notesController.text,
        'p_routing_strategy': selectedRouting,
      },
    );

    showSuccessSnackbar('Prescription created successfully');
    Navigator.pop(context, prescriptionId);
  } catch (e) {
    showErrorSnackbar('Failed to create prescription: $e');
  }
}

// Load common medications for autocomplete
Future<List<String>> searchMedications(String query) async {
  // This could be from a local database or API
  return commonMedications.where((med) =>
    med.toLowerCase().contains(query.toLowerCase())
  ).toList();
}
```

### Validation Rules
- Diagnosis: Required, min 10 characters
- Medications: At least 1 medication required
- Each medication: name, dosage, frequency, duration required

### FlutterFlow AI Prompt
```
Create a prescription form modal with:
- Full-screen modal with header and close button
- Patient context card at top
- Form with validation
- Diagnosis text area with character counter
- Medications section with "Add Medication" button
- Each medication card with:
  * Autocomplete search for drug name
  * Dosage input with unit selector
  * Frequency dropdown
  * Duration number input with unit (days/weeks/months)
  * Instructions text field
  * Delete icon button
- Notes text area
- Pharmacy routing radio group
- Bottom action bar with "Cancel" and "Create Prescription" buttons
- Loading overlay during submission
- Success animation on completion
```

---

## 5. Availability Management

### Purpose
Set up and manage consultation availability schedule.

### User Access
Healthcare providers

### Data Sources

**Table**: `provider_availability_templates`, `provider_time_slots`

**RPC Functions**:
- `create_availability_template`
- `generate_time_slots`

### UI Components

#### Tab Navigation
- **Templates** - Recurring weekly schedule
- **Calendar** - View generated slots
- **Blocked Dates** - Manage unavailable dates

#### Templates Tab

**Weekly Schedule Grid**
- 7 rows (Sunday - Saturday)
- Each row shows:
  - Day name
  - Toggle switch (available/unavailable)
  - Time range (start - end)
  - Slot duration selector
  - Consultation types chips
  - Edit/Delete buttons

**Add Template Button** (Floating)
- Opens template form modal

#### Calendar Tab

**Month Calendar View**
- Days with available slots: green dot
- Days fully booked: red dot
- Today highlighted
- Click day to see slot details

**Day Detail View** (Bottom Sheet)
- List of time slots for selected day
- Each slot shows:
  - Time
  - Consultation type
  - Status (available/booked/blocked)
  - Toggle to block/unblock

**Generate Slots Button**
- Opens date range picker
- Generates slots from templates

#### Blocked Dates Tab

**Date Ranges List**
- List of blocked periods
- Each with start date, end date, reason
- Delete button

**Add Blocked Date Button**

### Button Actions

| Button | Action | API Call | Result |
|--------|--------|----------|--------|
| Day Toggle | Enable/disable day | - | Show time picker |
| Edit Template | Modify template | Update template | Refresh |
| Delete Template | Remove template | Delete | Refresh |
| Add Template | Create new template | `create_availability_template` | Add to list |
| Generate Slots | Create bookable slots | `generate_time_slots` | Success message |
| Block Date | Mark date unavailable | Update slots | Update calendar |

### Data Fetching
```dart
// Load templates
Future<void> loadTemplates() async {
  final templates = await Supabase.instance.client
    .from('provider_availability_templates')
    .select()
    .eq('provider_id', currentProviderId)
    .eq('is_active', true)
    .order('day_of_week');

  setState(() {
    availabilityTemplates = templates;
  });
}

// Create template
Future<void> createTemplate() async {
  final templateId = await Supabase.instance.client.rpc(
    'create_availability_template',
    params: {
      'p_provider_id': currentProviderId,
      'p_day_of_week': selectedDay,
      'p_start_time': startTime.format(context),
      'p_end_time': endTime.format(context),
      'p_slot_duration': slotDuration,
      'p_buffer_minutes': bufferMinutes,
      'p_consultation_types': selectedTypes,
    },
  );

  showSuccessSnackbar('Schedule template created');
  loadTemplates();
}

// Generate slots
Future<void> generateSlots() async {
  showLoadingDialog();

  final slotsCreated = await Supabase.instance.client.rpc(
    'generate_time_slots',
    params: {
      'p_provider_id': currentProviderId,
      'p_start_date': startDate.toIso8601String(),
      'p_end_date': endDate.toIso8601String(),
    },
  );

  hideLoadingDialog();
  showSuccessSnackbar('$slotsCreated slots created');
  loadCalendar();
}

// Load calendar slots
Future<void> loadCalendar(DateTime month) async {
  final startOfMonth = DateTime(month.year, month.month, 1);
  final endOfMonth = DateTime(month.year, month.month + 1, 0);

  final slots = await Supabase.instance.client
    .from('provider_time_slots')
    .select()
    .eq('provider_id', currentProviderId)
    .gte('date', startOfMonth.toIso8601String())
    .lte('date', endOfMonth.toIso8601String())
    .order('date')
    .order('start_time');

  setState(() {
    calendarSlots = groupSlotsByDate(slots);
  });
}
```

### FlutterFlow AI Prompt
```
Create an availability management page with:
- Tab bar with 3 tabs: Templates, Calendar, Blocked Dates
- Templates tab:
  * Weekly schedule list (7 days)
  * Each day has toggle, time picker, duration selector, type chips
  * FAB for "Add Template"
- Calendar tab:
  * Month calendar with colored dots for availability
  * Bottom sheet day detail view with slot list
  * "Generate Slots" button with date range picker
- Blocked dates tab:
  * List of date ranges with delete option
  * "Add Blocked Date" button
- Template form modal with all fields
- Use calendar icons and time picker widgets
- Green/red color coding for availability
- Confirmation dialogs for destructive actions
```

---

## 6. Earnings & Payouts

### Purpose
Track consultation revenue, commissions, and payout history.

### User Access
Healthcare providers

### Data Sources

**Table**: `consultation_transactions`, `consultations`

**RPC Function**: `get_provider_earnings_summary`

### UI Components

#### Summary Cards (Top Row)

1. **This Month Earnings**
   - Net amount (after commission)
   - Percentage change from last month
   - Icon: trending up/down

2. **Pending Payout**
   - Amount awaiting payout
   - Count of transactions
   - Icon: clock

3. **Total Paid Out**
   - Lifetime payouts
   - Last payout date
   - Icon: check circle

4. **Average Per Consultation**
   - Average net earning
   - Consultation count
   - Icon: calculator

#### Date Range Filter
- Preset buttons: This Week, This Month, Last Month, Custom
- Date picker for custom range

#### Earnings Chart
- Line chart showing daily earnings
- Toggle between gross and net
- Consultation count overlay

#### Breakdown by Type
- Pie chart or bar chart
- Chat, Video, Audio, Office Visit
- Earnings and count per type

#### Transaction History List
- Each item shows:
  - Date and time
  - Patient name (anonymized if needed)
  - Consultation type
  - Gross amount
  - Commission amount
  - Net amount
  - Payout status
  - Receipt download button

#### Payout History Section
- List of past payouts
- Each with:
  - Payout date
  - Amount
  - Reference number
  - Bank details
  - Status badge

### Button Actions

| Button | Action | Result |
|--------|--------|--------|
| Date Filter | Update date range | Refresh data |
| Download Receipt | Generate PDF | Download file |
| Request Payout | Initiate payout | Show confirmation |
| View Details | Show transaction detail | Modal |

### Data Fetching
```dart
// Load earnings summary
Future<void> loadEarnings() async {
  final summary = await Supabase.instance.client.rpc(
    'get_provider_earnings_summary',
    params: {
      'p_provider_id': currentProviderId,
      'p_start_date': dateRange.start.toIso8601String(),
      'p_end_date': dateRange.end.toIso8601String(),
    },
  );

  setState(() {
    totalConsultations = summary['total_consultations'];
    grossEarnings = summary['gross_earnings'];
    totalCommission = summary['total_commission'];
    netEarnings = summary['net_earnings'];
    pendingPayout = summary['pending_payout'];
    paidOut = summary['paid_out'];
    byConsultationType = summary['by_consultation_type'];
  });
}

// Load transaction history
Future<void> loadTransactions() async {
  final transactions = await Supabase.instance.client
    .from('consultation_transactions')
    .select('''
      *,
      consultations!inner(type, created_at),
      users!inner(full_name)
    ''')
    .eq('provider_id', currentProviderId)
    .gte('created_at', dateRange.start.toIso8601String())
    .lte('created_at', dateRange.end.toIso8601String())
    .order('created_at', ascending: false)
    .limit(50);

  setState(() {
    transactionList = transactions;
  });
}

// Request payout
Future<void> requestPayout() async {
  // This would typically call a backend function to initiate payout
  // For now, placeholder
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Request Payout'),
      content: Text('Payout of ${formatCurrency(pendingPayout)} will be processed within 3-5 business days.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            // Initiate payout process
            Navigator.pop(context);
            showSuccessSnackbar('Payout requested successfully');
          },
          child: Text('Confirm'),
        ),
      ],
    ),
  );
}
```

### FlutterFlow AI Prompt
```
Create an earnings dashboard with:
- 4 stat cards in a grid at top
- Date range filter bar with preset buttons
- Line chart for daily earnings (use fl_chart package)
- Pie chart for earnings by consultation type
- Transaction history list with detailed cards
- Each transaction card shows all amounts with clear labels
- Color coding: green for earnings, red for commission
- "Request Payout" button (disabled if pending < minimum)
- Payout history expandable section
- Professional financial UI with currency formatting
- Export to CSV button
- Use green/teal theme for positive numbers
```

---

## 7. Profile Management

### Purpose
Edit provider profile, credentials, and practice settings.

### User Access
Healthcare providers

### Data Sources

**Table**: `healthcare_providers`, `users`

**RPC Function**: `update_provider_profile`

### UI Components

#### Profile Photo Section
- Large circular avatar (150px)
- "Change Photo" button overlay
- Upload from gallery/camera
- Crop and resize

#### Basic Information
- Full name (text input)
- Email (text input, verified badge)
- Phone (text input, verified badge)
- Specialization (dropdown with search)
- Provider type (dropdown: doctor, pharmacist, etc.)
- Credentials (text input, e.g., "MD, MBBS")
- License number (text input)
- Years of experience (number input)

#### Professional Bio
- Rich text editor
- Character limit: 1000
- Preview mode

#### Clinic Address
- Address line 1 (text input)
- Address line 2 (optional)
- City (text input)
- Region/State (dropdown)
- Country (dropdown)
- Map picker for coordinates

#### Consultation Settings
- Consultation types offered (multi-select chips)
  - Chat
  - Video
  - Audio
  - Office Visit
- Fees for each type (number input per type)

#### Clinic Settings (Pro/Enterprise)
- Clinic name
- Logo upload
- Brand colors
- Custom domain (enterprise only)

#### Verification Status
- Verification badge
- Document upload for verification
- Status: Pending, Verified, Rejected

### Button Actions

| Button | Action | API Call | Result |
|--------|--------|----------|--------|
| Change Photo | Open image picker | Upload to storage | Update profile_photo_url |
| Save Profile | Update profile | `update_provider_profile` | Success message |
| Upload Document | Document picker | Upload | Submit for verification |
| Preview Profile | View public profile | - | Modal preview |
| Cancel | Discard changes | - | Confirm dialog |

### Data Fetching
```dart
// Load profile
Future<void> loadProfile() async {
  final profile = await Supabase.instance.client.rpc(
    'get_provider_profile',
    params: {'p_provider_id': currentProviderId},
  );

  setState(() {
    // Populate form fields
    fullNameController.text = profile['full_name'];
    emailController.text = profile['email'];
    phoneController.text = profile['phone'];
    specializationController.text = profile['specialization'];
    // ... etc
  });
}

// Update profile
Future<void> updateProfile() async {
  if (!_formKey.currentState!.validate()) {
    return;
  }

  showLoadingOverlay();

  final result = await Supabase.instance.client.rpc(
    'update_provider_profile',
    params: {
      'p_provider_id': currentProviderId,
      'p_full_name': fullNameController.text,
      'p_bio': bioController.text,
      'p_specialization': selectedSpecialization,
      'p_credentials': credentialsController.text,
      'p_phone': phoneController.text,
      'p_profile_photo_url': profilePhotoUrl,
      'p_consultation_types': selectedConsultationTypes,
      'p_fees': {
        'chat': chatFee,
        'video': videoFee,
        'audio': audioFee,
        'office_visit': officeVisitFee,
      },
      'p_clinic_address': {
        'street': addressLine1,
        'city': city,
        'region': region,
        'country': country,
        'lat': latitude,
        'lng': longitude,
      },
    },
  );

  hideLoadingOverlay();

  if (result['success']) {
    showSuccessSnackbar('Profile updated successfully');
  } else {
    showErrorSnackbar(result['message']);
  }
}

// Upload profile photo
Future<void> uploadProfilePhoto(File imageFile) async {
  final fileName = '${currentProviderId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

  final path = await Supabase.instance.client.storage
    .from('provider-photos')
    .upload(fileName, imageFile);

  final publicUrl = Supabase.instance.client.storage
    .from('provider-photos')
    .getPublicUrl(fileName);

  setState(() {
    profilePhotoUrl = publicUrl;
  });
}
```

### Validation Rules
- Full name: Required, min 3 characters
- Email: Valid email format
- Phone: Valid phone format
- Specialization: Required
- Credentials: Optional
- License number: Required for verification
- Bio: Max 1000 characters
- Fees: Positive numbers

### FlutterFlow AI Prompt
```
Create a profile edit page with:
- Scrollable form with sections
- Profile photo picker at top (circular, 150px, with edit overlay)
- Grouped form sections with headers
- Text fields with validation
- Dropdowns for specialization, type, region, country
- Multi-select chips for consultation types
- Number inputs for fees with currency symbol
- Rich text editor for bio
- Map picker for clinic location
- Save button (sticky bottom bar)
- Loading overlay during save
- Unsaved changes warning
- Verification status banner if not verified
- Professional medical form styling
```

---

## 8. Patient List

### Purpose
View patients the provider has consulted with.

### User Access
Healthcare providers

### Data Sources

**Table**: `consultations`, `users`

### UI Components

#### Search Bar
- Search by patient name
- Filter icon (opens filter sheet)

#### Filter Options (Bottom Sheet)
- Date range of last consultation
- Consultation type
- Number of consultations (1, 2-5, 6+)

#### Patient List
Each card shows:
- Patient avatar and name
- Age and gender
- Last consultation date and type
- Total consultations count
- Quick action buttons:
  - View history
  - Start new consultation
  - Send message

#### Patient Stats
- Total unique patients
- Returning patients percentage
- Most common consultation type

### Button Actions

| Button | Action | Navigation |
|--------|--------|------------|
| Patient Card | View patient detail | → Patient Detail |
| View History | Show all consultations | → Consultation History (filtered) |
| Start New | Create consultation | → New Consultation (pre-filled) |
| Send Message | Open chat | → Chat |

### Data Fetching
```dart
// Load patients
Future<void> loadPatients() async {
  final patients = await Supabase.instance.client
    .from('consultations')
    .select('''
      patient_id,
      users!inner(full_name, avatar_url, gender, date_of_birth),
      created_at,
      type
    ''')
    .eq('provider_id', currentProviderId)
    .order('created_at', ascending: false);

  // Group by patient_id and aggregate
  final patientMap = <String, dynamic>{};

  for (var consultation in patients) {
    final patientId = consultation['patient_id'];

    if (!patientMap.containsKey(patientId)) {
      patientMap[patientId] = {
        'patient_id': patientId,
        'full_name': consultation['users']['full_name'],
        'avatar_url': consultation['users']['avatar_url'],
        'gender': consultation['users']['gender'],
        'age': calculateAge(consultation['users']['date_of_birth']),
        'consultations': [],
      };
    }

    patientMap[patientId]['consultations'].add(consultation);
  }

  setState(() {
    patientList = patientMap.values.toList();
  });
}
```

### FlutterFlow AI Prompt
```
Create a patient list page with:
- Search bar at top
- Filter button with badge if filters applied
- ListView of patient cards
- Each card has: avatar (left), name, age/gender, last consultation date, consultation count badge
- Row of icon buttons: view history, new consultation, message
- Pull-to-refresh
- Empty state when no patients
- Patient stats card at top showing totals
- Alphabetical section headers
- Fast scroll with alphabet sidebar
```

---

## Navigation Map

```
Authentication Flow:
Splash → Login → Dashboard
       → Signup → Onboarding → Dashboard

Main Navigation (Bottom Nav):
├── Dashboard (Home)
├── Consultations
├── Schedule (Availability)
├── Earnings
└── Profile

From Dashboard:
├── Active Consultation → Consultation Detail
├── Pending Badge → Consultations (filtered)
├── Appointment Item → Consultation Detail
└── Quick Actions → respective pages

From Consultations List:
└── Consultation Item → Consultation Detail

From Consultation Detail:
├── Complete → Completion Form
├── Write Prescription → Prescription Form
└── Patient Info → Patient Detail

From Schedule:
├── Template → Template Form
└── Calendar Day → Slot Detail Sheet

From Earnings:
├── Transaction → Transaction Detail
└── Request Payout → Payout Confirmation

From Profile:
├── Edit → Profile Edit Form
└── Verification → Document Upload
```

---

## State Management

### App State Variables

```dart
class ProviderAppState {
  // User & Provider
  String userId;
  String providerId;
  String providerName;
  String providerPhoto;
  String providerType;
  String specialization;
  bool isVerified;

  // Session
  bool isAuthenticated;
  String authToken;

  // Current Consultation (if in progress)
  String? activeConsultationId;
  String? activeConsultationType;
  DateTime? consultationStartTime;

  // Notifications
  int unreadMessages;
  int pendingConsultations;

  // Settings
  bool notificationsEnabled;
  String preferredLanguage;
  String currency;

  // Agora (for video/audio)
  String? agoraAppId;
  String? agoraToken;
  String? agoraChannelName;
}
```

### Persistent Storage

Use Hive or Shared Preferences for:
- Auth token
- Provider ID
- Last sync timestamp
- Draft prescriptions
- User preferences

---

## Real-time Features

### Supabase Realtime Subscriptions

```dart
// 1. New consultation requests
final consultationSubscription = Supabase.instance.client
  .from('consultations')
  .stream(primaryKey: ['id'])
  .eq('provider_id', providerId)
  .eq('status', 'pending')
  .listen((data) {
    // Show notification
    // Update pending count
    // Play notification sound
  });

// 2. Chat messages
final messageSubscription = Supabase.instance.client
  .from('consultation_messages')
  .stream(primaryKey: ['id'])
  .eq('consultation_id', activeConsultationId)
  .listen((messages) {
    // Update chat UI
    // Mark as read
  });

// 3. Consultation status changes
final statusSubscription = Supabase.instance.client
  .from('consultations')
  .stream(primaryKey: ['id'])
  .eq('id', activeConsultationId)
  .listen((data) {
    // Update UI if patient cancels, etc.
  });

// 4. Payment confirmations
final paymentSubscription = Supabase.instance.client
  .from('consultation_transactions')
  .stream(primaryKey: ['id'])
  .eq('provider_id', providerId)
  .listen((transactions) {
    // Notify provider of new payment
    // Update earnings display
  });
```

---

## Integration Requirements

### 1. Agora RTC (Video/Audio Calls)

**Setup**:
```yaml
dependencies:
  agora_rtc_engine: ^6.2.6
```

**Implementation**:
```dart
import 'package:agora_rtc_engine/agora_rtc_engine.dart';

class AgoraService {
  late RtcEngine engine;

  Future<void> initializeAgora(String appId) async {
    engine = createAgoraRtcEngine();
    await engine.initialize(RtcEngineContext(appId: appId));

    await engine.enableVideo();
    await engine.setChannelProfile(ChannelProfileType.channelProfileCommunication);
    await engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
  }

  Future<void> joinChannel(String token, String channelName, int uid) async {
    await engine.joinChannel(
      token: token,
      channelId: channelName,
      uid: uid,
      options: const ChannelMediaOptions(),
    );
  }

  Future<void> leaveChannel() async {
    await engine.leaveChannel();
  }
}
```

### 2. Push Notifications

**Firebase Cloud Messaging**:
```yaml
dependencies:
  firebase_messaging: ^14.7.9
```

**Notification Types**:
- New consultation request
- Patient message
- Appointment reminder (15 min before)
- Payment received
- Review received

### 3. Image Upload (Profile, Attachments)

**Supabase Storage**:
```dart
Future<String> uploadImage(File imageFile, String bucket) async {
  final fileName = '${providerId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

  await Supabase.instance.client.storage
    .from(bucket)
    .upload(fileName, imageFile);

  return Supabase.instance.client.storage
    .from(bucket)
    .getPublicUrl(fileName);
}
```

### 4. PDF Generation (Prescriptions, Receipts)

**Package**:
```yaml
dependencies:
  pdf: ^3.10.7
  printing: ^5.11.1
```

### 5. Analytics (Optional)

**Mixpanel or Google Analytics**:
- Track consultation completions
- Monitor earnings
- User engagement metrics

---

## Security Considerations

### Row-Level Security (RLS)

All queries automatically enforce:
- Providers can only access their own data
- Patients can only view their own consultations
- Sensitive health data is encrypted

### Data Privacy

- Patient names can be anonymized in certain views
- Medical records follow HIPAA/GDPR guidelines
- Audit logs for all data access

### Authentication

- JWT tokens with expiration
- Refresh token rotation
- Biometric authentication support

---

## Testing Checklist

### Functional Testing

- [ ] Provider registration and onboarding
- [ ] Profile creation and editing
- [ ] Availability template setup
- [ ] Slot generation for 30 days
- [ ] Accept consultation request
- [ ] Start chat consultation
- [ ] Send/receive messages in real-time
- [ ] Start video consultation with Agora
- [ ] Write and submit prescription
- [ ] Complete consultation
- [ ] View earnings summary
- [ ] Request payout

### Real-time Testing

- [ ] New consultation notification
- [ ] Chat message real-time updates
- [ ] Consultation status changes
- [ ] Payment confirmation notification

### Edge Cases

- [ ] Handle double-booking (optimistic locking)
- [ ] Network interruption during video call
- [ ] Patient cancels mid-consultation
- [ ] Prescription save as draft
- [ ] Expired time slots
- [ ] Minimum payout threshold

---

## Deployment Checklist

- [ ] Supabase project configured
- [ ] All RPC functions deployed
- [ ] RLS policies enabled and tested
- [ ] Agora project created and credentials added
- [ ] Firebase project setup for notifications
- [ ] Storage buckets created (provider-photos, prescriptions, attachments)
- [ ] Environment variables configured
- [ ] App store assets prepared
- [ ] Privacy policy and terms of service
- [ ] Medical disclaimer
- [ ] Compliance verification (HIPAA, GDPR)

---

## Future Enhancements

1. **Telemedicine Integrations**
   - EHR system integration
   - Lab results import
   - Pharmacy API for prescription routing

2. **Advanced Features**
   - AI symptom checker
   - Multi-language support
   - Voice-to-text medical notes
   - Appointment reminders via SMS/WhatsApp

3. **Provider Tools**
   - Patient health timeline
   - Treatment templates
   - Medical calculators (BMI, dosage, etc.)

4. **Analytics Dashboard**
   - Patient demographics
   - Peak hours analysis
   - Revenue forecasting

---

**End of Healthcare Medic Guide**

For questions or support, contact the development team.
