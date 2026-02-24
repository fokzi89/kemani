# Quick Start Guide - Testing Owner Flow

Follow these steps to start testing the owner registration and onboarding flow.

## Step 1: Start the Development Server

```bash
npm run dev
```

This will start the Next.js development server at `http://localhost:3000`

**Expected output:**
```
▲ Next.js 16.x.x
- Local:        http://localhost:3000
- Environments: .env.local

✓ Ready in Xms
```

## Step 2: Open the Login Page

Once the server is running, open your browser and navigate to:

```
http://localhost:3000/login
```

## Step 3: Follow the Owner Flow

See `OWNER_FLOW_TESTING_GUIDE.md` for the complete testing guide with all steps, expected results, and troubleshooting tips.

### Quick Test Steps:

1. **Login** (`/login`)
   - Enter your email address
   - Click "Send Verification Code"

2. **Verify OTP** (`/verify-otp`)
   - Check your email for the 6-digit code
   - Enter the code in the 6 input boxes
   - It auto-submits

3. **Register** (`/register`) - For new users only
   - Business Name: e.g., "My Coffee Shop"
   - Your Full Name: e.g., "John Doe"
   - Email: (pre-filled)
   - 6-Digit Passcode: e.g., "123456"
   - Confirm Passcode: "123456"
   - Click "Create Account"

4. **Access POS** (`/pos/pos`)
   - You'll be redirected here automatically
   - POS interface should load

## Troubleshooting

### Server Won't Start

**Issue:** `npm run dev` fails

**Solutions:**
```bash
# Install dependencies first
npm install

# Then try again
npm run dev
```

### Environment Variables Missing

**Issue:** Supabase connection errors

**Solutions:**
1. Create `.env.local` file in the root directory
2. Add your Supabase credentials:
```env
NEXT_PUBLIC_SUPABASE_URL=your_supabase_url
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key
```
3. Restart the dev server

### Port Already in Use

**Issue:** Port 3000 is already in use

**Solutions:**
```bash
# Use a different port
npm run dev -- -p 3001
# Then access at http://localhost:3001
```

## Need More Details?

- **Complete Testing Guide:** `OWNER_FLOW_TESTING_GUIDE.md`
- **Migration Documentation:** `MIGRATION_SUMMARY.md`
- **Conflict Resolution:** `MIGRATION_CONFLICTS_RESOLVED.md`

Happy testing! 🚀
