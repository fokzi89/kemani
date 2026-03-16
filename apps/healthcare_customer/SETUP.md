# Healthcare Customer App - Setup Guide

Complete setup guide for the Kemani Health Customer Portal with Supabase and Agora integration.

## 📋 Prerequisites

- Node.js 18+ installed
- Supabase project created
- Agora.io account and project created
- Git installed

## 🔑 1. Supabase Setup

### Database Migrations

Ensure all healthcare migrations have been run:

```bash
# From project root
supabase db push

# Or manually run the migration
psql -d your_database < supabase/migrations/20260222194504_healthcare_consultation.sql
```

### Environment Variables

Create `.env` file in `apps/healthcare_customer/`:

```env
PUBLIC_SUPABASE_URL=https://your-project.supabase.co
PUBLIC_SUPABASE_ANON_KEY=your-anon-key
```

Get these values from Supabase Dashboard → Settings → API

## 🎥 2. Agora Setup

### Get Agora Credentials

1. Go to [Agora Console](https://console.agora.io/)
2. Create a project or use existing one
3. Get your **App ID** and **App Certificate**

### Configure Edge Function

Deploy the Agora token generation function:

```bash
# Set Agora secrets in Supabase
supabase secrets set AGORA_APP_ID=your_app_id
supabase secrets set AGORA_APP_CERTIFICATE=your_app_certificate

# Deploy the function
supabase functions deploy generate-agora-token
```

Alternatively, set secrets in Supabase Dashboard → Edge Functions → Secrets:
- `AGORA_APP_ID`: Your Agora App ID
- `AGORA_APP_CERTIFICATE`: Your Agora App Certificate

## 📦 3. Install Dependencies

```bash
cd apps/healthcare_customer
npm install
```

Dependencies include:
- `@supabase/supabase-js` - Supabase client
- `@supabase/ssr` - Server-side rendering support
- `agora-rtc-sdk-ng` - Agora video/audio SDK
- `lucide-svelte` - Icons
- `tailwindcss` - Styling

## 🚀 4. Run the Application

```bash
npm run dev
```

The app will be available at `http://localhost:5173`

## 🗂️ Project Structure

```
apps/healthcare_customer/
├── src/
│   ├── lib/
│   │   ├── supabase.ts              # Supabase client
│   │   ├── agora.ts                 # Agora service wrapper
│   │   └── stores/
│   │       └── auth.svelte.ts       # Auth state management
│   ├── routes/
│   │   ├── +layout.svelte           # Main layout with navigation
│   │   ├── +page.svelte             # Dashboard
│   │   ├── auth/
│   │   │   ├── login/               # Login page
│   │   │   └── signup/              # Signup page
│   │   ├── consultations/
│   │   │   ├── +page.svelte         # Consultations list
│   │   │   └── [id]/
│   │   │       ├── +page.svelte     # Video consultation room
│   │   │       └── +page.server.ts  # Load consultation data
│   │   ├── providers/
│   │   │   ├── +page.svelte         # Provider directory
│   │   │   └── +page.server.ts      # Load providers
│   │   ├── book/
│   │   │   └── [slug]/
│   │   │       ├── +page.svelte     # Booking flow
│   │   │       └── +page.server.ts  # Load provider & slots
│   │   ├── prescriptions/           # Prescriptions page
│   │   ├── profile/                 # User profile
│   │   └── notifications/           # Notifications
│   └── app.css                      # Global styles
└── .env                             # Environment variables
```

## 🎯 5. Key Features

### Authentication
- Email/password signup and login
- Session management with Supabase Auth
- Protected routes (automatic redirect to login)

### Video Consultations
- Real-time video/audio using Agora
- Secure token generation via Supabase Edge Function
- Picture-in-picture local video
- Microphone and camera controls
- Consultation timer

### Chat
- Real-time chat messages during consultations
- Stored in `consultation_messages` table
- Realtime subscriptions using Supabase Realtime

### Provider Directory
- Search and filter providers
- View ratings, specializations, fees
- Book consultations

### Booking Flow
- 3-step booking process
- Select consultation type (video, audio, chat, office visit)
- Choose date and time slot
- Payment integration (ready for Paystack/Flutterwave)

## 🔒 6. Security

### Row Level Security (RLS)
All tables have RLS policies:
- Patients can only see their own consultations
- Providers can only see consultations they're assigned to
- Secure message access for participants only

### Agora Token Security
- Tokens generated server-side only
- 1-hour expiration
- Consultation access verified before token generation

## 🧪 7. Testing

### Test User Flow

1. **Sign Up**
   - Navigate to `/auth/signup`
   - Create account with email/password

2. **Browse Providers**
   - Go to `/providers`
   - Search or filter by specialization

3. **Book Consultation**
   - Click "Book Consultation" on provider card
   - Select type (video/audio/chat)
   - Choose date/time
   - Complete payment

4. **Join Consultation**
   - Go to `/consultations`
   - Click on scheduled consultation
   - Click "Join Call"
   - Allow camera/microphone permissions

### Test Video Call

For testing video calls, you'll need:
1. Two browser windows (or incognito mode)
2. One logged in as patient
3. One logged in as provider
4. Both join the same consultation

## 📝 8. Environment Variables Reference

```env
# Required
PUBLIC_SUPABASE_URL=https://xxx.supabase.co
PUBLIC_SUPABASE_ANON_KEY=your-anon-key

# Agora (set via Supabase secrets)
AGORA_APP_ID=your-app-id
AGORA_APP_CERTIFICATE=your-app-certificate
```

## 🔧 9. Troubleshooting

### Video Call Not Connecting
- Check Agora credentials in Supabase secrets
- Verify Edge Function is deployed
- Check browser console for errors
- Ensure camera/microphone permissions granted

### Database Errors
- Verify migrations are applied
- Check RLS policies
- Ensure user is authenticated

### Authentication Issues
- Clear browser localStorage
- Check Supabase auth settings
- Verify email confirmation settings

## 🚀 10. Deployment

### Vercel Deployment

```bash
# Build the app
npm run build

# Deploy to Vercel
vercel deploy
```

### Environment Variables in Production
Set in your hosting platform:
- `PUBLIC_SUPABASE_URL`
- `PUBLIC_SUPABASE_ANON_KEY`

### Edge Function Deployment
```bash
supabase functions deploy generate-agora-token
```

## 📚 11. Additional Resources

- [Supabase Documentation](https://supabase.com/docs)
- [Agora Web SDK Documentation](https://docs.agora.io/en/video-calling/get-started/get-started-sdk)
- [SvelteKit Documentation](https://kit.svelte.dev/docs)

## 🆘 12. Support

For issues or questions:
1. Check database schema in `supabase/migrations/20260222194504_healthcare_consultation.sql`
2. Review RLS policies
3. Check browser console for errors
4. Verify environment variables

## ✅ 13. Next Steps

After setup:
1. Add sample providers to the database
2. Test full booking flow
3. Integrate payment gateway (Paystack/Flutterwave)
4. Set up email notifications
5. Configure custom domain
6. Add prescription management
7. Implement provider dashboard

---

**Built with:** SvelteKit 2.0 • Supabase • Agora • Tailwind CSS 4
