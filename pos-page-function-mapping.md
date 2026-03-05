# POS Pages to RPC Functions - Quick Reference Mapping

**Complete mapping of which RPC functions each page uses**

---

## Dashboard & Home

### Page 7: Dashboard/Home
**RPC Functions:**
- `get_daily_sales_summary`
- `get_recent_sales`
- `get_low_stock_count`

---

## POS Operations

### Page 8: POS Sale Screen
**RPC Functions:**
- `search_products_for_pos`
- `search_customers`
- `complete_sale_transaction`

### Page 15: Sale Details
**RPC Functions:**
- `void_sale` (manager only)

---

## Product Management

### Page 9: Products Management
**RPC Functions:**
- `get_products_with_stock`

### Page 10: Product Details/Edit
**Direct Queries:**
- Direct Supabase queries (no RPC)

### Page 11: Add Product
**Direct Queries:**
- Direct Supabase insert (no RPC)

---

## Inventory Management

### Page 12: Branch Inventory
**RPC Functions:**
- `get_products_with_stock` (filtered by branch)
- `calculate_inventory_value`

### Page 13: Adjust Stock
**RPC Functions:**
- `adjust_stock`

---

## Sales History

### Page 14: Sales History
**RPC Functions:**
- `get_sales_with_filters`
- `get_sales_summary`

### Page 15: Sale Details
**RPC Functions:**
- `void_sale` (if manager/admin)

---

## Customer Management

### Page 16: Customers List
**RPC Functions:**
- `search_customers`

### Page 17: Customer Details
**RPC Functions:**
- `get_customer_stats`

### Page 18: Add/Edit Customer
**Direct Queries:**
- Direct Supabase insert/update (no RPC)

---

## Reports & Analytics

### Page 19: Reports Dashboard
**RPC Functions:**
- `get_sales_summary`
- `get_daily_sales_trend`
- `get_top_products`
- `calculate_inventory_value`

### Page 20: Sales Report
**RPC Functions:**
- `get_sales_summary`
- `get_daily_sales_trend`
- `get_top_products`
- `get_sales_with_filters`

### Page 21: Inventory Report
**RPC Functions:**
- `calculate_inventory_value`
- `get_products_with_stock`

### Page 22: Low Stock Alerts
**RPC Functions:**
- `get_products_with_stock` (with stock_filter='low_stock')

---

## Branch & Staff Management

### Page 23: Branches List
**Direct Queries:**
- Direct Supabase queries (no RPC)

### Page 24: Branch Details/Edit
**Direct Queries:**
- Direct Supabase queries (no RPC)

### Page 25: Add Branch
**Direct Queries:**
- Direct Supabase insert (no RPC)

### Page 26: Staff Management
**RPC Functions:**
- `get_staff_performance` (for performance view)

### Page 27: Add/Invite Staff
**Direct Queries:**
- Direct Supabase insert into staff_invites (no RPC)

### Page 28: Inter-Branch Transfer
**RPC Functions:**
- `create_inter_branch_transfer`

### Page 29: Transfer History
**Direct Queries:**
- Direct Supabase queries (no RPC)

---

## Settings & Profile

### Page 30: Settings
**Direct Queries:**
- Direct Supabase queries (no RPC)

### Page 31: Profile
**Direct Queries:**
- Direct Supabase queries (no RPC)

### Page 32: Subscription & Billing
**Direct Queries:**
- Direct Supabase queries (no RPC)

---

## Summary Statistics

### Total Pages: 32
- **Pages using RPC functions: 13**
- **Pages using direct queries: 19**

### RPC Functions by Usage Frequency

| Function | Used On Pages | Purpose |
|----------|---------------|---------|
| `get_sales_summary` | 3 pages (14, 19, 20) | Sales summary for date ranges |
| `get_daily_sales_trend` | 2 pages (19, 20) | Daily sales data for charts |
| `get_products_with_stock` | 3 pages (9, 12, 21, 22) | Products with stock levels |
| `search_customers` | 2 pages (8, 16) | Customer search |
| `search_products_for_pos` | 1 page (8) | POS product search |
| `complete_sale_transaction` | 1 page (8) | Complete sale atomically |
| `void_sale` | 1 page (15) | Void completed sale |
| `adjust_stock` | 1 page (13) | Adjust inventory |
| `get_sales_with_filters` | 2 pages (14, 20) | Advanced sales filtering |
| `get_customer_stats` | 1 page (17) | Customer statistics |
| `get_top_products` | 2 pages (19, 20) | Best sellers |
| `calculate_inventory_value` | 2 pages (12, 19, 21) | Inventory valuation |
| `get_staff_performance` | 1 page (26) | Staff metrics |
| `create_inter_branch_transfer` | 1 page (28) | Create transfer |
| `get_daily_sales_summary` | 1 page (7) | Dashboard metrics |
| `get_recent_sales` | 1 page (7) | Recent transactions |
| `get_low_stock_count` | 1 page (7) | Alert count |

### Utility Functions (Used Programmatically)
- `generate_slug` - Used during onboarding (page 4)
- `calculate_profit_margin` - Used in product views (pages 10, 11)

---

## Implementation Priority

### Phase 1: Core POS (Must Have)
1. `complete_sale_transaction` ✅ Critical
2. `search_products_for_pos` ✅ Critical
3. `search_customers` ✅ Critical
4. `get_daily_sales_summary` ✅ Important
5. `get_recent_sales` ✅ Important

### Phase 2: Inventory & Sales (High Priority)
6. `adjust_stock` 🔶 High
7. `get_products_with_stock` 🔶 High
8. `get_sales_with_filters` 🔶 High
9. `get_sales_summary` 🔶 High
10. `void_sale` 🔶 High

### Phase 3: Reports & Analytics (Medium Priority)
11. `get_daily_sales_trend` 🔷 Medium
12. `get_top_products` 🔷 Medium
13. `calculate_inventory_value` 🔷 Medium
14. `get_customer_stats` 🔷 Medium
15. `get_low_stock_count` 🔷 Medium

### Phase 4: Management Features (Low Priority)
16. `get_staff_performance` 🔹 Low
17. `create_inter_branch_transfer` 🔹 Low

### Phase 5: Utilities (As Needed)
18. `generate_slug` ⚪ Utility
19. `calculate_profit_margin` ⚪ Utility

---

## Testing Checklist

### Dashboard (Page 7)
- [ ] Today's sales display correctly
- [ ] Recent sales list populates
- [ ] Low stock badge shows count
- [ ] All metrics update on refresh

### POS Sale (Page 8)
- [ ] Product search returns results
- [ ] Stock levels show correctly
- [ ] Customer search works
- [ ] Sale completion succeeds
- [ ] Inventory auto-updates
- [ ] Receipt generates

### Inventory (Pages 12-13)
- [ ] Stock levels display correctly
- [ ] Stock adjustment works
- [ ] Inventory value calculates
- [ ] Low stock filters work

### Sales History (Pages 14-15)
- [ ] Sales list with filters
- [ ] Sale details display
- [ ] Void sale works (manager)
- [ ] Summary calculations correct

### Reports (Pages 19-22)
- [ ] All charts render
- [ ] Data matches summary
- [ ] Filters apply correctly
- [ ] Export works

### Customers (Pages 16-18)
- [ ] Customer search works
- [ ] Stats display correctly
- [ ] Add/edit saves properly

### Management (Pages 23-29)
- [ ] Branch list displays
- [ ] Staff performance shows
- [ ] Transfer creation works

---

## FlutterFlow Backend Configuration

### Step 1: Add All RPC Calls

For each function above, create a Backend Query in FlutterFlow:

1. Go to **Backend Query** → **Supabase**
2. Click **Add Query** → **RPC Call**
3. Name the query (camelCase, e.g., `getDailySales`)
4. Enter function name (snake_case, e.g., `get_daily_sales_summary`)
5. Add parameters with app state bindings
6. Configure response parsing

### Step 2: Test Each Query

Use FlutterFlow's test feature to verify:
- Parameters pass correctly
- Response structure matches expectations
- Error handling works

### Step 3: Bind to UI

Connect queries to UI components:
- ListView data sources
- Text fields for metrics
- Charts for trend data
- Conditional visibility based on results

---

## Error Handling Pattern

All RPC calls should follow this pattern in FlutterFlow:

```dart
// Backend Query: exampleRPCCall

// Success Handler:
if (exampleRPCCallResult.succeeded) {
  final data = exampleRPCCallResult.jsonBody;

  // Check function-specific success
  if (data['success'] == true) {
    // Process data
    // Update UI
    // Show success message
  } else {
    // Show error from function
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(data['error_message'] ?? 'Operation failed'),
        backgroundColor: Colors.red,
      ),
    );
  }
} else {
  // Show network/query error
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Connection error. Please try again.'),
      backgroundColor: Colors.red,
    ),
  );
}
```

---

## Performance Optimization

### Caching Strategy

Cache frequently accessed data in FFAppState:

```dart
// Cache product catalog (refresh every 5 minutes)
FFAppState().cachedProducts
FFAppState().lastProductCachetime

// Cache customer list (refresh every 2 minutes)
FFAppState().cachedCustomers
FFAppState().lastCustomerCacheTime

// Cache current stock levels (refresh every 1 minute)
FFAppState().cachedInventory
FFAppState().lastInventoryCacheTime
```

### Debouncing

Add debounce to search fields:
- Product search: 300ms
- Customer search: 300ms
- Sales filter: 500ms

### Pagination

Use LIMIT and OFFSET for large datasets:
- Products: 50 per page
- Sales: 50 per page
- Customers: 50 per page

### Lazy Loading

Load data on-demand:
- Reports: Load when page opens
- Charts: Load after summary
- Details: Load on tap

---

## Offline Support

### Critical Functions (Must Work Offline)

Store in local Hive database:
1. `complete_sale_transaction` - Queue for sync
2. `search_products_for_pos` - Use cached products
3. `search_customers` - Use cached customers

### Sync Queue

Maintain offline queue:
```dart
FFAppState().pendingSales = []
FFAppState().pendingInventoryAdjustments = []
FFAppState().pendingCustomers = []
```

Sync when online:
```dart
if (isOnline) {
  await syncPendingSales();
  await syncInventoryAdjustments();
  await refreshCache();
}
```

---

**End of Mapping Guide**

Use this as a quick reference when building pages in FlutterFlow. Each page lists exactly which RPC functions it needs, so you can configure backend queries efficiently.
