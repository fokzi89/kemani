# Quickstart: Multi-Tenant Referral Commission System

**Feature**: Multi-Tenant Referral Commission System
**Branch**: `004-tenant-referral-commissions`
**Last Updated**: 2026-03-13

## Overview

This guide helps developers get started implementing the referral commission system. Follow these steps to set up your development environment and understand the core workflows.

---

## Prerequisites

- **Supabase Project**: Running locally or remote
- **SvelteKit App**: `apps/storefront` set up
- **Flutter App**: `apps/pos_admin` configured
- **Node.js**: v18+ with npm
- **Flutter SDK**: 3.x
- **PostgreSQL**: 15+ (via Supabase)

---

## 1. Database Setup (30 minutes)

### Step 1: Run Migration

```bash
# From repository root
cd supabase

# Create migration file
supabase migration new referral_commissions

# Copy SQL from specs/004-tenant-referral-commissions/data-model.md
# into migrations/20260313_referral_commissions.sql

# Apply migration
supabase db reset  # Local development
# OR
supabase db push   # Remote project
```

### Step 2: Verify Tables Created

```sql
-- Check all tables exist
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN (
    'referral_sessions',
    'transactions',
    'commissions',
    'fulfillment_routing'
  );

-- Verify RLS policies enabled
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN ('referral_sessions', 'commissions');
-- Should show rowsecurity = true
```

### Step 3: Test Commission Functions

```sql
-- Test service commission calculation
SELECT * FROM calculate_service_commission(1000, true);
-- Expected: customer_pays=1100, provider_gets=900, referrer_gets=100, platform_gets=100

-- Test product commission calculation
SELECT * FROM calculate_product_commission(5000, true);
-- Expected: customer_pays=5000, provider_gets=4700, referrer_gets=225, platform_gets=75
```

---

## 2. SvelteKit Frontend Setup (45 minutes)

### Step 1: Install Dependencies

```bash
cd apps/storefront

# Already have Supabase client from existing setup
# If not:
# npm install @supabase/supabase-js
```

### Step 2: Create Referral Session Tracker

Create `apps/storefront/src/lib/services/referralSession.ts`:

```typescript
import { createClient } from '@supabase/supabase-js';

export class ReferralSessionService {
  async createSession(referringTenantId: string, customerId?: string) {
    const sessionToken = crypto.randomUUID();

    const { data, error } = await supabase
      .from('referral_sessions')
      .insert({
        session_token: sessionToken,
        customer_id: customerId,
        referring_tenant_id: referringTenantId,
        active: true,
        expires_at: new Date(Date.now() + 24 * 60 * 60 * 1000) // 24 hours
      })
      .select()
      .single();

    if (error) throw error;

    // Set HTTP-only cookie (via server-side hook)
    return sessionToken;
  }

  async getActiveSession(sessionToken: string) {
    const { data } = await supabase
      .from('referral_sessions')
      .select('*')
      .eq('session_token', sessionToken)
      .eq('active', true)
      .single();

    return data;
  }
}
```

### Step 3: Update Server Hooks

Modify `apps/storefront/src/hooks.server.ts`:

```typescript
export async function handle({ event, resolve }) {
  // Extract subdomain to determine referring tenant
  const host = event.request.headers.get('host') || '';
  const subdomain = host.split('.')[0]; // e.g., "fokz" from "fokz.kemani.com"

  // Look up tenant by subdomain
  const { data: tenant } = await supabase
    .from('tenants')
    .select('id')
    .eq('subdomain', subdomain)
    .single();

  if (tenant) {
    // Create or refresh referral session
    const sessionToken = event.cookies.get('referral_session_id');

    if (!sessionToken) {
      const newToken = await referralSessionService.createSession(tenant.id);
      event.cookies.set('referral_session_id', newToken, {
        httpOnly: true,
        secure: true,
        sameSite: 'lax',
        maxAge: 86400 // 24 hours
      });
    }

    event.locals.referringTenantId = tenant.id;
  }

  return resolve(event);
}
```

### Step 4: Commission Calculation Component

Create `apps/storefront/src/lib/components/referral/CommissionPreview.svelte`:

```svelte
<script lang="ts">
  import { onMount } from 'svelte';

  export let basePrice: number;
  export let transactionType: 'consultation' | 'product_sale' | 'diagnostic_test';
  export let hasReferrer: boolean;

  let commission: any = null;

  onMount(async () => {
    const response = await fetch('/api/commissions/calculate', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ transaction_type: transactionType, base_price: basePrice, has_referrer: hasReferrer })
    });

    commission = await response.json();
  });
</script>

{#if commission}
  <div class="commission-breakdown">
    <h3>Total: ₦{commission.data.customer_pays}</h3>
    <ul>
      <li>Provider gets: ₦{commission.data.breakdown.provider_gets}</li>
      {#if hasReferrer}
        <li>Referrer earns: ₦{commission.data.breakdown.referrer_gets}</li>
      {/if}
      <li>Platform fee: ₦{commission.data.breakdown.platform_gets}</li>
    </ul>
  </div>
{/if}
```

---

## 3. Flutter POS Dashboard (60 minutes)

### Step 1: Install Dependencies

```bash
cd apps/pos_admin

# Add dependencies to pubspec.yaml
flutter pub add supabase_flutter
flutter pub add hive
flutter pub add fl_chart  # For commission charts
flutter pub get
```

### Step 2: Create Commission Service

Create `apps/pos_admin/lib/features/commissions/services/commission_service.dart`:

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

class CommissionService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Commission>> getCommissions({
    String? status,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    var query = _supabase
        .from('commissions')
        .select()
        .order('created_at', ascending: false);

    if (status != null) {
      query = query.eq('status', status);
    }

    if (dateFrom != null) {
      query = query.gte('created_at', dateFrom.toIso8601String());
    }

    if (dateTo != null) {
      query = query.lte('created_at', dateTo.toIso8601String());
    }

    final response = await query;
    return (response as List).map((e) => Commission.fromJson(e)).toList();
  }

  Future<CommissionSummary> getSummary({
    required DateTime dateFrom,
    required DateTime dateTo,
  }) async {
    final response = await _supabase.rpc('get_commission_summary', params: {
      'tenant_id': _supabase.auth.currentUser!.id,
      'date_from': dateFrom.toIso8601String(),
      'date_to': dateTo.toIso8601String(),
    });

    return CommissionSummary.fromJson(response);
  }
}
```

### Step 3: Create Dashboard Screen

Create `apps/pos_admin/lib/features/commissions/screens/commission_dashboard.dart`:

```dart
import 'package:flutter/material.dart';

class CommissionDashboard extends StatefulWidget {
  @override
  State<CommissionDashboard> createState() => _CommissionDashboardState();
}

class _CommissionDashboardState extends State<CommissionDashboard> {
  final _commissionService = CommissionService();
  CommissionSummary? _summary;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    final summary = await _commissionService.getSummary(
      dateFrom: DateTime.now().subtract(Duration(days: 30)),
      dateTo: DateTime.now(),
    );

    setState(() {
      _summary = summary;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_summary == null) {
      return Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(title: Text('Commission Dashboard')),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          CommissionSummaryCard(
            totalEarned: _summary!.totalEarned,
            pending: _summary!.totalPending,
            paidOut: _summary!.totalPaidOut,
          ),
          SizedBox(height: 16),
          CommissionChart(dailyTrend: _summary!.dailyTrend),
          SizedBox(height: 16),
          TransactionTypeBreakdown(byType: _summary!.byTransactionType),
        ],
      ),
    );
  }
}
```

---

## 4. Testing (30 minutes)

### Step 1: Unit Tests for Commission Calculation

Create `apps/storefront/tests/commission-calculation.test.ts`:

```typescript
import { describe, it, expect } from 'vitest';
import { calculateServiceCommission, calculateProductCommission } from '$lib/services/commissionCalculator';

describe('Commission Calculations', () => {
  it('calculates service commission with referrer correctly', () => {
    const result = calculateServiceCommission(1000, true);

    expect(result.customer_pays).toBe(1100);
    expect(result.provider_gets).toBe(900);
    expect(result.referrer_gets).toBe(100);
    expect(result.platform_gets).toBe(100);
  });

  it('calculates product commission without referrer correctly', () => {
    const result = calculateProductCommission(5000, false);

    expect(result.customer_pays).toBe(5100); // +100 fixed charge
    expect(result.provider_gets).toBe(4700);
    expect(result.referrer_gets).toBe(0);
    expect(result.platform_gets).toBe(175); // 75 + 100
  });
});
```

### Step 2: Run Tests

```bash
# SvelteKit tests
cd apps/storefront
npm run test

# Flutter tests
cd apps/pos_admin
flutter test
```

---

## 5. Local Development Workflow

### Start All Services

```bash
# Terminal 1: Supabase local
supabase start

# Terminal 2: SvelteKit dev server
cd apps/storefront
npm run dev

# Terminal 3: Flutter app
cd apps/pos_admin
flutter run -d chrome
```

### Test Complete Flow

1. Visit `http://fokz.localhost:5173` (mock tenant subdomain)
2. Browse medic directory
3. Book consultation with base price ₦1,000
4. Verify customer pays ₦1,100 at checkout
5. Complete payment
6. Open Flutter POS dashboard
7. Verify Fokz Pharmacy has ₦100 pending commission

---

## 6. Common Issues & Solutions

### Issue: RLS Policy Blocking Queries

**Error**: `new row violates row-level security policy`

**Solution**: Ensure JWT token has correct `tenant_id` claim:

```sql
-- Add tenant_id to JWT claims
CREATE OR REPLACE FUNCTION auth.uid_to_tenant()
RETURNS UUID AS $$
  SELECT tenant_id FROM users WHERE id = auth.uid();
$$ LANGUAGE SQL STABLE;
```

### Issue: Commission Calculation Precision Errors

**Error**: Total doesn't match (`900 + 100 + 100 ≠ 1100.01`)

**Solution**: Use `DECIMAL(12,2)` everywhere, round to 2 decimal places:

```typescript
const roundToTwo = (num: number) => Math.round(num * 100) / 100;
```

### Issue: Fulfillment Not Auto-Routing

**Error**: Prescription not assigned to referring pharmacy

**Solution**: Verify trigger is installed:

```sql
SELECT tgname FROM pg_trigger WHERE tgname = 'prescription_auto_route';
```

---

## Next Steps

1. **Implement tasks**: Run `/speckit.tasks` to generate implementation tasks
2. **Review contracts**: See `contracts/` directory for API specs
3. **Database schema**: Refer to `data-model.md` for complete schema
4. **Technical decisions**: Review `research.md` for implementation guidance

---

## Resources

- **Specification**: [spec.md](./spec.md)
- **Plan**: [plan.md](./plan.md)
- **Data Model**: [data-model.md](./data-model.md)
- **API Contracts**: [contracts/](./contracts/)
- **Research**: [research.md](./research.md)
