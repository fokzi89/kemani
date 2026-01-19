# E-Commerce Storefront Guide

## Overview

The multi-tenant POS platform provides integrated e-commerce storefronts for tenants, allowing them to sell products online across all their branches.

## Subscription Tiers & E-Commerce Access

### Plan Tiers

| Plan Tier | E-Commerce Enabled | URL Structure | Custom Domain | Monthly Fee |
|-----------|-------------------|---------------|---------------|-------------|
| **Free** | ❌ No | N/A | ❌ No | ₦0 |
| **Basic** | ❌ No | N/A | ❌ No | ₦5,000 |
| **Pro** | ✅ Yes | `/tenant-slug` | ❌ No | ₦15,000 |
| **Enterprise** | ✅ Yes | `/tenant-slug` | ❌ No | ₦50,000 |
| **Enterprise Custom** | ✅ Yes | Custom domain | ✅ Yes | Contact Sales |

### E-Commerce Features by Plan

**Pro & Enterprise Plans:**
- Storefront URL: `https://yourdomain.com/acme-supermarket`
- Uses tenant slug from `tenants.slug`
- Multi-branch product display
- Category & location filtering
- Chat feature on product pages
- Standard theme customization

**Enterprise Custom Plan:**
- Everything in Enterprise, plus:
- Custom domain: `https://shop.acmestore.com`
- Full white-label capability
- Advanced theme customization
- Custom integrations
- Dedicated support
- Requires contacting sales team

## Database Schema

### Tenants Table (Updated)

```sql
CREATE TABLE tenants (
    id UUID PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,  -- Used for default storefront URL

    -- E-Commerce fields
    ecommerce_enabled BOOLEAN DEFAULT FALSE,
    custom_domain VARCHAR(255),  -- e.g., "shop.acmestore.com"
    custom_domain_verified BOOLEAN DEFAULT FALSE,
    ecommerce_settings JSONB DEFAULT '{}',

    -- Other fields...
    subscription_id UUID REFERENCES subscriptions(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

### E-Commerce Settings JSONB Structure

```json
{
  "show_out_of_stock": false,
  "enable_branch_filter": true,
  "enable_location_filter": true,
  "default_view": "category",
  "currency_display": "NGN",
  "delivery_enabled": true,
  "pickup_enabled": true,
  "min_order_amount": 1000,
  "seo": {
    "meta_title": "Shop at MyStore",
    "meta_description": "Quality products delivered to your doorstep",
    "meta_keywords": "supermarket, grocery, online shopping",
    "og_image": "https://storage.example.com/og-image.jpg"
  },
  "theme": {
    "primary_color": "#FF6B35",
    "secondary_color": "#004E89",
    "font_family": "Inter",
    "logo_url": "https://..."
  }
}
```

## Storefront URL Structure

### Default Storefront (Pro & Enterprise)

```
https://yourdomain.com/[tenant-slug]
```

**Examples:**
- `https://yourplatform.com/acme-supermarket`
- `https://yourplatform.com/downtown-pharmacy`
- `https://yourplatform.com/fresh-groceries`

### Custom Domain (Enterprise Custom)

```
https://[custom-domain]
```

**Examples:**
- `https://shop.acmestore.com`
- `https://www.downtownpharmacy.ng`
- `https://order.freshgroceries.com`

### Getting Storefront URL (SQL Function)

```sql
-- Get the storefront URL for a tenant
SELECT get_storefront_url('tenant-uuid', 'https://yourplatform.com');

-- Result examples:
-- 'https://yourplatform.com/acme-supermarket' (default)
-- 'https://shop.acmestore.com' (custom domain)
-- NULL (if e-commerce not enabled)
```

## Product Display Architecture

### Multi-Branch Product Aggregation

Products are displayed across **all branches** of a tenant, showing:
1. **Product Information**: Name, description, price, image
2. **Total Stock**: Sum of stock across all branches
3. **Branch Availability**: Which branches have the product in stock
4. **Branch Details**: Address, phone, coordinates for each branch

### E-Commerce Products View

The `ecommerce_products` view automatically aggregates products:

```sql
SELECT * FROM ecommerce_products
WHERE tenant_id = 'tenant-uuid';
```

**Returns:**
```json
{
  "id": "product-uuid",
  "name": "Premium Coffee Beans 500g",
  "description": "Freshly roasted Arabica beans",
  "category": "Beverages",
  "unit_price": 4500.00,
  "image_url": "https://...",
  "total_stock": 75,
  "branch_count": 3,
  "branches": [
    {
      "branch_id": "branch-1-uuid",
      "branch_name": "Victoria Island Branch",
      "branch_address": "123 Main St, Victoria Island, Lagos",
      "branch_phone": "+234 801 234 5678",
      "latitude": 6.4281,
      "longitude": 3.4219,
      "stock_quantity": 25,
      "in_stock": true
    },
    {
      "branch_id": "branch-2-uuid",
      "branch_name": "Lekki Branch",
      "branch_address": "456 Admiralty Way, Lekki, Lagos",
      "branch_phone": "+234 802 345 6789",
      "latitude": 6.4474,
      "longitude": 3.4700,
      "stock_quantity": 50,
      "in_stock": true
    }
  ],
  "min_price": 4500.00,
  "max_price": 4500.00
}
```

## Filtering Options

### 1. Category Filter

Group and filter products by category:

```sql
SELECT * FROM get_ecommerce_products(
    p_tenant_id := 'tenant-uuid',
    p_category := 'Beverages'
);
```

**Frontend Example:**
```typescript
// Product categories displayed as tabs or sidebar
const categories = ['All', 'Beverages', 'Snacks', 'Dairy', 'Meat', 'Vegetables'];
```

### 2. Branch Filter

Show products from a specific branch:

```sql
SELECT * FROM get_ecommerce_products(
    p_tenant_id := 'tenant-uuid',
    p_branch_id := 'branch-uuid'
);
```

**Frontend Example:**
```typescript
// Dropdown: "Select a branch"
<select>
  <option value="">All Branches</option>
  <option value="branch-1-uuid">Victoria Island Branch</option>
  <option value="branch-2-uuid">Lekki Branch</option>
  <option value="branch-3-uuid">Ikeja Branch</option>
</select>
```

### 3. Location Filter (Distance-Based)

Show products from branches within X kilometers of customer location:

```sql
SELECT * FROM get_ecommerce_products(
    p_tenant_id := 'tenant-uuid',
    p_latitude := 6.5244,      -- Customer's latitude
    p_longitude := 3.3792,     -- Customer's longitude
    p_max_distance_km := 5.0   -- Within 5km
);
```

**Frontend Example:**
```typescript
// Get customer location
navigator.geolocation.getCurrentPosition((position) => {
  const { latitude, longitude } = position.coords;

  // Fetch products within 5km
  fetchProducts({
    latitude,
    longitude,
    maxDistanceKm: 5
  });
});
```

**UI Display:**
```
📍 Showing products from branches within 5km of your location

[○ 2km] [○ 5km] [○ 10km] [○ 20km] [○ All]
```

### 4. Stock Filter

Show only in-stock products:

```sql
SELECT * FROM get_ecommerce_products(
    p_tenant_id := 'tenant-uuid',
    p_in_stock_only := TRUE  -- Default is TRUE
);
```

### Combined Filters Example

```sql
-- Beverages, in stock, within 10km of customer
SELECT * FROM get_ecommerce_products(
    p_tenant_id := 'tenant-uuid',
    p_category := 'Beverages',
    p_latitude := 6.5244,
    p_longitude := 3.3792,
    p_max_distance_km := 10.0,
    p_in_stock_only := TRUE
);
```

## Storefront Page Structure

### 1. Homepage (`/acme-supermarket`)

```
┌─────────────────────────────────────────┐
│  Logo    Acme Supermarket    [Cart] [Login] │
├─────────────────────────────────────────┤
│  [Search products...]                   │
├─────────────────────────────────────────┤
│  Categories: [All] [Beverages] [Snacks] │
│  Branches:   [All Branches ▼]           │
│  Location:   [📍 Within 5km ▼]          │
├─────────────────────────────────────────┤
│  ┌──────┐  ┌──────┐  ┌──────┐          │
│  │ Prod │  │ Prod │  │ Prod │          │
│  │ ₦450 │  │ ₦1200│  │ ₦800 │          │
│  │ 3 br │  │ 2 br │  │ 5 br │          │
│  └──────┘  └──────┘  └──────┘          │
└─────────────────────────────────────────┘
```

### 2. Product Detail Page (`/acme-supermarket/products/coffee-beans`)

```
┌─────────────────────────────────────────┐
│  ← Back to Products                     │
├─────────────────────────────────────────┤
│  [Image]  │  Premium Coffee Beans 500g  │
│           │  ₦4,500                     │
│           │  ⭐⭐⭐⭐⭐ 4.5 (23 reviews)│
│           │                             │
│           │  [- 1 +] [Add to Cart]      │
│           │                             │
│           │  💬 Ask about this product  │  ← Only for Pro/Enterprise
│           │                             │
│           │  Available at 3 branches:   │
│           │                             │
│           │  ✓ Victoria Island (25)     │
│           │     📍 2.3km away           │
│           │  ✓ Lekki (50)               │
│           │     📍 5.1km away           │
│           │  ✓ Ikeja (0) Out of stock   │
│           │     📍 8.7km away           │
└─────────────────────────────────────────┘
```

### 3. Chat Integration (Pro/Enterprise Only)

When customer clicks "💬 Ask about this product":

```typescript
// Check if chat is available
const { data: canChat } = await supabase
  .rpc('has_ecommerce_chat_feature', { p_tenant_id: tenantId });

if (canChat) {
  // Open chat widget
  startProductChat(productId);
}
```

See [chat-system-guide.md](./chat-system-guide.md) for full chat integration details.

## Enabling E-Commerce for a Tenant

### 1. Check Plan Eligibility

```sql
-- Check if tenant can enable e-commerce
SELECT can_enable_ecommerce('tenant-uuid');
-- Returns: true (Pro/Enterprise/Enterprise Custom) or false (Free/Basic)
```

### 2. Enable E-Commerce Storefront

```sql
-- Enable e-commerce for Pro/Enterprise tenant
UPDATE tenants
SET ecommerce_enabled = TRUE,
    ecommerce_settings = jsonb_build_object(
        'show_out_of_stock', false,
        'enable_branch_filter', true,
        'enable_location_filter', true,
        'default_view', 'category'
    )
WHERE id = 'tenant-uuid'
AND can_enable_ecommerce(id) = TRUE;
```

### 3. Set Up Custom Domain (Enterprise Custom Only)

```sql
-- Check if tenant can use custom domain
SELECT can_use_custom_domain('tenant-uuid');
-- Returns: true (Enterprise Custom) or false (others)

-- Add custom domain
UPDATE tenants
SET custom_domain = 'shop.acmestore.com',
    custom_domain_verified = FALSE  -- Will be verified after DNS setup
WHERE id = 'tenant-uuid'
AND can_use_custom_domain(id) = TRUE;

-- After DNS verification
UPDATE tenants
SET custom_domain_verified = TRUE
WHERE id = 'tenant-uuid'
AND custom_domain = 'shop.acmestore.com';
```

### 4. DNS Configuration (Enterprise Custom)

Tenant must configure their DNS:

```
Type: CNAME
Host: shop (or www)
Value: yourplatform.com
TTL: 3600
```

Or for apex domain:

```
Type: A
Host: @
Value: [Your server IP]
TTL: 3600
```

## Frontend Implementation Examples

### React Component: Product Grid

```typescript
import { useEffect, useState } from 'react';
import { supabase } from './supabaseClient';

interface ProductFilters {
  category?: string;
  branchId?: string;
  latitude?: number;
  longitude?: number;
  maxDistanceKm?: number;
}

export function ProductGrid({ tenantId }: { tenantId: string }) {
  const [products, setProducts] = useState([]);
  const [filters, setFilters] = useState<ProductFilters>({});

  useEffect(() => {
    async function fetchProducts() {
      const { data, error } = await supabase.rpc('get_ecommerce_products', {
        p_tenant_id: tenantId,
        p_category: filters.category || null,
        p_branch_id: filters.branchId || null,
        p_latitude: filters.latitude || null,
        p_longitude: filters.longitude || null,
        p_max_distance_km: filters.maxDistanceKm || null,
        p_in_stock_only: true
      });

      if (!error) setProducts(data);
    }

    fetchProducts();
  }, [tenantId, filters]);

  return (
    <div>
      {/* Filters */}
      <CategoryFilter onChange={(cat) => setFilters({ ...filters, category: cat })} />
      <BranchFilter onChange={(branch) => setFilters({ ...filters, branchId: branch })} />
      <LocationFilter onChange={(loc) => setFilters({ ...filters, ...loc })} />

      {/* Product Grid */}
      <div className="grid grid-cols-3 gap-4">
        {products.map(product => (
          <ProductCard key={product.product_id} product={product} />
        ))}
      </div>
    </div>
  );
}
```

### Next.js Dynamic Route: `app/[slug]/page.tsx`

```typescript
import { supabase } from '@/lib/supabaseClient';
import ProductGrid from '@/components/ProductGrid';

export default async function StorefrontPage({
  params
}: {
  params: { slug: string }
}) {
  // Get tenant by slug
  const { data: tenant } = await supabase
    .from('tenants')
    .select('*')
    .eq('slug', params.slug)
    .eq('ecommerce_enabled', true)
    .single();

  if (!tenant) {
    return <div>Storefront not found</div>;
  }

  return (
    <div>
      <h1>{tenant.name}</h1>
      <ProductGrid tenantId={tenant.id} />
    </div>
  );
}
```

## Sales Flow from E-Commerce

When a customer places an order from the storefront:

1. **Create Order** in `orders` table with `order_type = 'marketplace'`
2. **Create Order Items** in `order_items` table
3. **Update Inventory** via `inventory_transactions`
4. **Create Delivery** (if fulfillment_type = 'delivery')
5. **Send Confirmation** via WhatsApp/Email
6. **Track Payment Status**
7. **Update Stock Quantities**

See [orders schema](../supabase/migrations/005_order_delivery_tables.sql) for details.

## Contact Sales for Enterprise Custom

Tenants who want custom domain e-commerce should:

1. **Contact your sales team** via:
   - Email: sales@yourplatform.com
   - Phone: +234 XXX XXX XXXX
   - In-app: "Upgrade to Enterprise Custom" button

2. **Sales process**:
   - Needs assessment
   - Custom pricing based on volume
   - DNS setup assistance
   - Domain verification
   - Theme customization
   - Onboarding & training

3. **Pricing factors**:
   - Number of branches
   - Transaction volume
   - Custom integrations needed
   - Support level required

## Summary

| Feature | Free | Basic | Pro | Enterprise | Enterprise Custom |
|---------|------|-------|-----|------------|-------------------|
| E-Commerce Storefront | ❌ | ❌ | ✅ | ✅ | ✅ |
| Storefront URL | N/A | N/A | `/slug` | `/slug` | Custom domain |
| Multi-branch Display | N/A | N/A | ✅ | ✅ | ✅ |
| Category Filter | N/A | N/A | ✅ | ✅ | ✅ |
| Branch Filter | N/A | N/A | ✅ | ✅ | ✅ |
| Location Filter | N/A | N/A | ✅ | ✅ | ✅ |
| Product Chat | N/A | N/A | ✅ | ✅ | ✅ |
| Custom Domain | N/A | N/A | ❌ | ❌ | ✅ |
| White Label | N/A | N/A | ❌ | ❌ | ✅ |
| Price | ₦0 | ₦5k | ₦15k | ₦50k | Contact Sales |
