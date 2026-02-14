# Research & Technical Decisions: Ecommerce Storefront

**Feature**: 002-ecommerce-storefront
**Date**: 2026-02-11
**Status**: Phase 0 Complete

## Overview

This document captures all technical research and decisions for the ecommerce storefront implementation. Each decision includes rationale and alternatives considered.

---

## 1. Storefront Architecture Integration

### Decision
**Separate SvelteKit Application on Subdomain**

Deploy storefront as standalone SvelteKit app accessible via tenant subdomains (e.g., `store.branch-name.tenant.com` or `branch-name.store.example.com`).

### Rationale
- **Clean Separation**: Independent codebase, deployment, and scaling for customer-facing storefront vs admin/POS systems
- **Framework Optimization**: Leverage SvelteKit's SSR, routing, and performance characteristics without Next.js constraints
- **Performance Isolation**: Storefront traffic spikes don't affect admin/POS performance
- **Independent Versioning**: Can update storefront without touching admin systems
- **Better SEO**: Proper SSR for product pages improves search engine indexing

### Alternatives Considered

**Option B: Embedded Iframe in Next.js**
- **Pros**: Single deployment, easier navigation between admin and storefront
- **Cons**: Complex authentication sharing, iframe limitations (full-page scrolling, mobile issues), SEO challenges
- **Rejected**: Poor user experience, SEO limitations, complexity of cross-frame communication

**Option C: Build in Next.js, Migrate to SvelteKit Later**
- **Pros**: Simpler initial setup, familiar stack
- **Cons**: Migration cost later, misses SvelteKit benefits immediately, user explicitly requested SvelteKit
- **Rejected**: Delays desired architecture, creates technical debt

### Implementation Notes
- Use Supabase JWT tokens for authentication across domains (shared session)
- Configure CORS for API endpoints accessed from storefront subdomain
- Shared Supabase database with RLS policies for multi-tenancy
- Separate Vercel/hosting deployment for storefront app

---

## 2. Real-Time Chat Communication

### Decision
**Server-Sent Events (SSE) + REST API with Supabase Realtime**

Use Supabase Realtime (PostgreSQL subscriptions) for live chat messages with REST API for message sending and SSE for receiving updates.

### Rationale
- **Native Integration**: Supabase Realtime built into existing infrastructure (no new service)
- **Simpler Than WebSockets**: SSE provides unidirectional real-time updates (server → client) which covers 90% of chat needs
- **REST for Actions**: Message sending, file uploads via standard REST endpoints
- **Scalability**: Supabase handles connection pooling and scaling
- **Fallback**: Automatic fallback to polling if SSE unavailable
- **Lower Complexity**: No separate WebSocket server to manage

### Alternatives Considered

**Option A: WebSocket with Socket.io**
- **Pros**: Full bidirectional communication, mature library, wide browser support
- **Cons**: Requires separate WebSocket server, connection management complexity, load balancing challenges
- **Rejected**: Over-engineered for chat use case, adds infrastructure complexity

**Option B: Firebase Realtime Database**
- **Pros**: Excellent real-time performance, managed service
- **Cons**: Introduces new vendor dependency, separate database from main Supabase, cost
- **Rejected**: Unnecessary additional vendor, prefer unified Supabase solution

**Option C: Long Polling**
- **Pros**: Universal browser support, simple implementation
- **Cons**: Higher latency, more server load, poor user experience
- **Rejected**: Inferior user experience compared to SSE/Realtime

### Implementation Notes
```typescript
// Subscribe to chat messages
const subscription = supabase
  .channel(`chat:${sessionId}`)
  .on('postgres_changes',
    { event: 'INSERT', schema: 'public', table: 'chat_messages' },
    payload => updateChatUI(payload.new)
  )
  .subscribe()

// Send message via REST
await fetch('/api/chat/send', {
  method: 'POST',
  body: JSON.stringify({ sessionId, message, attachments })
})
```

---

## 3. AI Agent Service Provider

### Decision
**OpenAI GPT-4 Vision API**

Use OpenAI's GPT-4 with vision capabilities for Business plan AI agent with image recognition.

### Rationale
- **Image Recognition**: Native vision API can analyze product images shared by customers
- **Conversational AI**: GPT-4 provides natural language understanding for customer queries
- **Context Awareness**: Can be provided product catalog context for accurate responses
- **Proven Reliability**: Production-ready API with high uptime
- **Cost-Effective**: Pay-per-use pricing aligns with Business plan premium tier
- **Future-Proof**: OpenAI continuously improves models

### Alternatives Considered

**Option A: Anthropic Claude 3 with Vision**
- **Pros**: Excellent reasoning, longer context window, strong vision capabilities
- **Cons**: Newer API, less integration ecosystem, similar pricing
- **Rejected**: OpenAI has more established ecosystem and documentation

**Option B: Google Vertex AI (Gemini)**
- **Pros**: Multimodal by default, competitive pricing, Google Cloud integration
- **Cons**: Requires Google Cloud setup, less proven in production for ecommerce
- **Rejected**: Adds Google Cloud dependency, team less familiar

**Option C: Custom Fine-Tuned Model**
- **Pros**: Specialized for product catalog, potentially lower cost at scale
- **Cons**: High upfront cost, maintenance burden, training data requirements
- **Rejected**: Premature optimization, use managed service first

### Implementation Notes
```typescript
// AI Agent Service (Supabase Edge Function)
const response = await openai.chat.completions.create({
  model: "gpt-4-vision-preview",
  messages: [
    { role: "system", content: "You are a helpful shopping assistant..." },
    {
      role: "user",
      content: [
        { type: "text", text: customerMessage },
        { type: "image_url", image_url: { url: imageUrl } }
      ]
    }
  ],
  max_tokens: 500
})
```

**Cost Management**:
- Cache product catalog context to reduce token usage
- Rate limit AI agent calls per session
- Monitor usage per tenant (Business plan only)
- Fallback to non-AI responses if quota exceeded

---

## 4. Payment Gateway Integration (Paystack)

### Decision
**Paystack Standard Checkout (Hosted Payment Page)**

Use Paystack's hosted payment page (Popup/Redirect) with webhook verification for payment status.

### Rationale
- **PCI Compliance**: Paystack handles sensitive card data (no PCI-DSS burden on our app)
- **Local Payment Methods**: Supports Nigerian banks, USSD, bank transfer, cards
- **Proven UI**: Optimized checkout flow reduces cart abandonment
- **Mobile Optimized**: Works seamlessly on mobile devices
- **Webhook Security**: Verifies payment status server-side via webhooks
- **Simple Integration**: JavaScript SDK + REST API

### Implementation Flow
1. **Initialization**: Server generates Paystack transaction reference + access code
2. **Checkout**: Customer clicks "Pay Now" → Paystack popup/redirect
3. **Payment**: Customer completes payment on Paystack page
4. **Callback**: Paystack redirects back with transaction reference
5. **Verification**: Webhook confirms payment status server-side
6. **Order Update**: System updates order status to "paid"

### Security Considerations
- **Never trust frontend**: Always verify payment via webhook or server-side API call
- **Webhook signature**: Validate `x-paystack-signature` header to prevent spoofing
- **Idempotency**: Handle duplicate webhooks gracefully (check if order already processed)
- **Timeout**: Set payment session timeout (15 minutes)

### Alternative Considered

**Paystack Inline API (Custom Form)**
- **Pros**: Fully custom UI, more control over flow
- **Cons**: PCI compliance requirements, more implementation complexity, card data handling
- **Rejected**: Standard checkout provides better security and UX out-of-box

### Implementation Notes
```typescript
// Server: Initialize payment
const paystackInit = await fetch('https://api.paystack.co/transaction/initialize', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${process.env.PAYSTACK_SECRET_KEY}`,
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    email: customerEmail,
    amount: totalAmount * 100, // Convert to kobo
    reference: orderReference,
    callback_url: `${storefrontUrl}/checkout/callback`,
    metadata: { orderId, branchId, tenantId }
  })
})

// Client: Open Paystack popup
PaystackPop.setup({
  key: publicKey,
  email: customerEmail,
  amount: totalAmount * 100,
  ref: reference,
  onSuccess: (transaction) => {
    // Redirect to confirmation page (webhook will verify)
    window.location = `/orders/${orderId}/success`
  },
  onCancel: () => {
    // Handle payment cancellation
    alert('Payment cancelled')
  }
})
```

---

## 5. File Storage for Chat Attachments

### Decision
**Supabase Storage**

Use Supabase Storage buckets for storing chat attachments (images, voice notes, PDFs).

### Rationale
- **Integrated**: Part of existing Supabase infrastructure
- **Secure**: RLS policies control access per tenant/session
- **CDN**: Built-in CDN for fast global delivery
- **Cost-Effective**: Competitive pricing, included in Supabase plan
- **Signed URLs**: Temporary access URLs for secure file sharing
- **Image Transformations**: Built-in image resizing/optimization

### Storage Structure
```
buckets/
└── chat-attachments/
    └── {tenantId}/
        └── {chatSessionId}/
            ├── {messageId}-image.jpg      # Images (max 5MB)
            ├── {messageId}-voice.webm     # Voice notes (max 2 min)
            └── {messageId}-document.pdf   # PDFs (max 10MB)
```

### Security Implementation
- **RLS Policy**: Users can only access attachments from their own chat sessions
- **File Validation**: Server-side checks for file type, size before upload
- **Virus Scanning**: Consider adding ClamAV or similar for production
- **Expiration**: Set 90-day retention policy, delete old attachments

### Alternatives Considered

**AWS S3 + CloudFront**
- **Pros**: Industry standard, high reliability, advanced features
- **Cons**: Additional vendor, more configuration, separate authentication
- **Rejected**: Supabase Storage sufficient for requirements, prefer unified stack

**Cloudflare R2**
- **Pros**: S3-compatible, zero egress fees
- **Cons**: Separate service, more setup complexity
- **Rejected**: Supabase Storage meets needs, avoid adding vendors

---

## 6. OAuth Authentication (Google & Apple)

### Decision
**Supabase Auth with Social Providers**

Use Supabase Auth's built-in OAuth providers for Google and Apple Sign In.

### Rationale
- **Managed Service**: Supabase handles OAuth flow, token refresh, session management
- **Secure**: Industry-standard OAuth 2.0 / OpenID Connect
- **Consistent**: Same auth mechanism as existing admin/POS systems
- **Multiplatform**: Works on web, will support future mobile apps
- **Token Management**: Automatic JWT token issuance and refresh

### Setup Requirements
1. **Google OAuth**:
   - Create OAuth 2.0 credentials in Google Cloud Console
   - Configure authorized redirect URIs (Supabase callback URL)
   - Add client ID/secret to Supabase Auth settings

2. **Apple Sign In**:
   - Register App ID and Services ID in Apple Developer
   - Generate private key for Sign In with Apple
   - Configure Supabase with Apple credentials

### Implementation
```typescript
// Initiate Google Sign In
const { data, error } = await supabase.auth.signInWithOAuth({
  provider: 'google',
  options: {
    redirectTo: `${storefrontUrl}/auth/callback`,
    scopes: 'email profile'
  }
})

// Initiate Apple Sign In
const { data, error } = await supabase.auth.signInWithOAuth({
  provider: 'apple',
  options: {
    redirectTo: `${storefrontUrl}/auth/callback`
  }
})

// Handle callback
// Supabase automatically sets session cookie
// User data available via: supabase.auth.getUser()
```

### Customer Profile Management
- Link OAuth accounts to `customers` table via trigger on `auth.users`
- Store customer preferences (delivery address) in `customers` table
- Use Supabase `user_id` as foreign key for orders, chat sessions

---

## 7. Third-Party Platform Delivery API

### Decision
**Defer to Configuration / Plugin Architecture**

Design delivery system to support multiple delivery providers via configuration, start with manual configuration.

### Rationale
- **Uncertainty**: User hasn't specified preferred platform delivery provider (GIG Logistics, Kwik, SendBox, etc.)
- **Flexibility**: Different tenants may prefer different providers
- **MVP Approach**: Launch with manual platform delivery booking (tenant arranges), add API integration later
- **Plugin Architecture**: Design abstractions to add providers without refactoring

### Delivery Provider Interface
```typescript
interface DeliveryProvider {
  name: string;
  calculateFee(origin: Address, destination: Address, weight: number): Promise<number>;
  createShipment(order: Order): Promise<{ trackingNumber: string; label: string }>;
  getStatus(trackingNumber: string): Promise<DeliveryStatus>;
}

// Future implementations
class GIGLogisticsProvider implements DeliveryProvider { ... }
class KwikDeliveryProvider implements DeliveryProvider { ... }
class SendBoxProvider implements DeliveryProvider { ... }
```

### MVP Implementation (Launch)
- **Manual Process**: Order marked as "Platform Delivery", tenant manually books with provider
- **Fee Calculation**: Fixed fee structure (configurable per tenant)
- **Tracking**: Manual tracking number entry by tenant

### Phase 2 Integration Targets
1. **GIG Logistics** (Nigeria): Enterprise API, good documentation
2. **Kwik Delivery** (Lagos): Fast local delivery, API available
3. **SendBox** (National): Multi-provider aggregator

### Alternative Considered

**Immediate API Integration**
- **Pros**: Full automation from launch
- **Cons**: Requires selecting provider without tenant input, implementation time
- **Rejected**: Better to launch with manual process, gather requirements from actual usage

---

## 8. Notification Service (Email/Push)

### Decision
**Resend (Email) + Firebase Cloud Messaging (Push Notifications)**

Use Resend for transactional emails and Firebase Cloud Messaging (FCM) for push notifications.

### Rationale

**Resend (Email)**:
- **Developer-Friendly**: Modern API, excellent TypeScript SDK
- **Deliverability**: High inbox placement rates
- **Templates**: React Email for beautiful transactional templates
- **Analytics**: Built-in open/click tracking
- **Affordable**: Generous free tier, low cost per email

**Firebase Cloud Messaging (FCM - Push Notifications)**:
- **Completely Free**: No cost for any volume
- **Cross-Platform**: Works on web (PWA), Android, and iOS
- **Reliable**: Google infrastructure with high delivery rates
- **Modern Web API**: Native browser support via Service Workers
- **Plan-Based Control**: Easy to gate by subscription tier (disabled for Free plan)
- **Rich Notifications**: Supports images, actions, custom data

### Email Notifications (via Resend)
- Order confirmation
- Payment receipt
- Order status updates
- Shipping notifications

### Push Notifications (via FCM - Growth & Business Plans Only)
- Order confirmation (with order number)
- Payment received
- Order ready for pickup (Self Pickup orders)
- Delivery dispatched (with tracking)
- Chat message received (when customer not actively viewing chat)

### Implementation
```typescript
// Email via Resend
import { Resend } from 'resend';
const resend = new Resend(process.env.RESEND_API_KEY);

await resend.emails.send({
  from: 'orders@yourbrand.com',
  to: customerEmail,
  subject: `Order Confirmation #${orderNumber}`,
  react: OrderConfirmationEmail({ order })
});

// Push Notification via FCM (Growth & Business plans only)
import { getMessaging } from 'firebase-admin/messaging';

// Check plan tier before sending
if (tenant.plan !== 'free') {
  await getMessaging().send({
    token: customerDeviceToken,
    notification: {
      title: 'Order Confirmed!',
      body: `Order #${orderNumber} confirmed! Total: ₦${total}`,
      imageUrl: branchLogoUrl
    },
    data: {
      orderId: orderId,
      orderNumber: orderNumber,
      clickAction: `/orders/${orderId}`
    },
    webpush: {
      fcmOptions: {
        link: `https://store.yourbrand.com/orders/${orderId}`
      }
    }
  });
}
```

### Web Push Setup (Service Worker)
```javascript
// Register service worker for push notifications
if ('serviceWorker' in navigator && 'PushManager' in window) {
  const registration = await navigator.serviceWorker.register('/sw.js');

  const permission = await Notification.requestPermission();
  if (permission === 'granted') {
    const token = await getToken(messaging, {
      vapidKey: 'YOUR_VAPID_KEY',
      serviceWorkerRegistration: registration
    });
    // Save token to customer profile
    await saveDeviceToken(customerId, token);
  }
}
```

### Alternatives Considered

**SendGrid (Email)**
- **Pros**: Industry standard, feature-rich
- **Cons**: More expensive, complex UI, past deliverability issues
- **Rejected**: Resend provides better developer experience and pricing

**OneSignal (Push)**
- **Pros**: Easy to use, free tier available
- **Cons**: Vendor lock-in, unnecessary abstraction layer
- **Rejected**: FCM is free and directly integrated with Google services

**Pusher Beams (Push)**
- **Pros**: Developer-friendly API
- **Cons**: Paid service, limited free tier
- **Rejected**: FCM provides same features completely free

**Web Push API (Native)**
- **Pros**: No external dependencies, completely free
- **Cons**: Limited to web browsers, no mobile app support
- **Partially Adopted**: Using Web Push API with FCM for cross-platform support

---

## 9. Product Data Synchronization

### Decision
**Real-Time Sync via Supabase Realtime + Background Jobs**

Sync products from POS system to storefront database in real-time using Supabase database triggers and periodic background jobs for consistency.

### Rationale
- **Real-Time Updates**: Product availability reflects immediately on storefront
- **Performance**: Storefront queries optimized denormalized product table (no joins to POS tables)
- **Scalability**: Separate read replicas for storefront traffic if needed
- **Data Isolation**: Clear boundary between POS and storefront data

### Sync Architecture
```
POS System (Next.js) → products table (master)
                          ↓ (trigger)
                    Supabase Function (sync logic)
                          ↓
              storefront_products table (replica)
                          ↓
           SvelteKit Storefront (reads only)
```

### Implementation Strategy
1. **Trigger-Based**: PostgreSQL trigger on `products` table fires Supabase Edge Function
2. **Edge Function**: Transforms POS product data to storefront format, updates `storefront_products`
3. **Denormalization**: Include precomputed fields (category name, branch name, image URLs)
4. **Consistency Check**: Nightly job compares POS products with storefront products, fixes drift

### Alternative Considered

**Direct Database Access**
- **Pros**: Always consistent, no sync lag
- **Cons**: Tight coupling, performance impact on POS queries, complex RLS policies
- **Rejected**: Separation of concerns more important, sync lag acceptable (<1 second)

---

## 10. Testing Strategy

### Decision
**Playwright E2E + Vitest Unit + Manual Payment Testing**

Use Playwright for critical path E2E tests, Vitest for unit tests, manual testing for payment flows in sandbox.

### Test Coverage Priorities
1. **E2E (Playwright)**:
   - Guest checkout flow (product → cart → checkout → payment → confirmation)
   - Authenticated checkout flow
   - Search and filtering
   - Chat message sending
   - File upload in chat

2. **Unit Tests (Vitest)**:
   - Cart state management
   - Fee calculation (delivery + transaction fees)
   - Product filtering logic
   - Form validation

3. **Integration Tests**:
   - Paystack webhook handling
   - OAuth callback processing
   - Supabase Realtime message delivery

4. **Manual Testing**:
   - Complete payment flow in Paystack sandbox
   - Test all payment methods (card, bank transfer, USSD)
   - Mobile responsiveness
   - Accessibility with screen readers

### Test Environment Setup
```typescript
// playwright.config.ts
export default {
  use: {
    baseURL: 'http://localhost:5173',
    trace: 'on-first-retry'
  },
  projects: [
    { name: 'chromium' },
    { name: 'mobile', use: devices['iPhone 13'] }
  ]
}

// E2E test example
test('guest can complete checkout', async ({ page }) => {
  await page.goto('/');
  await page.click('text=Add to Cart');
  await page.click('text=Checkout');
  await page.fill('[name="phone"]', '08012345678');
  await page.fill('[name="address"]', '123 Test St');
  await page.selectOption('[name="delivery"]', 'self-pickup');
  // Mock Paystack for E2E (use test mode)
  await page.click('text=Pay Now');
  await expect(page).toHaveURL(/\/orders\/.*\/success/);
});
```

---

## 11. Mobile Responsiveness Strategy

### Decision
**Mobile-First Tailwind CSS with Breakpoint Utilities**

Design all components mobile-first using Tailwind CSS responsive utilities, test on real devices.

### Rationale
- **Mobile Traffic**: Expect 50%+ traffic from mobile devices (Nigerian market)
- **Performance**: Mobile-first ensures lightweight initial load
- **Tailwind**: Built-in responsive utilities (sm, md, lg, xl breakpoints)
- **Touch-Friendly**: Minimum 44px touch targets, proper spacing

### Breakpoints
- **Default (mobile)**: 320px - 640px
- **sm (tablet)**: 640px+
- **md (desktop)**: 768px+
- **lg (large desktop)**: 1024px+

### Key Mobile Optimizations
- Sticky header with cart count
- Bottom navigation for key actions
- Swipe gestures for product image gallery
- Mobile-optimized checkout (single column, large inputs)
- Collapsible filters for product search

```svelte
<!-- Example mobile-first component -->
<div class="
  grid grid-cols-1 gap-4
  sm:grid-cols-2
  md:grid-cols-3
  lg:grid-cols-4
">
  {#each products as product}
    <ProductCard {product} />
  {/each}
</div>
```

---

## 12. Progressive Web App (PWA)

### Decision
**SvelteKit PWA with @vite-pwa/sveltekit**

Implement Progressive Web App functionality using Vite PWA plugin for SvelteKit with Service Worker and Web App Manifest.

### Rationale

**PWA Benefits**:
- **App-Like Experience**: Full-screen mode without browser chrome on mobile
- **Home Screen Installation**: One-tap access from device home screen
- **Offline Support**: Graceful fallback when network unavailable
- **Performance**: Service Worker caching dramatically improves repeat visit speed
- **Push Notifications**: Required for FCM web push (already implemented)
- **SEO Friendly**: Still crawlable by search engines (unlike native apps)
- **No App Store**: Bypass app store submission and fees

**@vite-pwa/sveltekit**:
- **Zero Config**: Auto-generates manifest and service worker
- **SvelteKit Integration**: First-class support for SvelteKit adapter
- **Workbox**: Google's battle-tested service worker library
- **Automatic Updates**: Handles SW lifecycle and updates
- **TypeScript**: Full type safety
- **Development Mode**: SW disabled in dev, enabled in production

### PWA Features

#### Web App Manifest
```json
{
  "name": "YourBrand Store",
  "short_name": "Store",
  "description": "Shop products from YourBrand",
  "start_url": "/",
  "display": "standalone",
  "background_color": "#ffffff",
  "theme_color": "#0ea5e9",
  "orientation": "portrait-primary",
  "icons": [
    {
      "src": "/icon-192x192.png",
      "sizes": "192x192",
      "type": "image/png",
      "purpose": "any maskable"
    },
    {
      "src": "/icon-512x512.png",
      "sizes": "512x512",
      "type": "image/png",
      "purpose": "any maskable"
    }
  ]
}
```

#### Service Worker Caching Strategy

**Static Assets** (Cache First):
- JavaScript bundles
- CSS stylesheets
- Fonts
- Product images

**API Requests** (Network First):
- Product catalog
- Cart data
- Orders
- Chat messages

**Offline Fallback**:
- Custom offline page when network unavailable
- Cached product listings for browsing
- Queue failed cart/order mutations for retry

### Implementation

#### Install Plugin
```bash
npm install -D @vite-pwa/sveltekit workbox-window
```

#### Configure svelte.config.js
```javascript
import { sveltekit } from '@sveltejs/kit/vite';
import { SvelteKitPWA } from '@vite-pwa/sveltekit';

/** @type {import('vite').UserConfig} */
const config = {
  plugins: [
    sveltekit(),
    SvelteKitPWA({
      srcDir: 'src',
      mode: 'production',
      strategies: 'injectManifest', // Custom SW
      filename: 'sw.ts',
      manifest: {
        name: 'YourBrand Store',
        short_name: 'Store',
        theme_color: '#0ea5e9',
        background_color: '#ffffff',
        display: 'standalone',
        scope: '/',
        start_url: '/',
        icons: [
          {
            src: 'icon-192x192.png',
            sizes: '192x192',
            type: 'image/png',
            purpose: 'any maskable'
          },
          {
            src: 'icon-512x512.png',
            sizes: '512x512',
            type: 'image/png',
            purpose: 'any maskable'
          }
        ]
      },
      injectManifest: {
        globPatterns: ['**/*.{js,css,html,svg,png,woff2}']
      },
      workbox: {
        globPatterns: ['**/*.{js,css,html,svg,png,woff2}'],
        runtimeCaching: [
          {
            urlPattern: /^https:\/\/.*\.supabase\.co\/storage\/.*/i,
            handler: 'CacheFirst',
            options: {
              cacheName: 'product-images',
              expiration: {
                maxEntries: 200,
                maxAgeSeconds: 60 * 60 * 24 * 30 // 30 days
              }
            }
          },
          {
            urlPattern: /^https:\/\/.*\.supabase\.co\/rest\/.*/i,
            handler: 'NetworkFirst',
            options: {
              cacheName: 'api-cache',
              networkTimeoutSeconds: 10
            }
          }
        ]
      },
      devOptions: {
        enabled: false, // Disable in dev
        type: 'module'
      }
    })
  ]
};

export default config;
```

#### Custom Service Worker (src/sw.ts)
```typescript
/// <reference lib="webworker" />
import { build, files, version } from '$service-worker';
import { precacheAndRoute } from 'workbox-precaching';
import { registerRoute } from 'workbox-routing';
import { CacheFirst, NetworkFirst } from 'workbox-strategies';

const sw = self as unknown as ServiceWorkerGlobalScope;

// Precache static assets
precacheAndRoute([
  ...build.map(f => ({ url: f, revision: version })),
  ...files.map(f => ({ url: f, revision: version }))
]);

// Cache product images
registerRoute(
  /^https:\/\/.*\.supabase\.co\/storage\/.*/i,
  new CacheFirst({
    cacheName: 'product-images',
    plugins: [
      {
        cacheWillUpdate: async ({ response }) => {
          return response.status === 200 ? response : null;
        }
      }
    ]
  })
);

// Network first for API calls
registerRoute(
  /^https:\/\/.*\.supabase\.co\/rest\/.*/i,
  new NetworkFirst({
    cacheName: 'api-cache',
    networkTimeoutSeconds: 10
  })
);

// Offline fallback
sw.addEventListener('fetch', (event) => {
  if (event.request.mode === 'navigate') {
    event.respondWith(
      fetch(event.request).catch(() => {
        return caches.match('/offline');
      })
    );
  }
});
```

#### Offline Fallback Page (src/routes/offline/+page.svelte)
```svelte
<script>
  import { onMount } from 'svelte';

  let isOnline = false;

  onMount(() => {
    const checkOnline = () => {
      isOnline = navigator.onLine;
      if (isOnline) {
        window.location.reload();
      }
    };

    window.addEventListener('online', checkOnline);
    return () => window.removeEventListener('online', checkOnline);
  });
</script>

<div class="flex flex-col items-center justify-center min-h-screen p-4">
  <h1 class="text-2xl font-bold mb-4">You're Offline</h1>
  <p class="text-gray-600 mb-6">
    Check your internet connection and we'll reconnect automatically.
  </p>
  <button
    on:click={() => window.location.reload()}
    class="px-6 py-2 bg-primary-500 text-white rounded-lg"
  >
    Try Again
  </button>
</div>
```

### Install Prompt

Users can install PWA after visiting 2-3 times. Customize prompt:

```svelte
<!-- src/lib/components/PWAInstallPrompt.svelte -->
<script lang="ts">
  import { onMount } from 'svelte';

  let deferredPrompt: any = null;
  let showPrompt = false;

  onMount(() => {
    window.addEventListener('beforeinstallprompt', (e) => {
      e.preventDefault();
      deferredPrompt = e;
      showPrompt = true;
    });
  });

  async function installPWA() {
    if (!deferredPrompt) return;

    deferredPrompt.prompt();
    const { outcome } = await deferredPrompt.userChoice;

    if (outcome === 'accepted') {
      showPrompt = false;
    }

    deferredPrompt = null;
  }
</script>

{#if showPrompt}
  <div class="fixed bottom-4 left-4 right-4 bg-white shadow-lg rounded-lg p-4 z-50">
    <h3 class="font-semibold mb-2">Install App</h3>
    <p class="text-sm text-gray-600 mb-4">
      Add to your home screen for quick access
    </p>
    <div class="flex gap-2">
      <button
        on:click={installPWA}
        class="flex-1 px-4 py-2 bg-primary-500 text-white rounded-lg"
      >
        Install
      </button>
      <button
        on:click={() => showPrompt = false}
        class="px-4 py-2 border border-gray-300 rounded-lg"
      >
        Later
      </button>
    </div>
  </div>
{/if}
```

### Alternatives Considered

**Vite Plugin PWA (Generic)**
- **Pros**: Framework-agnostic, well-documented
- **Cons**: Requires manual SvelteKit adapter configuration
- **Rejected**: @vite-pwa/sveltekit provides better SvelteKit integration

**Manual Service Worker**
- **Pros**: Full control, no dependencies
- **Cons**: Complex lifecycle management, error-prone
- **Rejected**: Workbox provides battle-tested reliability

**SvelteKit Service Worker API**
- **Pros**: Built into SvelteKit
- **Cons**: Lower-level, more boilerplate required
- **Rejected**: @vite-pwa/sveltekit provides higher-level abstraction

**Next.js PWA (for comparison)**
- **Pros**: Popular in Next.js ecosystem
- **Cons**: Not compatible with SvelteKit
- **Not Applicable**: Different framework

---

## Summary of Decisions

| Area | Decision | Status |
|------|----------|--------|
| **Architecture** | Separate SvelteKit app on subdomain | ✅ Resolved |
| **Chat Communication** | Supabase Realtime (SSE) + REST | ✅ Resolved |
| **AI Agent** | OpenAI GPT-4 Vision | ✅ Resolved |
| **Payment** | Paystack Standard Checkout | ✅ Resolved |
| **File Storage** | Supabase Storage | ✅ Resolved |
| **OAuth** | Supabase Auth (Google/Apple) | ✅ Resolved |
| **Platform Delivery** | Plugin architecture, manual MVP | ✅ Resolved |
| **Notifications** | Resend (email) + Firebase Cloud Messaging (push) | ✅ Resolved |
| **Product Sync** | Real-time triggers + background jobs | ✅ Resolved |
| **Testing** | Playwright + Vitest | ✅ Resolved |
| **Mobile** | Mobile-first Tailwind CSS | ✅ Resolved |
| **PWA** | @vite-pwa/sveltekit + Workbox | ✅ Resolved |

**All NEEDS CLARIFICATION items resolved. Ready for Phase 1: Design & Contracts.**

---

**Phase 0 Complete** | **Next**: Generate data-model.md and API contracts
