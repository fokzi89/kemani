# Multi-Tenant POS Flutter App - FlutterFlow Build Guide

**Project:** Kemani POS System
**Platform:** FlutterFlow
**Database:** Supabase
**Architecture:** Multi-tenant with Branch Isolation
**Last Updated:** March 5, 2026

---

## Table of Contents

1. [Overview](#overview)
2. [App Architecture](#app-architecture)
3. [RPC Functions & Helper Functions](#rpc-functions--helper-functions)
4. [Authentication Flow](#authentication-flow)
5. [Page Directory](#page-directory)
6. [Detailed Page Specifications](#detailed-page-specifications)
7. [Navigation Map](#navigation-map)
8. [State Management](#state-management)
9. [Offline Capabilities](#offline-capabilities)
10. [FlutterFlow Configuration](#flutterflow-configuration)

---

## Overview

This guide provides complete specifications for building a multi-tenant POS system in FlutterFlow. The app supports:

**📋 Important**: For all RPC functions, SQL definitions, and FlutterFlow integration examples, see the companion document:
**[pos-rpc-functions.md](./pos-rpc-functions.md)**

### What's in This Guide

- **Multi-tenancy**: Each business (tenant) has isolated data
- **Multi-branch**: Tenants can operate multiple branches
- **Role-based access**: tenant_admin, branch_manager, cashier
- **Offline-first**: Critical POS operations work offline
- **Real-time sync**: Data syncs when online

---

## App Architecture

### Data Model Summary

```
tenant (Business)
  ├── branches (Physical locations)
  ├── users (Staff members with roles)
  ├── products (Tenant-wide catalog)
  └── branch_inventory (Stock per branch)
```

### User Roles & Permissions

| Role | Access Level |
|------|-------------|
| **tenant_admin** | All branches, all data, user management |
| **branch_manager** | Assigned branch only, staff management, reports |
| **cashier** | Assigned branch only, POS sales, customer lookup |

---

## RPC Functions & Helper Functions

### Overview

This POS system uses **19 custom PostgreSQL functions** to handle complex business logic efficiently. These functions are called as **RPC (Remote Procedure Call)** from FlutterFlow.

### Complete Function List

All SQL definitions and FlutterFlow integration examples are in **[pos-rpc-functions.md](./pos-rpc-functions.md)**

#### Dashboard Functions (3)
1. `get_daily_sales_summary` - Today's sales metrics
2. `get_recent_sales` - Recent transactions for quick view
3. `get_low_stock_count` - Low stock alert count

#### POS Sale Functions (3)
4. `search_products_for_pos` - Product search with stock
5. `complete_sale_transaction` - Atomic sale completion
6. `void_sale` - Void sale and restore inventory

#### Product & Inventory Functions (2)
7. `get_products_with_stock` - Products with stock levels
8. `adjust_stock` - Adjust inventory levels

#### Sales History Functions (2)
9. `get_sales_with_filters` - Advanced sales filtering
10. `get_sales_summary` - Sales summary for date range

#### Customer Functions (2)
11. `search_customers` - Fuzzy customer search
12. `get_customer_stats` - Customer statistics

#### Reports Functions (3)
13. `get_daily_sales_trend` - Daily sales data for charts
14. `get_top_products` - Best-selling products
15. `calculate_inventory_value` - Total inventory valuation

#### Staff & Branch Functions (2)
16. `get_staff_performance` - Staff metrics
17. `create_inter_branch_transfer` - Create stock transfer

#### Utility Functions (2)
18. `generate_slug` - URL-friendly slugs
19. `calculate_profit_margin` - Profit margin calculation

### Page-to-Function Mapping

Each page section below indicates which RPC functions it uses. Refer to the companion document for complete implementation details.

---

## Authentication Flow

### Pages Involved
1. Splash Screen
2. Login Page
3. Onboarding Flow (for new tenants)
4. Main App (after authentication)

---

## Page Directory

### 🔐 Authentication Pages
1. [Splash Screen](#1-splash-screen)
2. [Login Page](#2-login-page)
3. [Signup Page](#3-signup-page)
4. [Onboarding - Business Info](#4-onboarding---business-info)
5. [Onboarding - Branch Setup](#5-onboarding---branch-setup)
6. [Onboarding - Complete](#6-onboarding---complete)

### 🏠 Main Pages
7. [Dashboard/Home](#7-dashboardhome)
8. [POS Sale Screen](#8-pos-sale-screen)
9. [Products Management](#9-products-management)
10. [Product Details/Edit](#10-product-detailsedit)
11. [Add Product](#11-add-product)
12. [Branch Inventory](#12-branch-inventory)
13. [Adjust Stock](#13-adjust-stock)

### 📊 Sales & Customers
14. [Sales History](#14-sales-history)
15. [Sale Details](#15-sale-details)
16. [Customers List](#16-customers-list)
17. [Customer Details](#17-customer-details)
18. [Add/Edit Customer](#18-addedit-customer)

### 📈 Reports & Analytics
19. [Reports Dashboard](#19-reports-dashboard)
20. [Sales Report](#20-sales-report)
21. [Inventory Report](#21-inventory-report)
22. [Low Stock Alerts](#22-low-stock-alerts)

### 🏢 Management Pages (Admin/Manager)
23. [Branches List](#23-branches-list)
24. [Branch Details/Edit](#24-branch-detailsedit)
25. [Add Branch](#25-add-branch)
26. [Staff Management](#26-staff-management)
27. [Add/Invite Staff](#27-addinvite-staff)
28. [Inter-Branch Transfer](#28-inter-branch-transfer)
29. [Transfer History](#29-transfer-history)

### ⚙️ Settings & Profile
30. [Settings](#30-settings)
31. [Profile](#31-profile)
32. [Subscription & Billing](#32-subscription--billing)

---

## Detailed Page Specifications

---

## 1. Splash Screen

### Purpose
App initialization and authentication check.

### User Access
Everyone (unauthenticated)

### Data Fetching
```dart
// Check if user is authenticated
final session = Supabase.instance.client.auth.currentSession;

if (session != null) {
  // Fetch user profile
  final user = await Supabase.instance.client
    .from('users')
    .select('*, tenants(*), branches(*)')
    .eq('id', session.user.id)
    .single();

  // Navigate to Dashboard
} else {
  // Navigate to Login
}
```

### Navigation
- If authenticated → Dashboard
- If not authenticated → Login Page
- If authenticated but no tenant → Onboarding

### FlutterFlow AI Prompt
```
Create a splash screen widget with:
- Centered app logo
- Loading indicator below logo
- App name "Kemani POS" in bold
- Tagline "Multi-Store Management Made Easy"
- Background gradient from primary to secondary color
- Auto-navigate after 2 seconds based on auth state
```

---

## 2. Login Page

### Purpose
User authentication with email/phone and password.

### User Access
Everyone (unauthenticated)

### UI Components
- Email/Phone input field
- Password input field (obscured)
- "Remember Me" checkbox
- Login button
- "Forgot Password?" link
- "Sign Up" link

### Data Fetching
```dart
// Sign in with Supabase Auth
final response = await Supabase.instance.client.auth.signInWithPassword(
  email: emailController.text,
  password: passwordController.text,
);

if (response.session != null) {
  // Fetch user profile
  final user = await Supabase.instance.client
    .from('users')
    .select('*, tenants!inner(*), branches(*)')
    .eq('id', response.user!.id)
    .single();

  // Store user data in app state
  FFAppState().update(() {
    FFAppState().userId = user['id'];
    FFAppState().tenantId = user['tenant_id'];
    FFAppState().branchId = user['branch_id'];
    FFAppState().userRole = user['role'];
    FFAppState().tenantName = user['tenants']['name'];
  });

  // Navigate to Dashboard
  context.pushNamed('Dashboard');
}
```

### Navigation
- Success → Dashboard
- New user → Signup Page
- Forgot password → Password Reset Page

### FlutterFlow AI Prompt
```
Create a modern login page with:
- App logo at top
- Email/phone text field with icon
- Password field with show/hide toggle
- Checkbox for "Remember me"
- Primary button "Sign In" (full width, rounded)
- Text links for "Forgot Password?" and "Don't have an account? Sign Up"
- Social login buttons (Google, Apple) - optional
- Loading overlay when authenticating
- Error message display area
- Responsive design for mobile and tablet
```

---

## 3. Signup Page

### Purpose
Create new user account and business tenant.

### User Access
Everyone (unauthenticated)

### UI Components
- Full name input
- Email input
- Phone number input (with country code selector)
- Password input (with strength indicator)
- Confirm password input
- Country selector
- Terms & Conditions checkbox
- Sign Up button

### Data Fetching
```dart
// Step 1: Create auth user
final authResponse = await Supabase.instance.client.auth.signUp(
  email: emailController.text,
  password: passwordController.text,
  data: {
    'full_name': fullNameController.text,
    'phone': phoneController.text,
  },
);

// Step 2: User will be redirected to onboarding to create tenant
// The users table record is created automatically via database trigger
```

### Navigation
- Success → Onboarding - Business Info
- Already have account → Login Page

### FlutterFlow AI Prompt
```
Create a signup form with:
- "Create Account" header
- Form fields in a scrollable column:
  * Full Name (text field)
  * Email (email field with validation)
  * Phone Number (with country code dropdown)
  * Password (with strength meter)
  * Confirm Password (with match validation)
  * Country/Region dropdown
- Checkbox for "I agree to Terms & Conditions" with link
- Primary button "Create Account" (disabled until valid)
- Secondary text "Already have an account? Sign In"
- Form validation indicators
- Loading state during submission
- Success/error snackbar
```

---

## 4. Onboarding - Business Info

### Purpose
Collect business/tenant information after signup.

### User Access
New users who completed signup

### UI Components
- Business name input
- Business type dropdown (supermarket, pharmacy, grocery, mini_mart, restaurant)
- Business logo upload
- Brand color picker
- Phone number input
- Email input
- Continue button

### Data Fetching
```dart
// Create tenant record
final tenant = await Supabase.instance.client
  .from('tenants')
  .insert({
    'name': businessNameController.text,
    'slug': generateSlug(businessNameController.text),
    'email': emailController.text,
    'phone': phoneController.text,
    'logo_url': logoUrl,
    'brand_color': selectedColor,
    'country_code': selectedCountry,
    'dial_code': selectedDialCode,
    'currency_code': selectedCurrency,
  })
  .select()
  .single();

// Update user with tenant_id
await Supabase.instance.client
  .from('users')
  .update({'tenant_id': tenant['id']})
  .eq('id', currentUserId);

// Assign free subscription
await Supabase.instance.client
  .from('subscriptions')
  .update({'tenant_id': tenant['id']})
  .eq('plan_tier', 'free')
  .is_('tenant_id', null)
  .limit(1);
```

### Navigation
- Continue → Onboarding - Branch Setup

### FlutterFlow AI Prompt
```
Create an onboarding step 1 screen with:
- Progress indicator (Step 1 of 3)
- "Tell us about your business" heading
- Form fields:
  * Business Name (required)
  * Business Type dropdown (Supermarket, Pharmacy, Grocery, Mini Mart, Restaurant)
  * Upload Business Logo (image picker with preview)
  * Brand Color (color picker with preset swatches)
  * Business Phone
  * Business Email
- "Continue" button (primary, full width)
- "Skip for now" link
- Smooth transitions between fields
- Field validation with inline error messages
```

---

## 5. Onboarding - Branch Setup

### Purpose
Create first branch location.

### User Access
New tenants completing onboarding

### UI Components
- Branch name input
- Address text area
- Location picker (map or lat/lng)
- Phone number input
- Tax rate input (percentage)
- Currency dropdown
- Create Branch button

### Data Fetching
```dart
// Create first branch
final branch = await Supabase.instance.client
  .from('branches')
  .insert({
    'tenant_id': FFAppState().tenantId,
    'name': branchNameController.text,
    'business_type': selectedBusinessType,
    'address': addressController.text,
    'latitude': selectedLatitude,
    'longitude': selectedLongitude,
    'phone': phoneController.text,
    'tax_rate': taxRateController.text,
    'currency': selectedCurrency,
  })
  .select()
  .single();

// Update user with branch_id
await Supabase.instance.client
  .from('users')
  .update({
    'branch_id': branch['id'],
    'role': 'tenant_admin',
  })
  .eq('id', currentUserId);

// Store in app state
FFAppState().update(() {
  FFAppState().branchId = branch['id'];
  FFAppState().userRole = 'tenant_admin';
});
```

### Navigation
- Continue → Onboarding - Complete

### FlutterFlow AI Prompt
```
Create an onboarding step 2 screen with:
- Progress indicator (Step 2 of 3)
- "Set up your first store location" heading
- Form fields:
  * Branch/Store Name (required)
  * Address (multiline text field)
  * Location (map picker or coordinates input)
  * Phone Number
  * Tax Rate % (number input with % suffix)
  * Currency (dropdown: NGN, USD, etc.)
- "Continue" button (primary)
- "Back" button (secondary)
- Interactive map for location selection
- Validation indicators
```

---

## 6. Onboarding - Complete

### Purpose
Welcome screen and setup completion.

### User Access
New tenants completing onboarding

### UI Components
- Success icon/animation
- Welcome message
- Quick tips carousel
- "Get Started" button

### Navigation
- Get Started → Dashboard

### FlutterFlow AI Prompt
```
Create an onboarding completion screen with:
- Large checkmark or success animation
- "You're all set!" heading
- Welcome message with user's business name
- Quick tips carousel showing:
  * "Add your first product"
  * "Make your first sale"
  * "Invite your team"
- Primary button "Get Started"
- Confetti or celebration animation
- Smooth fade-in animations
```

---

## 7. Dashboard/Home

### Purpose
Main overview screen with key metrics and quick actions.

### User Access
All authenticated users (tenant_admin, branch_manager, cashier)

### RPC Functions Used
- `get_daily_sales_summary` - Fetch today's sales metrics
- `get_recent_sales` - Get last 5 transactions
- `get_low_stock_count` - Alert badge count

**📘 See [pos-rpc-functions.md](./pos-rpc-functions.md) for function definitions**

### UI Components
- Welcome header with user name and branch name
- Today's sales summary card
  - Total sales amount
  - Number of transactions
  - Average transaction value
- Quick action buttons
  - New Sale (large, prominent)
  - Add Product
  - View Inventory
  - View Reports (admin/manager only)
- Recent sales list (last 5 transactions)
- Low stock alerts badge
- Navigation drawer/bottom bar

### Data Fetching

```dart
// Fetch today's sales summary
final todaySales = await Supabase.instance.client
  .rpc('get_daily_sales_summary', params: {
    'p_tenant_id': FFAppState().tenantId,
    'p_branch_id': FFAppState().branchId,
    'p_date': DateTime.now().toIso8601String().split('T')[0],
  });

// Response: { total_amount, transaction_count, avg_transaction }

// Fetch recent sales
final recentSales = await Supabase.instance.client
  .from('sales')
  .select('id, sale_number, total_amount, created_at, payment_method')
  .eq('tenant_id', FFAppState().tenantId)
  .eq('branch_id', FFAppState().branchId)
  .order('created_at', ascending: false)
  .limit(5);

// Fetch low stock count
final lowStockCount = await Supabase.instance.client
  .from('product_stock_status')
  .select('product_id', const FetchOptions(count: CountOption.exact))
  .eq('tenant_id', FFAppState().tenantId)
  .eq('branch_id', FFAppState().branchId)
  .eq('stock_status', 'low_stock');

// lowStockCount.count
```

### Navigation
- New Sale → POS Sale Screen
- Add Product → Add Product
- View Inventory → Branch Inventory
- View Reports → Reports Dashboard
- Low Stock Alert → Low Stock Alerts
- Recent Sale Item → Sale Details
- Drawer Menu → Various pages

### FlutterFlow AI Prompt
```
Create a dashboard home screen with:
- App bar with:
  * Hamburger menu icon (left)
  * Branch name (center)
  * Notification bell icon (right)
- Welcome section: "Hello, [User Name]" with branch name subtitle
- Today's metrics card (elevated, with gradient background):
  * "Today's Sales" label
  * Large total amount (₦ format)
  * Two columns: "Transactions: X" | "Avg: ₦X"
- Quick actions grid (2x2):
  * "New Sale" (primary color, larger)
  * "Add Product"
  * "Inventory"
  * "Reports" (if admin/manager)
- "Recent Sales" section:
  * Section header with "View All" link
  * List of 5 sale cards showing sale number, amount, time
- Low stock alert banner (if count > 0)
- Floating action button for "New Sale" (always visible)
- Pull-to-refresh functionality
- Smooth animations for cards
```

---

## 8. POS Sale Screen

### Purpose
Primary sales transaction interface for cashiers.

### User Access
All roles (tenant_admin, branch_manager, cashier)

### RPC Functions Used
- `search_products_for_pos` - Search products with real-time stock
- `search_customers` - Quick customer lookup
- `complete_sale_transaction` - Atomic sale completion (handles inventory deduction, loyalty points)

**📘 See [pos-rpc-functions.md](./pos-rpc-functions.md) for function definitions**

### UI Components
- Product search bar with barcode scanner button
- Cart items list
  - Product name, quantity, unit price, subtotal
  - Quantity +/- buttons
  - Remove item button
- Cart summary panel
  - Subtotal
  - Tax amount
  - Discount input
  - Total (large, bold)
- Customer selection (optional)
  - Search existing customer
  - Quick add customer
- Payment method selector (cash, card, bank_transfer, mobile_money)
- Complete Sale button
- Clear Cart button

### Data Fetching

```dart
// Search products by name/SKU/barcode
final products = await Supabase.instance.client
  .from('v_branch_products')
  .select('*, products!inner(*)')
  .eq('branch_id', FFAppState().branchId)
  .eq('tenant_id', FFAppState().tenantId)
  .or('name.ilike.%$searchQuery%,sku.ilike.%$searchQuery%,barcode.eq.$searchQuery')
  .gt('stock_quantity', 0)
  .limit(20);

// Search customers
final customers = await Supabase.instance.client
  .from('customers')
  .select('id, full_name, phone, loyalty_points')
  .eq('tenant_id', FFAppState().tenantId)
  .or('full_name.ilike.%$searchQuery%,phone.ilike.%$searchQuery%')
  .limit(10);

// Complete sale transaction
final sale = await Supabase.instance.client
  .from('sales')
  .insert({
    'tenant_id': FFAppState().tenantId,
    'branch_id': FFAppState().branchId,
    'cashier_id': FFAppState().userId,
    'customer_id': selectedCustomerId,
    'subtotal': cartSubtotal,
    'tax_amount': taxAmount,
    'discount_amount': discountAmount,
    'total_amount': totalAmount,
    'payment_method': selectedPaymentMethod,
    'status': 'completed',
  })
  .select()
  .single();

// Insert sale items
final saleItems = cartItems.map((item) => {
  'sale_id': sale['id'],
  'tenant_id': FFAppState().tenantId,
  'product_id': item['product_id'],
  'product_name': item['name'],
  'quantity': item['quantity'],
  'unit_price': item['unit_price'],
  'discount_amount': item['discount'],
  'subtotal': item['subtotal'],
}).toList();

await Supabase.instance.client
  .from('sale_items')
  .insert(saleItems);

// Inventory will auto-update via database trigger
// Customer loyalty points will auto-update via trigger
```

### Navigation
- Product Search → Product Selection
- Customer Search → Customer Selection
- Complete Sale → Sale Receipt/Confirmation
- Back → Dashboard

### State Management
- Cart state (list of items, quantities, prices)
- Selected customer
- Payment method
- Discount applied

### FlutterFlow AI Prompt
```
Create a POS sale screen with split layout:

LEFT PANEL (Product Selection):
- Search bar with barcode scanner icon
- Product search results (grid or list)
- Each product card shows: image, name, price, stock level
- Tap to add to cart

RIGHT PANEL (Cart & Checkout):
- "Cart" header with item count
- Scrollable cart items list:
  * Product name
  * Quantity controls (-, count, +)
  * Unit price × Quantity = Subtotal
  * Remove icon
- Cart summary section:
  * Subtotal row
  * Tax row (calculated)
  * Discount input field
  * TOTAL (large, bold, highlighted)
- Customer selection:
  * "Select Customer" button (optional)
  * Shows selected customer name + loyalty points
- Payment method chips (Cash, Card, Transfer, Mobile Money)
- Two action buttons:
  * "Clear Cart" (outlined, red)
  * "Complete Sale" (filled, primary, large)
- Loading overlay during transaction
- Success animation on completion

Responsive: Stack vertically on mobile, side-by-side on tablet
Include barcode scanner camera integration
Keyboard shortcuts for desktop
Offline-capable with sync indicator
```

---

## 9. Products Management

### Purpose
View and manage tenant-wide product catalog.

### User Access
tenant_admin, branch_manager

### UI Components
- Search bar
- Filter chips (category, active/inactive, low stock)
- Sort dropdown (name, price, created date)
- Product list/grid
  - Product image
  - Name
  - SKU
  - Category
  - Unit price
  - Total stock (across branches)
  - Edit button
- Add Product FAB
- Bulk actions (if multiple selected)

### Data Fetching

```dart
// Fetch products with aggregated stock
final products = await Supabase.instance.client
  .from('products')
  .select('''
    *,
    branch_inventory (
      stock_quantity,
      reserved_quantity,
      branch:branches (name)
    )
  ''')
  .eq('tenant_id', FFAppState().tenantId)
  .eq('_sync_is_deleted', false)
  .order('name', ascending: true);

// Calculate total stock per product
final productsWithStock = products.map((product) {
  final totalStock = product['branch_inventory']
    .fold(0, (sum, inv) => sum + inv['stock_quantity']);
  return {
    ...product,
    'total_stock': totalStock,
    'branch_count': product['branch_inventory'].length,
  };
}).toList();

// Filter by category
final filteredProducts = await Supabase.instance.client
  .from('products')
  .select('*')
  .eq('tenant_id', FFAppState().tenantId)
  .eq('category', selectedCategory)
  .eq('_sync_is_deleted', false);
```

### Navigation
- Add Product → Add Product Page
- Product Item → Product Details/Edit
- Search → Filtered Results

### FlutterFlow AI Prompt
```
Create a products management screen with:
- App bar with "Products" title and search icon
- Search bar (expandable from icon)
- Filter row with chips:
  * All Categories
  * Category filters (dynamic from categories)
  * Active/Inactive toggle
  * Low Stock filter
- Sort dropdown (Name, Price, Stock, Date Added)
- Product list (or grid toggle):
  * Product card with:
    - Product image (placeholder if none)
    - Product name (bold)
    - SKU and category (small text)
    - Price (prominent)
    - Total stock across branches (with badge)
    - Edit icon button
- Empty state: "No products found. Add your first product!"
- Floating Action Button "Add Product" (primary color)
- Pull-to-refresh
- Pagination or infinite scroll
- Multi-select mode for bulk actions
- Smooth list animations
```

---

## 10. Product Details/Edit

### Purpose
View and edit product information.

### User Access
tenant_admin, branch_manager

### UI Components
- Product image display/upload
- Editable fields:
  - Product name
  - Description
  - SKU
  - Barcode
  - Category dropdown
  - Unit price
  - Cost price
- Stock by branch section
  - List of branches with stock levels
  - Link to adjust stock
- Save button
- Delete button (with confirmation)
- Cancel button

### Data Fetching

```dart
// Fetch product details
final product = await Supabase.instance.client
  .from('products')
  .select('''
    *,
    branch_inventory (
      *,
      branch:branches (id, name)
    )
  ''')
  .eq('id', productId)
  .single();

// Update product
await Supabase.instance.client
  .from('products')
  .update({
    'name': nameController.text,
    'description': descriptionController.text,
    'sku': skuController.text,
    'barcode': barcodeController.text,
    'category': selectedCategory,
    'unit_price': unitPriceController.text,
    'cost_price': costPriceController.text,
    'image_url': uploadedImageUrl,
  })
  .eq('id', productId);

// Delete product (soft delete)
await Supabase.instance.client
  .from('products')
  .update({
    '_sync_is_deleted': true,
    'deleted_at': DateTime.now().toIso8601String(),
  })
  .eq('id', productId);
```

### Navigation
- Back → Products List
- Save → Products List (with success message)
- Branch Stock Item → Branch Inventory (filtered)
- Delete (confirmed) → Products List

### FlutterFlow AI Prompt
```
Create a product details/edit screen with:
- App bar with "Edit Product" title and delete icon
- Scrollable form with sections:

SECTION 1: Product Image
- Large product image display (tap to change)
- Camera/gallery picker

SECTION 2: Basic Information
- Product Name (text field, required)
- Description (multiline, optional)
- Category (dropdown or autocomplete)

SECTION 3: Identification
- SKU (text field with generate button)
- Barcode (text field with scanner button)

SECTION 4: Pricing
- Unit Price (currency input, required)
- Cost Price (currency input, for margin calc)
- Margin % (calculated, read-only, highlighted if low)

SECTION 5: Stock by Branch
- "Stock Across Branches" header
- List of branch cards:
  * Branch name
  * Stock quantity (colored by level: green/yellow/red)
  * "Adjust Stock" link
- Total stock summary

SECTION 6: Actions
- Two buttons:
  * "Save Changes" (primary, full width)
  * "Delete Product" (danger, outlined)

- Confirmation dialog for delete
- Validation indicators
- Unsaved changes warning
- Loading states
```

---

## 11. Add Product

### Purpose
Create new product in tenant catalog.

### User Access
tenant_admin, branch_manager

### UI Components
- Same as Product Edit, but with:
  - "Add Product" title
  - Initial stock setup for current/selected branch
  - Create button instead of Save

### Data Fetching

```dart
// Create product
final product = await Supabase.instance.client
  .from('products')
  .insert({
    'tenant_id': FFAppState().tenantId,
    'name': nameController.text,
    'description': descriptionController.text,
    'sku': skuController.text,
    'barcode': barcodeController.text,
    'category': selectedCategory,
    'unit_price': unitPriceController.text,
    'cost_price': costPriceController.text,
    'image_url': uploadedImageUrl,
    'is_active': true,
  })
  .select()
  .single();

// Create initial branch inventory
await Supabase.instance.client
  .from('branch_inventory')
  .insert({
    'tenant_id': FFAppState().tenantId,
    'branch_id': FFAppState().branchId,
    'product_id': product['id'],
    'stock_quantity': initialStockController.text,
    'low_stock_threshold': lowStockController.text,
  });
```

### Navigation
- Cancel → Products List
- Create → Products List (with success message)

### FlutterFlow AI Prompt
```
Create an add product screen similar to edit product, but with:
- "Add New Product" title
- All fields empty/default values
- Additional section:
  * "Initial Stock" header
  * Branch selector (if multi-branch tenant)
  * Stock Quantity (number input, required)
  * Low Stock Threshold (number input, default 10)
  * Expiry Date (date picker, optional)
- "Create Product" button (primary, full width)
- "Cancel" button (secondary)
- Stepper progress indicator (optional for multi-step)
- Auto-generate SKU option
- Import from barcode feature
- Duplicate product detection warning
```

---

## 12. Branch Inventory

### Purpose
View and manage stock levels for current branch.

### User Access
All roles (view), branch_manager and above (edit)

### UI Components
- Branch selector (tenant_admin sees all branches)
- Search and filter (category, stock status)
- Inventory list
  - Product name
  - Current stock (colored: green/yellow/red)
  - Reserved quantity
  - Available quantity
  - Low stock threshold
  - Expiry date (if applicable)
  - Adjust button
- Stock status filter chips (All, In Stock, Low Stock, Out of Stock)
- Export button (admin/manager)

### Data Fetching

```dart
// Fetch branch inventory with product details
final inventory = await Supabase.instance.client
  .from('branch_inventory')
  .select('''
    *,
    product:products (
      id, name, sku, category, unit_price, cost_price, image_url
    )
  ''')
  .eq('tenant_id', FFAppState().tenantId)
  .eq('branch_id', FFAppState().branchId)
  .eq('is_active', true)
  .order('product.name', ascending: true);

// Calculate stock status for each item
final inventoryWithStatus = inventory.map((item) {
  final available = item['stock_quantity'] - item['reserved_quantity'];
  final threshold = item['low_stock_threshold'] ?? 10;

  String status;
  if (available <= 0) {
    status = 'out_of_stock';
  } else if (available <= threshold) {
    status = 'low_stock';
  } else {
    status = 'in_stock';
  }

  return {
    ...item,
    'available_quantity': available,
    'stock_status': status,
  };
}).toList();

// Filter by stock status
final lowStockItems = await Supabase.instance.client
  .from('product_stock_status')
  .select('*')
  .eq('tenant_id', FFAppState().tenantId)
  .eq('branch_id', FFAppState().branchId)
  .eq('stock_status', 'low_stock');
```

### Navigation
- Adjust Stock → Adjust Stock Page
- Product Item → Product Details
- Branch Selector → Reload with new branch

### FlutterFlow AI Prompt
```
Create a branch inventory screen with:
- App bar with "Inventory" title and branch dropdown (if admin)
- Search bar
- Filter chips row:
  * All Items (count)
  * In Stock (green badge)
  * Low Stock (yellow badge)
  * Out of Stock (red badge)
- Sort dropdown (Name, Stock Level, Value)
- Inventory list items:
  * Product image thumbnail
  * Product name and category
  * Stock level with color coding:
    - Green (> threshold): "In Stock: X units"
    - Yellow (≤ threshold): "Low Stock: X units"
    - Red (0): "Out of Stock"
  * Reserved: X (if > 0)
  * Available: X (calculated)
  * Expiry date (if set, highlight if expiring soon)
  * "Adjust" button
- Summary card at top:
  * Total items
  * Total value (cost × quantity)
  * Items needing reorder
- Export button (CSV/PDF) for managers
- Floating action button for quick stock adjustment
- Pull-to-refresh
- Offline indicator with last sync time
```

---

## 13. Adjust Stock

### Purpose
Adjust inventory levels for a product at a branch.

### User Access
branch_manager, tenant_admin

### UI Components
- Product information display (read-only)
  - Name, SKU, current stock
- Adjustment type selector
  - Add Stock (restock)
  - Remove Stock (adjustment, expiry, damage)
  - Set Stock (direct set)
- Quantity input
- Reason/notes text area
- New stock level preview (calculated)
- Confirm button
- Cancel button

### Data Fetching

```dart
// Get current stock
final currentInventory = await Supabase.instance.client
  .from('branch_inventory')
  .select('stock_quantity, reserved_quantity')
  .eq('branch_id', FFAppState().branchId)
  .eq('product_id', productId)
  .single();

// Create inventory transaction
final transaction = await Supabase.instance.client
  .from('inventory_transactions')
  .insert({
    'tenant_id': FFAppState().tenantId,
    'branch_id': FFAppState().branchId,
    'product_id': productId,
    'transaction_type': selectedType, // 'restock', 'adjustment', 'expiry'
    'quantity_delta': quantityDelta, // +10 or -5
    'previous_quantity': currentInventory['stock_quantity'],
    'new_quantity': currentInventory['stock_quantity'] + quantityDelta,
    'notes': notesController.text,
    'staff_id': FFAppState().userId,
  })
  .select()
  .single();

// Branch inventory will auto-update via database trigger
```

### Navigation
- Confirm → Branch Inventory (with success message)
- Cancel → Back to previous page

### FlutterFlow AI Prompt
```
Create a stock adjustment dialog/page with:
- "Adjust Stock" header
- Product info card (read-only):
  * Product image
  * Product name
  * Current Stock: X units (large)
  * Reserved: X units (if > 0)
  * Available: X units (highlighted)

- Adjustment section:
  * "Adjustment Type" segmented control:
    - Add Stock (green, + icon)
    - Remove Stock (red, - icon)
    - Set Stock (blue, = icon)
  * Quantity input (large number field)
    - Show +/- based on type
  * Reason dropdown:
    - For Add: Restock, Purchase, Transfer In
    - For Remove: Sale, Damage, Expiry, Transfer Out, Adjustment
    - For Set: Stock Count, Correction
  * Notes (optional multiline)

- Preview section:
  * Current Stock → New Stock
  * Visual arrow or animation
  * New stock highlighted in color (green if increase, red if decrease)

- Action buttons:
  * "Cancel" (secondary)
  * "Confirm Adjustment" (primary, disabled until valid)

- Confirmation required if large adjustment (> 100 units or > 50% change)
- Loading state during save
- Success animation
```

---

## 14. Sales History

### Purpose
View all completed sales transactions.

### User Access
All roles (filtered by branch for cashiers)

### UI Components
- Date range selector
- Search bar (sale number, customer)
- Filter chips (payment method, today/week/month)
- Sales list
  - Sale number
  - Date and time
  - Customer name (if any)
  - Total amount
  - Payment method badge
  - Status (completed/voided/refunded)
- Summary card
  - Total sales in period
  - Transaction count
  - Average transaction value
- Export button (manager/admin)

### Data Fetching

```dart
// Fetch sales with filters
final sales = await Supabase.instance.client
  .from('sales')
  .select('''
    *,
    customer:customers (full_name, phone),
    cashier:users!cashier_id (full_name)
  ''')
  .eq('tenant_id', FFAppState().tenantId)
  .eq('branch_id', FFAppState().branchId)
  .gte('created_at', startDate.toIso8601String())
  .lte('created_at', endDate.toIso8601String())
  .order('created_at', ascending: false)
  .limit(50);

// Calculate summary
final summary = await Supabase.instance.client
  .rpc('get_sales_summary', params: {
    'p_tenant_id': FFAppState().tenantId,
    'p_branch_id': FFAppState().branchId,
    'p_start_date': startDate.toIso8601String().split('T')[0],
    'p_end_date': endDate.toIso8601String().split('T')[0],
  });

// Response: { total_amount, transaction_count, avg_transaction }

// Filter by payment method
final filteredSales = await Supabase.instance.client
  .from('sales')
  .select('*')
  .eq('tenant_id', FFAppState().tenantId)
  .eq('branch_id', FFAppState().branchId)
  .eq('payment_method', selectedPaymentMethod)
  .gte('created_at', startDate.toIso8601String())
  .order('created_at', ascending: false);
```

### Navigation
- Sale Item → Sale Details
- Date Range → Filtered Results
- Export → Generate Report

### FlutterFlow AI Prompt
```
Create a sales history screen with:
- App bar with "Sales History" title and filter/export icons
- Summary card at top:
  * Total Sales (large amount)
  * Transactions: X
  * Average: ₦X
  * Date range label

- Filter section:
  * Date range selector (Today, This Week, This Month, Custom)
  * Payment method chips (All, Cash, Card, Transfer, Mobile)
  * Search bar (sale number or customer name)

- Sales list:
  * Each sale card shows:
    - Sale number (bold, primary color)
    - Date and time (small, grey)
    - Customer name (if exists, with icon)
    - Payment method badge (chip/tag)
    - Total amount (large, right-aligned)
    - Status indicator (completed/voided/refunded)
  * Tap to view details
  * Swipe actions: View Receipt, Void Sale (manager only)

- Empty state: "No sales in this period"
- Load more button or infinite scroll
- Pull-to-refresh
- Floating action button "New Sale"
- Export dialog (CSV, PDF) for managers
```

---

## 15. Sale Details

### Purpose
View complete details of a sale transaction.

### User Access
All roles (can view sales from their branch)

### UI Components
- Sale header
  - Sale number
  - Date and time
  - Status badge
- Customer information (if applicable)
- Sale items list
  - Product name
  - Quantity × Unit Price
  - Subtotal
- Summary
  - Subtotal
  - Tax
  - Discount
  - Total
- Payment information
  - Method
  - Reference (if any)
- Cashier information
- Action buttons
  - Print Receipt
  - Email Receipt
  - Void Sale (manager only, if not already voided)
  - Refund (if supported)

### Data Fetching

```dart
// Fetch sale with all details
final sale = await Supabase.instance.client
  .from('sales')
  .select('''
    *,
    customer:customers (id, full_name, phone, email),
    cashier:users!cashier_id (full_name),
    branch:branches (name, address, phone),
    sale_items (
      *,
      product:products (name, sku)
    )
  ''')
  .eq('id', saleId)
  .single();

// Fetch receipt if exists
final receipt = await Supabase.instance.client
  .from('receipts')
  .select('receipt_number, file_url, email_sent_to, email_sent_at')
  .eq('sale_id', saleId)
  .maybeSingle();

// Void sale (manager only)
await Supabase.instance.client
  .from('sales')
  .update({
    'status': 'voided',
    'voided_at': DateTime.now().toIso8601String(),
    'voided_by_id': FFAppState().userId,
    'void_reason': reasonController.text,
  })
  .eq('id', saleId);
```

### Navigation
- Back → Sales History
- Customer Name → Customer Details
- Print Receipt → Receipt View/Print
- Void Sale → Confirmation Dialog → Sales History

### FlutterFlow AI Prompt
```
Create a sale details screen with:
- App bar with "Sale Details" and action icons (print, email)
- Sale header card:
  * Sale number (large, bold)
  * Date and time
  * Status badge (Completed/Voided/Refunded)
  * Branch name

- Customer section (if applicable):
  * Customer name with avatar
  * Phone number
  * Email (if available)
  * Loyalty points earned (highlighted)

- Items section:
  * "Items Purchased" header
  * List of items:
    - Product name
    - Quantity × Unit Price = Subtotal
    - Discount (if any, shown in red)
  * Divider

- Summary section:
  * Subtotal
  * Tax (X%)
  * Discount
  * Total (large, bold, highlighted)

- Payment section:
  * Payment Method (with icon)
  * Reference Number (if exists)
  * Paid Amount

- Staff section:
  * Cashier name
  * Transaction time

- Action buttons (bottom):
  * "Print Receipt" (outlined)
  * "Email Receipt" (outlined)
  * "Void Sale" (danger, only if manager and not voided)

- Void confirmation dialog with reason input
- Receipt preview/print dialog
- Email sent success message
```

---

## 16. Customers List

### Purpose
View and manage customer database.

### User Access
All roles

### UI Components
- Search bar (name, phone, email)
- Sort dropdown (name, loyalty points, last purchase)
- Filter chips (has purchases, high loyalty)
- Customer list
  - Avatar or initials
  - Name
  - Phone number
  - Loyalty points badge
  - Last purchase date
  - Total purchases amount
- Add Customer button

### Data Fetching

```dart
// Fetch customers
final customers = await Supabase.instance.client
  .from('customers')
  .select('*')
  .eq('tenant_id', FFAppState().tenantId)
  .eq('_sync_is_deleted', false)
  .order('created_at', ascending: false);

// Search customers
final searchResults = await Supabase.instance.client
  .from('customers')
  .select('*')
  .eq('tenant_id', FFAppState().tenantId)
  .or('full_name.ilike.%$query%,phone.ilike.%$query%,email.ilike.%$query%')
  .limit(20);

// Filter by loyalty
final loyalCustomers = await Supabase.instance.client
  .from('customers')
  .select('*')
  .eq('tenant_id', FFAppState().tenantId)
  .gte('loyalty_points', 100)
  .order('loyalty_points', ascending: false);
```

### Navigation
- Customer Item → Customer Details
- Add Customer → Add/Edit Customer Page
- Search → Filtered Results

### FlutterFlow AI Prompt
```
Create a customers list screen with:
- App bar with "Customers" title and search icon
- Search bar (expandable)
- Filter/sort row:
  * All Customers (count)
  * Active (has purchases)
  * High Loyalty (> 100 points)
  * Sort by: Name, Loyalty, Recent

- Customer list items:
  * Avatar (initials if no image)
  * Customer name (bold)
  * Phone number (with call icon)
  * Loyalty points badge (if > 0, gold star icon)
  * Last purchase: "X days ago"
  * Total spent: ₦X (small, grey)
  * Right arrow for details

- Summary card at top:
  * Total Customers
  * Active Customers (purchased in last 30 days)
  * Average Loyalty Points

- Floating action button "Add Customer"
- Empty state: "No customers yet. Add your first customer!"
- Pull-to-refresh
- Swipe actions: Call, Message, View Details
- Alphabet scroll bar (optional)
```

---

## 17. Customer Details

### Purpose
View customer information, purchase history, and loyalty points.

### User Access
All roles

### UI Components
- Customer header
  - Avatar/photo
  - Name
  - Phone, email
  - Loyalty points (prominent)
- Contact actions (call, email, WhatsApp)
- Stats cards
  - Total purchases
  - Purchase count
  - Last purchase date
  - Average transaction
- Purchase history list
  - Recent sales with this customer
- Loyalty transactions (if applicable)
- Edit button
- Delete button (manager/admin)

### Data Fetching

```dart
// Fetch customer with stats
final customer = await Supabase.instance.client
  .from('customers')
  .select('*')
  .eq('id', customerId)
  .single();

// Fetch customer's sales
final customerSales = await Supabase.instance.client
  .from('sales')
  .select('id, sale_number, total_amount, created_at, payment_method')
  .eq('tenant_id', FFAppState().tenantId)
  .eq('customer_id', customerId)
  .order('created_at', ascending: false)
  .limit(10);

// Stats are already in customer record:
// - loyalty_points
// - total_purchases
// - purchase_count
// - last_purchase_at
```

### Navigation
- Edit → Add/Edit Customer Page
- Purchase Item → Sale Details
- Back → Customers List
- Call/Email → External app
- Delete (confirmed) → Customers List

### FlutterFlow AI Prompt
```
Create a customer details screen with:
- App bar with "Customer Details" and edit/delete icons
- Header section:
  * Large avatar (with edit overlay)
  * Customer name (large, bold)
  * Phone number (with call icon button)
  * Email (with email icon button)
  * WhatsApp button (if whatsapp_number exists)

- Loyalty section (highlighted card):
  * "Loyalty Points" label
  * Large points number (with star icon)
  * Points value: ₦X (if redeemable)
  * Progress bar to next reward (optional)

- Stats grid (2x2):
  * Total Spent: ₦X
  * Purchases: X
  * Average Order: ₦X
  * Last Visit: X days ago

- Addresses section (if applicable):
  * "Saved Addresses" header
  * List of addresses with default badge
  * Add address button

- Purchase history section:
  * "Recent Purchases" header with "View All" link
  * List of recent sales (last 5):
    - Sale number
    - Date
    - Amount
    - Payment method
  * Tap to view sale details

- Action buttons (bottom):
  * "Edit Customer" (outlined)
  * "Delete Customer" (danger, outlined, manager only)

- Delete confirmation dialog
- Contact action sheet (Call, SMS, Email, WhatsApp)
```

---

## 18. Add/Edit Customer

### Purpose
Create or update customer information.

### User Access
All roles

### UI Components
- Customer photo upload
- Basic info
  - Full name (required)
  - Phone number (required)
  - Email (optional)
  - WhatsApp number (optional)
- Addresses section
  - Add address button
  - Address list (if editing)
- Notes text area
- Save button
- Cancel button

### Data Fetching

```dart
// Create customer
final customer = await Supabase.instance.client
  .from('customers')
  .insert({
    'tenant_id': FFAppState().tenantId,
    'full_name': nameController.text,
    'phone': phoneController.text,
    'email': emailController.text,
    'whatsapp_number': whatsappController.text,
  })
  .select()
  .single();

// Update customer
await Supabase.instance.client
  .from('customers')
  .update({
    'full_name': nameController.text,
    'phone': phoneController.text,
    'email': emailController.text,
    'whatsapp_number': whatsappController.text,
  })
  .eq('id', customerId);

// Add customer address
await Supabase.instance.client
  .from('customer_addresses')
  .insert({
    'customer_id': customerId,
    'label': labelController.text, // e.g., "Home", "Office"
    'address_line': addressController.text,
    'latitude': selectedLat,
    'longitude': selectedLng,
    'is_default': isDefault,
  });
```

### Navigation
- Save → Customer Details (if editing) or Customers List (if new)
- Cancel → Previous page

### FlutterFlow AI Prompt
```
Create an add/edit customer form with:
- App bar with "Add Customer" or "Edit Customer" title
- Scrollable form with sections:

SECTION 1: Photo
- Avatar display (tap to change)
- Camera/gallery picker

SECTION 2: Basic Information
- Full Name (text field, required)
- Phone Number (with country code, required)
- Email (email field, optional)
- WhatsApp Number (phone field, optional)

SECTION 3: Addresses
- "Delivery Addresses" header
- Add Address button
- List of addresses (if editing):
  * Address label (Home, Office, etc.)
  * Address text
  * Default badge
  * Edit/Delete icons
- Address form fields (expandable):
  * Label
  * Address (multiline)
  * Location picker (map)
  * Set as Default checkbox

SECTION 4: Notes
- Notes (multiline, optional)

Action buttons (bottom, sticky):
- "Cancel" (secondary)
- "Save Customer" (primary, full width)

- Form validation
- Phone number formatting
- Duplicate detection warning
- Loading state during save
- Success animation
```

---

## 19. Reports Dashboard

### Purpose
Overview of business analytics and reports.

### User Access
tenant_admin, branch_manager

### UI Components
- Date range selector (defaults to current month)
- Report cards (tap to view details)
  - Sales Report
  - Inventory Report
  - Customer Report
  - Staff Performance
  - Profit & Loss
- Quick stats grid
  - Total revenue
  - Total profit
  - Items sold
  - Customers served
- Charts
  - Sales trend (line chart)
  - Top products (bar chart)
  - Payment methods (pie chart)
- Export All button

### Data Fetching

```dart
// Fetch sales summary
final salesSummary = await Supabase.instance.client
  .rpc('get_sales_summary', params: {
    'p_tenant_id': FFAppState().tenantId,
    'p_branch_id': FFAppState().branchId,
    'p_start_date': startDate.toIso8601String().split('T')[0],
    'p_end_date': endDate.toIso8601String().split('T')[0],
  });

// Fetch daily sales for trend
final dailySales = await Supabase.instance.client
  .rpc('get_daily_sales_trend', params: {
    'p_tenant_id': FFAppState().tenantId,
    'p_branch_id': FFAppState().branchId,
    'p_start_date': startDate.toIso8601String().split('T')[0],
    'p_end_date': endDate.toIso8601String().split('T')[0],
  });

// Fetch top products
final topProducts = await Supabase.instance.client
  .from('sale_items')
  .select('product_id, product_name, quantity, subtotal')
  .eq('tenant_id', FFAppState().tenantId)
  .gte('created_at', startDate.toIso8601String())
  .lte('created_at', endDate.toIso8601String())
  .order('quantity', ascending: false)
  .limit(10);

// Group by product and sum quantities
```

### Navigation
- Sales Report Card → Sales Report
- Inventory Report Card → Inventory Report
- Chart → Detailed Report
- Export → Generate PDF/CSV

### FlutterFlow AI Prompt
```
Create a reports dashboard with:
- App bar with "Reports" title and date range button
- Date range selector (sheet/dialog):
  * Today
  * This Week
  * This Month
  * Custom Range (date pickers)

- Quick stats grid (2x2):
  * Revenue: ₦X (with trend arrow)
  * Profit: ₦X (with margin %)
  * Items Sold: X
  * Customers: X

- Report cards (grid or list):
  * Sales Report card:
    - Icon
    - "Sales Report" title
    - Quick summary: "₦X in Y transactions"
    - Arrow icon
  * Inventory Report card:
    - Icon
    - "Inventory Report"
    - "X items, ₦X value"
  * Customer Report card:
    - Icon
    - "Customer Report"
    - "X customers, Y active"
  * Staff Performance card (if manager+):
    - Icon
    - "Staff Performance"
    - "X staff members"

- Charts section:
  * "Sales Trend" line chart (daily/weekly sales)
  * "Top Products" horizontal bar chart
  * "Payment Methods" pie/donut chart

- Export button (floating or bottom)
- Pull-to-refresh
- Loading skeleton for charts
- Empty state for no data
```

---

## 20. Sales Report

### Purpose
Detailed sales analytics and breakdown.

### User Access
tenant_admin, branch_manager

### UI Components
- Date range filter
- Branch filter (if tenant_admin)
- Summary cards
  - Total sales
  - Total transactions
  - Average transaction
  - Sales growth %
- Sales by time chart (hourly, daily, weekly)
- Sales by payment method
- Sales by cashier (manager view)
- Top selling products
- Export button (PDF, CSV, Excel)

### Data Fetching
```dart
// Use same queries as Reports Dashboard but more detailed
// Add breakdown by hour, day of week, payment method, cashier
```

### FlutterFlow AI Prompt
```
Create a detailed sales report screen with:
- Filters bar (date range, branch, cashier)
- Summary section (4 cards)
- Multiple chart sections with headers
- Expandable lists for details
- Export options
- Print preview
```

---

## 21. Inventory Report

### Purpose
Stock valuation, turnover, and inventory health.

### User Access
tenant_admin, branch_manager

### UI Components
- Stock valuation card
- Inventory turnover metrics
- Stock aging analysis
- Low stock items
- Overstock items
- Dead stock (no movement)
- Expiring items

### Data Fetching
```dart
// Fetch stock valuation
final valuation = await Supabase.instance.client
  .rpc('calculate_inventory_value', params: {
    'p_tenant_id': FFAppState().tenantId,
    'p_branch_id': FFAppState().branchId,
  });
```

### FlutterFlow AI Prompt
```
Create an inventory report with:
- Valuation summary at top
- Multiple sections for different inventory statuses
- Charts for stock distribution
- Action buttons for each section
```

---

## 22. Low Stock Alerts

### Purpose
Monitor products that need reordering.

### User Access
tenant_admin, branch_manager

### UI Components
- Alert count badge
- Urgency filter (critical, warning, info)
- Low stock items list
  - Product name
  - Current stock
  - Threshold
  - Suggested reorder quantity
  - Quick action buttons
- Bulk reorder button

### Data Fetching
```dart
// Fetch low stock items
final lowStock = await Supabase.instance.client
  .from('product_stock_status')
  .select('*')
  .eq('tenant_id', FFAppState().tenantId)
  .eq('branch_id', FFAppState().branchId)
  .in_('stock_status', ['low_stock', 'out_of_stock'])
  .order('available_quantity', ascending: true);
```

### FlutterFlow AI Prompt
```
Create a low stock alerts screen with:
- Alert summary card
- Urgency filters
- Scrollable alerts list with action buttons
- Bulk actions footer
```

---

## 23. Branches List

### Purpose
View all branches (tenant admin only).

### User Access
tenant_admin only

### UI Components
- Branch cards
  - Name
  - Address
  - Phone
  - Manager name
  - Staff count
  - Stock value
  - Status (active/inactive)
- Add Branch button

### FlutterFlow AI Prompt
```
Create a branches list with:
- Branch cards showing key info
- Status indicators
- Quick stats per branch
- Add branch FAB
```

---

## 24. Branch Details/Edit

### Purpose
View and edit branch information.

### User Access
tenant_admin

### FlutterFlow AI Prompt
```
Create a branch details form similar to product edit:
- Branch info fields
- Manager assignment
- Staff list
- Inventory summary
- Edit/delete actions
```

---

## 25. Add Branch

### Purpose
Create new branch location.

### User Access
tenant_admin (if plan allows)

### FlutterFlow AI Prompt
```
Create an add branch form with:
- Branch details
- Location picker
- Manager assignment
- Initial setup options
```

---

## 26. Staff Management

### Purpose
View and manage staff users.

### User Access
tenant_admin, branch_manager (limited to their branch)

### UI Components
- Staff list
  - Avatar
  - Name
  - Role badge
  - Branch assignment
  - Status (active/invited)
  - Last active
- Invite Staff button
- Role filter chips

### Data Fetching
```dart
// Fetch staff
final staff = await Supabase.instance.client
  .from('users')
  .select('''
    *,
    branch:branches (name)
  ''')
  .eq('tenant_id', FFAppState().tenantId)
  .order('full_name', ascending: true);

// If branch manager, filter by branch
if (FFAppState().userRole == 'branch_manager') {
  staff = staff.where((s) => s['branch_id'] == FFAppState().branchId);
}
```

### FlutterFlow AI Prompt
```
Create a staff management screen with:
- Staff list with role badges
- Invite button
- Filter by role and branch
- Quick actions per staff member
```

---

## 27. Add/Invite Staff

### Purpose
Invite new staff member.

### User Access
tenant_admin, branch_manager

### UI Components
- Email input
- Role selector
- Branch assignment
- Send Invite button

### Data Fetching
```dart
// Create staff invite
final invite = await Supabase.instance.client
  .from('staff_invites')
  .insert({
    'tenant_id': FFAppState().tenantId,
    'email': emailController.text,
    'assigned_role': selectedRole,
    'branch_id': selectedBranchId,
    'invite_token': generateToken(),
    'invite_url': generateInviteUrl(),
    'expires_at': DateTime.now().add(Duration(days: 7)).toIso8601String(),
    'created_by_user_id': FFAppState().userId,
  })
  .select()
  .single();

// Send email (via Edge Function or external service)
```

### FlutterFlow AI Prompt
```
Create an invite staff form with:
- Email input
- Role selector (dropdown)
- Branch assignment
- Preview of invite email
- Send button
```

---

## 28. Inter-Branch Transfer

### Purpose
Transfer stock between branches.

### User Access
tenant_admin, branch_manager (source branch)

### UI Components
- Source branch (current/selected)
- Destination branch selector
- Product selector with stock levels
- Quantity inputs
- Notes
- Submit Transfer button

### Data Fetching
```dart
// Create transfer
final transfer = await Supabase.instance.client
  .from('inter_branch_transfers')
  .insert({
    'tenant_id': FFAppState().tenantId,
    'source_branch_id': FFAppState().branchId,
    'destination_branch_id': destinationBranchId,
    'status': 'pending',
    'notes': notesController.text,
    'authorized_by_id': FFAppState().userId,
  })
  .select()
  .single();

// Create transfer items
final items = selectedProducts.map((p) => {
  'transfer_id': transfer['id'],
  'product_id': p['product_id'],
  'quantity': p['quantity'],
}).toList();

await Supabase.instance.client
  .from('transfer_items')
  .insert(items);
```

### FlutterFlow AI Prompt
```
Create an inter-branch transfer form with:
- Branch selectors
- Product picker with current stock
- Quantity inputs per product
- Transfer summary
- Confirmation dialog
```

---

## 29. Transfer History

### Purpose
View all inter-branch transfers.

### User Access
tenant_admin, branch_manager

### FlutterFlow AI Prompt
```
Create a transfer history screen with:
- Transfer list with status
- Filter by status and branch
- Transfer details on tap
```

---

## 30. Settings

### Purpose
App configuration and preferences.

### User Access
All users

### UI Components
- General settings
  - Language
  - Currency display
  - Date format
  - Receipt format
- Business settings (admin only)
  - Tax rate
  - Loyalty program toggle
  - Receipt footer text
- Notifications
  - Low stock alerts
  - Sales notifications
- About
  - App version
  - Terms & Conditions
  - Privacy Policy
- Logout button

### FlutterFlow AI Prompt
```
Create a settings screen with:
- Grouped settings list
- Toggle switches
- Navigation to detail pages
- Logout button at bottom
```

---

## 31. Profile

### Purpose
View and edit user profile.

### User Access
All users

### UI Components
- Avatar upload
- Name, email, phone
- Branch assignment (read-only for non-admin)
- Password change button
- Logout button

### FlutterFlow AI Prompt
```
Create a profile screen with:
- Avatar at top
- Editable fields
- Password change link
- Logout button
```

---

## 32. Subscription & Billing

### Purpose
View and manage subscription plan.

### User Access
tenant_admin only

### UI Components
- Current plan card
- Plan features list
- Usage statistics
- Upgrade button
- Billing history
- Invoice list

### FlutterFlow AI Prompt
```
Create a subscription screen with:
- Current plan display
- Usage meters
- Upgrade options
- Billing history list
```

---

## Navigation Map

```
Splash
  ├─→ Login → Dashboard (if authenticated)
  └─→ Signup → Onboarding → Dashboard

Dashboard
  ├─→ POS Sale → Sale Details
  ├─→ Products → Product Details → Edit
  ├─→ Inventory → Adjust Stock
  ├─→ Sales History → Sale Details
  ├─→ Customers → Customer Details → Edit
  ├─→ Reports → Detailed Reports
  ├─→ Branches (admin) → Branch Details
  ├─→ Staff (admin/manager) → Invite Staff
  ├─→ Settings
  └─→ Profile

Menu Drawer
  ├─→ Dashboard
  ├─→ New Sale
  ├─→ Products
  ├─→ Inventory
  ├─→ Sales History
  ├─→ Customers
  ├─→ Reports
  ├─→ Branches (admin)
  ├─→ Staff (admin/manager)
  ├─→ Transfers (manager+)
  ├─→ Settings
  ├─→ Subscription (admin)
  └─→ Logout
```

---

## State Management

### App State Variables (FFAppState)

```dart
// User session
String userId
String tenantId
String branchId
String userRole
String userName
String tenantName
String branchName

// POS cart
List<CartItem> cartItems
double cartSubtotal
double cartTax
double cartDiscount
double cartTotal
String selectedCustomerId
String selectedPaymentMethod

// Filters
String selectedCategory
DateTime startDate
DateTime endDate
String selectedBranchId (for tenant_admin)

// UI state
bool isOnline
DateTime lastSyncTime
bool isSyncing
```

### Persistent Storage (Hive/Local Storage)

```dart
// Offline queue
List<PendingSale> pendingSales
List<PendingInventoryAdjustment> pendingAdjustments

// Cached data
List<Product> cachedProducts
List<Customer> cachedCustomers
```

---

## Offline Capabilities

### Offline-First Features

1. **POS Sales** - Complete sales offline, sync when online
2. **Product Lookup** - Search cached products
3. **Customer Lookup** - Search cached customers
4. **Inventory View** - View last synced inventory

### Sync Strategy

```dart
// Auto-sync when online
if (isOnline) {
  await syncPendingSales();
  await syncInventoryAdjustments();
  await syncCustomerData();
  await syncProductUpdates();
}

// Manual sync trigger
Future<void> manualSync() async {
  setState(() => isSyncing = true);

  try {
    await syncPendingSales();
    await fetchLatestData();
    FFAppState().lastSyncTime = DateTime.now();
  } catch (e) {
    showError('Sync failed: $e');
  } finally {
    setState(() => isSyncing = false);
  }
}
```

---

## FlutterFlow Configuration

### Supabase Integration

1. **Enable Supabase in FlutterFlow**
   - Add Supabase URL and Anon Key
   - Enable Authentication
   - Configure RLS policies

2. **API Calls Configuration**
   - Create API Groups for each table
   - Set up queries with filters
   - Configure response parsers

3. **Custom Actions**
   - Create custom actions for complex queries
   - Add error handling
   - Implement offline queue

### Custom Widgets Needed

1. **ProductCard** - Reusable product display
2. **CartItem** - POS cart item with +/- buttons
3. **StockLevelIndicator** - Color-coded stock status
4. **SaleCard** - Sale list item display
5. **CustomerCard** - Customer list item
6. **ChartWidget** - Sales/inventory charts
7. **DateRangePicker** - Custom date range selector
8. **BarcodeScanner** - Camera barcode scanning
9. **ReceiptPrinter** - Thermal printer integration
10. **SyncIndicator** - Offline/online status

### Theme Configuration

```dart
// Primary Colors
Primary: #your_brand_color (from tenant.brand_color)
Secondary: #complementary_color
Success: #4CAF50
Warning: #FFC107
Error: #F44336

// Typography
Heading1: 32px, Bold
Heading2: 24px, Bold
Heading3: 20px, SemiBold
Body1: 16px, Regular
Body2: 14px, Regular
Caption: 12px, Regular

// Spacing
xs: 4px
sm: 8px
md: 16px
lg: 24px
xl: 32px
```

---

## Development Checklist

- [ ] Set up Supabase integration
- [ ] Configure authentication flow
- [ ] Create app state variables
- [ ] Build authentication pages (1-6)
- [ ] Build main POS flow (7-8)
- [ ] Build product management (9-13)
- [ ] Build sales history (14-15)
- [ ] Build customer management (16-18)
- [ ] Build reports (19-22)
- [ ] Build admin pages (23-27)
- [ ] Build transfer management (28-29)
- [ ] Build settings (30-32)
- [ ] Implement offline capabilities
- [ ] Add barcode scanning
- [ ] Add receipt printing
- [ ] Test all user roles
- [ ] Test multi-branch scenarios
- [ ] Test offline sync
- [ ] Performance optimization
- [ ] Deploy to production

---

**End of POS Guide**

This guide provides complete specifications for all 32 pages of the multi-tenant POS system, including data fetching strategies, navigation flows, UI components, and FlutterFlow AI prompts for rapid development.
