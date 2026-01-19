# Supabase Setup Guide

## 📍 Where to Add Supabase Credentials

### Location: `.env.local`

The Supabase credentials go in the **`.env.local`** file in your project root:

```
C:\Users\AFOKE\kemani\.env.local
```

This file has been created for you with placeholders. You just need to fill in your actual values.

---

## 🔑 How to Get Your Supabase Credentials

### Step 1: Go to Your Supabase Dashboard

1. Visit: https://supabase.com/dashboard
2. Log in to your account
3. Select your project (or create a new one if you haven't already)

---

### Step 2: Get Your Project URL

1. In your project dashboard, go to **Settings** (gear icon on left sidebar)
2. Click **API** in the settings menu
3. Under **Project URL**, copy the URL
   - It looks like: `https://abcdefghijklmnop.supabase.co`

**Paste it in `.env.local`:**
```env
NEXT_PUBLIC_SUPABASE_URL=https://abcdefghijklmnop.supabase.co
```

---

### Step 3: Get Your Anon/Public Key

1. Still in **Settings → API**
2. Under **Project API keys**, find **`anon` `public`**
3. Copy the key (it starts with `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`)

**Paste it in `.env.local`:**
```env
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

---

### Step 4: Get Your Service Role Key

⚠️ **WARNING:** This key has admin privileges. NEVER expose it publicly!

1. Still in **Settings → API**
2. Under **Project API keys**, find **`service_role` `secret`**
3. Click **Reveal** and copy the key

**Paste it in `.env.local`:**
```env
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

---

## ✅ Final `.env.local` File Should Look Like:

```env
# Supabase Configuration
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlvdXItcHJvamVjdCIsInJvbGUiOiJhbm9uIiwiaWF0IjoxNjk5OTk5OTk5LCJleHAiOjIwMTU1NzU5OTl9.abcdefghijklmnopqrstuvwxyz1234567890
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlvdXItcHJvamVjdCIsInJvbGUiOiJzZXJ2aWNlX3JvbGUiLCJpYXQiOjE2OTk5OTk5OTksImV4cCI6MjAxNTU3NTk5OX0.abcdefghijklmnopqrstuvwxyz1234567890
```

---

## 🔒 Security Notes

1. **`.env.local` is git-ignored** - Your credentials are safe and won't be committed
2. **NEVER commit** `.env.local` to version control
3. **Service Role Key** should only be used server-side (never in browser)
4. **Anon Key** is safe to expose in the browser (it's public)

---

## 📂 Files Created for You

### 1. **`.env.local`** (Your actual credentials - NOT committed to git)
```
C:\Users\AFOKE\kemani\.env.local
```

### 2. **`.env.example`** (Template - safe to commit)
```
C:\Users\AFOKE\kemani\.env.example
```

### 3. **`lib/supabase/server.ts`** (Server-side Supabase client)
```typescript
// Use in Server Components, Server Actions, Route Handlers
import { createClient } from '@/lib/supabase/server'

export async function MyServerComponent() {
  const supabase = await createClient()
  const { data } = await supabase.from('products').select('*')
  // ...
}
```

### 4. **`lib/supabase/client.ts`** (Client-side Supabase client)
```typescript
// Use in Client Components (marked with 'use client')
import { createClient } from '@/lib/supabase/client'

export function MyClientComponent() {
  const supabase = createClient()
  // ...
}
```

### 5. **`lib/supabase/middleware.ts`** (Auth middleware helper)
```typescript
// Used in middleware.ts for authentication
```

---

## 🚀 Next Steps After Adding Credentials

### 1. Restart Your Dev Server

After updating `.env.local`, restart your Next.js dev server:

```bash
# Stop the current server (Ctrl+C)
# Then restart:
npm run dev
```

### 2. Verify Connection

Create a test file to verify your connection works:

**`app/test/page.tsx`:**
```typescript
import { createClient } from '@/lib/supabase/server'

export default async function TestPage() {
  const supabase = await createClient()

  // Test connection by listing subscription plans
  const { data, error } = await supabase
    .from('subscriptions')
    .select('plan_tier, monthly_fee')

  if (error) {
    return <div>Error: {error.message}</div>
  }

  return (
    <div>
      <h1>Supabase Connection Test</h1>
      <pre>{JSON.stringify(data, null, 2)}</pre>
    </div>
  )
}
```

Visit: http://localhost:3000/test

If you see your subscription plans, **you're connected!** ✅

---

## 🛠️ Apply Database Migrations

Now that your credentials are set, apply the migrations:

### Option A: Via Supabase Dashboard (Recommended)

1. Go to https://supabase.com/dashboard/project/YOUR_PROJECT/sql/new
2. Copy the content from each migration file in order:
   - `supabase/migrations/001_extensions_and_enums.sql`
   - `supabase/migrations/002_core_tables.sql`
   - etc. (through 012)
3. Paste and click **Run**
4. Repeat for all 12 migrations

### Option B: Via Supabase CLI

```bash
# Install Supabase CLI (if not already installed)
npm install -g supabase

# Login to Supabase
supabase login

# Link your project
supabase link --project-ref your-project-ref

# Push all migrations
supabase db push
```

---

## 📋 Verification Checklist

After setup, verify everything works:

- [ ] `.env.local` file created with all 3 credentials
- [ ] Dev server restarted
- [ ] Test page shows connection works
- [ ] All 12 migrations applied successfully
- [ ] Can query `subscriptions` table (should return 5 plans)

**Check migrations were applied:**
```sql
-- Run in Supabase SQL Editor
SELECT * FROM subscriptions ORDER BY monthly_fee;
```

Should return 5 rows:
- free (₦0)
- basic (₦5,000)
- pro (₦15,000)
- enterprise (₦50,000)
- enterprise_custom (₦0 - contact sales)

---

## ❓ Troubleshooting

### Error: "Invalid API key"
- Double-check you copied the full key (they're very long!)
- Make sure there are no extra spaces
- Verify you're using the correct project

### Error: "fetch failed"
- Check your NEXT_PUBLIC_SUPABASE_URL is correct
- Ensure you have internet connection
- Verify the Supabase project is active (not paused)

### Error: "relation does not exist"
- You haven't applied the migrations yet
- Go to Supabase Dashboard → SQL Editor and run migrations

### Changes not reflecting
- Restart your dev server: `Ctrl+C` then `npm run dev`
- Clear browser cache
- Check `.env.local` is in the project root

---

## 🔗 Useful Links

- **Supabase Dashboard:** https://supabase.com/dashboard
- **Supabase Docs:** https://supabase.com/docs
- **Next.js + Supabase Guide:** https://supabase.com/docs/guides/getting-started/quickstarts/nextjs

---

## 🆘 Need Help?

If you're stuck:

1. **Check Supabase Logs:**
   - Dashboard → Logs → Database Logs

2. **Verify API Keys:**
   - Dashboard → Settings → API
   - Confirm keys match your `.env.local`

3. **Test Connection:**
   - Create the test page above
   - Check browser console for errors

---

## 🎉 You're All Set!

Once you see your subscription plans in the test page, you're ready to start building! 🚀

**What's next?**
- Build authentication pages
- Create the POS interface
- Set up the e-commerce storefront

See: `docs/implementation-roadmap.md` for the full build plan.
