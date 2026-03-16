# Flutter POS Admin App - FlutterFlow Pages

This document lists all pages/screens required for the Flutter POS Admin application based on the Multi-Tenant POS-First Super App Platform specification (specs/001-multi-tenant-pos/).

## 📱 Page Overview

**Total Pages: 60+**

---

## 🔐 Authentication & Onboarding (5 pages)

### 1. Login Screen
- Email/password input fields
- Google Sign-In button
- "Forgot Password" link
- Form validation
- Loading states

### 2. Registration Screen
- Email/password registration form
- Google Sign-In option
- Terms of service checkbox
- Form validation
- Email confirmation notice

### 3. Email Confirmation Screen
- Email verification message
- Resend confirmation email button
- Check verification status

### 4. Country Selection Screen (Onboarding)
- Searchable country list
- Country flag display
- Auto-populated phone dial code (e.g., +234)
- Auto-populated currency (e.g., NGN)
- Confirmation card with selected country details
- Continue button

### 5. Onboarding Complete/Welcome Screen
- Welcome message
- Quick start guide
- Proceed to dashboard button

---

## 🏠 Dashboard (1 page)

### 6. Dashboard Home Screen
- Key metrics overview (total revenue, transactions, average order value)
- Recent sales summary
- Low stock alerts
- Expiry alerts
- Top selling products widget
- Quick actions (new sale, add product, view orders)
- Sync status indicator

---

## 💰 POS Operations (6 pages)

### 7. POS Interface Screen (Main Sales Screen)
- Product search/scan barcode
- Product grid/list view
- Shopping cart display
- Item quantity controls
- Discount application
- Tax calculation display
- Payment method selection
- Complete sale button
- Customer selection/add

### 8. Cart Screen
- Cart items list
- Item quantity adjustment
- Remove item
- Apply discount (percentage or fixed)
- Tax breakdown
- Total calculation
- Clear cart
- Proceed to payment

### 9. Payment Processing Screen
- Payment method selection (cash, card, bank transfer, mobile money)
- Amount tendered input
- Change calculation
- Split payment option
- Complete transaction button
- Loading/processing state

### 10. Receipt Screen
- Digital receipt display
- Itemized products
- Payment details
- Tenant branding (logo, colors)
- Print receipt button
- Share receipt (email, WhatsApp)
- New sale button

### 11. Transaction History Screen
- Transaction list (filterable by date, staff, payment method)
- Search transactions
- Transaction details view
- Void/refund option
- Sync status indicator
- Export transactions

### 12. Void/Refund Transaction Screen
- Transaction details display
- Void reason selection
- Refund amount input (full or partial)
- Authorization required
- Confirmation dialog
- Audit trail note

---

## 📦 Inventory Management (7 pages)

### 13. Product List Screen
- Product grid/list view
- Search products
- Filter by category, stock status, expiry
- Sort options (name, price, stock, date added)
- Product quick view
- Add new product button
- Bulk import button
- Expiry alerts badge

### 14. Add/Edit Product Screen
- Product name input
- Description textarea
- SKU/barcode input
- Category selection
- Price input
- Stock quantity input
- Expiry date picker
- Product image upload
- Variants (size, color) management
- Save/update button

### 15. Bulk Import CSV Screen
- CSV file upload
- Template download link
- Preview imported data
- Validation errors display
- Field mapping interface
- Import confirmation
- Import progress indicator

### 16. Expiry Alerts Screen
- Products expiring soon list (default 30 days)
- Days until expiry countdown
- Filter by timeframe (7, 14, 30, 60 days)
- Product details quick view
- Mark as sold/removed
- Export alert list

### 17. Category Management Screen
- Category list
- Add new category
- Edit category
- Delete category (with product reassignment)
- Category hierarchy (parent/child)

### 18. Stock Adjustment Screen
- Product selection
- Current stock display
- Adjustment type (restock, adjustment, expiry, damage)
- Quantity adjustment input
- Reason/notes textarea
- Staff attribution
- Submit adjustment

### 19. Inventory Transaction Log Screen
- Transaction history (sales, restocks, adjustments)
- Filter by type, product, date range
- Search functionality
- Export log

---

## 👥 Customer Management (4 pages)

### 20. Customer List Screen
- Customer list/grid view
- Search customers
- Filter by loyalty tier, purchase frequency
- Sort by total spend, last purchase
- Customer quick view
- Add new customer button

### 21. Customer Profile Screen
- Customer details (name, email, phone, WhatsApp)
- Purchase history list
- Total spend display
- Order frequency metrics
- Loyalty points balance
- Delivery addresses list
- Edit customer button

### 22. Customer Insights Screen
- Top customers ranking
- Purchase patterns visualization
- Loyalty tier distribution chart
- Customer segments
- Average order value by customer
- Export insights

### 23. Add/Edit Customer Screen
- Name input
- Email input
- Phone number input (with country dial code)
- WhatsApp number input
- Delivery addresses management
- Loyalty tier assignment
- Save/update button

---

## 📋 Order Management (3 pages)

### 24. Order List Screen
- Order list with status badges
- Filter by status (pending, confirmed, preparing, ready, out for delivery, delivered, cancelled)
- Search orders
- Sort by date, customer, total
- Order quick view
- Create new order button

### 25. Order Detail Screen
- Order items list
- Customer details
- Order status timeline
- Payment status
- Fulfillment type (pickup/delivery)
- Delivery details (if applicable)
- Update status button
- Cancel order option
- Print order

### 26. Order Status Management Screen
- Current status display
- Status update workflow
- Status change reason (for cancellations)
- Notification trigger (customer notification)
- Confirm status change

---

## 👨‍💼 Staff Management (6 pages)

### 27. Staff List Screen
- Staff list with roles
- Filter by role (Admin, Manager, Cashier, Driver)
- Staff status (active, inactive)
- Staff quick view
- Add staff/send invite button
- Pending invites section

### 28. Add/Edit Staff Screen
- Name input
- Email input
- Role selection
- Permissions configuration
- Phone number input
- Active/inactive toggle
- Save/update button

### 29. Staff Invite Screen
- Email input
- Role selection (Branch Manager, Cashier/Staff, Delivery Rider)
- Send invite button
- Pending invites list
- Resend invite option
- Revoke invite option
- Invite status (pending, accepted, expired, revoked)
- Expiry countdown (7 days)

### 30. Clock In/Out Screen
- Staff member selection/auto-detect
- Current status (clocked in/out)
- Clock in button
- Clock out button
- Current shift duration
- Recent clock in/out history

### 31. Staff Attendance Reports Screen
- Staff attendance calendar
- Filter by staff member, date range
- Clock in/out timestamps
- Total hours worked calculation
- Attendance patterns visualization
- Export attendance report

### 32. Staff Performance Reports Screen
- Sales by staff member
- Average transaction value by staff
- Transaction count by staff
- Time period selection
- Performance comparison chart
- Export performance report

---

## 🚚 Delivery Management (6 pages)

### 33. Delivery Dashboard
- Active deliveries count
- Delivery success rate
- Average delivery time
- Rider availability status
- Pending deliveries list
- Completed deliveries summary

### 34. Create Delivery Order Screen
- Order selection (from existing orders)
- Customer address display/edit
- Delivery type selection (local bike/bicycle or inter-city)
- Distance calculation
- Delivery instructions textarea
- Assign rider (if local)
- Create delivery button

### 35. Assign Rider Screen
- Available riders list
- Rider details (name, contact, current deliveries)
- Rider performance metrics
- Select rider
- Notify rider option
- Confirm assignment

### 36. Delivery Tracking Screen
- Delivery status timeline
- Current status display
- Customer details
- Delivery address map (optional)
- Rider details (if assigned)
- Tracking number
- Update status button
- Customer tracking link

### 37. Proof of Delivery Screen
- Delivery details display
- Photo upload (proof of delivery)
- Signature capture
- Recipient name input
- Delivery notes
- Mark as delivered button

### 38. Rider Performance Screen
- Rider list
- Deliveries completed count
- Success rate
- Average delivery time
- Customer ratings (if applicable)
- Current availability status

---

## 📊 Analytics (7 pages)

### 39. Analytics Dashboard
- Key metrics cards (total revenue, transaction count, average order value)
- Revenue trend graph
- Top products widget
- Sales by category chart
- Time period selector (weekly, monthly, quarterly, annual)
- Export analytics button

### 40. Product Sales History Screen
- Product selection
- Sales trend graph (line chart)
- Time period selector (weekly, monthly, quarterly, annual, custom)
- Total units sold
- Total revenue
- Average selling price
- Peak sales periods display

### 41. Sales Graphs Screen (Multi-Period View)
- Weekly view (sales by week with week-over-week comparison)
- Monthly view (sales by month with month-over-month analysis)
- Quarterly view (Q1-Q4 comparison)
- Annual view (year-over-year comparison)
- Chart type selector (line, bar, area)
- Dual Y-axis (revenue and volume)
- Interactive tooltips

### 42. Category Comparison Screen
- Category selection (multiple)
- Side-by-side bar charts (volume and revenue)
- Product comparison within category
- Brand comparison (same product type, different brands)
- Comparison metrics (units sold, revenue, avg price, profit margin, growth rate)
- Time period selector

### 43. Top Selling Products Screen
- Top products by volume ranking
- Top products by value ranking
- Time period filter (this week, month, quarter, year, custom)
- Product details (sales velocity, peak day/time, turnover rate)
- Trend indicators (up/down/stable)
- Export top products list

### 44. Sales Pattern Analysis Screen
- Peak sales hours (hourly heatmap)
- Day-of-week trends (bar chart)
- Seasonal patterns (monthly line chart)
- Customer purchase behavior insights
- Time-based filtering

### 45. Inventory Turnover Screen
- Fast-moving products list
- Slow-moving products list
- Turnover rate calculation
- Days to sell calculation
- Stock movement visualization
- Time period selector

---

## 🔌 Integrations (6 pages)

### 46. Integrations Hub Screen
- Connected integrations list
- Available integrations showcase
- Integration status indicators
- Add new integration button
- Sync status overview

### 47. WooCommerce Connection Screen
- Connection status
- API credentials input (consumer key, secret)
- Test connection button
- Sync settings (frequency, conflict resolution)
- Last sync timestamp
- Sync now button
- Disconnect option

### 48. Shopify Connection Screen
- Connection status
- API credentials input (shop URL, access token)
- Test connection button
- Sync settings (frequency, conflict resolution)
- Last sync timestamp
- Sync now button
- Disconnect option

### 49. WhatsApp Setup Screen
- WhatsApp Business API status
- Phone number input
- API key input
- Test connection button
- Message templates configuration
- Automated notification settings
- Disconnect option

### 50. Payment Gateway Setup Screen
- Paystack configuration
- Flutterwave configuration
- API credentials input
- Test mode toggle
- Webhook configuration
- Transaction fee display
- Save configuration

### 51. Sync Status Screen
- Pending sync items count
- Last sync timestamp by platform
- Sync errors list
- Sync health indicators
- Sync logs
- Manual sync trigger
- Conflict resolution queue

---

## ⚙️ Settings (8 pages)

### 52. Tenant Settings Screen
- Settings categories list
- Business information
- Branding
- Tax configuration
- Business hours
- Payment methods
- Delivery zones
- Subscription

### 53. Branding Configuration Screen
- Business name input
- Logo upload
- Primary color picker
- Secondary color picker
- Receipt template preview
- Save branding button

### 54. Tax Configuration Screen
- Tax rate input (percentage)
- Tax rules configuration
- Tax-exempt products selection
- Apply tax toggle
- Save tax settings

### 55. Business Hours Screen
- Days of week list
- Opening time picker
- Closing time picker
- Closed days selection
- Holiday schedule
- Save hours button

### 56. Payment Methods Configuration Screen
- Available payment methods list (cash, card, bank transfer, mobile money)
- Enable/disable toggles
- Payment method priority
- Save payment settings

### 57. Delivery Zones Configuration Screen
- Local delivery zones list
- Add delivery zone
- Zone radius/boundary
- Delivery fee settings
- Inter-city delivery toggle
- Save delivery settings

### 58. Subscription Management Screen
- Current plan display
- Plan features list
- Usage metrics (users, products, transactions)
- Plan limits display
- Upgrade/downgrade options
- Billing cycle

### 59. Billing History Screen
- Invoice list
- Invoice details view
- Payment status
- Download invoice (PDF)
- Subscription fees breakdown
- Commission charges (marketplace sales)

---

## 💬 Communication (2 pages)

### 60. Unified Inbox Screen
- Message threads list
- Filter by platform (WhatsApp, chat, email)
- Search messages
- Message preview
- Unread message count
- Reply to message
- Customer details quick view

### 61. AI Chat Configuration Screen
- AI agent enable/disable toggle
- AI model selection
- Response templates
- Fallback to human settings
- Conversation logs access
- AI performance metrics

---

## 🔄 Sync & Offline Indicators (Embedded in Multiple Screens)

### 62. Sync Status Indicator Component
- Online/offline badge
- Pending sync count
- Last sync timestamp
- Sync in progress animation
- Tap to view sync details

### 63. Offline Mode Banner
- Offline mode notification
- Limited functionality warning
- Sync queue count
- Reconnect prompt

---

## 🎨 Design Considerations for FlutterFlow

### Component Library Recommendations
- **Navigation**: Bottom navigation bar (Dashboard, POS, Inventory, Orders, More)
- **Lists**: Use ListView.builder for performance with large datasets
- **Forms**: Form validation with real-time feedback
- **Charts**: Use fl_chart or syncfusion_flutter_charts for analytics
- **Search**: Implement search with debouncing for performance
- **Filters**: Bottom sheet or drawer for filter options
- **Camera**: Camera integration for barcode scanning and proof of delivery
- **File Picker**: CSV upload and image upload
- **Date Pickers**: Calendar widgets for date range selection
- **Color Pickers**: For branding configuration
- **Maps**: Optional for delivery tracking (Google Maps integration)

### Responsive Design
- Mobile-first design (optimized for Android low-end devices)
- Tablet support for POS interface (larger screen real estate)
- Adaptive layouts for different screen sizes

### Performance Optimization
- Lazy loading for lists
- Image caching
- Offline data storage (SQLite)
- Background sync with isolates
- Pagination for large datasets

### Offline-First Architecture
- All core POS screens must work offline
- Local SQLite database
- Sync queue management
- Conflict resolution UI
- Clear online/offline indicators

### Multi-Tenant Context
- Tenant branding (logo, colors) applied throughout app
- Currency formatting based on tenant's selected currency
- Dial code display in phone number fields
- Tenant-scoped data isolation

---

## 📋 Phase-Based Implementation Priority

### Phase 1: Core POS (MVP)
- Pages 1-5 (Auth & Onboarding)
- Page 6 (Dashboard)
- Pages 7-12 (POS Operations)
- Pages 13-19 (Inventory Management)
- Pages 27-28 (Basic Staff Management)
- Pages 52-56 (Basic Settings)
- Page 62-63 (Sync Indicators)

### Phase 2: Customers & Marketplace
- Pages 20-23 (Customer Management)
- Pages 24-26 (Order Management)
- Pages 29-32 (Full Staff Management)

### Phase 3: Delivery
- Pages 33-38 (Delivery Management)

### Phase 4: Integrations & AI
- Pages 46-51 (Integrations)
- Pages 60-61 (Communication)

### Phase 5: Analytics & Payments
- Pages 39-45 (Analytics)
- Pages 58-59 (Subscription & Billing)

---

## 🔑 Key Features Summary

- **Total Pages**: 63 pages/screens
- **Main Navigation**: 5 sections (Dashboard, POS, Inventory, Orders, More)
- **Authentication**: Email/Password + Google Sign-In
- **Offline Support**: SQLite local storage with automatic sync
- **Multi-Tenant**: Complete data isolation with tenant branding
- **Analytics**: 7 comprehensive analytics screens with graphs
- **Integrations**: WooCommerce, Shopify, WhatsApp, Payment Gateways
- **Role-Based Access**: Platform Admin, Tenant Admin, Manager, Cashier, Driver
- **Country/Currency**: Configurable during onboarding

---

## 📝 Notes for FlutterFlow Implementation

1. **Custom Code**: May need custom code for:
   - SQLite/IndexedDB offline storage
   - Barcode scanning
   - Service Worker for PWA
   - Advanced sync logic
   - CSV parsing and import
   - Signature capture
   - Complex chart interactions

2. **State Management**: Consider using:
   - Provider or Riverpod for app-wide state
   - Local state for UI-only changes
   - Sync state management for offline queue

3. **API Integration**:
   - Supabase Flutter SDK for backend
   - Custom API calls for third-party integrations
   - Webhook handlers

4. **Testing**:
   - Widget tests for critical UI components
   - Integration tests for offline sync
   - E2E tests for complete workflows

5. **Accessibility**:
   - Semantic labels for screen readers
   - Sufficient touch target sizes (minimum 44x44)
   - Color contrast compliance
   - Keyboard navigation support

---

**Document Version**: 1.0
**Last Updated**: 2026-03-02
**Specification Reference**: specs/001-multi-tenant-pos/spec.md
