# Healthcare Customer Portal

Patient/customer interface for booking and managing healthcare consultations.

## Tech Stack

- SvelteKit 2.0
- Svelte 5
- Tailwind CSS 4
- TypeScript
- Supabase

## Features

- Book consultations
- View appointment history
- Manage profile
- Real-time notifications

## Getting Started

### Prerequisites

- Node.js 18+
- Supabase account

### Installation

```bash
# Install dependencies
npm install

# Copy environment variables
cp .env.example .env
# Edit .env with your Supabase credentials

# Start development server
npm run dev
```

The app will run on http://localhost:5173

### Build for Production

```bash
npm run build
npm run preview
```

## Environment Variables

Create a `.env` file with:

```
PUBLIC_SUPABASE_URL=https://your-project.supabase.co
PUBLIC_SUPABASE_ANON_KEY=your-anon-key
```

## Project Structure

```
src/
├── routes/
│   ├── +layout.svelte          # Root layout
│   ├── +page.svelte            # Home/dashboard
│   ├── consultations/          # Consultations list
│   ├── book/                   # Book new consultation
│   ├── profile/                # User profile
│   └── notifications/          # Notifications
├── lib/
│   ├── components/             # Reusable components
│   ├── stores/                 # Svelte stores
│   └── supabase.ts             # Supabase client
├── app.html                    # HTML template
└── app.css                     # Global styles
```

## Database Schema

This app connects to the following Supabase tables:

- `patients` - Patient records
- `consultations` - Consultation sessions
- `appointments` - Scheduled appointments
- `healthcare_providers` - Medical professionals

## Development

```bash
# Type checking
npm run check

# Watch mode
npm run check:watch
```

## Deployment

Deploy to Vercel, Netlify, or Cloudflare Pages:

```bash
npm run build
```

Deploy the `.svelte-kit/` output.
