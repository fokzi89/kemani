# Flutter Migration Plan: Next.js to Flutter + SvelteKit

**Created**: 2026-02-11
**Current State**: Next.js 16 POS Application
**Target State**: Flutter (POS Mobile + Web) + SvelteKit (Marketing/Storefront)
**Flutter Version**: 3.38.9 (Dart 3.10.8)

---

## Executive Summary

This plan outlines the migration from a Next.js-based multi-tenant POS system to a hybrid architecture:
- **Flutter**: POS application (iOS, Android, Web)
- **SvelteKit**: Marketing pages, pricing, storefront (SEO-optimized)
- **Supabase**: Shared backend (no changes needed)

**Migration Strategy**: Incremental, parallel development (build Flutter app while Next.js runs in production)

**Timeline Estimate**: 3-6 months for full migration (depends on team size)

---

## Architecture Comparison

### Current Architecture (Next.js)

```
┌─────────────────────────────────────────┐
│         Next.js 16 (App Router)         │
│  ┌─────────────────────────────────┐   │
│  │  Marketing (Landing, Pricing)   │   │
│  │  Auth (Login, Register)         │   │
│  │  POS (Inventory, Sales)         │   │
│  │  Admin (Staff, Analytics)       │   │
│  │  Marketplace (Storefront)       │   │
│  └─────────────────────────────────┘   │
└─────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────┐
│       Supabase (PostgreSQL + Auth)      │
│       PowerSync (Offline Sync)          │
└─────────────────────────────────────────┘
```

### Target Architecture (Flutter + SvelteKit)

```
┌──────────────────────┐   ┌──────────────────────┐
│   SvelteKit (Web)    │   │  Flutter (Multi-Plat)│
│  ┌────────────────┐  │   │ ┌──────────────────┐ │
│  │ Landing Page   │  │   │ │ POS (Inventory)  │ │
│  │ Pricing Page   │  │   │ │ Sales            │ │
│  │ Storefront     │  │   │ │ Admin Dashboard  │ │
│  │ SEO Content    │  │   │ │ Staff Mgmt       │ │
│  └────────────────┘  │   │ │ Analytics        │ │
│                      │   │ └──────────────────┘ │
│  Deployment:         │   │                      │
│  yourdomain.com      │   │  Deployment:         │
│  shop.yourdomain.com │   │  pos.yourdomain.com  │
│                      │   │  iOS App Store       │
│                      │   │  Google Play Store   │
└──────────────────────┘   └──────────────────────┘
              ↓                      ↓
┌─────────────────────────────────────────────────┐
│       Supabase (PostgreSQL + Auth)              │
│       PowerSync (Offline Sync) - Flutter SDK    │
└─────────────────────────────────────────────────┘
```

**Benefits:**
- ✅ Single codebase for mobile + web POS
- ✅ Native mobile performance
- ✅ SEO-optimized marketing with SvelteKit
- ✅ Clear separation of concerns
- ✅ Smaller bundle sizes (Flutter for POS, SvelteKit for web)

---

## Migration Phases

### Phase 0: Preparation & Setup (Week 1)

**Goal**: Set up development environment and project structure

#### Tasks:

1. **Install Development Tools**
   - [x] Upgrade Flutter SDK to 3.38.9
   - [ ] Install VS Code + Flutter/Dart extensions
   - [ ] Install Java JDK 17 (for Android builds)
   - [ ] Verify Chrome for web testing

2. **Create Project Structure**
   ```
   /kemani
     /apps
       /pos_flutter          # New Flutter POS app
       /marketing_sveltekit  # New SvelteKit marketing site
     /supabase               # Existing backend (keep as-is)
     /packages               # Shared types/utilities (optional)
   ```

3. **Initialize Flutter Project**
   ```bash
   cd apps
   flutter create pos_flutter
   cd pos_flutter
   flutter pub add supabase_flutter powersync riverpod go_router freezed
   ```

4. **Initialize SvelteKit Project**
   ```bash
   cd apps
   npm create svelte@latest marketing_sveltekit
   cd marketing_sveltekit
   npm install @supabase/supabase-js
   ```

5. **Configure Development Environment**
   - [ ] Set up environment variables (.env files)
   - [ ] Configure Supabase connection in both apps
   - [ ] Set up VS Code workspace for monorepo

**Deliverable**: Working Flutter + SvelteKit projects with Supabase connection

---

### Phase 1: Core Infrastructure (Weeks 2-3)

**Goal**: Build foundational Flutter architecture matching Next.js capabilities

#### 1.1 State Management Setup

**Technology Choice**: Riverpod (recommended for Flutter)

```dart
// lib/providers/auth_provider.dart
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

// lib/providers/tenant_provider.dart
final tenantProvider = StateNotifierProvider<TenantNotifier, TenantState>((ref) {
  return TenantNotifier();
});

// lib/providers/cart_provider.dart
final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});
```

**Tasks:**
- [ ] Create provider structure (auth, tenant, user, cart, inventory)
- [ ] Implement state persistence (SharedPreferences)
- [ ] Set up Riverpod code generation for type safety

#### 1.2 Navigation Setup

**Technology Choice**: GoRouter

```dart
// lib/router/app_router.dart
final router = GoRouter(
  routes: [
    GoRoute(path: '/login', builder: (context, state) => LoginPage()),
    GoRoute(path: '/pos', builder: (context, state) => POSHomePage()),
    GoRoute(path: '/inventory', builder: (context, state) => InventoryPage()),
  ],
  redirect: (context, state) {
    // Auth guard logic
  },
);
```

**Tasks:**
- [ ] Set up GoRouter with auth guards
- [ ] Create route definitions for all POS screens
- [ ] Implement deep linking (for web URLs)

#### 1.3 Offline-First Architecture

**Technology Choice**: PowerSync Flutter SDK + sqflite

```dart
// lib/database/powersync.dart
class PowerSyncService {
  late PowerSyncDatabase db;

  Future<void> init() async {
    db = PowerSyncDatabase(
      schema: schema,
      path: 'pos_database.db',
    );

    await db.connect(
      connector: SupabaseConnector(supabaseUrl, supabaseKey),
    );
  }
}
```

**Tasks:**
- [ ] Integrate PowerSync Flutter SDK
- [ ] Define SQLite schema matching Supabase
- [ ] Implement sync status monitoring
- [ ] Create offline queue manager

#### 1.4 Supabase Integration

```dart
// lib/services/supabase_service.dart
class SupabaseService {
  static final instance = Supabase.instance.client;

  Future<AuthResponse> signInWithOTP(String phone) async {
    return await instance.auth.signInWithOtp(phone: phone);
  }
}
```

**Tasks:**
- [ ] Set up Supabase Flutter client
- [ ] Implement authentication (OTP, Google OAuth)
- [ ] Create service layer for API calls
- [ ] Set up real-time subscriptions

#### 1.5 UI Component Library

**Technology Choice**: Material Design 3 + Custom Components

```dart
// lib/components/pos_button.dart
class POSButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Text(label),
    );
  }
}
```

**Tasks:**
- [ ] Create design system (colors, typography, spacing)
- [ ] Build reusable components (Button, Card, Input, etc.)
- [ ] Implement responsive layout utilities
- [ ] Create offline indicator widget

**Deliverable**: Core Flutter infrastructure matching Next.js foundation

---

### Phase 2: Feature Migration - Authentication (Week 4)

**Goal**: Migrate User Story 2 (Multi-Tenant Authentication)

#### 2.1 Authentication Flow

**Screens to Build:**
- [ ] Login screen (email/password + Google Sign-In)
- [ ] Registration screen
- [ ] OTP verification screen
- [ ] Onboarding flow (profile setup, company setup)
- [ ] Passcode setup screen
- [ ] Inactivity lock screen

**Next.js Code to Migrate:**
- `app/(auth)/login/page.tsx` → `lib/screens/auth/login_page.dart`
- `app/(auth)/register/page.tsx` → `lib/screens/auth/register_page.dart`
- `app/(onboarding)/profile/page.tsx` → `lib/screens/onboarding/profile_page.dart`
- `app/(onboarding)/company/page.tsx` → `lib/screens/onboarding/company_page.dart`

**Migration Steps:**

1. **Convert Login UI**
   ```dart
   // lib/screens/auth/login_page.dart
   class LoginPage extends ConsumerWidget {
     @override
     Widget build(BuildContext context, WidgetRef ref) {
       final authState = ref.watch(authProvider);

       return Scaffold(
         body: Column(
           children: [
             TextField(/* email field */),
             TextField(/* password field */),
             ElevatedButton(
               onPressed: () => ref.read(authProvider.notifier).login(),
               child: Text('Login'),
             ),
             GoogleSignInButton(),
           ],
         ),
       );
     }
   }
   ```

2. **Port Authentication Logic**
   - Migrate `lib/auth/user.ts` → `lib/services/auth_service.dart`
   - Migrate `lib/auth/otp.ts` → `lib/services/otp_service.dart`
   - Port API calls to Supabase Flutter SDK

3. **Implement Onboarding**
   - Profile setup with image upload (image_picker package)
   - Company setup with geocoding
   - Multi-step form navigation

**Deliverable**: Complete authentication flow in Flutter

---

### Phase 3: Feature Migration - Core POS (Weeks 5-7)

**Goal**: Migrate User Story 1 (Offline-First POS Operations)

#### 3.1 Inventory Management

**Screens to Build:**
- [ ] Product list screen
- [ ] Product detail/edit screen
- [ ] CSV import screen
- [ ] Expiry alerts screen

**Next.js Code to Migrate:**
- `app/(pos)/inventory/page.tsx` → `lib/screens/pos/inventory_page.dart`
- `lib/pos/product.ts` → `lib/services/product_service.dart`
- `lib/pos/inventory.ts` → `lib/services/inventory_service.dart`

**Migration Steps:**

1. **Create Product Model**
   ```dart
   // lib/models/product.dart
   @freezed
   class Product with _$Product {
     factory Product({
       required String id,
       required String tenantId,
       required String name,
       required String sku,
       required double price,
       required int stockQuantity,
       DateTime? expiryDate,
     }) = _Product;

     factory Product.fromJson(Map<String, dynamic> json) =>
       _$ProductFromJson(json);
   }
   ```

2. **Build Inventory UI**
   - Product list with search/filter
   - Add/Edit product form
   - Stock adjustment interface
   - Expiry date tracking

3. **Implement Offline Storage**
   - Store products in PowerSync/SQLite
   - Sync to Supabase when online
   - Handle conflict resolution

#### 3.2 Sales/Cart System

**Screens to Build:**
- [ ] POS sales screen (main interface)
- [ ] Product selector with barcode scan
- [ ] Cart component
- [ ] Payment method selector
- [ ] Receipt preview

**Next.js Code to Migrate:**
- `app/(pos)/sales/page.tsx` → `lib/screens/pos/sales_page.dart`
- `app/components/pos/Cart.tsx` → `lib/widgets/pos/cart_widget.dart`
- `app/components/pos/ProductSelector.tsx` → `lib/widgets/pos/product_selector.dart`
- `lib/pos/transaction.ts` → `lib/services/transaction_service.dart`

**Migration Steps:**

1. **Create Sale Models**
   ```dart
   // lib/models/sale.dart
   @freezed
   class Sale with _$Sale {
     factory Sale({
       required String id,
       required String tenantId,
       required List<SaleItem> items,
       required double subtotal,
       required double tax,
       required double discount,
       required double total,
       required String paymentMethod,
       required String cashierId,
       required DateTime createdAt,
       required bool synced,
     }) = _Sale;
   }
   ```

2. **Build POS Interface**
   - Touch-optimized product grid
   - Cart management with quantity controls
   - Tax and discount calculation
   - Multiple payment methods

3. **Implement Barcode Scanning**
   ```dart
   // Use mobile_scanner package
   import 'package:mobile_scanner/mobile_scanner.dart';

   class BarcodeScannerWidget extends StatelessWidget {
     @override
     Widget build(BuildContext context) {
       return MobileScanner(
         onDetect: (barcode) {
           // Add product to cart by barcode
         },
       );
     }
   }
   ```

4. **Receipt Generation**
   - Generate PDF receipts (pdf package)
   - Support thermal printer (esc_pos_bluetooth)
   - Display digital receipt

**Deliverable**: Fully functional offline POS with inventory management

---

### Phase 4: Feature Migration - Staff & Admin (Weeks 8-9)

**Goal**: Migrate staff management, branches, and admin features

#### 4.1 Staff Management

**Screens to Build:**
- [ ] Staff list screen
- [ ] Staff invitation screen
- [ ] Attendance (clock in/out) screen
- [ ] Attendance reports

**Migration:**
- `app/(admin)/staff/page.tsx` → `lib/screens/admin/staff_page.dart`
- `app/(pos)/attendance/page.tsx` → `lib/screens/pos/attendance_page.dart`
- `lib/auth/invitation.ts` → `lib/services/invitation_service.dart`

#### 4.2 Branch Management

**Screens to Build:**
- [ ] Branch list screen
- [ ] Branch creation/edit screen
- [ ] Inter-branch transfer screen

**Migration:**
- `app/(admin)/branches/page.tsx` → `lib/screens/admin/branches_page.dart`
- `lib/pos/branch.ts` → `lib/services/branch_service.dart`

**Deliverable**: Complete staff and branch management

---

### Phase 5: Feature Migration - Customer & Orders (Weeks 10-11)

**Goal**: Migrate marketplace storefront and order management

#### 5.1 Customer Management

**Screens to Build:**
- [ ] Customer list screen
- [ ] Customer detail screen (purchase history)
- [ ] Loyalty points tracker

**Migration:**
- `app/(pos)/customers/page.tsx` → `lib/screens/pos/customers_page.dart`
- `lib/pos/customer.ts` → `lib/services/customer_service.dart`

#### 5.2 Order Management

**Screens to Build:**
- [ ] Order list screen
- [ ] Order detail screen
- [ ] Order status update

**Migration:**
- `app/(pos)/orders/page.tsx` → `lib/screens/pos/orders_page.dart`
- `lib/pos/order.ts` → `lib/services/order_service.dart`

**Deliverable**: Customer and order management in Flutter

---

### Phase 6: Feature Migration - Delivery & Analytics (Weeks 12-13)

#### 6.1 Delivery Management

**Screens:**
- [ ] Delivery list screen
- [ ] Rider management screen
- [ ] Delivery tracking (customer-facing)

**Migration:**
- `app/(admin)/deliveries/page.tsx` → `lib/screens/admin/deliveries_page.dart`
- `lib/pos/delivery.ts` → `lib/services/delivery_service.dart`

#### 6.2 Analytics Dashboard

**Screens:**
- [ ] Analytics overview
- [ ] Product sales charts
- [ ] Category comparison
- [ ] Sales patterns

**Migration:**
- `app/(admin)/analytics/page.tsx` → `lib/screens/admin/analytics_page.dart`
- Use fl_chart package for graphs

**Deliverable**: Delivery and analytics features

---

### Phase 7: Feature Migration - Integrations (Weeks 14-15)

#### 7.1 E-Commerce Integration

**Migration:**
- `lib/integrations/woocommerce.ts` → `lib/services/woocommerce_service.dart`
- Build sync dashboard UI

#### 7.2 WhatsApp Integration

**Migration:**
- `lib/integrations/whatsapp.ts` → `lib/services/whatsapp_service.dart`
- Implement messaging UI

#### 7.3 AI Chat Agent

**Migration:**
- `lib/integrations/ai-chat.ts` → `lib/services/ai_chat_service.dart`
- Build chat widget

**Deliverable**: All integrations working in Flutter

---

### Phase 8: SvelteKit Marketing Site (Weeks 16-17)

**Goal**: Build SEO-optimized marketing pages

#### 8.1 Core Pages

**Pages to Build:**
- [ ] Landing page (`src/routes/+page.svelte`)
- [ ] Pricing page (`src/routes/pricing/+page.svelte`)
- [ ] Storefront (`src/routes/shop/+page.svelte`)
- [ ] Product detail (`src/routes/shop/[slug]/+page.svelte`)

#### 8.2 Features

**Implementation:**
- Server-side rendering (SSR) for SEO
- Static site generation (SSG) where possible
- Supabase integration for product data
- Shopping cart (session-based)

**Example SvelteKit Page:**
```svelte
<!-- src/routes/+page.svelte -->
<script lang="ts">
  export let data;
</script>

<h1>Welcome to POS Platform</h1>
<p>Manage your business with ease</p>

<!-- src/routes/+page.server.ts -->
export async function load() {
  return {
    title: 'POS Platform',
  };
}
```

**Deliverable**: SEO-optimized marketing site

---

### Phase 9: Testing & Optimization (Weeks 18-19)

#### 9.1 Testing

**Test Types:**
- [ ] Unit tests (Dart test package)
- [ ] Widget tests (Flutter test framework)
- [ ] Integration tests (integration_test package)
- [ ] E2E tests (Patrol or similar)

#### 9.2 Performance Optimization

**Tasks:**
- [ ] Optimize bundle size (tree shaking)
- [ ] Implement lazy loading
- [ ] Add caching strategies
- [ ] Profile and fix performance bottlenecks
- [ ] Test on low-end devices

#### 9.3 Cross-Platform Testing

**Platforms to Test:**
- [ ] Chrome (web)
- [ ] Firefox (web)
- [ ] Safari (web)
- [ ] Android (physical device)
- [ ] iOS (if available)

**Deliverable**: Tested, optimized Flutter + SvelteKit apps

---

### Phase 10: Deployment & Cutover (Weeks 20-22)

#### 10.1 Flutter Web Deployment

**Steps:**
```bash
# Build Flutter web
flutter build web --release

# Deploy to Vercel/Netlify
vercel deploy --prod
```

**Setup:**
- [ ] Domain: `pos.yourdomain.com`
- [ ] Configure CDN
- [ ] Set up SSL certificates
- [ ] Enable PWA features

#### 10.2 Mobile App Deployment

**Android:**
```bash
flutter build apk --release
flutter build appbundle --release
```

**Tasks:**
- [ ] Create Google Play Console account
- [ ] Set up app signing
- [ ] Upload to Play Store (beta first)

**iOS (if available):**
```bash
flutter build ipa --release
```

**Tasks:**
- [ ] Create Apple Developer account
- [ ] Configure code signing
- [ ] Upload to App Store Connect

#### 10.3 SvelteKit Deployment

**Steps:**
```bash
npm run build
vercel deploy --prod
```

**Setup:**
- [ ] Domain: `yourdomain.com`
- [ ] Configure SSR
- [ ] Set up edge functions

#### 10.4 Cutover Strategy

**Parallel Run (Recommended):**

1. **Week 20**: Deploy Flutter + SvelteKit to staging
2. **Week 21**: Beta testing with select users
3. **Week 22**:
   - Launch Flutter web at `pos.yourdomain.com`
   - Launch SvelteKit at `yourdomain.com`
   - Keep Next.js at `old.yourdomain.com` (backup)
4. **Week 23+**: Monitor, gather feedback, iterate

**Rollback Plan:**
- Keep Next.js deployment active for 2-4 weeks
- DNS can be switched back immediately if issues arise

**Deliverable**: Production deployment of Flutter + SvelteKit

---

## Technology Stack Mapping

### State Management

| Next.js (Current) | Flutter (Target) |
|-------------------|------------------|
| Zustand | Riverpod |
| React Context | Provider (deprecated, use Riverpod) |
| useState | StateNotifier + Riverpod |

### Routing

| Next.js (Current) | Flutter (Target) |
|-------------------|------------------|
| App Router (file-based) | GoRouter (declarative) |
| `useRouter()` | `context.go()` / `context.push()` |
| Dynamic routes `[id]` | Path parameters `:id` |

### Data Fetching

| Next.js (Current) | Flutter (Target) |
|-------------------|------------------|
| Server Components | FutureProvider (Riverpod) |
| `fetch()` | `http` package or `dio` |
| SWR / React Query | AsyncValue (Riverpod) |

### UI Components

| Next.js (Current) | Flutter (Target) |
|-------------------|------------------|
| shadcn/ui | Material Design 3 |
| Radix UI | Custom widgets |
| Tailwind CSS | Flutter styling (ThemeData) |

### Offline Storage

| Next.js (Current) | Flutter (Target) |
|-------------------|------------------|
| IndexedDB | sqflite + PowerSync |
| LocalStorage | shared_preferences |
| Service Workers | WorkManager (background sync) |

### Authentication

| Next.js (Current) | Flutter (Target) |
|-------------------|------------------|
| Supabase Auth (JS) | Supabase Auth (Dart) |
| NextAuth.js | N/A (use Supabase) |

---

## Code Examples: Side-by-Side Comparison

### Example 1: Login Screen

**Next.js (TypeScript):**
```typescript
// app/(auth)/login/page.tsx
'use client'
import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { supabase } from '@/lib/supabase/client'

export default function LoginPage() {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const router = useRouter()

  const handleLogin = async () => {
    const { error } = await supabase.auth.signInWithPassword({
      email,
      password,
    })
    if (!error) router.push('/pos')
  }

  return (
    <div>
      <input
        type="email"
        value={email}
        onChange={(e) => setEmail(e.target.value)}
      />
      <input
        type="password"
        value={password}
        onChange={(e) => setPassword(e.target.value)}
      />
      <button onClick={handleLogin}>Login</button>
    </div>
  )
}
```

**Flutter (Dart):**
```dart
// lib/screens/auth/login_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class LoginPage extends ConsumerStatefulWidget {
  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _handleLogin() async {
    final authService = ref.read(authServiceProvider);
    final error = await authService.signInWithPassword(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (error == null) {
      context.go('/pos');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(labelText: 'Email'),
          ),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(labelText: 'Password'),
          ),
          ElevatedButton(
            onPressed: _handleLogin,
            child: Text('Login'),
          ),
        ],
      ),
    );
  }
}
```

### Example 2: Product List with Search

**Next.js (TypeScript):**
```typescript
// app/(pos)/inventory/page.tsx
'use client'
import { useState, useEffect } from 'react'
import { supabase } from '@/lib/supabase/client'

export default function InventoryPage() {
  const [products, setProducts] = useState([])
  const [search, setSearch] = useState('')

  useEffect(() => {
    const fetchProducts = async () => {
      const { data } = await supabase
        .from('products')
        .select('*')
        .ilike('name', `%${search}%`)
      setProducts(data || [])
    }
    fetchProducts()
  }, [search])

  return (
    <div>
      <input
        value={search}
        onChange={(e) => setSearch(e.target.value)}
        placeholder="Search products..."
      />
      {products.map(product => (
        <div key={product.id}>
          <h3>{product.name}</h3>
          <p>₦{product.price}</p>
        </div>
      ))}
    </div>
  )
}
```

**Flutter (Dart):**
```dart
// lib/screens/pos/inventory_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider for search query
final searchQueryProvider = StateProvider<String>((ref) => '');

// Provider for products (auto-updates when search changes)
final productsProvider = FutureProvider<List<Product>>((ref) async {
  final search = ref.watch(searchQueryProvider);
  final supabase = ref.read(supabaseProvider);

  final response = await supabase
      .from('products')
      .select()
      .ilike('name', '%$search%');

  return (response as List).map((e) => Product.fromJson(e)).toList();
});

class InventoryPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);
    final search = ref.watch(searchQueryProvider);

    return Scaffold(
      appBar: AppBar(title: Text('Inventory')),
      body: Column(
        children: [
          TextField(
            onChanged: (value) =>
              ref.read(searchQueryProvider.notifier).state = value,
            decoration: InputDecoration(
              hintText: 'Search products...',
            ),
          ),
          Expanded(
            child: productsAsync.when(
              data: (products) => ListView.builder(
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return ListTile(
                    title: Text(product.name),
                    subtitle: Text('₦${product.price}'),
                  );
                },
              ),
              loading: () => CircularProgressIndicator(),
              error: (err, stack) => Text('Error: $err'),
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## Risk Mitigation

### Risk 1: Team Learning Curve (Dart + Flutter)

**Mitigation:**
- [ ] 1-week Flutter/Dart training for team
- [ ] Start with simple screens (login, product list)
- [ ] Pair programming for complex features
- [ ] Use Flutter documentation and examples

### Risk 2: Performance on Low-End Devices

**Mitigation:**
- [ ] Test on physical low-end Android devices early
- [ ] Use Flutter DevTools to profile performance
- [ ] Implement lazy loading and pagination
- [ ] Use HTML renderer for web if CanvasKit is too heavy

### Risk 3: Migration Delays

**Mitigation:**
- [ ] Keep Next.js running in production during migration
- [ ] Migrate features incrementally (can deploy partial functionality)
- [ ] Set realistic milestones with buffer time
- [ ] Have rollback plan ready

### Risk 4: Data Sync Issues (PowerSync Flutter)

**Mitigation:**
- [ ] Test PowerSync Flutter SDK thoroughly
- [ ] Implement comprehensive error handling
- [ ] Keep offline queue visible to users
- [ ] Add manual sync trigger

---

## Success Criteria

### Technical Metrics

- [ ] Flutter web loads in < 3 seconds on 3G
- [ ] Mobile apps < 30MB download size
- [ ] Offline POS works 100% without internet
- [ ] Sync completes within 2 minutes for 100 transactions
- [ ] 60fps scrolling in product lists (1000+ items)

### Feature Parity

- [ ] All Next.js POS features work in Flutter
- [ ] All authentication flows work
- [ ] Offline sync matches Next.js behavior
- [ ] Mobile apps on iOS + Android stores
- [ ] SvelteKit marketing site has better SEO than Next.js

### User Acceptance

- [ ] Beta users successfully use Flutter POS
- [ ] No critical bugs blocking daily operations
- [ ] Positive feedback on mobile app UX
- [ ] Staff can use app with minimal retraining

---

## Resources & Dependencies

### Flutter Packages Needed

```yaml
# pubspec.yaml
dependencies:
  flutter:
    sdk: flutter

  # State Management
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5

  # Navigation
  go_router: ^14.0.0

  # Backend
  supabase_flutter: ^2.5.0
  powersync: ^1.6.0

  # Database
  sqflite: ^2.3.0
  path: ^1.8.3

  # Models
  freezed: ^2.4.7
  freezed_annotation: ^2.4.1
  json_annotation: ^4.9.0

  # UI
  flutter_svg: ^2.0.10
  cached_network_image: ^3.3.1
  shimmer: ^3.0.0

  # Charts
  fl_chart: ^0.69.0

  # Camera/Barcode
  mobile_scanner: ^5.0.0
  image_picker: ^1.0.7

  # PDF/Printing
  pdf: ^3.10.8
  printing: ^5.12.0

  # Utils
  intl: ^0.19.0
  uuid: ^4.3.3
  dio: ^5.4.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.8
  riverpod_generator: ^2.3.11
  freezed: ^2.4.7
  json_serializable: ^6.7.1
```

### Team Skills Required

- [ ] Dart programming language
- [ ] Flutter framework
- [ ] Riverpod state management
- [ ] Supabase (already familiar)
- [ ] SvelteKit (for marketing team)

### External Services (No Changes)

- ✅ Supabase (PostgreSQL, Auth, Storage)
- ✅ PowerSync (offline sync)
- ✅ Paystack/Flutterwave (payments)
- ✅ Termii (SMS/OTP)

---

## Timeline Summary

| Phase | Duration | Deliverable |
|-------|----------|-------------|
| 0. Preparation | 1 week | Dev environment ready |
| 1. Infrastructure | 2 weeks | State management, routing, offline |
| 2. Authentication | 1 week | Login, register, onboarding |
| 3. Core POS | 3 weeks | Inventory, sales, cart |
| 4. Staff/Admin | 2 weeks | Staff mgmt, branches |
| 5. Customer/Orders | 2 weeks | Customer mgmt, orders |
| 6. Delivery/Analytics | 2 weeks | Delivery, charts |
| 7. Integrations | 2 weeks | WooCommerce, WhatsApp, AI |
| 8. SvelteKit Site | 2 weeks | Marketing pages |
| 9. Testing/Optimization | 2 weeks | QA, performance |
| 10. Deployment | 3 weeks | Production launch |

**Total: 22 weeks (~5.5 months)**

---

## Next Steps

1. **Review this plan** with the team
2. **Set up Flutter development environment** (Phase 0)
3. **Create proof of concept** (simple login + product list)
4. **Get stakeholder approval** to proceed
5. **Start Phase 1** (Infrastructure)

---

**Document Version**: 1.0
**Last Updated**: 2026-02-11
**Status**: Draft - Pending Approval
