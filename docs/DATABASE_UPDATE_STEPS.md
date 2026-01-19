# Database Update Steps

## ✅ Connection Status: SUCCESS!

Your Supabase connection is working! Now we need to update the database with the latest schema changes.

---

## 📋 What Needs to Be Done

1. ✅ **Connection established** - DONE!
2. ⏳ **Update subscription data** - PENDING
3. ⏳ **Apply chat enhancements (Migration 011)** - PENDING
4. ⏳ **Apply e-commerce enhancements (Migration 012)** - PENDING

---

## 🚀 Step-by-Step Instructions

### **Step 1: Open Supabase SQL Editor**

1. Go to: https://supabase.com/dashboard/project/ykbpznoqebhopyqpoqaf
2. Click **SQL Editor** in the left sidebar
3. Click **New query**

---

### **Step 2: Run Update Script**

Copy and paste the contents of this file into the SQL Editor:

📁 **File:** `supabase/migrations/000_update_existing_database.sql`

This script will:
- Delete old subscription data
- Add `enterprise_custom` plan tier
- Add `commission_cap_amount` column
- Insert 5 updated subscription plans with correct rates:
  - Free: 0% commission
  - Basic: 0% commission
  - Pro: 1.5% commission, ₦500 cap
  - Enterprise: 1% commission, ₦500 cap
  - Enterprise Custom: 0.5% commission, ₦500 cap
- Add e-commerce fields to tenants table

**Click "Run" ▶️**

You should see a table showing 5 subscription plans.

---

### **Step 3: Apply Chat Enhancements (Migration 011)**

1. Create a **New query** in SQL Editor
2. Copy and paste the contents of this file:

📁 **File:** `supabase/migrations/011_chat_enhancements.sql`

This adds:
- Rich media support (images, audio, video)
- Product cards in chat
- Payment confirmations
- Interactive actions

**Click "Run" ▶️**

You should see: `Success. No rows returned`

---

### **Step 4: Apply E-Commerce Enhancements (Migration 012)**

1. Create a **New query** in SQL Editor
2. Copy and paste the contents of this file:

📁 **File:** `supabase/migrations/012_ecommerce_enhancements.sql`

This adds:
- E-commerce product views
- Custom domain support
- Location-based filtering
- Commission calculation functions

**Click "Run" ▶️**

You should see: `Success. No rows returned`

---

## ✅ Verification

After running all 3 scripts, verify everything is working:

### **Option A: Run Test Script (CLI)**

```bash
cd C:\Users\AFOKE\kemani
node scripts/test-connection.mjs
```

You should see:
```
✅ Connection successful!
📊 Found 5 subscription plans:
- free (₦0, 0%)
- basic (₦5,000, 0%)
- pro (₦15,000, 1.5%)
- enterprise (₦50,000, 1%)
- enterprise_custom (₦0, 0.5%)
```

### **Option B: Check in Browser**

1. Make sure dev server is running: `npm run dev`
2. Visit: http://localhost:3000/test
3. You should see 5 subscription plans with correct commission rates

### **Option C: SQL Query**

Run this in Supabase SQL Editor:

```sql
SELECT
    plan_tier,
    monthly_fee,
    commission_rate,
    commission_cap_amount
FROM subscriptions
ORDER BY monthly_fee;
```

Should return 5 rows with the updated data.

---

## 🎯 Expected Results

After all updates, your database should have:

### **Subscription Plans (5 total)**

| Plan | Monthly Fee | Commission | Cap |
|------|-------------|------------|-----|
| free | ₦0 | 0% | ₦500 |
| basic | ₦5,000 | 0% | ₦500 |
| pro | ₦15,000 | 1.5% | ₦500 |
| enterprise | ₦50,000 | 1% | ₦500 |
| enterprise_custom | Contact Sales | 0.5% | ₦500 |

### **New Enums**
- `plan_tier`: includes 'enterprise_custom'
- `chat_message_type`: text, image, audio, video, etc.
- `chat_action_type`: add_to_cart, apply_discount, etc.

### **New Tables/Columns**
- `chat_messages`: Enhanced with rich media support
- `tenants`: Added e-commerce columns
- `subscriptions`: Added commission_cap_amount

### **New Functions**
- `has_chat_feature(tenant_id)`
- `has_ecommerce_chat_feature(tenant_id)`
- `can_enable_ecommerce(tenant_id)`
- `can_use_custom_domain(tenant_id)`
- `get_storefront_url(tenant_id, base_url)`
- `get_ecommerce_products(...)`
- `calculate_commission(tenant_id, amount)`

---

## ❓ Troubleshooting

### Error: "relation already exists"
- Skip that part of the script, it's already been applied

### Error: "column already exists"
- The migration has already been partially applied
- Check if the column exists with the correct data

### Error: "type already exists"
- The enum has already been created
- Verify it has the correct values

---

## 📞 Need Help?

If you encounter any errors:

1. **Copy the error message**
2. **Note which step failed**
3. **Share the error** and I'll help you fix it

---

## 🎉 Next Steps After Database Update

Once all migrations are applied successfully:

1. ✅ **Start building** - Choose your first feature:
   - Authentication pages
   - POS interface
   - E-commerce storefront

2. ✅ **Check the roadmap** - See `docs/implementation-roadmap.md`

3. ✅ **Review documentation**:
   - `docs/ecommerce-storefront-guide.md`
   - `docs/chat-system-guide.md`
   - `docs/subscription-tiers.md`
   - `docs/commission-structure.md`

---

## 🚀 Ready to Start!

Once you see ✅ for all verification steps, your database is fully set up and you're ready to start building the application!

**Need me to guide you through any of these steps?** Just let me know!
