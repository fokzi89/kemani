# Commission Structure

## Overview

The platform charges commission **only on e-commerce orders**. In-store POS transactions have **no commission fees**.

## Commission Rates by Plan

| Plan | E-Commerce Available | Commission Rate | Maximum Per Order |
|------|---------------------|-----------------|-------------------|
| **Free** | ❌ No | 0% | N/A |
| **Basic** | ❌ No | 0% | N/A |
| **Pro** | ✅ Yes | 1.5% | **₦500 cap** |
| **Enterprise** | ✅ Yes | 1% | **₦500 cap** |
| **Enterprise Custom** | ✅ Yes | 0.5% (negotiable) | **₦500 cap** |

## Commission Cap: ₦500

**All e-commerce plans have a ₦500 maximum commission per order**, regardless of order value.

### Why the Cap?

The ₦500 cap ensures:
- Predictable costs for high-value orders
- Fair pricing for both platform and tenants
- Maximum commission revenue per transaction is capped

## Commission Calculation Examples

### Pro Plan (1.5% rate, ₦500 cap)

| Order Amount | Calculated (1.5%) | Actual Commission | Explanation |
|--------------|-------------------|-------------------|-------------|
| ₦5,000 | ₦75 | **₦75** | Below cap |
| ₦10,000 | ₦150 | **₦150** | Below cap |
| ₦20,000 | ₦300 | **₦300** | Below cap |
| ₦33,333 | ₦500 | **₦500** | At cap |
| ₦50,000 | ₦750 | **₦500** | Capped |
| ₦100,000 | ₦1,500 | **₦500** | Capped |
| ₦500,000 | ₦7,500 | **₦500** | Capped |

**Breakeven point:** Orders above ₦33,333 are capped at ₦500 commission.

---

### Enterprise Plan (1% rate, ₦500 cap)

| Order Amount | Calculated (1%) | Actual Commission | Explanation |
|--------------|-----------------|-------------------|-------------|
| ₦10,000 | ₦100 | **₦100** | Below cap |
| ₦25,000 | ₦250 | **₦250** | Below cap |
| ₦50,000 | ₦500 | **₦500** | At cap |
| ₦75,000 | ₦750 | **₦500** | Capped |
| ₦100,000 | ₦1,000 | **₦500** | Capped |
| ₦500,000 | ₦5,000 | **₦500** | Capped |
| ₦1,000,000 | ₦10,000 | **₦500** | Capped |

**Breakeven point:** Orders above ₦50,000 are capped at ₦500 commission.

---

### Enterprise Custom Plan (0.5% rate, ₦500 cap)

| Order Amount | Calculated (0.5%) | Actual Commission | Explanation |
|--------------|-------------------|-------------------|-------------|
| ₦20,000 | ₦100 | **₦100** | Below cap |
| ₦50,000 | ₦250 | **₦250** | Below cap |
| ₦100,000 | ₦500 | **₦500** | At cap |
| ₦200,000 | ₦1,000 | **₦500** | Capped |
| ₦500,000 | ₦2,500 | **₦500** | Capped |
| ₦1,000,000 | ₦5,000 | **₦500** | Capped |
| ₦10,000,000 | ₦50,000 | **₦500** | Capped |

**Breakeven point:** Orders above ₦100,000 are capped at ₦500 commission.

---

## Database Implementation

### Schema

The `subscriptions` table has two commission-related columns:

```sql
CREATE TABLE subscriptions (
    ...
    commission_rate DECIMAL(5,2),           -- Percentage (e.g., 1.5)
    commission_cap_amount DECIMAL(12,2),    -- Maximum amount (default ₦500)
    ...
);
```

### Calculation Function

Use the `calculate_commission()` function to automatically apply the cap:

```sql
SELECT calculate_commission('tenant-uuid', 50000);
-- Returns: 500.00 (for Pro plan)
```

**Function Logic:**
1. Get tenant's commission rate and cap from subscription
2. Calculate: `order_amount × (commission_rate / 100)`
3. If calculated > cap, return cap
4. Otherwise, return calculated amount

### Example Queries

**Calculate commission for a single order:**
```sql
SELECT calculate_commission('tenant-uuid', 75000);
```

**Calculate commissions for all orders:**
```sql
SELECT
    order_id,
    order_number,
    total_amount,
    calculate_commission(tenant_id, total_amount) as commission,
    total_amount - calculate_commission(tenant_id, total_amount) as tenant_receives
FROM orders
WHERE tenant_id = 'tenant-uuid'
AND order_type = 'marketplace'
AND payment_status = 'paid';
```

**Monthly commission report:**
```sql
SELECT
    DATE_TRUNC('month', created_at) as month,
    COUNT(*) as total_orders,
    SUM(total_amount) as total_sales,
    SUM(calculate_commission(tenant_id, total_amount)) as total_commission,
    AVG(calculate_commission(tenant_id, total_amount)) as avg_commission
FROM orders
WHERE tenant_id = 'tenant-uuid'
AND order_type = 'marketplace'
AND payment_status = 'paid'
GROUP BY DATE_TRUNC('month', created_at)
ORDER BY month DESC;
```

---

## Commission Settlement

### Settlement Flow

1. **Order Completed** → Commission calculated using `calculate_commission()`
2. **Record Commission** → Insert into `commissions` table
3. **Monthly Settlement** → Platform generates invoice
4. **Payment** → Tenant pays accumulated commissions

### Commissions Table

```sql
CREATE TABLE commissions (
    id UUID PRIMARY KEY,
    tenant_id UUID NOT NULL,
    order_id UUID UNIQUE NOT NULL,
    sale_amount DECIMAL(12,2) NOT NULL,
    commission_rate DECIMAL(5,2) NOT NULL,
    commission_amount DECIMAL(12,2) NOT NULL,  -- Capped amount
    settlement_status settlement_status DEFAULT 'pending',
    settlement_date DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

### Creating Commission Records

When an e-commerce order is completed:

```sql
-- Calculate and insert commission
INSERT INTO commissions (
    tenant_id,
    order_id,
    sale_amount,
    commission_rate,
    commission_amount,
    settlement_status
)
SELECT
    o.tenant_id,
    o.id,
    o.total_amount,
    s.commission_rate,
    calculate_commission(o.tenant_id, o.total_amount),  -- Applies cap automatically
    'pending'
FROM orders o
JOIN tenants t ON o.tenant_id = t.id
JOIN subscriptions s ON t.subscription_id = s.id
WHERE o.id = 'order-uuid'
AND o.order_type = 'marketplace'
AND o.payment_status = 'paid';
```

---

## Key Benefits

### For Tenants

1. **Predictable Costs** - Know maximum commission is ₦500
2. **High-Value Orders** - No penalty for large sales
3. **Scalability** - Grow sales without increasing per-order costs
4. **Transparency** - Clear commission structure

### For Platform

1. **Fair Revenue** - Earn from each transaction
2. **Competitive Rates** - Lower than most marketplace platforms
3. **Volume Growth** - Encourages high-value transactions
4. **Simple Billing** - Easy to calculate and explain

---

## Comparison with Other Platforms

| Platform | Commission Rate | Cap | Notes |
|----------|----------------|-----|-------|
| **Your Platform (Pro)** | 1.5% | ₦500 | Capped |
| **Your Platform (Enterprise)** | 1% | ₦500 | Capped |
| Jumia | 10-15% | None | No cap |
| Konga | 8-12% | None | No cap |
| Shopify Payments | 2.9% + ₦100 | None | Per transaction fee |
| WooCommerce | 0% + Payment fees | N/A | Self-hosted |

**Your platform is significantly more cost-effective for high-value orders!**

---

## FAQs

### Q: Are in-store POS sales charged commission?
**A:** No. Only e-commerce orders incur commission. In-store sales have no fees.

### Q: What if my order is ₦1,000,000?
**A:** You pay only ₦500 commission, regardless of plan.

### Q: Can the cap be negotiated?
**A:** For Enterprise Custom plans, both the rate and cap are negotiable.

### Q: When is commission charged?
**A:** Commission is calculated when the order is marked as `paid`. It's settled monthly.

### Q: What if an order is refunded?
**A:** Commission is also refunded. The `commissions` table tracks refunds.

### Q: Do I pay commission on delivery fees?
**A:** Yes, commission is calculated on the `total_amount` including delivery fees.

### Q: How do I see my commission breakdown?
**A:** Use the analytics dashboard or query the `commissions` table.

---

## Related Documentation

- [Subscription Tiers](./subscription-tiers.md) - Full plan comparison
- [E-Commerce Storefront Guide](./ecommerce-storefront-guide.md) - Setting up your storefront
- [Database Schema Changes](./database-schema-changes.md) - Technical implementation
