# Healthcare Medic Provider Dashboard

SvelteKit-based healthcare provider/medic interface for managing consultations, availability, prescriptions, and analytics.

## Features

- **Dashboard** - Overview of consultations, patients, and earnings
- **Patient Management** - View patients list, add new patients, manage patient records
- **Consultations Management** - View, update status, manage patient consultations
- **Schedule Consultations** - Manually schedule office visits for patients
- **Prescriptions** - Create and manage digital prescriptions with medication details
- **Lab Test Requests** - Request laboratory tests and diagnostic services for patients
- **Chat System** - Real-time messaging with patients, pharmacies, and labs
  - Reply to patient messages
  - Initiate chats with pharmacies and labs
  - Upload images, PDFs, and voice notes
  - File attachments and previews
- **Commissions & Earnings** - Track consultation earnings and payout history
- **Availability Management** - Set weekly availability templates and manage time slots
- **Analytics** - Track performance metrics, revenue, and patient statistics
- **Authentication** - Secure login for healthcare providers

## Tech Stack

- **SvelteKit 2.0** - Full-stack web framework
- **Svelte 5** - Reactive UI framework
- **Tailwind CSS 4** - Utility-first CSS framework
- **Supabase** - Backend database and authentication
- **TypeScript** - Type-safe development
- **Lucide Svelte** - Icon library

## Prerequisites

- Node.js 18+
- npm or pnpm
- Supabase account

## Getting Started

### 1. Install Dependencies

```bash
cd apps/healthcare_medic
npm install
```

### 2. Environment Setup

Create a `.env` file in the root directory:

```bash
PUBLIC_SUPABASE_URL=https://your-project.supabase.co
PUBLIC_SUPABASE_ANON_KEY=your-anon-key
```

You can copy `.env.example` and fill in your Supabase credentials.

### 3. Run Development Server

```bash
npm run dev
```

The application will be available at `http://localhost:5174`

### 4. Build for Production

```bash
npm run build
npm run preview
```

## Project Structure

```
apps/healthcare_medic/
├── src/
│   ├── routes/
│   │   ├── +layout.svelte          # Main layout with navigation
│   │   ├── +page.svelte            # Dashboard page
│   │   ├── auth/
│   │   │   ├── login/+page.svelte  # Login page
│   │   │   └── signup/+page.svelte # Provider registration
│   │   ├── consultations/
│   │   │   └── +page.svelte        # Consultations management
│   │   ├── availability/
│   │   │   └── +page.svelte        # Availability management
│   │   ├── prescriptions/
│   │   │   └── +page.svelte        # Prescriptions management
│   │   ├── patients/
│   │   │   ├── +page.svelte        # Patients list
│   │   │   ├── add/+page.svelte    # Add new patient
│   │   │   └── [id]/
│   │   │       ├── schedule/+page.svelte   # Schedule consultation
│   │   │       ├── prescribe/+page.svelte  # Create prescription
│   │   │       └── lab-test/+page.svelte   # Request lab test
│   │   ├── chats/
│   │   │   ├── +page.svelte        # Chats list
│   │   │   ├── new/+page.svelte    # Start new chat
│   │   │   └── [id]/+page.svelte   # Individual chat
│   │   ├── commissions/
│   │   │   └── +page.svelte        # Commission tracking & earnings
│   │   └── analytics/
│   │       └── +page.svelte        # Analytics dashboard
│   ├── lib/
│   │   └── supabase.ts             # Supabase client
│   ├── app.css                      # Global styles
│   ├── app.d.ts                     # Type definitions
│   └── app.html                     # HTML template
├── package.json
├── svelte.config.js
├── tailwind.config.js
└── vite.config.ts
```

## Database Tables

This app connects to the following Supabase tables:

- `healthcare_providers` - Provider profiles and settings
- `consultations` - Consultation sessions with patients
- `consultation_messages` - Chat messages (future feature)
- `provider_availability_templates` - Weekly availability schedules
- `provider_time_slots` - Bookable time slots
- `prescriptions` - Digital prescriptions
- `consultation_transactions` - Payment and commission tracking with payout status

## Key Pages

### Dashboard (`/`)
- Overview of today's consultations
- Upcoming appointments
- Total patients and earnings
- Recent consultations table
- Monthly earnings with link to commissions

### Patients (`/patients`)
- View all patients with search functionality
- Patient statistics (total consultations, last visit)
- Quick actions: Schedule, Prescribe, Lab Test
- Add new patient with medical history
- Patient profile management

**Add Patient (`/patients/add`)**
- Create patient account with email/password
- Collect personal information (name, phone, DOB, gender)
- Medical information (blood group, allergies, medical history)
- Address details

**Schedule Consultation (`/patients/[id]/schedule`)**
- Book office visits for patients
- Set consultation type, date, time, and duration
- Configure consultation fees
- Add location details for office visits

**Create Prescription (`/patients/[id]/prescribe`)**
- Link to consultation (optional)
- Add diagnosis
- Multiple medications support
- Medication details: name, dosage, frequency, duration
- NAFDAC number tracking
- Special instructions per medication

**Request Lab Test (`/patients/[id]/lab-test`)**
- Link to consultation (optional)
- Select test category (blood, urine, imaging, biopsy, culture)
- Set priority (routine, urgent, STAT)
- Clinical indication
- Multiple tests per request
- Sample type specification

### Consultations (`/consultations`)
- View all consultations (filterable by status)
- Update consultation status (pending → in_progress → completed)
- Cancel consultations
- View consultation details

### Availability (`/availability`)
- Create weekly availability templates
- Set working hours by day of week
- Configure slot duration and buffer time
- Specify consultation types available

### Prescriptions (`/prescriptions`)
- View all issued prescriptions
- Create new prescriptions (future feature)
- Track prescription status (active, expired, fulfilled)
- View medication details

### Commissions (`/commissions`)
- Track all consultation earnings and commission breakdowns
- View total earnings, pending payouts, and paid out amounts
- Filter transactions by payout status and date range
- Export commission history to CSV
- Real-time earnings from `consultation_transactions` table
- Commission breakdown showing gross amount, platform fee, and net earnings
- Payout status tracking (pending, paid out, on hold, cancelled)

### Messages (`/chats`)
- View all conversations (patients, pharmacies, labs)
- Search conversations
- Filter by participant type
- Unread message indicators
- Real-time chat interface

**Individual Chat (`/chats/[id]`)**
- Send and receive messages
- Upload attachments (images, PDFs, documents)
- Image previews
- Voice note recording (with MediaRecorder API)
- File attachments with icons
- Message timestamps
- Scrollable chat history

**Start New Chat (`/chats/new`)**
- Initiate conversations with pharmacies
- Initiate conversations with labs
- Search available entities
- Filter by type

### Analytics (`/analytics`)
- Total consultations and revenue
- Completion rate and patient count
- Consultations by type (chat, video, audio)
- Consultations by status
- Average provider rating

## Authentication Flow

1. **Login** (`/auth/login`) - Email/password authentication
2. **Signup** (`/auth/signup`) - Two-step provider registration:
   - Step 1: Account information (email, password, name, phone)
   - Step 2: Professional information (type, specialization, license, fees)
3. **Auto-redirect** - Authenticated users redirect to dashboard
4. **Provider Verification** - Only users with `healthcare_providers` profile can access

## Features Roadmap

- [x] Dashboard with key metrics
- [x] Patient management (list, add, search)
- [x] Consultations management (view, update status)
- [x] Schedule consultations manually
- [x] Create prescriptions with multiple medications
- [x] Request lab tests
- [x] Chat system (patients, pharmacies, labs)
- [x] File uploads (images, PDFs, voice notes)
- [x] Availability templates
- [x] Commission tracking and earnings history
- [x] Analytics dashboard
- [x] CSV export for commissions
- [ ] Video consultation integration (Agora)
- [ ] Real-time chat with WebSockets
- [ ] Patient medical records timeline
- [ ] Appointment calendar view
- [ ] Push notifications system
- [ ] Export analytics reports
- [ ] Profile settings management
- [ ] Payout request feature
- [ ] Bank account management
- [ ] Lab test results viewing
- [ ] Prescription tracking and fulfillment

## Development Commands

```bash
# Start dev server
npm run dev

# Type check
npm run check

# Type check in watch mode
npm run check:watch

# Build for production
npm run build

# Preview production build
npm run preview
```

## Port Configuration

The dev server runs on port **5174** (different from healthcare_customer which runs on 5173).

## Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `PUBLIC_SUPABASE_URL` | Supabase project URL | Yes |
| `PUBLIC_SUPABASE_ANON_KEY` | Supabase anonymous key | Yes |

## Security Notes

- All routes except `/auth/*` require authentication
- Row-Level Security (RLS) policies enforce data access control
- Providers can only access their own consultations and prescriptions
- JWT verification is handled by Supabase Auth

## License

[Add your license here]
