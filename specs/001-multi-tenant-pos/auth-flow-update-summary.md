# Authentication Flow Update Summary

**Date**: 2026-02-08 (Updated)
**Status**: ✅ Complete - Including Staff Passcode/Biometric Authentication

## Overview

Updated the authentication and onboarding flow for User Story 2 to reflect the new business requirements, including owner registration with guided onboarding and staff invitation with two-factor authentication (passcode/biometric).

---

## Changes Made

### 1. **spec.md** - Updated User Story 2

**Previous Flow**:
- Phone-based OTP authentication for all users
- Tenant created immediately upon OTP verification
- Manual branding configuration later

**New Flow**:

**Owner Registration & Onboarding**:
- **Registration**: Email/password OR Google Sign-In
- **Step 1 - Profile Setup**: Profile picture, full name, gender (Male/Female), phone number
- **Step 2 - Company Setup**: Company name, business type, address, country, city, office address, logo (auto-geocoding for lat/long)
- **Step 3 - Security Setup**: 6-digit passcode OR biometric authentication
- **Navigate to Dashboard**: After all steps completed

**Staff Invitation & Onboarding**:
- **Invitation**: Owner invites staff via email with role and branch assignment (7-day expiry link)
- **Step 1 - Account Creation**: Staff clicks link → sets password
- **Step 2 - Profile Setup**: Full name, profile picture, phone number
- **Step 3 - Security Setup**: 6-digit passcode OR biometric authentication
- **Navigate to Dashboard**: After all steps completed

**Login Flow (All Users)**:
- **Step 1**: Email/password authentication
- **Step 2**: Passcode/biometric verification (second factor)
- **Step 3**: Dashboard access

**Inactivity Lock**:
- Triggers after 10 minutes idle on POS
- Requires passcode/biometric to unlock
- No full logout - quick resume

**Updated Acceptance Scenarios**:
- 16 comprehensive acceptance scenarios covering:
  - Owner registration & onboarding (4 scenarios)
  - Multi-tenancy & data isolation (2 scenarios)
  - Staff invitation & onboarding (5 scenarios)
  - Staff login & security (5 scenarios)

---

### 2. **tasks.md** - Phase 4 Completely Rewritten

**Task Summary**:
- **Total Tasks**: 56 (previously 22, now expanded to include passcode/biometric)
- **Completed**: 18 tasks (marked with ✅)
- **Pending**: 38 tasks

**New Task Categories**:

#### Models (7 tasks)
- ✅ T069-T071: Tenant, User, Branch models
- ✅ T071a: StaffInvitation model
- ⬜ T071b: Add profile fields (profile_picture_url, gender, onboarding_completed_at)
- ⬜ T071c: Add company fields (business_type, address, country, city, lat/long)
- ✅ T071d: Add passcode_hash field to User model

#### Services (6 tasks)
- ✅ T072-T074: Tenant, user, branding services
- ⬜ T074a: Onboarding service
- ⬜ T074b: Geocoding service
- ✅ T074c: Staff invitation service
- ⬜ T074d: Passcode service (hash, verify, biometric support)

#### API Endpoints (13 tasks)
- ⬜ T075: Registration endpoint (email/password)
- ⬜ T075a: Configure Google OAuth
- ⬜ T076: Login endpoint
- ✅ T077-T079: Tenant, staff, branding endpoints
- ⬜ T079a-T079b: Onboarding endpoints (profile, company)
- ✅ T079c: Staff invitation endpoints
- ⬜ T079d: Update invitation acceptance (password setup)
- ⬜ T079e: Passcode setup endpoint
- ⬜ T079f: Passcode verification endpoint
- ⬜ T079g: Staff profile endpoint

#### UI Components (18 tasks)
- ⬜ T080-T084: Registration, login, onboarding pages (owner flow)
- ✅ T085-T088: Staff management, branding, role selector, branch selector
- ⬜ T089: Update invitation acceptance page (password setup)
- ⬜ T089a-T089d: Onboarding components (business type, country, gender, profile picture)
- ⬜ T089e: Staff profile setup page
- ✅ T089f: Passcode setup page (6-digit PIN or biometric)
- ⬜ T089g: Verify passcode page (after login)
- ⬜ T089h: Inactivity lock component

#### Integration (18 tasks)
- ⬜ T090: Configure Supabase Auth (email + Google OAuth)
- ⬜ T091: Multi-step auth redirect logic (includes passcode check)
- ⬜ T092-T093: Geocoding, image upload
- ✅ T094: Email sending service
- ⬜ T095: Database migration (profile, company fields)
- ✅ T095a: Database migration (passcode_hash field)
- ⬜ T096: RLS policy enforcement
- ⬜ T097: Inactivity detection (10 min idle → lock screen)
- ⬜ T098: WebAuthn biometric authentication
- ⬜ T099-T106: Comprehensive testing (owner flow, staff flow, login, inactivity, biometric, etc.)

---

### 3. **research.md** - Section 6 Replaced

**Previous**: "OTP Delivery Service Selection" (Termii + Twilio)

**New**: "Authentication Strategy"

**Key Decisions**:
- **Email/Password**: Built-in Supabase Auth, familiar UX, no SMS costs
- **Google OAuth**: One-click registration, reduces friction
- **Guided Onboarding**: 2-step flow captures complete data upfront
- **Email Invitations**: Staff-only, maintains security and RBAC

**Implementation Stack**:
- Supabase Auth (email + Google OAuth)
- Resend (transactional emails for invitations)
- Google Maps Geocoding API or OpenCage (lat/long auto-population)
- Supabase Storage (profile pics, logos)

---

### 4. **data-model.md** - Updated Tables

#### `tenants` Table Updates:
**New Fields**:
- `business_type`: Updated enum (pharmacy, supermarket, pharmacy_supermarket, restaurant, retail, kiosk, neighbourhood_store)
- `country`: VARCHAR(100) - Full country name
- `city`: VARCHAR(100)
- `office_address`: TEXT
- `latitude`: DECIMAL(10, 8) - Auto-populated
- `longitude`: DECIMAL(11, 8) - Auto-populated

**Modified Fields**:
- `subdomain`: Now nullable, auto-generated from business_name
- `phone_number`: Now nullable (collected during profile setup)

#### `users` Table Updates:
**New Fields**:
- `profile_picture_url`: TEXT
- `gender`: VARCHAR(10) - Values: male, female
- `onboarding_completed_at`: TIMESTAMPTZ - Tracks onboarding completion

**Modified Fields**:
- `tenant_id`: Now nullable (for users during onboarding flow)
- `phone_number`: Now nullable (email-only registration supported)
- `role`: DEFAULT 'tenant_admin'

---

## Migration Path

### What's Already Built (from previous implementation):
✅ Staff invitation system (`app/api/staff/invite/`)
✅ Invitation acceptance page (`app/accept-invitation/[token]/`)
✅ Staff management UI (`app/(admin)/staff/page.tsx`)
✅ Role selector component
✅ Branch selector component
✅ Email sending via Resend
✅ Database migration for staff_invitations table
✅ Database migration for passcode_hash field
✅ Passcode setup page (`app/(onboarding)/setup-passcode/page.tsx`)
✅ Verify passcode page skeleton (`app/(auth)/verify-passcode/`)
✅ Inactivity lock component (`app/components/auth/InactivityLock.tsx`)

### What Needs to Be Built:

**Owner Flow**:
⬜ Owner registration page (email/password + Google OAuth)
⬜ Owner profile setup page (Step 1)
⬜ Company setup page (Step 2)
⬜ Owner onboarding API endpoints

**Staff Flow**:
⬜ Update invitation acceptance page (password setup instead of automatic account creation)
⬜ Staff profile setup page (full name, profile pic, phone)
⬜ Staff profile API endpoint
⬜ Passcode/biometric setup API endpoints

**Authentication**:
⬜ Login page (email/password + Google OAuth)
⬜ Complete verify passcode page implementation
⬜ Passcode verification API endpoint
⬜ Update inactivity lock component (integrate passcode verification)

**Common Components**:
⬜ Onboarding UI components (profile pic upload, gender select, business type, country list)
⬜ Geocoding service integration
⬜ Image upload to Supabase Storage
⬜ Database migration for new user/tenant fields

**Integration**:
⬜ Auth state management with multi-step redirect logic (check onboarding + passcode status)
⬜ Inactivity detection system (10 min timer)
⬜ WebAuthn biometric implementation (optional alternative to passcode)

---

## Next Steps

### Option 1: Complete the New Authentication Flow (Recommended)
Start with the pending tasks in Phase 4 (prioritized order):

**Foundation** (Do First):
1. ⬜ T095: Create database migration for new fields
2. ⬜ T075a: Configure Google OAuth in Supabase
3. ⬜ T093: Implement image upload to Supabase Storage
4. ⬜ T092: Integrate geocoding API

**Owner Flow**:
5. ⬜ T080: Create registration page
6. ⬜ T081: Create login page
7. ⬜ T082-T084: Create onboarding pages (owner profile + company)
8. ⬜ T074a: Implement onboarding service
9. ⬜ T079a-T079b: Create onboarding API endpoints
10. ⬜ T089a-T089d: Create onboarding UI components

**Staff Flow**:
11. ⬜ T089: Update invitation acceptance page (password setup)
12. ⬜ T079d: Update invitation acceptance API
13. ⬜ T089e: Create staff profile setup page
14. ⬜ T079g: Create staff profile API endpoint

**Passcode/Biometric Security**:
15. ⬜ T074d: Implement passcode service
16. ⬜ T079e: Create passcode setup endpoint
17. ⬜ T079f: Create passcode verification endpoint
18. ⬜ T089g: Complete verify passcode page
19. ⬜ T089h: Update inactivity lock component
20. ⬜ T097: Implement inactivity detection
21. ⬜ T098: Implement WebAuthn biometric (optional)

**Integration & Testing**:
22. ⬜ T090: Configure Supabase Auth
23. ⬜ T091: Implement multi-step auth redirect logic
24. ⬜ T096: Implement RLS policy enforcement
25. ⬜ T099-T106: Comprehensive testing

### Option 2: Continue to Next User Story
If Phase 4 (US2) is considered "good enough" with current email-only authentication and staff invitations, proceed to Phase 5 (User Story 3 - Customer Management).

---

## Business Type Enum

The following business types are now supported:
1. Pharmacy
2. Supermarket
3. Pharmacy/Supermarket (combined)
4. Restaurant
5. Retail
6. Kiosk
7. Neighbourhood Store

---

## Testing Checklist

When implementing, ensure the following flows are tested:

**Owner Flow**:
- [ ] Owner registers with email/password
- [ ] Owner registers with Google Sign-In
- [ ] Profile setup (Step 1) with all fields including photo upload
- [ ] Company setup (Step 2) with geocoding auto-populating lat/long
- [ ] Security setup (Step 3) - passcode creation
- [ ] Security setup (Step 3) - biometric setup (if device supports)
- [ ] Navigation from onboarding completion to dashboard
- [ ] Owner login: email/password → passcode verification → dashboard

**Staff Flow**:
- [ ] Owner invites staff with role and branch
- [ ] Staff receives invitation email
- [ ] Staff clicks invitation link (valid within 7 days)
- [ ] Staff creates password
- [ ] Staff completes profile setup (full name, profile pic, phone)
- [ ] Staff sets up passcode or biometric
- [ ] Staff navigates to dashboard with role-appropriate access
- [ ] Staff login: email/password → passcode verification → dashboard

**Security & Inactivity**:
- [ ] Passcode verification required after email/password login
- [ ] Biometric verification works as alternative to passcode
- [ ] Inactivity lock triggers after 10 minutes idle
- [ ] Unlock with passcode restores session
- [ ] Unlock with biometric restores session
- [ ] Multiple failed passcode attempts handled gracefully

**Middleware Redirects**:
- [ ] Unauthenticated → `/login`
- [ ] Authenticated without `onboarding_completed_at` → onboarding flow
- [ ] Authenticated with onboarding but no `passcode_hash` → `/onboarding/setup-passcode`
- [ ] Authenticated with onboarding and passcode → `/verify-passcode` → dashboard

**Permissions & Isolation**:
- [ ] Staff sees only role-appropriate features (Branch Manager vs Cashier vs Rider)
- [ ] Cross-tenant data isolation (Tenant A cannot see Tenant B)
- [ ] RLS policies enforce tenant isolation at database level

**Google OAuth**:
- [ ] Google OAuth registration for owners
- [ ] Google OAuth login for existing users
- [ ] Google OAuth users complete onboarding flow properly

---

## Documentation Updated

✅ `specs/001-multi-tenant-pos/spec.md` - User Story 2 rewritten
✅ `specs/001-multi-tenant-pos/tasks.md` - Phase 4 completely updated
✅ `specs/001-multi-tenant-pos/research.md` - Authentication strategy documented
✅ `specs/001-multi-tenant-pos/data-model.md` - Tables updated with new fields
✅ `specs/001-multi-tenant-pos/auth-flow-update-summary.md` - This summary document

---

**Status**: All specification documents updated and ready for implementation.
