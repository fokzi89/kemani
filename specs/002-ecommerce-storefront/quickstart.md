# Quickstart Guide: Ecommerce Storefront

**Feature**: 002-ecommerce-storefront
**Framework**: SvelteKit 2.x
**Database**: Supabase PostgreSQL
**Deployment**: Subdomain (e.g., `store.tenant.com`)

This guide will help you set up the ecommerce storefront feature from scratch in under 30 minutes.

---

## Prerequisites

Before starting, ensure you have:

- ✅ **Node.js 18+** and npm installed
- ✅ **Supabase CLI** installed (`npm install -g supabase`)
- ✅ **Supabase project** set up (or local Supabase instance running)
- ✅ **Paystack account** with test API keys
- ✅ **Google OAuth credentials** (Client ID + Secret)
- ✅ **Apple Developer account** for Apple Sign In (optional)
- ✅ **OpenAI API key** (for AI agent - Business plan only)

---

## Step 1: Initialize SvelteKit Application

### 1.1 Create SvelteKit App

```bash
# From repository root
cd apps/

# Create SvelteKit app with TypeScript
npm create svelte@latest storefront

# Select options:
# - Which Svelte app template? → Skeleton project
# - Add type checking with TypeScript? → Yes, using TypeScript syntax
# - Select additional options:
#   ✓ Add ESLint for code linting
#   ✓ Add Prettier for code formatting
#   ✓ Add Playwright for browser testing
#   ✓ Add Vitest for unit testing
```

### 1.2 Install Dependencies

```bash
cd storefront

# Core dependencies
npm install @supabase/supabase-js @supabase/ssr

# Payment integration
npm install @paystack/inline-js

# AI agent (Business plan)
npm install openai

# Email & push notifications
npm install resend firebase-admin

# Progressive Web App (PWA)
npm install -D @vite-pwa/sveltekit workbox-window workbox-precaching workbox-routing workbox-strategies

# Utilities
npm install zod date-fns slugify

# Tailwind CSS 4
npm install -D tailwindcss@next postcss autoprefixer
npx tailwindcss init -p
```

### 1.3 Configure Tailwind CSS

Edit `tailwind.config.js`:

```javascript
/** @type {import('tailwindcss').Config} */
export default {
  content: ['./src/**/*.{html,js,svelte,ts}'],
  theme: {
    extend: {
      colors: {
        primary: {
          50: '#f0f9ff',
          500: '#0ea5e9',
          600: '#0284c7',
          700: '#0369a1',
        }
      }
    }
  },
  plugins: []
}
```

Add to `src/app.css`:

```css
@tailwind base;
@tailwind components;
@tailwind utilities;

/* Mobile-first responsive design */
@layer base {
  html {
    @apply text-base antialiased;
  }
  body {
    @apply bg-white text-gray-900;
  }
}
```

---

## Step 2: Configure Environment Variables

Create `.env.local` in `apps/storefront/`:

```bash
# Supabase Configuration
PUBLIC_SUPABASE_URL=https://your-project.supabase.co
PUBLIC_SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key

# Paystack Configuration (Test Mode)
PUBLIC_PAYSTACK_PUBLIC_KEY=pk_test_xxxxxxxxxxxxx
PAYSTACK_SECRET_KEY=sk_test_xxxxxxxxxxxxx

# Google OAuth (obtain from Google Cloud Console)
GOOGLE_CLIENT_ID=xxxxxxxxxxxxx.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=GOCSPX-xxxxxxxxxxxxx

# Apple Sign In (optional)
APPLE_CLIENT_ID=com.yourdomain.storefront
APPLE_TEAM_ID=XXXXXXXXXX
APPLE_KEY_ID=XXXXXXXXXX
APPLE_PRIVATE_KEY=-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----

# OpenAI API (for AI agent - Business plan only)
OPENAI_API_KEY=sk-proj-xxxxxxxxxxxxx

# Email & Push Notifications
RESEND_API_KEY=re_xxxxxxxxxxxxx

# Firebase Cloud Messaging (for push notifications)
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----"
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@your-project.iam.gserviceaccount.com
PUBLIC_FIREBASE_VAPID_KEY=Bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# Application URLs
PUBLIC_STOREFRONT_URL=http://localhost:5173
PUBLIC_ADMIN_URL=http://localhost:3000

# Session Configuration
SESSION_SECRET=your-random-secret-key-min-32-chars
```

**Security Notes**:
- Never commit `.env.local` to version control
- Use different keys for development and production
- Rotate secrets regularly

---

## Step 3: Database Setup

### 3.1 Run Supabase Migrations

Navigate to your repository root and run migrations:

```bash
# From repository root
cd supabase/

# Create new migration file
supabase migration new ecommerce_storefront

# Copy SQL from data-model.md to migration file
# File location: supabase/migrations/YYYYMMDD_ecommerce_storefront.sql
```

Copy the complete schema from `specs/002-ecommerce-storefront/data-model.md` including:
- All 11 tables (customers → chat_attachments)
- RLS policies for each table
- Indexes for performance
- Database functions (auto_update_timestamp, calculate_order_total, generate_order_number)
- Supabase Storage bucket setup

Apply migrations:

```bash
# Local development
supabase db reset  # Resets and applies all migrations

# Production
supabase db push
```

### 3.2 Configure Supabase Auth

Enable OAuth providers in Supabase Dashboard:

1. **Google OAuth**:
   - Navigate to Authentication → Providers → Google
   - Enable Google provider
   - Add Client ID and Client Secret from `.env.local`
   - Set redirect URL: `https://your-project.supabase.co/auth/v1/callback`

2. **Apple Sign In** (optional):
   - Navigate to Authentication → Providers → Apple
   - Enable Apple provider
   - Add Client ID, Team ID, Key ID, and Private Key
   - Set redirect URL: `https://your-project.supabase.co/auth/v1/callback`

### 3.3 Set Up Storage Bucket

```bash
# Run in Supabase SQL Editor or add to migration
INSERT INTO storage.buckets (id, name, public)
VALUES ('chat-attachments', 'chat-attachments', false);

-- Apply RLS policies from data-model.md
```

---

## Step 4: Project Structure Setup

Create the recommended directory structure:

```bash
cd apps/storefront/

# Create directory structure
mkdir -p src/lib/components/{ui,products,cart,checkout,chat}
mkdir -p src/lib/stores
mkdir -p src/lib/services
mkdir -p src/lib/utils
mkdir -p src/routes/api/{products,cart,checkout,chat,payment}
mkdir -p src/routes/{checkout,orders,auth}
```

### 4.1 Create Supabase Client

Create `src/lib/services/supabase.ts`:

```typescript
import { createClient } from '@supabase/supabase-js'
import { PUBLIC_SUPABASE_URL, PUBLIC_SUPABASE_ANON_KEY } from '$env/static/public'
import type { Database } from '$lib/types/database.types'

export const supabase = createClient<Database>(
  PUBLIC_SUPABASE_URL,
  PUBLIC_SUPABASE_ANON_KEY,
  {
    auth: {
      persistSession: true,
      autoRefreshToken: true
    },
    realtime: {
      params: {
        eventsPerSecond: 10
      }
    }
  }
)
```

### 4.2 Create Type Definitions

Generate TypeScript types from Supabase schema:

```bash
# From repository root
npx supabase gen types typescript --project-id your-project-id > apps/storefront/src/lib/types/database.types.ts
```

---

## Step 5: Configure Paystack Integration

Create `src/lib/services/paystack.ts`:

```typescript
import { PAYSTACK_SECRET_KEY } from '$env/static/private'
import { PUBLIC_PAYSTACK_PUBLIC_KEY } from '$env/static/public'

export async function initializePaystackTransaction({
  email,
  amount,
  reference,
  metadata
}: {
  email: string
  amount: number  // In kobo (multiply Naira by 100)
  reference: string
  metadata: Record<string, any>
}) {
  const response = await fetch('https://api.paystack.co/transaction/initialize', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${PAYSTACK_SECRET_KEY}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      email,
      amount,
      reference,
      metadata,
      callback_url: `${PUBLIC_STOREFRONT_URL}/checkout/callback`
    })
  })

  if (!response.ok) {
    throw new Error('Failed to initialize Paystack transaction')
  }

  const data = await response.json()
  return {
    authorization_url: data.data.authorization_url,
    access_code: data.data.access_code,
    reference: data.data.reference
  }
}

export function verifyPaystackSignature(signature: string, payload: string): boolean {
  const crypto = require('crypto')
  const hash = crypto
    .createHmac('sha512', PAYSTACK_SECRET_KEY)
    .update(payload)
    .digest('hex')
  return hash === signature
}
```

---

## Step 6: Set Up Real-time Chat

Create `src/lib/services/chat.ts`:

```typescript
import { supabase } from './supabase'
import type { RealtimeChannel } from '@supabase/supabase-js'

export function subscribeToChatMessages(
  sessionId: string,
  onMessage: (message: any) => void
): RealtimeChannel {
  const channel = supabase
    .channel(`chat:${sessionId}`)
    .on(
      'postgres_changes',
      {
        event: 'INSERT',
        schema: 'public',
        table: 'chat_messages',
        filter: `session_id=eq.${sessionId}`
      },
      (payload) => {
        onMessage(payload.new)
      }
    )
    .subscribe()

  return channel
}

export function unsubscribeFromChat(channel: RealtimeChannel) {
  supabase.removeChannel(channel)
}
```

---

## Step 7: Set Up Push Notifications (Firebase Cloud Messaging)

### 7.1 Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or use existing project
3. Navigate to Project Settings → Service Accounts
4. Click "Generate new private key" to download JSON file

### 7.2 Configure Firebase Admin SDK

Create `src/lib/services/firebase.ts`:

```typescript
import { initializeApp, cert, getApps } from 'firebase-admin/app'
import { getMessaging } from 'firebase-admin/messaging'
import {
  FIREBASE_PROJECT_ID,
  FIREBASE_PRIVATE_KEY,
  FIREBASE_CLIENT_EMAIL
} from '$env/static/private'

// Initialize Firebase Admin (singleton)
if (getApps().length === 0) {
  initializeApp({
    credential: cert({
      projectId: FIREBASE_PROJECT_ID,
      privateKey: FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
      clientEmail: FIREBASE_CLIENT_EMAIL
    })
  })
}

export async function sendPushNotification({
  token,
  title,
  body,
  imageUrl,
  data,
  link
}: {
  token: string
  title: string
  body: string
  imageUrl?: string
  data?: Record<string, string>
  link?: string
}) {
  try {
    await getMessaging().send({
      token,
      notification: {
        title,
        body,
        imageUrl
      },
      data,
      webpush: link ? {
        fcmOptions: { link }
      } : undefined
    })
  } catch (error) {
    console.error('Failed to send push notification:', error)
  }
}
```

### 7.3 Set Up Web Push (Client-Side)

Create `src/lib/services/push.ts`:

```typescript
import { initializeApp } from 'firebase/app'
import { getMessaging, getToken, onMessage } from 'firebase/messaging'
import { PUBLIC_FIREBASE_VAPID_KEY } from '$env/static/public'

const firebaseConfig = {
  // Your Firebase config from console
  apiKey: "...",
  authDomain: "...",
  projectId: "...",
  messagingSenderId: "...",
  appId: "..."
}

const app = initializeApp(firebaseConfig)
const messaging = getMessaging(app)

export async function requestNotificationPermission(customerId: string) {
  try {
    const permission = await Notification.requestPermission()

    if (permission === 'granted') {
      const registration = await navigator.serviceWorker.register('/firebase-messaging-sw.js')

      const token = await getToken(messaging, {
        vapidKey: PUBLIC_FIREBASE_VAPID_KEY,
        serviceWorkerRegistration: registration
      })

      // Save token to customer profile
      await fetch('/api/customers/device-token', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ customerId, token })
      })

      return token
    }
  } catch (error) {
    console.error('Failed to get notification permission:', error)
  }
}

// Listen for foreground messages
export function onForegroundMessage(callback: (payload: any) => void) {
  onMessage(messaging, callback)
}
```

### 7.4 Create Service Worker

Create `static/firebase-messaging-sw.js`:

```javascript
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js')
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js')

firebase.initializeApp({
  apiKey: "...",
  authDomain: "...",
  projectId: "...",
  messagingSenderId: "...",
  appId: "..."
})

const messaging = firebase.messaging()

// Handle background messages
messaging.onBackgroundMessage((payload) => {
  const notificationTitle = payload.notification.title
  const notificationOptions = {
    body: payload.notification.body,
    icon: payload.notification.image || '/icon-192x192.png',
    data: payload.data
  }

  self.registration.showNotification(notificationTitle, notificationOptions)
})

// Handle notification click
self.addEventListener('notificationclick', (event) => {
  event.notification.close()

  const urlToOpen = event.notification.data?.clickAction || '/'

  event.waitUntil(
    clients.openWindow(urlToOpen)
  )
})
```

### 7.5 Plan-Based Gating

Only send push notifications to Growth and Business plan tenants:

```typescript
// In order confirmation API route
if (tenant.plan !== 'free' && customer.deviceToken) {
  await sendPushNotification({
    token: customer.deviceToken,
    title: 'Order Confirmed!',
    body: `Order #${orderNumber} confirmed! Total: ₦${total}`,
    imageUrl: branch.logoUrl,
    data: {
      orderId: order.id,
      orderNumber: order.orderNumber
    },
    link: `/orders/${order.id}`
  })
}
```

---

## Step 8: Configure Progressive Web App (PWA)

### 8.1 Update svelte.config.js

Add PWA plugin to your SvelteKit configuration:

```javascript
import adapter from '@sveltejs/adapter-auto';
import { vitePreprocess } from '@sveltejs/vite-plugin-svelte';
import { SvelteKitPWA } from '@vite-pwa/sveltekit';

/** @type {import('@sveltejs/kit').Config} */
const config = {
  preprocess: vitePreprocess(),

  kit: {
    adapter: adapter()
  },

  // Add Vite config for PWA
  vite: {
    plugins: [
      SvelteKitPWA({
        srcDir: './src',
        mode: 'production',
        scope: '/',
        base: '/',
        // Manifest will be dynamically generated per tenant
        manifest: false, // Disable static manifest
        registerType: 'autoUpdate',
        injectManifest: {
          globPatterns: ['client/**/*.{js,css,ico,png,svg,webp,woff,woff2}']
        },
        workbox: {
          globPatterns: ['client/**/*.{js,css,ico,png,svg,webp,woff,woff2}'],
          runtimeCaching: [
            {
              urlPattern: /^https:\/\/.*\.supabase\.co\/storage\/.*/i,
              handler: 'CacheFirst',
              options: {
                cacheName: 'product-images-cache',
                expiration: {
                  maxEntries: 200,
                  maxAgeSeconds: 60 * 60 * 24 * 30 // 30 days
                },
                cacheableResponse: {
                  statuses: [0, 200]
                }
              }
            },
            {
              urlPattern: /^https:\/\/.*\.supabase\.co\/rest\/.*/i,
              handler: 'NetworkFirst',
              options: {
                cacheName: 'api-cache',
                networkTimeoutSeconds: 10,
                expiration: {
                  maxEntries: 50,
                  maxAgeSeconds: 60 * 5 // 5 minutes
                }
              }
            }
          ]
        },
        devOptions: {
          enabled: false, // Disable in development
          type: 'module',
          navigateFallback: '/'
        }
      })
    ]
  }
};

export default config;
```

### 8.2 Dynamic PWA Icons (Using Tenant Logo or Initials)

Since this is a multi-tenant system, PWA icons should use the tenant's branding. We'll generate icons dynamically:

**Option 1: Use Tenant Logo** (if available)
```typescript
// src/lib/services/pwa-icon.ts
import sharp from 'sharp';

export async function generatePWAIcon(
  logoUrl: string,
  size: number,
  backgroundColor: string = '#ffffff'
): Promise<Buffer> {
  const response = await fetch(logoUrl);
  const buffer = await response.arrayBuffer();

  return sharp(Buffer.from(buffer))
    .resize(size, size, { fit: 'contain', background: backgroundColor })
    .png()
    .toBuffer();
}
```

**Option 2: Generate from Business Name** (fallback)
```typescript
// src/lib/services/pwa-icon.ts
export async function generateInitialIcon(
  businessName: string,
  brandColor: string,
  size: number
): Promise<string> {
  const initial = businessName.charAt(0).toUpperCase();

  // Generate SVG
  const svg = `
    <svg width="${size}" height="${size}" xmlns="http://www.w3.org/2000/svg">
      <rect width="${size}" height="${size}" fill="${brandColor}"/>
      <text
        x="50%"
        y="50%"
        dominant-baseline="middle"
        text-anchor="middle"
        font-family="Arial, sans-serif"
        font-size="${size * 0.5}"
        font-weight="bold"
        fill="#ffffff"
      >${initial}</text>
    </svg>
  `;

  // Convert SVG to PNG using sharp
  return sharp(Buffer.from(svg))
    .png()
    .toBuffer()
    .then(buffer => `data:image/png;base64,${buffer.toString('base64')}`);
}
```

**Dynamic Icon Route** (`src/routes/api/pwa-icon/[size]/+server.ts`):
```typescript
import { json } from '@sveltejs/kit';
import { generatePWAIcon, generateInitialIcon } from '$lib/services/pwa-icon';
import { getTenantBranding } from '$lib/services/tenant';

export async function GET({ params, url }) {
  const size = parseInt(params.size);
  const branchId = url.searchParams.get('branch_id');

  if (!branchId) {
    return new Response('Missing branch_id', { status: 400 });
  }

  try {
    const branding = await getTenantBranding(branchId);

    let iconBuffer: Buffer;

    // Use logo if available, otherwise generate from initial
    if (branding.logoUrl) {
      iconBuffer = await generatePWAIcon(
        branding.logoUrl,
        size,
        branding.backgroundColor || '#ffffff'
      );
    } else {
      const iconDataUrl = await generateInitialIcon(
        branding.businessName,
        branding.brandColor || '#0ea5e9',
        size
      );
      iconBuffer = Buffer.from(iconDataUrl.split(',')[1], 'base64');
    }

    return new Response(iconBuffer, {
      headers: {
        'Content-Type': 'image/png',
        'Cache-Control': 'public, max-age=86400' // Cache for 1 day
      }
    });
  } catch (error) {
    console.error('Error generating PWA icon:', error);
    return new Response('Error generating icon', { status: 500 });
  }
}
```

**Install Sharp** for image processing:
```bash
npm install sharp
```

### 8.3 Dynamic Web App Manifest

Create a dynamic manifest route (`src/routes/manifest.webmanifest/+server.ts`):

```typescript
import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { getTenantBranding } from '$lib/services/tenant';

export const GET: RequestHandler = async ({ url }) => {
  const branchId = url.searchParams.get('branch_id');

  if (!branchId) {
    return new Response('Missing branch_id', { status: 400 });
  }

  try {
    const branding = await getTenantBranding(branchId);

    const manifest = {
      name: `${branding.businessName} Store`,
      short_name: branding.businessName,
      description: `Shop products from ${branding.businessName}`,
      start_url: `/?branch_id=${branchId}`,
      scope: '/',
      display: 'standalone',
      orientation: 'portrait-primary',
      theme_color: branding.brandColor || '#0ea5e9',
      background_color: branding.backgroundColor || '#ffffff',
      icons: [
        {
          src: `/api/pwa-icon/192?branch_id=${branchId}`,
          sizes: '192x192',
          type: 'image/png',
          purpose: 'any maskable'
        },
        {
          src: `/api/pwa-icon/512?branch_id=${branchId}`,
          sizes: '512x512',
          type: 'image/png',
          purpose: 'any maskable'
        }
      ],
      categories: ['shopping', 'ecommerce'],
      prefer_related_applications: false
    };

    return new Response(JSON.stringify(manifest), {
      headers: {
        'Content-Type': 'application/json',
        'Cache-Control': 'public, max-age=3600' // Cache for 1 hour
      }
    });
  } catch (error) {
    console.error('Error generating manifest:', error);
    return new Response('Error generating manifest', { status: 500 });
  }
};
```

### 8.4 Create Service Worker

Create `src/service-worker.ts`:

```typescript
/// <reference types="@sveltejs/kit" />
/// <reference no-default-lib="true"/>
/// <reference lib="esnext" />
/// <reference lib="webworker" />

import { build, files, version } from '$service-worker';

const sw = self as unknown as ServiceWorkerGlobalScope & typeof globalThis;

const CACHE_NAME = `cache-${version}`;
const STATIC_CACHE = `static-${version}`;

// Files to precache
const ASSETS = [...build, ...files];

// Install event - precache static assets
sw.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(STATIC_CACHE).then((cache) => cache.addAll(ASSETS))
  );
  sw.skipWaiting();
});

// Activate event - clean up old caches
sw.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then(async (keys) => {
      for (const key of keys) {
        if (key !== CACHE_NAME && key !== STATIC_CACHE) {
          await caches.delete(key);
        }
      }
      sw.clients.claim();
    })
  );
});

// Fetch event - serve from cache, fallback to network
sw.addEventListener('fetch', (event) => {
  const { request } = event;

  // Ignore non-GET requests
  if (request.method !== 'GET') return;

  // API requests - network first
  if (request.url.includes('/api/')) {
    event.respondWith(
      fetch(request)
        .then((response) => {
          const clone = response.clone();
          caches.open(CACHE_NAME).then((cache) => cache.put(request, clone));
          return response;
        })
        .catch(() => caches.match(request).then((r) => r || fetch(request)))
    );
    return;
  }

  // Static assets - cache first
  event.respondWith(
    caches.match(request).then((cached) => {
      if (cached) return cached;

      return fetch(request).then((response) => {
        const clone = response.clone();
        caches.open(CACHE_NAME).then((cache) => cache.put(request, clone));
        return response;
      });
    })
  );
});

// Push notification handler (for FCM)
sw.addEventListener('push', (event) => {
  if (!event.data) return;

  const data = event.data.json();
  const options = {
    body: data.body || 'New notification',
    icon: data.icon || '/icon-192x192.png',
    badge: '/badge-72x72.png',
    data: data.data || {}
  };

  event.waitUntil(sw.registration.showNotification(data.title || 'Notification', options));
});

// Notification click handler
sw.addEventListener('notificationclick', (event) => {
  event.notification.close();

  const urlToOpen = event.notification.data?.url || '/';

  event.waitUntil(
    sw.clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clientList) => {
      // Check if window is already open
      for (const client of clientList) {
        if (client.url === urlToOpen && 'focus' in client) {
          return client.focus();
        }
      }
      // Open new window
      if (sw.clients.openWindow) {
        return sw.clients.openWindow(urlToOpen);
      }
    })
  );
});
```

### 8.4 Create Offline Fallback Page

Create `src/routes/offline/+page.svelte`:

```svelte
<script lang="ts">
  import { onMount } from 'svelte';
  import { browser } from '$app/environment';

  let isOnline = false;

  onMount(() => {
    isOnline = navigator.onLine;

    const handleOnline = () => {
      isOnline = true;
      // Auto-reload when back online
      setTimeout(() => {
        window.location.reload();
      }, 1000);
    };

    const handleOffline = () => {
      isOnline = false;
    };

    window.addEventListener('online', handleOnline);
    window.addEventListener('offline', handleOffline);

    return () => {
      window.removeEventListener('online', handleOnline);
      window.removeEventListener('offline', handleOffline);
    };
  });
</script>

<svelte:head>
  <title>Offline - YourBrand Store</title>
  <meta name="robots" content="noindex, nofollow" />
</svelte:head>

<div class="flex flex-col items-center justify-center min-h-screen p-6 bg-gray-50">
  <div class="max-w-md w-full bg-white rounded-lg shadow-lg p-8 text-center">
    <!-- Offline Icon -->
    <svg
      class="w-24 h-24 mx-auto mb-6 text-gray-400"
      fill="none"
      stroke="currentColor"
      viewBox="0 0 24 24"
    >
      <path
        stroke-linecap="round"
        stroke-linejoin="round"
        stroke-width="2"
        d="M18.364 5.636a9 9 0 010 12.728m0 0l-2.829-2.829m2.829 2.829L21 21M15.536 8.464a5 5 0 010 7.072m0 0l-2.829-2.829m-4.243 2.829a4.978 4.978 0 01-1.414-2.83m-1.414 5.658a9 9 0 01-2.167-9.238m7.824 2.167a1 1 0 111.414 1.414m-1.414-1.414L3 3m8.293 8.293l1.414 1.414"
      />
    </svg>

    {#if isOnline}
      <h1 class="text-2xl font-bold mb-3 text-green-600">Back Online!</h1>
      <p class="text-gray-600 mb-6">Reconnecting...</p>
    {:else}
      <h1 class="text-2xl font-bold mb-3 text-gray-800">You're Offline</h1>
      <p class="text-gray-600 mb-6">
        Please check your internet connection. We'll reconnect automatically when you're back
        online.
      </p>

      <button
        on:click={() => window.location.reload()}
        class="w-full px-6 py-3 bg-primary-500 hover:bg-primary-600 text-white font-medium rounded-lg transition-colors"
      >
        Try Again
      </button>

      <p class="mt-4 text-sm text-gray-500">
        Some features may still work while offline thanks to caching.
      </p>
    {/if}
  </div>
</div>
```

### 8.5 Add PWA Install Prompt Component

Create `src/lib/components/PWAInstallPrompt.svelte`:

```svelte
<script lang="ts">
  import { onMount } from 'svelte';
  import { browser } from '$app/environment';

  let deferredPrompt: any = null;
  let showPrompt = false;
  let isInstalled = false;

  onMount(() => {
    if (!browser) return;

    // Check if already installed
    if (window.matchMedia('(display-mode: standalone)').matches) {
      isInstalled = true;
      return;
    }

    // Listen for install prompt
    window.addEventListener('beforeinstallprompt', (e) => {
      e.preventDefault();
      deferredPrompt = e;

      // Don't show prompt immediately - wait for user engagement
      setTimeout(() => {
        showPrompt = true;
      }, 30000); // Show after 30 seconds
    });

    // Listen for successful install
    window.addEventListener('appinstalled', () => {
      isInstalled = true;
      showPrompt = false;
      deferredPrompt = null;
    });
  });

  async function installPWA() {
    if (!deferredPrompt) return;

    deferredPrompt.prompt();
    const { outcome } = await deferredPrompt.userChoice;

    if (outcome === 'accepted') {
      console.log('PWA installed');
    }

    deferredPrompt = null;
    showPrompt = false;
  }

  function dismissPrompt() {
    showPrompt = false;
    // Set cookie to not show again for 7 days
    document.cookie = 'pwa-prompt-dismissed=true; max-age=604800; path=/';
  }
</script>

{#if showPrompt && !isInstalled}
  <div
    class="fixed bottom-4 left-4 right-4 md:left-auto md:right-4 md:max-w-sm bg-white shadow-2xl rounded-xl p-4 z-50 border border-gray-200 animate-slide-up"
  >
    <button
      on:click={dismissPrompt}
      class="absolute top-2 right-2 text-gray-400 hover:text-gray-600"
      aria-label="Dismiss"
    >
      <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
      </svg>
    </button>

    <div class="flex items-start gap-3">
      <img src="/icon-192x192.png" alt="App Icon" class="w-12 h-12 rounded-lg" />

      <div class="flex-1">
        <h3 class="font-semibold text-gray-900 mb-1">Install Our App</h3>
        <p class="text-sm text-gray-600 mb-3">
          Add to your home screen for quick access and a better experience!
        </p>

        <div class="flex gap-2">
          <button
            on:click={installPWA}
            class="flex-1 px-4 py-2 bg-primary-500 hover:bg-primary-600 text-white font-medium rounded-lg transition-colors text-sm"
          >
            Install Now
          </button>
          <button
            on:click={dismissPrompt}
            class="px-4 py-2 border border-gray-300 hover:bg-gray-50 rounded-lg transition-colors text-sm"
          >
            Later
          </button>
        </div>
      </div>
    </div>
  </div>
{/if}

<style>
  @keyframes slide-up {
    from {
      transform: translateY(100%);
      opacity: 0;
    }
    to {
      transform: translateY(0);
      opacity: 1;
    }
  }

  .animate-slide-up {
    animation: slide-up 0.3s ease-out;
  }
</style>
```

### 8.6 Add Component to Layout

Include the PWA install prompt in your root layout:

```svelte
<!-- src/routes/+layout.svelte -->
<script>
  import PWAInstallPrompt from '$lib/components/PWAInstallPrompt.svelte';
  import '../app.css';
</script>

<slot />

<PWAInstallPrompt />
```

### 8.7 Update Root Layout for Dynamic Manifest

Update `src/routes/+layout.svelte` to inject dynamic manifest link:

```svelte
<script lang="ts">
  import { page } from '$app/stores';
  import { onMount } from 'svelte';
  import PWAInstallPrompt from '$lib/components/PWAInstallPrompt.svelte';
  import '../app.css';

  $: branchId = $page.url.searchParams.get('branch_id');

  onMount(() => {
    // Dynamically update manifest link when branch_id changes
    if (branchId) {
      updateManifestLink(branchId);
    }
  });

  function updateManifestLink(branchId: string) {
    // Remove existing manifest link
    const existingLink = document.querySelector('link[rel="manifest"]');
    if (existingLink) {
      existingLink.remove();
    }

    // Add new manifest link with branch_id
    const manifestLink = document.createElement('link');
    manifestLink.rel = 'manifest';
    manifestLink.href = `/manifest.webmanifest?branch_id=${branchId}`;
    document.head.appendChild(manifestLink);
  }
</script>

<svelte:head>
  {#if branchId}
    <link rel="manifest" href="/manifest.webmanifest?branch_id={branchId}" />
  {/if}
</svelte:head>

<slot />

<PWAInstallPrompt />
```

### 8.8 Update app.html Base Template

Update `src/app.html` with fallback PWA meta tags:

```html
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <link rel="icon" href="%sveltekit.assets%/favicon.ico" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />

    <!-- PWA Meta Tags (defaults) -->
    <meta name="theme-color" content="#0ea5e9" />
    <meta name="mobile-web-app-capable" content="yes" />
    <meta name="apple-mobile-web-app-capable" content="yes" />
    <meta name="apple-mobile-web-app-status-bar-style" content="default" />
    <meta name="apple-mobile-web-app-title" content="Store" />

    %sveltekit.head%
  </head>
  <body data-sveltekit-preload-data="hover">
    <div style="display: contents">%sveltekit.body%</div>
  </body>
</html>
```

**Note**: The manifest link and Apple touch icons will be dynamically injected based on the branch_id parameter, ensuring each tenant gets their own branding.

---

## Step 9: Development Workflow

### 8.1 Start Development Server

```bash
# From apps/storefront/
npm run dev

# Server starts at http://localhost:5173
```

### 8.2 Run Tests

```bash
# Unit tests (Vitest)
npm run test:unit

# E2E tests (Playwright)
npm run test:e2e

# Type checking
npm run check
```

### 8.3 Linting & Formatting

```bash
# ESLint
npm run lint

# Prettier
npm run format
```

---

## Step 9: Testing the Integration

### 9.1 Test Product Listing

1. Navigate to `http://localhost:5173?branch_id={uuid}`
2. Verify products load from `storefront_products` table
3. Test search and filtering

### 9.2 Test Cart Functionality

1. Add items to cart (should be per-branch)
2. Verify cart persists in `shopping_carts` table
3. Test quantity updates and item removal

### 9.3 Test Checkout Flow

1. Proceed to checkout from cart
2. Fill delivery information
3. Verify order created with `payment_status='pending'`
4. Test Paystack redirect (use test card: 4084084084084081)
5. Verify webhook updates order to `payment_status='paid'`

### 9.4 Test Live Chat

1. Open product detail page
2. Click "Chat with us" button
3. Send test message
4. Verify message appears in `chat_messages` table
5. Test file uploads (image, PDF, voice note)
6. Verify Realtime updates in browser

### 9.5 Test Plan-Based Features

**Free Plan**:
- Verify only owner can respond to chats (`agent_type='owner'`)
- No AI agent available

**Growth Plan** (N7,500/month):
- Verify single branch access
- Verify 1 live agent assignment
- No AI agent

**Business Plan** (N30,000/month):
- Verify multi-branch filtering on product list
- Verify AI agent responds to chat messages
- Test AI image recognition (share product image in chat)

### 9.6 Test PWA Functionality

**PWA Installation**:
1. Open storefront in Chrome/Edge (with `?branch_id={uuid}`)
2. Visit 2-3 times to trigger install prompt
3. Click install prompt or use browser's "Install App" option
4. Verify app installs with tenant's logo or first letter icon
5. Verify app name matches tenant business name

**Offline Support**:
1. Install PWA on device
2. Open DevTools → Application → Service Workers
3. Check "Offline" mode
4. Navigate to different pages
5. Verify cached pages load correctly
6. Verify offline fallback page displays when hitting un-cached routes

**Manifest & Icons**:
1. Visit `/manifest.webmanifest?branch_id={uuid}`
2. Verify manifest includes correct business name, theme color, icons
3. Visit `/api/pwa-icon/192?branch_id={uuid}` and `/api/pwa-icon/512?branch_id={uuid}`
4. Verify icons display tenant logo or generated initial

**Lighthouse PWA Audit**:
1. Open Chrome DevTools → Lighthouse
2. Run PWA audit
3. Verify score above 90
4. Check for "Installable" badge
5. Verify "Add to Home Screen" works on mobile

**Multi-Tenant Testing**:
1. Install PWA for Branch A
2. Switch to Branch B URL (different `branch_id`)
3. Verify manifest updates with Branch B branding
4. Install as separate PWA
5. Confirm both PWAs coexist with different icons/names

---

## Step 10: Deployment Checklist

### 10.1 Environment Setup

- [ ] Production Supabase project created
- [ ] All migrations applied to production database
- [ ] RLS policies tested with multiple tenants
- [ ] Storage buckets configured with correct permissions
- [ ] Paystack live keys added (not test keys)
- [ ] OAuth providers configured with production redirect URLs
- [ ] OpenAI API key with billing enabled

### 10.2 Build & Deploy

```bash
# Build production bundle
npm run build

# Preview production build locally
npm run preview

# Deploy to hosting platform (Vercel, Netlify, etc.)
# Ensure environment variables are set in platform dashboard
```

### 10.3 Post-Deployment Verification

- [ ] Test product listing on production URL
- [ ] Verify cart functionality across different branches
- [ ] Complete test checkout with Paystack test card
- [ ] Test live chat with real-time message delivery
- [ ] Verify AI agent responds (Business plan tenants only)
- [ ] Test email/push notifications (Growth & Business plans only)
- [ ] Verify webhook endpoint receives Paystack callbacks
- [ ] Check analytics dashboard for order metrics
- [ ] Test PWA installation on mobile devices (Android & iOS)
- [ ] Verify dynamic manifest generates with correct tenant branding
- [ ] Run Lighthouse PWA audit (target score > 90)
- [ ] Test offline functionality with service worker
- [ ] Verify PWA icons use tenant logo or generated initial
- [ ] Test multiple tenants can install separate PWAs

---

## Common Issues & Solutions

### Issue: PWA icon shows default icon instead of tenant logo

**Solution**: Check that `tenant_branding` table has correct `logo_url` for the branch:

```sql
SELECT * FROM tenant_branding WHERE branch_id = 'your-branch-uuid';
```

If `logo_url` is NULL, the system will generate an icon from the first letter. To use a logo:

```sql
UPDATE tenant_branding
SET logo_url = 'https://your-supabase-url/storage/v1/object/public/logos/tenant-logo.png'
WHERE branch_id = 'your-branch-uuid';
```

### Issue: PWA install prompt doesn't show

**Solution**: PWA install criteria must be met:
1. Must be served over HTTPS (or localhost)
2. Must have valid manifest with name, icons, start_url
3. Must have registered service worker
4. User must visit site at least 2-3 times
5. User must engage with page (click, scroll, etc.)

Debug with Chrome DevTools:
```
Application → Manifest → Check for errors
Application → Service Workers → Verify registration
Console → Look for "beforeinstallprompt" event
```

### Issue: Dynamic manifest not updating when switching branches

**Solution**: The manifest link is dynamically injected via the layout. Clear browser cache and ensure `branch_id` is in the URL:

```javascript
// In browser console
window.location.href = '/?branch_id=your-branch-uuid';
```

Or force manifest refresh:
```javascript
const link = document.querySelector('link[rel="manifest"]');
if (link) {
  link.href = `/manifest.webmanifest?branch_id=your-branch-uuid&t=${Date.now()}`;
}
```

### Issue: Service worker not caching correctly

### Issue: Supabase Realtime not connecting

**Solution**: Check that your Supabase project has Realtime enabled and verify the Realtime API key is correct.

```typescript
// Add logging to debug
channel.on('system', {}, (payload) => {
  console.log('Realtime status:', payload)
})
```

### Issue: Paystack webhook signature verification fails

**Solution**: Ensure you're using the raw request body (not parsed JSON):

```typescript
// In webhook endpoint
export async function POST({ request }) {
  const rawBody = await request.text()  // Use text(), not json()
  const signature = request.headers.get('x-paystack-signature')

  if (!verifyPaystackSignature(signature, rawBody)) {
    return new Response('Invalid signature', { status: 400 })
  }

  const payload = JSON.parse(rawBody)
  // Process webhook...
}
```

### Issue: RLS policies blocking legitimate queries

**Solution**: Set session variables for guest users:

```typescript
// For guest carts
await supabase.rpc('set_config', {
  setting: 'app.session_id',
  value: sessionId
})
```

### Issue: AI agent not recognizing products from images

**Solution**: Verify OpenAI API key and use GPT-4 Vision model:

```typescript
import OpenAI from 'openai'

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY
})

const response = await openai.chat.completions.create({
  model: 'gpt-4-vision-preview',  // Not gpt-4-turbo
  messages: [
    {
      role: 'user',
      content: [
        { type: 'text', text: 'What product is in this image?' },
        { type: 'image_url', image_url: { url: imageUrl } }
      ]
    }
  ]
})
```

---

## Next Steps

After completing this quickstart:

1. **Read API Contracts**: Review `contracts/*.yaml` for complete API specifications
2. **Implement UI Components**: Build Svelte components for product list, cart, checkout, chat
3. **Add Delivery Fee Calculator**: Implement plugin architecture for delivery providers
4. **Set Up Monitoring**: Add error tracking (Sentry) and analytics (PostHog)
5. **Performance Optimization**: Add caching layer (Redis) for product catalog
6. **Run Tasks**: Execute `/speckit.tasks` to generate implementation tasks

---

## Resources

- **SvelteKit Documentation**: https://kit.svelte.dev/docs
- **Supabase Realtime**: https://supabase.com/docs/guides/realtime
- **Paystack API Reference**: https://paystack.com/docs/api/
- **OpenAI API (GPT-4 Vision)**: https://platform.openai.com/docs/guides/vision
- **Tailwind CSS**: https://tailwindcss.com/docs

---

**Quickstart Complete** | **Next**: Run agent context update script
