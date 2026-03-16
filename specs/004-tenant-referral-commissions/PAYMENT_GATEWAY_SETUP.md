# Payment Gateway Webhook Setup Guide

**Feature**: 004-tenant-referral-commissions
**Updated**: 2026-03-15

## Overview

This guide explains how to integrate payment gateways (Paystack, Flutterwave) with the commission system's Edge Function webhook handler.

## Prerequisites

✅ Edge Function deployed to Supabase
✅ Database migration applied (20260315_tenant_services_routing.sql)
✅ Payment gateway account created

## Webhook URL

Your Edge Function webhook URL is:
```
https://[your-project-ref].supabase.co/functions/v1/process-referral-payment
```

**Find your project ref:**
- Supabase Dashboard → Settings → API → Project URL
- Example: `https://abcdefghij.supabase.co` → project ref is `abcdefghij`

---

## Option 1: Paystack Integration

### Step 1: Configure Webhook in Paystack Dashboard

1. Go to **Paystack Dashboard** → **Settings** → **Webhooks**
2. Click **Add Webhook**
3. Enter webhook URL:
   ```
   https://[your-project-ref].supabase.co/functions/v1/process-referral-payment
   ```
4. Select events to listen for:
   - ✅ `charge.success` (required)
   - ⚠️ Only select this event to avoid unnecessary webhook calls
5. Click **Save**

### Step 2: Frontend Payment Initialization

Create an API route to initialize Paystack payment:

**File:** `apps/storefront/src/routes/api/payment/initialize/+server.ts`

```typescript
import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';

const PAYSTACK_SECRET_KEY = process.env.PAYSTACK_SECRET_KEY!;

export const POST: RequestHandler = async ({ request }) => {
  const { amount, email, metadata } = await request.json();

  const response = await fetch('https://api.paystack.co/transaction/initialize', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${PAYSTACK_SECRET_KEY}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      amount: amount * 100, // Convert to kobo
      email,
      metadata: {
        ...metadata,
        // CRITICAL: Include either group_id (multi-service) or transaction_id (single)
        custom_fields: [
          {
            display_name: 'Customer ID',
            variable_name: 'customer_id',
            value: metadata.customer_id
          }
        ]
      },
      callback_url: `${process.env.PUBLIC_APP_URL}/payment/callback`
    })
  });

  const data = await response.json();
  return json(data);
};
```

### Step 3: Frontend Checkout Integration

In your checkout page:

```typescript
async function initializePayment(config: {
  amount: number;
  email: string;
  metadata: any;
}) {
  const response = await fetch('/api/payment/initialize', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      amount: config.amount, // Amount in Naira
      email: config.email,
      metadata: {
        customer_id: config.metadata.customer_id,
        group_id: config.metadata.group_id, // For multi-service checkout
        // OR
        transaction_id: config.metadata.transaction_id, // For single transaction
        transaction_type: config.metadata.transaction_type,
        provider_tenant_id: config.metadata.provider_tenant_id,
        base_price: config.metadata.base_price
      }
    })
  });

  const data = await response.json();

  if (data.status && data.data?.authorization_url) {
    // Redirect to Paystack payment page
    window.location.href = data.data.authorization_url;
  } else {
    throw new Error('Payment initialization failed');
  }
}
```

### Step 4: Payment Callback Handler

Create a callback route to handle return from Paystack:

**File:** `apps/storefront/src/routes/payment/callback/+page.server.ts`

```typescript
import type { PageServerLoad } from './$types';
import { redirect } from '@sveltejs/kit';

export const load: PageServerLoad = async ({ url, locals }) => {
  const reference = url.searchParams.get('reference');

  if (!reference) {
    throw redirect(303, '/');
  }

  // Verify payment with Paystack
  const response = await fetch(
    `https://api.paystack.co/transaction/verify/${reference}`,
    {
      headers: {
        'Authorization': `Bearer ${process.env.PAYSTACK_SECRET_KEY}`
      }
    }
  );

  const data = await response.json();

  if (data.status && data.data.status === 'success') {
    // Payment successful, webhook will handle commission creation
    return {
      success: true,
      reference,
      amount: data.data.amount / 100,
      metadata: data.data.metadata
    };
  } else {
    return {
      success: false,
      error: 'Payment verification failed'
    };
  }
};
```

### Step 5: Test Webhook

Test your webhook with Paystack's test cards:

**Test Card:**
```
Card Number: 4084 0840 8408 4081
Expiry: Any future date
CVV: Any 3 digits
PIN: 0000
OTP: 123456
```

**Verify webhook received:**
1. Make a test payment
2. Check Supabase Edge Function logs:
   - Dashboard → Edge Functions → process-referral-payment → Logs
3. Verify commission record created in database:
   ```sql
   SELECT * FROM commissions ORDER BY created_at DESC LIMIT 5;
   ```

---

## Option 2: Flutterwave Integration

### Step 1: Configure Webhook

1. Go to **Flutterwave Dashboard** → **Settings** → **Webhooks**
2. Add webhook URL:
   ```
   https://[your-project-ref].supabase.co/functions/v1/process-referral-payment
   ```
3. Copy webhook **secret hash** (for verification)

### Step 2: Update Edge Function for Flutterwave

Modify the Edge Function to handle Flutterwave webhooks:

```typescript
// Add webhook verification for Flutterwave
const signature = req.headers.get('verif-hash');
const FLUTTERWAVE_WEBHOOK_SECRET = Deno.env.get('FLUTTERWAVE_WEBHOOK_SECRET');

if (signature !== FLUTTERWAVE_WEBHOOK_SECRET) {
  return new Response('Invalid signature', { status: 401 });
}

// Parse Flutterwave payload format
const payload = await req.json();

if (payload.event === 'charge.completed' && payload.data.status === 'successful') {
  // Process payment...
  const { tx_ref, amount, customer, meta } = payload.data;

  // Extract metadata
  const metadata = {
    customer_id: meta.customer_id,
    group_id: meta.group_id,
    transaction_id: meta.transaction_id,
    // ...
  };
}
```

### Step 3: Frontend Payment Initialization

```typescript
async function initializeFlutterwavePayment(config: any) {
  const response = await fetch('https://api.flutterwave.com/v3/payments', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${FLUTTERWAVE_SECRET_KEY}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      tx_ref: `TX-${Date.now()}`,
      amount: config.amount,
      currency: 'NGN',
      redirect_url: `${process.env.PUBLIC_APP_URL}/payment/callback`,
      customer: {
        email: config.email,
        name: config.customerName
      },
      meta: {
        customer_id: config.metadata.customer_id,
        group_id: config.metadata.group_id
      }
    })
  });

  const data = await response.json();

  if (data.status === 'success') {
    window.location.href = data.data.link;
  }
}
```

---

## Environment Variables

Add these to your `.env` file:

```bash
# Paystack
PAYSTACK_SECRET_KEY=sk_live_your_secret_key
PAYSTACK_PUBLIC_KEY=pk_live_your_public_key

# Flutterwave
FLUTTERWAVE_SECRET_KEY=FLWSECK-your_secret_key
FLUTTERWAVE_PUBLIC_KEY=FLWPUBK-your_public_key
FLUTTERWAVE_WEBHOOK_SECRET=your_webhook_secret

# App
PUBLIC_APP_URL=https://yourdomain.com

# Supabase (already configured)
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
```

---

## Webhook Payload Examples

### Single Transaction (Paystack format)
```json
{
  "event": "charge.success",
  "data": {
    "reference": "tx_abcd1234",
    "amount": 110000,
    "currency": "NGN",
    "status": "success",
    "customer": {
      "email": "customer@example.com"
    },
    "metadata": {
      "customer_id": "customer-uuid-123",
      "transaction_id": "transaction-uuid-456",
      "transaction_type": "consultation",
      "provider_tenant_id": "doctor-uuid-789",
      "base_price": 1000
    }
  }
}
```

### Multi-Service Transaction Group
```json
{
  "event": "charge.success",
  "data": {
    "reference": "tx_abcd5678",
    "amount": 1160000,
    "currency": "NGN",
    "status": "success",
    "customer": {
      "email": "customer@example.com"
    },
    "metadata": {
      "customer_id": "customer-uuid-123",
      "group_id": "group-uuid-999"
    }
  }
}
```

---

## Security Best Practices

### 1. Verify Webhook Signatures

**Paystack:**
```typescript
const signature = req.headers.get('x-paystack-signature');
const hash = crypto
  .createHmac('sha512', PAYSTACK_SECRET_KEY)
  .update(JSON.stringify(req.body))
  .digest('hex');

if (signature !== hash) {
  return new Response('Invalid signature', { status: 401 });
}
```

### 2. Validate Amount

Always verify the amount matches your records:

```typescript
const expectedAmount = totalCustomerPays * 100; // kobo
const receivedAmount = payload.data.amount;

if (Math.abs(expectedAmount - receivedAmount) > 100) { // 1 Naira tolerance
  console.warn('Amount mismatch');
}
```

### 3. Idempotency

The Edge Function already handles idempotency by checking for existing commissions before creating new ones.

### 4. HTTPS Only

Webhooks must be HTTPS. Supabase Edge Functions are automatically HTTPS.

---

## Troubleshooting

### Webhook Not Received

**Check:**
1. ✅ Webhook URL is correct
2. ✅ Edge Function is deployed and active
3. ✅ Payment gateway webhook settings saved
4. ✅ Test payment completed successfully

**View logs:**
```bash
# Supabase Dashboard
Dashboard → Edge Functions → process-referral-payment → Logs

# OR via CLI
supabase functions logs process-referral-payment
```

### Commission Not Created

**Check database:**
```sql
-- Check transactions
SELECT * FROM transactions
WHERE payment_reference = 'your-payment-reference';

-- Check commissions
SELECT c.*, t.payment_reference
FROM commissions c
JOIN transactions t ON c.transaction_id = t.id
WHERE t.payment_reference = 'your-payment-reference';

-- Check Edge Function logs for errors
```

### Invalid Metadata

**Error:** "Webhook must include either group_id or transaction_id"

**Fix:** Ensure your payment initialization includes the correct metadata:
```typescript
metadata: {
  customer_id: '...', // Required
  // One of these:
  group_id: '...',    // For multi-service
  transaction_id: '...' // For single transaction
}
```

---

## Testing Checklist

- [ ] Webhook URL configured in payment gateway
- [ ] Test payment with test card successful
- [ ] Webhook received by Edge Function (check logs)
- [ ] Transaction status updated to 'completed'
- [ ] Commission record created in database
- [ ] Self-provider check working (no referral commission when provider = referrer)
- [ ] External provider check working (referral commission when provider ≠ referrer)
- [ ] Multi-service group processing works
- [ ] Payment callback redirects correctly
- [ ] Production keys configured in environment variables

---

## Next Steps

After webhook setup:
1. **Test thoroughly** with test cards
2. **Monitor logs** for first few real transactions
3. **Set up alerts** for failed webhooks
4. **Document** your specific payment flow for team
5. **Go live** with production keys

Your commission system is now fully integrated with payment processing! 🎉
