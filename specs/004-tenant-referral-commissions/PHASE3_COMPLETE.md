# Phase 3 Complete: Session-Based Referral Attribution

**Feature**: 004-tenant-referral-commissions
**User Story 1**: Track customer browsing sessions to determine referring tenant
**Status**: ✅ Implementation Complete

## What Was Built

### 1. ReferralSessionService (`apps/storefront/src/lib/services/referralSession.ts`)

A TypeScript service class that handles all referral session operations:

**Methods:**
- `createSession(referringTenantId, customerId)` - Creates new 24-hour session
- `getSessionByToken(sessionToken)` - Retrieves active session
- `refreshSession(sessionToken)` - Updates last_activity_at timestamp
- `getActiveSessionForCustomer(customerId)` - Gets customer's active session
- `deactivateSession(sessionToken)` - Manually deactivates session
- `cleanupExpiredSessions()` - Utility to remove expired sessions

**Features:**
- Automatic UUID token generation
- 24-hour session expiry
- Activity timestamp tracking
- Support for anonymous and logged-in customers

### 2. Server-Side Session Tracking (`apps/storefront/src/hooks.server.ts`)

Added `referralSessionHandle` middleware that:

**Subdomain Detection:**
- Extracts subdomain from hostname (e.g., `fokz.kemani.com` → `fokz`)
- Handles localhost and production domains
- Ignores base domain (no subdomain = no tracking)

**Session Management:**
- Creates session on first visit via subdomain
- Sets HTTP-only, secure cookie (`referral_session`) for 24 hours
- Validates existing sessions on subsequent requests
- Refreshes session activity on each request
- Maps subdomain to tenant_id via database lookup

**Cookie Configuration:**
- HTTP-only: ✓ (prevents JavaScript access)
- Secure: ✓ (production only, HTTPS)
- SameSite: Lax (CSRF protection)
- Max-Age: 86400 seconds (24 hours)
- Path: / (site-wide)

**Event Locals:**
- Sets `event.locals.referringTenantId` for use in routes
- Available in all server-side code and API endpoints

### 3. TypeScript Type Definitions

Updated `apps/storefront/src/app.d.ts`:
- Added `referringTenantId: string | null` to `App.Locals`
- Added optional `referringTenantId` to `App.PageData`

### 4. Client-Side Session Tracker (`apps/storefront/src/lib/components/referral/ReferralSessionTracker.svelte`)

A Svelte component that:
- Validates session on component mount
- Refreshes session on user activity (mouse, keyboard, scroll)
- Debounces refresh calls (1 minute intervals)
- Refreshes on page visibility change
- Optional referral badge display (hidden by default)

**Event Listeners:**
- `visibilitychange` - Refresh when tab becomes visible
- `mousemove`, `keydown`, `scroll` - Track user activity

### 5. Playwright E2E Tests (`tests/referral-session.spec.ts`)

Comprehensive test suite with 5 test cases:

**T041**: Session creation via subdomain
- Verifies cookie is set
- Checks HTTP-only and SameSite attributes
- Validates token format

**T042**: Session persistence across navigation
- Confirms same token after page reload
- Tests cookie retention

**T043**: Session expiry handling
- Simulates invalid/expired token
- Verifies new session creation

**T044**: Session isolation between subdomains
- Creates sessions for different subdomains
- Confirms different tokens for different tenants

**Bonus**: Base domain behavior
- Tests that no session is created without subdomain

## How It Works

### Flow Diagram

```
Customer visits fokz.kemani.com
         ↓
hooks.server.ts extracts "fokz" subdomain
         ↓
Looks up tenant_id for "fokz" in database
         ↓
Creates referral_session record (24h expiry)
         ↓
Sets HTTP-only cookie: referral_session=<token>
         ↓
Sets event.locals.referringTenantId = <tenant_id>
         ↓
Customer browses site (all pages have referringTenantId)
         ↓
On each request: session refreshed (last_activity_at updated)
         ↓
Customer makes purchase → transaction linked to referringTenantId
```

### Database Changes

Uses existing `referral_sessions` table from Phase 2:
```sql
CREATE TABLE referral_sessions (
  id UUID PRIMARY KEY,
  session_token VARCHAR(255) UNIQUE,
  customer_id UUID,  -- NULL for anonymous
  referring_tenant_id UUID NOT NULL,
  active BOOLEAN DEFAULT TRUE,
  expires_at TIMESTAMPTZ,
  last_activity_at TIMESTAMPTZ
);
```

## Testing Instructions

### Prerequisites

1. **Database Setup**: Ensure Phase 2 migration is applied
2. **Tenant Data**: Add test tenants with subdomains
3. **Dev Server**: Run SvelteKit app

### Manual Testing

```bash
# 1. Add test tenant to database
INSERT INTO tenants (id, name, subdomain, business_type)
VALUES (
  gen_random_uuid(),
  'Fokz Pharmacy',
  'fokz',
  'pharmacy'
);

# 2. Start dev server
cd apps/storefront
npm run dev

# 3. Update /etc/hosts (or C:\Windows\System32\drivers\etc\hosts on Windows)
127.0.0.1  fokz.localhost
127.0.0.1  medic.localhost

# 4. Visit http://fokz.localhost:5173 in browser

# 5. Open DevTools → Application → Cookies
# You should see: referral_session cookie

# 6. Check database
SELECT * FROM referral_sessions WHERE active = TRUE;
```

### Automated Testing

```bash
# Run Playwright tests
npm run test:e2e

# Or specifically referral tests
npx playwright test tests/referral-session.spec.ts
```

### Expected Results

✅ Cookie created on subdomain visit
✅ Session record in database
✅ `referringTenantId` available in server code
✅ Session persists across navigation
✅ Different subdomains create different sessions
✅ Invalid tokens trigger new session creation

## Configuration Required

### Environment Variables

Add to `apps/storefront/.env`:
```env
PUBLIC_SUPABASE_URL=your_supabase_url
PUBLIC_SUPABASE_ANON_KEY=your_anon_key
```

### Tenant Subdomain Setup

Each tenant needs a `subdomain` column in the `tenants` table:

```sql
ALTER TABLE tenants ADD COLUMN IF NOT EXISTS subdomain VARCHAR(50) UNIQUE;

UPDATE tenants SET subdomain = 'fokz' WHERE name = 'Fokz Pharmacy';
UPDATE tenants SET subdomain = 'medic' WHERE name = 'Medic Clinic';
```

### DNS/Hosts Configuration

**Production:**
- Set up wildcard DNS: `*.kemani.com` → Your server IP
- Configure web server (Nginx/Caddy) to handle subdomains

**Development:**
- Update hosts file to map subdomains to localhost
- Ensure dev server binds to `0.0.0.0` or specific hostname

## Next Steps

✅ **Phase 3 Complete**
➡️ **Phase 4**: User Story 2 - Commission Calculation Integration

Phase 4 will:
- Create CommissionCalculator service
- Build Supabase Edge Function for payment webhooks
- Create commission preview component
- Integrate with checkout flow
- Use `referringTenantId` from session to calculate commissions

## Files Created/Modified

**New Files:**
- `apps/storefront/src/lib/services/referralSession.ts`
- `apps/storefront/src/lib/components/referral/ReferralSessionTracker.svelte`
- `tests/referral-session.spec.ts`
- `specs/004-tenant-referral-commissions/PHASE3_COMPLETE.md`

**Modified Files:**
- `apps/storefront/src/hooks.server.ts` (added referralSessionHandle)
- `apps/storefront/src/app.d.ts` (added referringTenantId to Locals)

## Success Criteria

- ✅ T032: ReferralSessionService created
- ✅ T033: Session creation method implemented
- ✅ T034: Session retrieval method implemented
- ✅ T035: hooks.server.ts updated for subdomain extraction
- ✅ T036: Cookie setting with HTTP-only, secure, 24h expiry
- ✅ T037: referringTenantId added to event.locals
- ✅ T038: ReferralSessionTracker component created
- ✅ T039: Session validation on mount implemented
- ✅ T040: Session refresh on user activity
- ✅ T041: Playwright test for session creation
- ✅ T042: Playwright test for session persistence
- ✅ T043: Playwright test for session expiry
- ✅ T044: Playwright test for session isolation

**13/13 tasks completed** ✅

## Architecture Notes

### Why HTTP-only Cookies?
- Prevents XSS attacks (JavaScript can't access token)
- Automatically sent with every request
- Managed by browser securely

### Why 24-hour Expiry?
- Matches typical shopping session length
- Prevents stale referrals (customer might browse multiple sites)
- Balances attribution accuracy with fairness

### Why Server-Side Tracking?
- More reliable than client-side (no ad blockers, no JS disabled)
- Harder to manipulate (cookies validated against database)
- Accessible in API routes for transaction creation

### Session vs User Account
- Sessions work for anonymous users (no login required)
- When user logs in, `customer_id` can be linked
- One user can have multiple active sessions (different devices/tenants)
