# Feature Specification: Multi-Tenant POS-First Super App Platform

**Feature Branch**: `001-multi-tenant-pos`
**Created**: 2026-01-17
**Status**: Draft
**Input**: Multi-tenant POS-first super app for independent businesses (pharmacies, supermarkets, grocery shops, mini-marts) in Nigeria with offline-first architecture, cloud sync, e-commerce integrations, AI chat agent, delivery management, and comprehensive analytics

## Product Vision

A **POS-first super app platform** that empowers independent businesses in Nigeria (pharmacies, supermarkets, grocery shops, mini-marts, restaurants) to:
- Manage inventory and sales with offline-first reliability
- Sell to walk-in customers and nearby customers via marketplace
- Offer local delivery (bike/bicycle) and platform-provided inter-city delivery
- Accept remote orders via AI-powered chat agent
- Integrate with e-commerce platforms (WooCommerce, etc.)
- Operate reliably in low internet conditions with automatic cloud sync
- Access comprehensive sales analytics and business insights

**Platform Model**: The platform does NOT own inventory or businesses. It provides software, payments, delivery orchestration, marketplace connectivity, and business intelligence.

**Target Market**: Nigeria-first UX optimized for local business operations (pharmacies, supermarkets, grocery shops, mini-marts, restaurants), mobile connectivity patterns, and payment preferences.

**Technical Approach**: Progressive Web App (PWA) with offline-first architecture, Supabase backend, SQLite for offline persistence, automatic sync on internet availability, with native mobile apps as future enhancement.

## Clarifications

### Session 2026-01-17

- Q: For offline sync conflict resolution when multiple devices edit the same product's stock level offline, which strategy should be used for inventory conflicts? → A: Operational Transformation/CRDTs (mathematically correct; all operations preserved; ensures arithmetic correctness for concurrent inventory updates)
- Q: What is the default distance threshold for distinguishing local bike/bicycle delivery from platform inter-city delivery? → A: 25 kilometers
- Q: What is the default customer loyalty points earning rate? → A: 1 point per ₦100 spent (1% reward rate)
- Q: What is the OTP code expiration time for phone/email authentication? → A: 5 minutes (industry-standard balance between security and usability); also support email authentication as alternative to phone-based OTP
- Q: What happens when a staff member forgets to clock out at end of shift? → A: No auto clock-out; requires manual correction by admin (most accurate but requires intervention)

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Offline-First POS Operations (Priority: P1 - Phase 1: Core POS)

A cashier at a pharmacy with unreliable internet processes sales, manages inventory, applies discounts, and generates receipts. The system works seamlessly offline, storing transactions locally and automatically syncing to the cloud when internet becomes available.

**Why this priority**: This is the core value proposition and MVP. Independent shops need reliable POS functionality regardless of internet connectivity. Without offline-first POS, the platform cannot serve its primary use case in Nigeria's connectivity environment.

**Independent Test**: Can be fully tested by simulating offline environment, processing multiple sales transactions with various products and payment methods, going offline, verifying local storage persistence, reconnecting to internet, and confirming automatic sync to Supabase. Delivers immediate value by enabling reliable business operations.

**Acceptance Scenarios**:

1. **Given** a cashier is logged into the POS with internet connection, **When** they scan/select products and internet disconnects, **Then** the POS continues to function normally using local SQLite data
2. **Given** the POS is offline, **When** the cashier processes a sale with payment, **Then** the transaction is saved locally, inventory is updated in SQLite, and receipt is generated
3. **Given** multiple offline transactions exist, **When** internet connection is restored, **Then** all pending transactions sync to Supabase automatically within 30 seconds
4. **Given** a product has an expiry date approaching, **When** the cashier views inventory, **Then** the system displays expiry alerts for products expiring within 30 days
5. **Given** a merchant wants to bulk import products, **When** they upload a CSV file with product data, **Then** the system validates and imports products with name, SKU, price, category, stock quantity, and expiry date

---

### User Story 2 - Multi-Tenant Isolation and OTP Authentication (Priority: P2 - Phase 1: Core POS)

A platform administrator onboards new business tenants using OTP-based authentication via phone or email. Each tenant (pharmacy, supermarket, grocery shop) operates with complete data isolation, custom branding, and role-based access for their staff.

**Why this priority**: Multi-tenancy and secure authentication are foundational. Phone + OTP authentication aligns with Nigeria-first UX where phone numbers are primary identity, with email as alternative for users without reliable SMS access. Must be established early to support multiple businesses on the platform.

**Independent Test**: Can be tested by registering two tenants using phone numbers or email addresses, sending OTP verification, configuring each with different branding, creating staff accounts with different roles (admin, cashier, manager), and verifying complete data isolation between tenants.

**Acceptance Scenarios**:

1. **Given** a new business wants to join the platform, **When** they provide their phone number or email address, **Then** the system sends an OTP code (via SMS or email) that expires in 5 minutes
2. **Given** a user enters the correct OTP within 5 minutes, **When** verification succeeds, **Then** the system creates a tenant account with unique identifier and admin access
3. **Given** multiple tenants exist on the platform, **When** a user logs into tenant A, **Then** they can only access tenant A's data with zero visibility into other tenants
4. **Given** a tenant administrator, **When** they create staff accounts with roles (admin, cashier, manager, driver), **Then** each role has appropriate permissions enforced by the system
5. **Given** a tenant configures branding, **When** they upload logo and set colors, **Then** these settings apply to their POS interface and receipts only

---

### User Story 3 - Customer Management and Marketplace Storefront (Priority: P3 - Phase 2: Customers & Orders)

A business creates a digital storefront accessible to nearby customers. Customers browse products, place orders for delivery or pickup, view purchase history, and earn loyalty points. The marketplace connects customers with multiple nearby shops.

**Why this priority**: Extends the platform from in-store POS to online marketplace, enabling businesses to reach nearby customers and increase sales beyond walk-ins. Customer data and loyalty programs drive retention.

**Independent Test**: Can be tested by creating a tenant storefront, publishing products, having a test customer browse and place an order, processing the order, and verifying customer profile shows purchase history and loyalty points.

**Acceptance Scenarios**:

1. **Given** a tenant publishes their storefront, **When** nearby customers access the marketplace, **Then** they can browse products from this tenant with real-time inventory visibility
2. **Given** a customer places an order, **When** the order is confirmed, **Then** it appears in the merchant's order management system with customer details and fulfillment options (pickup or delivery)
3. **Given** a customer completes a purchase, **When** the sale is recorded, **Then** the customer earns loyalty points at the rate of 1 point per ₦100 spent and their profile shows updated purchase history and points balance
4. **Given** a returning customer, **When** they log in, **Then** they can view their complete purchase history across all orders and current loyalty points balance
5. **Given** a merchant views customer data, **When** they access customer management, **Then** they see customer profiles, purchase frequency, total spend, and loyalty status

---

### User Story 4 - Staff Management with Time Tracking (Priority: P4 - Phase 2: Customers & Orders)

A business owner manages staff accounts, assigns roles and permissions, and tracks employee attendance. Staff members clock in/out for shifts, and the system maintains attendance records for payroll and performance management.

**Why this priority**: Staff management is critical for multi-user tenant operations. Time tracking helps business owners monitor labor costs and staff productivity. This builds on the multi-tenant user management established in P2.

**Independent Test**: Can be tested by creating multiple staff accounts with different roles, having staff members clock in/out during shifts, processing sales transactions under different staff IDs, and verifying attendance reports show accurate clock in/out times.

**Acceptance Scenarios**:

1. **Given** a tenant administrator creates staff accounts, **When** they assign roles (cashier, manager, driver), **Then** each staff member receives login credentials and role-appropriate permissions
2. **Given** a staff member starts their shift, **When** they clock in using the POS system, **Then** the system records the timestamp and marks them as on duty
3. **Given** a staff member ends their shift, **When** they clock out, **Then** the system records the timestamp and calculates total hours worked
4. **Given** a manager reviews attendance, **When** they access staff reports, **Then** they see clock in/out history, total hours worked, and attendance patterns for payroll processing
5. **Given** a staff member forgets to clock out, **When** the administrator views staff attendance, **Then** the system alerts them about open clock-in sessions and allows manual correction of the clock-out time
6. **Given** a cashier processes a sale, **When** the transaction is recorded, **Then** the sale is attributed to the logged-in staff member for performance tracking

---

### User Story 5 - Delivery Management (Local and Inter-City) (Priority: P5 - Phase 3: Delivery)

A merchant fulfills customer orders through two delivery options: local delivery using bike/bicycle riders for nearby areas, or platform-provided inter-city delivery for distant locations. Customers track deliveries in real-time.

**Why this priority**: Delivery is critical for marketplace orders but not required for in-store POS. This priority allows core POS and marketplace to function first, then adds fulfillment options. Dual delivery model (local + inter-city) serves diverse customer needs.

**Independent Test**: Can be tested by creating delivery orders, assigning local orders to bike riders, assigning inter-city orders to platform delivery service, updating delivery status, and verifying customer receives tracking updates via public link.

**Acceptance Scenarios**:

1. **Given** a customer order requires delivery, **When** the merchant reviews the delivery address, **Then** the system suggests delivery option (local bike/bicycle for addresses within 25km, platform inter-city for addresses beyond 25km) based on distance threshold
2. **Given** a local delivery is selected, **When** the merchant assigns the order to an available bike rider, **Then** the rider receives notification with delivery details and customer location
3. **Given** an inter-city delivery is selected, **When** the merchant initiates platform delivery, **Then** the order is handed off to the platform delivery service with tracking number
4. **Given** a delivery is in progress, **When** the rider/driver updates status (picked up, in transit, delivered), **Then** the customer tracking page reflects the update within 60 seconds
5. **Given** a delivery is completed, **When** the rider marks it as delivered with proof (photo or signature), **Then** customer receives confirmation and order status updates to completed

---

### User Story 6 - E-Commerce Platform Integrations (Priority: P6 - Phase 4: Integrations)

A merchant who sells on WooCommerce, Shopify, or other e-commerce platforms connects their online store to sync products, inventory, and orders bidirectionally. This prevents overselling and eliminates manual data entry across platforms.

**Why this priority**: E-commerce integration extends omnichannel capabilities but is not required for core POS or marketplace. Merchants already using platforms like WooCommerce benefit from unified inventory management. Third-party integrations add value without blocking core features.

**Independent Test**: Can be tested by connecting a test WooCommerce store via API credentials, syncing products and inventory, placing an order on WooCommerce, verifying it appears in the POS system, making a POS sale, and confirming WooCommerce inventory updates.

**Acceptance Scenarios**:

1. **Given** a tenant has a WooCommerce store, **When** they provide API credentials (consumer key and secret), **Then** the system authenticates and establishes a connection
2. **Given** a WooCommerce connection is active, **When** products are added/updated in WooCommerce, **Then** they sync to the POS system within 5 minutes including name, price, SKU, categories, and images
3. **Given** a sale is made in the POS, **When** inventory is updated locally, **Then** the WooCommerce store inventory reflects the change on next sync cycle
4. **Given** an order is placed on WooCommerce, **When** the order syncs to the POS, **Then** it appears in the order management system and can be fulfilled through local or inter-city delivery
5. **Given** sync conflicts occur, **When** the same product sells simultaneously on both platforms, **Then** the system resolves conflicts using configurable rules (POS priority, last-write-wins, or manual resolution) and alerts the merchant

---

### User Story 7 - AI Chat Agent for Remote Purchases (Priority: P7 - Phase 4: Integrations)

A customer interacts with an AI-powered chat agent to browse products, check stock availability, place orders, modify orders, or cancel orders using natural language. The AI agent has real-time access to inventory and order systems.

**Why this priority**: AI chat agent provides innovative customer experience and reduces merchant workload by automating remote sales. This is a differentiator but requires core POS, inventory, and order systems to be operational first. Conversational commerce is emerging in Nigeria's mobile-first market.

**Independent Test**: Can be tested by initiating a chat session as a customer, asking the AI about product availability, requesting to purchase specific items, modifying quantities via chat, confirming the order is created in the system, and verifying inventory updates accordingly.

**Acceptance Scenarios**:

1. **Given** a customer accesses a merchant's storefront, **When** they initiate a chat, **Then** the AI agent greets them and offers to help browse products or check availability
2. **Given** a customer asks about product availability, **When** they inquire "Do you have paracetamol in stock?", **Then** the AI agent queries real-time inventory and responds with availability and price
3. **Given** a customer wants to purchase via chat, **When** they say "I want to buy 2 bottles of paracetamol", **Then** the AI agent creates an order with the specified items and asks for delivery details
4. **Given** a customer wants to modify their order, **When** they say "Remove one bottle" or "Add ibuprofen", **Then** the AI agent updates the order accordingly and confirms the changes
5. **Given** a customer wants to cancel, **When** they say "Cancel my order", **Then** the AI agent cancels the order, restores inventory, and provides cancellation confirmation

---

### User Story 8 - Analytics and Sales Insights (Priority: P8 - Phase 5: Analytics & Payments)

A business owner accesses comprehensive analytics dashboards showing product sales history, sales graphs, category comparisons, sales patterns, top-selling products, revenue trends, and inventory turnover. The system provides actionable insights for business decisions.

**Why this priority**: Analytics transform the platform from operational tool to business intelligence system. While valuable, merchants can operate without analytics initially. This priority delivers data-driven insights once sufficient transaction history exists.

**Independent Test**: Can be tested by processing diverse sales transactions over time, accessing the analytics dashboard, viewing product sales graphs, comparing products in the same category, and verifying sales pattern analysis shows accurate trends.

**Acceptance Scenarios**:

1. **Given** a merchant has sales history, **When** they access the analytics dashboard, **Then** they see key metrics (total revenue, transactions count, average order value, top products) for selected time period
2. **Given** a merchant wants product insights, **When** they view product sales history, **Then** they see sales volume, revenue, and trends over time with graphical visualization
3. **Given** a merchant wants category analysis, **When** they compare products in the same category, **Then** the system displays side-by-side sales performance, helping identify winners and underperformers
4. **Given** a merchant reviews sales patterns, **When** they access pattern analysis, **Then** the system shows peak sales hours, day-of-week trends, and seasonal patterns to optimize staffing and inventory
5. **Given** a merchant needs inventory insights, **When** they view inventory turnover reports, **Then** they see which products move fast vs. slow, helping with purchasing decisions

---

### User Story 9 - WhatsApp Customer Communication (Priority: P9 - Phase 4: Integrations)

A merchant sends order confirmations, delivery updates, and promotional messages to customers via WhatsApp. Customers can also initiate inquiries through WhatsApp, which appear in the merchant's unified inbox.

**Why this priority**: WhatsApp is the dominant messaging platform in Nigeria, making it valuable for customer engagement. However, it's not critical for core POS or marketplace operations. This priority enhances communication after order and delivery systems are established.

**Independent Test**: Can be tested by processing a sale with customer WhatsApp number, triggering automated confirmation message, updating order status, verifying customer receives WhatsApp notification, and testing merchant inbox receives customer messages.

**Acceptance Scenarios**:

1. **Given** a tenant configures WhatsApp Business API credentials, **When** a sale is completed with customer WhatsApp number, **Then** the customer receives automated order confirmation via WhatsApp
2. **Given** a delivery status changes, **When** the rider updates to "out for delivery", **Then** the customer receives a WhatsApp notification with updated status and estimated delivery time
3. **Given** a customer sends a WhatsApp message, **When** it arrives at the business number, **Then** it appears in the merchant's unified inbox within the POS system for response
4. **Given** a merchant wants to send promotions, **When** they compose a message for customer segments (e.g., loyalty members), **Then** customers receive the WhatsApp message using approved templates
5. **Given** WhatsApp API fails, **When** message sending fails, **Then** the system logs the error and falls back to SMS or email notification

---

### User Story 10 - Payments and Monetization (Priority: P10 - Phase 5: Analytics & Payments)

The platform monetizes through subscription plans (tiered based on features and transaction volume) and commission on marketplace sales. Merchants manage subscriptions, view billing history, and the platform tracks commission earnings.

**Why this priority**: Monetization is essential for platform sustainability but not required for MVP launch. Early adopters may use the platform free or at reduced rates. This priority implements billing infrastructure once the platform demonstrates value.

**Independent Test**: Can be tested by creating subscription plans with different tiers, enrolling a tenant in a plan, processing marketplace sales, calculating commissions, generating invoices, and verifying subscription limits are enforced.

**Acceptance Scenarios**:

1. **Given** a new tenant signs up, **When** they select a subscription plan, **Then** the system enrolls them with plan-specific limits (users, products, monthly transactions)
2. **Given** a marketplace sale completes, **When** the transaction is recorded, **Then** the system calculates platform commission based on the merchant's plan and tracks it for settlement
3. **Given** a tenant exceeds plan limits, **When** they attempt to add more users/products, **Then** the system prompts them to upgrade their subscription
4. **Given** a billing cycle completes, **When** the month ends, **Then** the system generates an invoice with subscription fees and commission charges for the merchant
5. **Given** a merchant views billing, **When** they access subscription management, **Then** they see current plan, usage metrics, billing history, and upgrade options

---

### User Story 11 - Multi-Branch and Multi-Business Management (Priority: P11 - Phase 2: Customers & Marketplace)

A business owner (tenant company) operates multiple branches with different business types. For example, they own a supermarket in Lagos, a pharmacy in Abuja, and another supermarket in Port Harcourt. Each branch operates independently with its own staff, inventory, and sales, but the owner admin can view consolidated analytics and manage all businesses from a unified dashboard.

**Why this priority**: Many Nigerian entrepreneurs operate multiple businesses or expand successful ventures to new locations. Multi-branch support enables the platform to grow with merchants and capture larger enterprise accounts. This builds on the multi-tenancy foundation from Phase 1 and customer management from Phase 2.

**Independent Test**: Can be tested by creating a tenant company account, adding three branches with different business types (supermarket, pharmacy, grocery, restaurant), configuring each branch with separate staff and inventory, processing sales in each branch, and verifying the owner admin can view consolidated analytics across all branches while each branch operates independently.

**Acceptance Scenarios**:

1. **Given** a tenant admin owns multiple businesses, **When** they create branches in their account, **Then** the system allows them to specify business type (supermarket, pharmacy, grocery, mini-mart, restaurant) and location for each branch
2. **Given** multiple branches exist under one tenant company, **When** the admin assigns staff to a specific branch, **Then** staff members can only access data and perform operations for their assigned branch
3. **Given** each branch has independent inventory, **When** a product is added to Branch A, **Then** it does not automatically appear in Branch B (inventory is isolated per branch unless explicitly shared)
4. **Given** sales occur across multiple branches, **When** the owner admin views the consolidated dashboard, **Then** they see aggregated analytics (total revenue, transaction count, top products) across all branches with drill-down capability per branch
5. **Given** a branch-specific manager, **When** they log into their branch, **Then** they see only their branch's data, staff, inventory, and analytics without visibility into other branches
6. **Given** a tenant company with multiple branches, **When** the owner transfers inventory from Branch A to Branch B, **Then** the system records an inter-branch transfer reducing Branch A stock and increasing Branch B stock with audit trail
7. **Given** different business types across branches, **When** the owner views branch-specific settings, **Then** each branch can have different tax rates, payment methods, branding, and operational configurations

---

### Edge Cases

- What happens when a tenant processes 100+ offline transactions and then syncs to cloud? Does sync handle large batches without timeout?
- How does the system handle sync conflicts when the same product is edited offline and online simultaneously?
- What happens when a customer's WhatsApp number is invalid or blocked?
- How does the AI chat agent handle ambiguous product requests like "I need medicine for headache"?
- What happens when a merchant's subscription expires while they have active orders in fulfillment?
- How does the system handle inventory going negative due to sync conflicts between POS and e-commerce platforms?
- What happens when a delivery rider accepts an order but never completes it?
- How does the system handle products with expiry dates in the past? Can they still be sold?
- What happens when CSV import contains duplicate SKUs or invalid data?
- How does the platform handle commission calculation if a marketplace order is refunded?
- What happens when a staff member forgets to clock out at end of shift? System does not auto clock-out; administrators must manually correct the clock-out time to ensure accurate payroll and attendance records.
- How does the system handle timezone differences for inter-city deliveries across Nigeria?
- What happens when an owner tries to transfer inventory between branches but one branch is offline?
- How does the system handle a staff member reassigned from Branch A to Branch B mid-shift while they have an active clock-in session?
- What happens when consolidated analytics are calculated across branches with different currencies or tax jurisdictions (future international expansion)?

## Requirements *(mandatory)*

### Functional Requirements

#### Core POS Requirements (Offline-First)

- **FR-001**: System MUST function fully offline using local SQLite database for all POS operations including sales, inventory, customer data, and staff actions
- **FR-002**: System MUST automatically sync all offline transactions to Supabase backend when internet connection is detected, handling sync conflicts using Operational Transformation or CRDTs for inventory updates to ensure arithmetic correctness when multiple devices modify the same product stock offline
- **FR-003**: System MUST allow cashiers to create sales transactions by selecting/scanning products, applying discounts, calculating taxes, and processing payments while offline
- **FR-004**: System MUST support multiple payment methods including cash, card, bank transfer, and mobile money (Nigeria-specific options)
- **FR-005**: System MUST generate receipts (digital and/or printable) with itemized products, taxes, discounts, payment method, and tenant branding
- **FR-006**: System MUST maintain real-time inventory tracking in SQLite, deducting stock when sales are processed and syncing to cloud when online
- **FR-007**: System MUST allow merchants to manage product catalog including product creation, editing, pricing, categories, variants (size, color), SKU, and expiry dates
- **FR-008**: System MUST display expiry alerts for products expiring within configurable timeframe (default 30 days) to prevent selling expired goods
- **FR-009**: System MUST support bulk product import via CSV file upload with validation for required fields (name, SKU, price, category, stock, expiry date)
- **FR-010**: System MUST allow cashiers to void/refund transactions with proper authorization and complete audit trail
- **FR-011**: System MUST record all transactions with timestamps, staff identity, items sold, payment details, customer information, and sync status (synced/pending)
- **FR-012**: System MUST support tax calculation based on configurable tax rates and rules per tenant

#### Multi-Tenancy and Authentication Requirements

- **FR-013**: System MUST provide complete data isolation between tenants at database and application layers ensuring no cross-tenant data access
- **FR-014**: System MUST implement authentication using OTP (One-Time Password) sent via SMS (for phone numbers) or email (for email addresses) with 5-minute expiration time for user registration and login, allowing users to choose their preferred authentication method
- **FR-015**: System MUST assign each tenant a unique identifier and subdomain or access path for their storefront
- **FR-016**: System MUST allow each tenant to configure custom branding including logo, colors, business name, and receipt templates
- **FR-017**: System MUST support tenant-specific configurations including tax rates, currency (Naira), business hours, payment methods, and delivery zones
- **FR-018**: System MUST provide role-based access control with predefined roles (Platform Admin, Tenant Admin, Manager, Cashier, Driver) and customizable permissions
- **FR-019**: System MUST enforce subscription-based limits per tenant including number of staff users, products, monthly transactions, and storage capacity

#### Customer Management and Marketplace Requirements

- **FR-020**: System MUST allow tenants to create public marketplace storefronts accessible to nearby customers via web browser
- **FR-021**: System MUST enable customers to browse products by category, search by name/keyword, and filter by price, availability, and location
- **FR-022**: System MUST display real-time inventory availability on storefront synced from offline POS data
- **FR-023**: System MUST allow customers to create accounts (phone or email-based OTP authentication), place orders for pickup or delivery, and track order status
- **FR-024**: System MUST maintain customer profiles with purchase history, total spend, order frequency, and delivery addresses
- **FR-025**: System MUST implement customer loyalty program with default earning rate of 1 point per ₦100 spent (configurable per tenant) and redemption rules
- **FR-026**: System MUST allow merchants to view customer insights including top customers, purchase patterns, and loyalty tier distribution
- **FR-027**: System MUST support order lifecycle management with statuses: pending, confirmed, preparing, ready for pickup, out for delivery, delivered, cancelled

#### Staff Management Requirements

- **FR-028**: System MUST allow tenant administrators to create, edit, and deactivate staff accounts with assigned roles and permissions
- **FR-029**: System MUST provide clock in/clock out functionality for staff members to record shift start and end times
- **FR-030**: System MUST track staff attendance including clock in/out timestamps, total hours worked, and attendance history; system does not auto clock-out staff members, requiring manual correction by administrators for forgotten clock-outs to ensure accuracy
- **FR-031**: System MUST attribute all sales transactions to the logged-in staff member for performance tracking and accountability
- **FR-032**: System MUST generate staff reports showing individual sales performance, hours worked, and attendance patterns for payroll and management
- **FR-032a**: System MUST alert administrators about open clock-in sessions (staff who clocked in but have not clocked out) to facilitate manual correction of forgotten clock-outs

#### Delivery Management Requirements

- **FR-033**: System MUST support dual delivery options: local delivery (bike/bicycle riders) and platform inter-city delivery service
- **FR-034**: System MUST suggest delivery option based on customer delivery address distance with default threshold of 25 kilometers (local bike/bicycle delivery within 25km, platform inter-city delivery beyond 25km, configurable per tenant)
- **FR-035**: System MUST allow merchants to create delivery orders with customer address, contact information, items, delivery instructions, and selected delivery type
- **FR-036**: System MUST generate unique tracking numbers for each delivery order accessible via public tracking link
- **FR-037**: System MUST assign local delivery orders to available bike/bicycle riders and notify them with delivery details via SMS or in-app notification
- **FR-038**: System MUST hand off inter-city delivery orders to platform delivery service with tracking integration for status updates
- **FR-039**: System MUST support delivery status workflow: pending, assigned, picked up, in transit, delivered, failed, cancelled
- **FR-040**: System MUST allow riders/drivers to update delivery status and capture proof of delivery (photo, signature, recipient name)
- **FR-041**: System MUST update customer tracking page within 60 seconds when delivery status changes
- **FR-042**: System MUST provide merchants with delivery dashboard showing active deliveries, rider performance, delivery success rate, and average delivery time

#### E-Commerce Integration Requirements

- **FR-043**: System MUST authenticate with third-party e-commerce platforms (WooCommerce, Shopify, etc.) using API credentials provided by merchant
- **FR-044**: System MUST sync products from connected e-commerce platforms to POS including name, description, price, SKU, categories, images, and variants
- **FR-045**: System MUST sync inventory levels bidirectionally between POS and connected platforms ensuring both systems reflect current stock
- **FR-046**: System MUST import orders from connected platforms into the POS order management system with customer details, items, and payment status
- **FR-047**: System MUST handle sync conflicts using configurable rules (POS priority, platform priority, last-write-wins, or manual resolution queue)
- **FR-048**: System MUST provide sync status dashboard showing last sync time, pending sync items, sync errors, and sync health per connected platform
- **FR-049**: System MUST support multiple simultaneous platform connections per tenant (e.g., WooCommerce + Shopify)

#### AI Chat Agent Requirements

- **FR-050**: System MUST provide AI-powered chat interface accessible from merchant storefronts for customer interactions
- **FR-051**: System MUST enable AI agent to query real-time inventory when customers ask about product availability
- **FR-052**: System MUST allow AI agent to create customer orders based on chat conversation including product selection, quantity, delivery details
- **FR-053**: System MUST enable AI agent to modify existing orders (add items, remove items, change quantities) based on customer chat requests
- **FR-054**: System MUST allow AI agent to cancel orders when customers request cancellation via chat with proper inventory restoration
- **FR-055**: System MUST log all AI chat conversations for merchant review, training, and customer service escalation
- **FR-056**: System MUST provide fallback to human merchant when AI agent cannot handle complex requests or customer specifically requests human assistance

#### Analytics and Reporting Requirements

- **FR-057**: System MUST provide analytics dashboard with key metrics: total revenue, transaction count, average order value, top products, and growth trends
- **FR-058**: System MUST generate product sales history reports showing sales volume, revenue, and trends over selectable time periods (daily, weekly, monthly, custom)
- **FR-059**: System MUST visualize product sales data with graphs (line charts for trends, bar charts for comparisons, pie charts for category distribution)
- **FR-060**: System MUST enable category-based product comparison showing side-by-side sales performance for products in the same category
- **FR-061**: System MUST analyze sales patterns including peak sales hours, day-of-week trends, seasonal patterns, and customer purchase behavior
- **FR-062**: System MUST provide inventory turnover analysis showing fast-moving vs. slow-moving products to inform purchasing decisions
- **FR-063**: System MUST generate staff performance reports showing individual sales, average transaction value, and customer ratings per staff member
- **FR-064**: System MUST support data export (CSV, PDF) for all reports and analytics for external analysis or record-keeping

#### WhatsApp Communication Requirements

- **FR-065**: System MUST authenticate with WhatsApp Business API using tenant-provided credentials (phone number, API key)
- **FR-066**: System MUST send automated order confirmation messages to customers via WhatsApp when orders are placed (if customer provides WhatsApp number)
- **FR-067**: System MUST send delivery status update notifications to customers via WhatsApp when delivery status changes
- **FR-068**: System MUST provide unified inbox within POS system to receive and respond to customer WhatsApp messages
- **FR-069**: System MUST support WhatsApp message templates with dynamic variables (customer name, order number, delivery time, tracking link)
- **FR-070**: System MUST allow merchants to send promotional messages to customer segments based on criteria (loyalty tier, purchase history, location)
- **FR-071**: System MUST log all WhatsApp message history for compliance and customer service reference
- **FR-072**: System MUST implement fallback notification mechanism (SMS or email) when WhatsApp message delivery fails

#### Payments and Monetization Requirements

- **FR-073**: System MUST support tiered subscription plans with different feature access, user limits, product limits, and transaction quotas
- **FR-074**: System MUST enforce subscription limits preventing tenants from exceeding their plan's constraints (staff users, products, monthly transactions)
- **FR-075**: System MUST calculate platform commission on marketplace sales based on tenant's subscription plan (e.g., 2.5% for basic, 1.5% for premium)
- **FR-076**: System MUST track commission earnings per tenant and provide commission reports for platform revenue management
- **FR-077**: System MUST generate monthly invoices for tenants including subscription fees and commission charges
- **FR-078**: System MUST allow tenants to view billing history, current plan details, usage metrics, and upgrade/downgrade subscription options
- **FR-079**: System MUST integrate with payment gateways for subscription and marketplace transaction processing (Paystack, Flutterwave for Nigeria market)

#### Multi-Branch and Multi-Business Management Requirements

- **FR-080**: System MUST allow tenant companies to create multiple branches under a single tenant account with each branch having a unique identifier, name, business type, and location
- **FR-081**: System MUST support different business types per branch (supermarket, pharmacy, grocery shop, mini-mart, restaurant) with type-specific configurations and features
- **FR-082**: System MUST isolate inventory per branch by default, ensuring products added to one branch do not appear in other branches unless explicitly shared
- **FR-083**: System MUST allow branch-specific staff assignments ensuring staff members can only access data and operations for their assigned branch(es)
- **FR-084**: System MUST provide consolidated analytics dashboard for tenant admins showing aggregated metrics across all branches with drill-down capability per branch
- **FR-085**: System MUST allow inter-branch inventory transfers with audit trail recording source branch, destination branch, products, quantities, transfer date, and authorizing staff
- **FR-086**: System MUST support branch-specific configurations including tax rates, payment methods, branding, receipt templates, business hours, and delivery zones
- **FR-087**: System MUST enforce role-based access control at branch level where branch managers see only their branch data while tenant admins see all branches
- **FR-088**: System MUST track sales, inventory, and staff performance independently per branch while maintaining consolidated reporting for tenant admins
- **FR-089**: System MUST sync offline transactions per branch to cloud, handling conflicts at branch level without affecting other branches
- **FR-090**: System MUST allow tenant admins to compare performance across branches including revenue comparisons, top-performing products, and efficiency metrics
- **FR-091**: System MUST support shared customer profiles across branches where a customer's purchase history and loyalty points are accessible company-wide
- **FR-092**: System MUST calculate subscription limits at tenant company level (total users, products, transactions across all branches) with per-branch visibility

### Key Entities

- **Tenant**: Tenant company account representing the business owner with one or more branches, isolated data, subscription plan, usage limits, and consolidated analytics access
- **Branch**: Physical or logical business location under a tenant with unique identifier, name, business type (supermarket, pharmacy, grocery, mini-mart, restaurant), location, independent inventory, staff assignments, and branch-specific configurations
- **User**: Person using the system belonging to a tenant and assigned to one or more branches with role (Platform Admin, Tenant Admin, Branch Manager, Cashier, Driver), phone number or email address (authentication identifier), permissions, and branch access scope
- **Product**: Sellable item belonging to a specific branch with name, description, SKU, barcode, price, category, variants, inventory quantity, expiry date, branch reference, and sync mappings to e-commerce platforms
- **InventoryTransaction**: Record of inventory change with product reference, branch reference, quantity delta, transaction type (sale, restock, adjustment, expiry, inter-branch transfer), timestamp, and staff reference
- **InterBranchTransfer**: Record of inventory transfer between branches with source branch, destination branch, product list, quantities, transfer date, authorizing staff, and transfer status
- **Sale**: Completed transaction with items sold, quantities, prices, taxes, discounts, payment method, total amount, cashier, branch reference, customer reference, timestamp, and sync status
- **SaleItem**: Line item in a sale linking to product with quantity sold, unit price at time of sale, discounts applied, and subtotal
- **Customer**: Person making purchases with phone number or email address (primary identifier), name, WhatsApp number, purchase history, loyalty points, and delivery addresses
- **Order**: Customer order (from marketplace or synced from e-commerce platform) with items, quantities, customer details, order status, payment status, fulfillment type (pickup/delivery), and delivery details
- **Delivery**: Delivery task with order reference, delivery type (local bike/bicycle or inter-city), customer address, assigned rider/service, status, tracking number, estimated delivery time, and proof of delivery
- **Rider**: Delivery personnel (bike/bicycle rider) with contact information, assigned deliveries, delivery completion rate, average delivery time, and current availability
- **StaffAttendance**: Time tracking record with staff reference, clock in timestamp, clock out timestamp, total hours worked, and date
- **ECommerceConnection**: Integration configuration with platform type (WooCommerce, Shopify), API credentials, sync settings, last sync timestamp, and sync status
- **ChatConversation**: AI chat session with customer reference, merchant reference, messages, order created/modified, and escalation status
- **Subscription**: Tenant subscription plan with tier level, feature access, user limits, product limits, transaction quota, monthly fee, and commission rate
- **Commission**: Platform commission record with order reference, sale amount, commission percentage, commission amount, and settlement status
- **WhatsAppMessage**: Communication record with sender, recipient, message content, timestamp, template used, delivery status, and conversation thread
- **Receipt**: Transaction receipt with tenant branding, itemized products, payment details, format (digital, print), and sync status

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Cashiers can complete a standard 5-item sale transaction in under 45 seconds from product selection to receipt generation while completely offline
- **SC-002**: System syncs 100 offline transactions to Supabase backend within 2 minutes when internet connection is restored
- **SC-003**: System supports at least 200 concurrent tenants with 5-10 active users each without performance degradation
- **SC-004**: PWA loads on low-end Android devices (2GB RAM, 3G connection) within 5 seconds and remains responsive during offline operations
- **SC-005**: Product expiry alerts identify 100% of products expiring within warning threshold preventing accidental sale of expired goods
- **SC-006**: E-commerce platform sync completes within 5 minutes for catalogs up to 1,000 products with 95% sync success rate
- **SC-007**: AI chat agent successfully handles 80% of customer inquiries without human escalation including product search, availability checks, and order creation
- **SC-008**: Customers receive order confirmation notifications (WhatsApp or SMS) within 30 seconds of order placement
- **SC-009**: Customer tracking pages reflect delivery status updates within 60 seconds of rider status changes
- **SC-010**: 95% of sales transactions complete successfully on first attempt without errors or system failures
- **SC-011**: Analytics dashboards load within 3 seconds and provide accurate sales insights based on real-time transaction data
- **SC-012**: System maintains 99.5% uptime during business hours with zero cross-tenant data leaks over any 90-day period
- **SC-013**: Merchants can onboard (register, configure branding, import products via CSV, configure integrations) within 60 minutes
- **SC-014**: Platform processes subscription billing for 200 tenants and calculates commissions on 10,000 monthly marketplace transactions with 100% accuracy
- **SC-015**: Tenant admins with 5 branches can view consolidated analytics aggregating data from all branches within 3 seconds with accurate drill-down per branch

## Scope and Boundaries *(mandatory)*

### In Scope

- **Core Platform**:
  - Offline-first POS system with SQLite local storage and Supabase cloud sync
  - Multi-tenant architecture with complete data isolation
  - Progressive Web App (PWA) optimized for mobile devices and low-end Android
  - Phone or email-based OTP authentication with 5-minute expiration (Nigeria-first UX)

- **POS Features**:
  - Inventory management with expiry tracking and alerts
  - CSV bulk product import
  - Cart, discounts, tax calculation, multiple payment methods
  - Receipt generation with tenant branding
  - Transaction history and audit trail
  - Void/refund capabilities

- **Marketplace & Customers**:
  - Digital storefront for tenants
  - Customer accounts and profiles
  - Order placement (pickup and delivery)
  - Customer loyalty program with points
  - Purchase history tracking

- **Staff Management**:
  - Role-based access control (Platform Admin, Tenant Admin, Manager, Cashier, Driver)
  - Clock in/out time tracking
  - Staff attendance reports
  - Sales performance attribution

- **Delivery**:
  - Dual delivery options (local bike/bicycle + platform inter-city)
  - Delivery order management
  - Rider assignment and notification
  - Customer order tracking with public links
  - Proof of delivery capture

- **Integrations**:
  - Third-party e-commerce platforms (WooCommerce, Shopify, etc.)
  - Bidirectional product and inventory sync
  - Order import from e-commerce platforms
  - WhatsApp Business API for notifications and messaging
  - Payment gateways (Paystack, Flutterwave)

- **AI & Automation**:
  - AI chat agent for remote customer purchases
  - Conversational product search and availability checks
  - Order creation/modification/cancellation via chat
  - Automated notifications (WhatsApp, SMS, email)

- **Analytics & Insights**:
  - Product sales history and trends
  - Sales graphs and visualizations
  - Category-based product comparisons
  - Sales pattern analysis (peak hours, day-of-week trends)
  - Inventory turnover analysis
  - Staff performance reports

- **Monetization**:
  - Tiered subscription plans with feature gating
  - Commission tracking on marketplace sales
  - Automated billing and invoicing
  - Usage metrics and limits enforcement

- **Multi-Branch Management**:
  - Multiple branches per tenant company
  - Different business types per branch (supermarket, pharmacy, grocery, mini-mart, restaurant)
  - Branch-specific inventory, staff, and configurations
  - Consolidated analytics across all branches
  - Inter-branch inventory transfers
  - Shared customer profiles company-wide

### Out of Scope

- **Medical Services**: No prescription management, doctor consultations, lab tests, or clinical decision support (pharmacies sell products only, not medical services)
- **Inventory Ownership**: Platform does NOT own, purchase, or stock inventory - it is a software and services provider only
- **Native Mobile Apps**: Initial release is PWA; iOS and Android native apps are future consideration
- **Advanced Accounting**: General ledger, balance sheets, P&L statements, tax filing (tenants should use dedicated accounting software)
- **Employee Payroll**: Salary calculation, payroll processing, tax withholding (time tracking provided, but not full HR/payroll)
- **Customer Loyalty Redemption**: Initial release tracks loyalty points; in-app redemption for discounts/rewards is future enhancement
- **Route Optimization**: Delivery rider route planning and optimization (manual routing initially)
- **Voice/Video Calling**: Communication limited to text-based chat and messaging (no voice or video calls)
- **Cryptocurrency Payments**: Fiat currency (Naira) and traditional payment methods only
- **International Expansion**: Nigeria-first UX and payment integrations; other African markets are future consideration
- **AI Implementation**: AI hooks and architecture designed but actual AI models (forecasting, fraud detection, advanced insights) deferred to future releases

## Assumptions *(mandatory)*

- Tenants have access to Android devices or modern web browsers capable of running PWA
- Internet connectivity is intermittent but available periodically for cloud sync (not 100% offline forever)
- Merchants using e-commerce integrations have active stores on supported platforms (WooCommerce, Shopify) with API access enabled
- WhatsApp Business API access requires approval from WhatsApp and may not be immediately available to all tenants
- Customers have smartphones with web browsers to access marketplace storefronts and order tracking
- Phone numbers are primary identifier in Nigeria with SMS delivery for OTP being reliable; email authentication provided as alternative for users without reliable SMS access
- Payment processing via Paystack/Flutterwave is available and compliant with Nigerian financial regulations
- Delivery riders (bike/bicycle) have smartphones capable of receiving notifications and updating delivery status
- Initial release supports single currency (Nigerian Naira); multi-currency support is future consideration
- Tax calculation follows standard Nigerian VAT rules; complex custom tax scenarios may require manual configuration
- Receipt printing uses browser print functionality or thermal printers with standard interfaces
- Tenants are responsible for compliance with local regulations (business registration, tax compliance, data privacy)
- Supabase backend provides sufficient scalability, reliability, and data residency options for Nigerian market
- SQLite provides reliable offline data persistence on target devices (Android, web browsers with IndexedDB)
- Platform delivery service for inter-city orders has API or partnership agreement for integration
- System operates in English initially; multi-language support (Yoruba, Hausa, Igbo) is future consideration

## Dependencies *(mandatory)*

- **Supabase Backend**: Requires Supabase project setup with PostgreSQL database, authentication, real-time subscriptions, and storage
- **SQLite/IndexedDB**: Requires browser support for IndexedDB (for web) or SQLite (for potential native apps) for offline data persistence
- **SMS Provider**: Requires SMS gateway (Termii, SMS Portal, Africa's Talking) for OTP delivery during phone authentication
- **Email Provider**: Requires email service (Supabase Auth, SendGrid, Mailgun) for OTP delivery during email authentication
- **WhatsApp Business API**: Requires approved WhatsApp Business API access (not standard WhatsApp Business app) which has approval process and may have regional restrictions
- **Payment Gateways**: Integration with Paystack and/or Flutterwave for payment processing (subject to merchant approval and fee structures)
- **E-Commerce Platform APIs**: WooCommerce REST API v3+, Shopify Admin API, or other platforms require API access enabled by merchant
- **Third-party Delivery Service**: Platform inter-city delivery requires partnership or API integration with logistics provider (e.g., GIG Logistics, Kwik Delivery, SendStack)
- **AI/LLM Service**: AI chat agent requires integration with LLM provider (OpenAI, Anthropic, or local models) for natural language processing
- **Internet Connectivity**: While offline-first, system requires periodic internet access for cloud sync, authentication, and third-party integrations
- **Browser Compatibility**: Requires modern browsers with PWA support (Chrome 90+, Firefox 88+, Safari 14+, Edge 90+)
- **Mobile Device Specifications**: Optimized for low-end Android devices with minimum 2GB RAM, Android 8.0+, and 3G connectivity

## Non-Functional Requirements *(mandatory)*

### Performance

- **Offline Operations**: All POS transactions (sales, inventory updates, receipt generation) complete in under 2 seconds while offline
- **Sync Performance**: Cloud sync handles up to 100 pending offline transactions within 2 minutes when internet becomes available
- **PWA Load Time**: Progressive Web App loads within 5 seconds on low-end Android devices over 3G connection
- **Dashboard Responsiveness**: Analytics dashboards and reports load within 3 seconds for datasets up to 10,000 transactions
- **Search Performance**: Product search returns results within 1 second for catalogs up to 10,000 products (offline local search)
- **API Response Time**: Backend API responses complete within 500ms for 90% of requests when online
- **Concurrent Users**: System supports 200 concurrent tenants with 5-10 active users each (1,000-2,000 total concurrent users)

### Offline-First Architecture

- **Full Offline Functionality**: Core POS features (sales, inventory, customer lookup, staff clock in/out) work 100% offline without degradation
- **Local Data Persistence**: SQLite/IndexedDB stores all tenant data locally with automatic background sync
- **Conflict Resolution**: System handles sync conflicts using Operational Transformation or CRDTs for inventory (arithmetic correctness), last-write-wins for non-critical data, and manual resolution queue for complex edge cases
- **Sync Status Visibility**: Users can see sync status (synced, pending, failed) for transactions and data changes
- **Background Sync**: Service workers handle background sync automatically when connectivity is detected
- **Offline Indicators**: Clear UI indicators show when system is offline vs. online

### Security

- **Data Encryption**: All data transmission encrypted using TLS 1.2 or higher; local data encrypted at rest on device
- **Multi-Tenant Isolation**: Complete data isolation between tenants at database level using Row Level Security (RLS) in Supabase
- **Authentication**: Phone or email-based OTP authentication with 5-minute expiration time and rate limiting to prevent brute force attacks
- **Authorization**: Role-based access control (RBAC) enforced at API and UI levels
- **API Security**: API credentials (e-commerce platforms, WhatsApp, payment gateways) stored encrypted in Supabase vault
- **Audit Logging**: All critical operations (sales, refunds, inventory adjustments, user changes, sync events) logged with timestamps and user attribution
- **Session Management**: Automatic session timeout after 30 minutes of inactivity with secure token refresh
- **Payment Security**: PCI-DSS compliant payment processing through certified gateways (Paystack, Flutterwave)

### Reliability

- **Uptime**: System maintains 99.5% uptime during business hours (6 AM - 10 PM WAT)
- **Data Backup**: Automated daily backups of Supabase database with 30-day retention
- **Disaster Recovery**: Point-in-time recovery capability for tenant data in case of data loss or corruption
- **Graceful Degradation**: System continues core operations (offline POS) even when third-party services (WhatsApp, e-commerce sync, payment gateways) are unavailable
- **Transaction Integrity**: All sales transactions persisted to local storage before confirmation ensuring zero data loss
- **Sync Resilience**: Failed sync operations are queued and retried automatically with exponential backoff

### Usability (Nigeria-First UX)

- **Learning Curve**: Cashiers with basic smartphone skills can complete training and process first sale within 2 hours
- **Touch-Optimized**: Interface optimized for touch screens with large tap targets (minimum 44x44px) for ease of use on mobile devices
- **Minimal Clicks**: Standard sale transaction requires 3-5 taps from product selection to receipt
- **Clear Feedback**: Clear visual and haptic feedback for all user actions (transaction success, sync status, errors)
- **Error Messages**: Actionable error messages in plain language (English initially) with suggested remediation steps
- **Progressive Disclosure**: Advanced features hidden initially; progressive disclosure based on user role and subscription tier
- **Responsive Design**: Adapts to various screen sizes (small Android phones to tablets) with consistent experience
- **Low Bandwidth**: Minimal data usage for core operations; images and assets cached locally for offline access

### Scalability

- **Horizontal Scaling**: System architecture supports horizontal scaling to accommodate tenant growth (target 10,000 tenants in 24 months)
- **Database Scalability**: Supabase PostgreSQL with partitioning strategy supports growing transaction volume (target 1M transactions/month)
- **Storage Scalability**: Local storage management includes automatic archival of old data to cloud and cleanup of local cache
- **API Rate Limiting**: Per-tenant and per-user rate limiting protects against abuse and ensures fair resource allocation
- **Async Processing**: Background jobs handle heavy operations (CSV import, sync, analytics calculation, commission processing)

### Extensibility (AI Hooks)

- **Pluggable AI Architecture**: System designed with hooks for future AI features (forecasting, fraud detection, sales insights) without requiring core refactoring
- **Event-Driven**: Event bus architecture allows AI modules to subscribe to business events (sale completed, inventory low, customer behavior)
- **Data Pipeline**: Transaction and inventory data structured for machine learning ingestion and analysis
- **API for AI**: Dedicated API endpoints designed for AI agent integration (product search, order creation, inventory queries)

## Risks and Mitigations *(mandatory)*

### Risk 1: Offline Sync Conflicts and Data Inconsistencies

**Description**: When multiple devices operate offline simultaneously (e.g., two cashiers in same store) and then sync, conflicts can occur with inventory updates, customer data changes, or transaction records.

**Impact**: Inventory inaccuracies, duplicate transactions, customer data corruption, loss of business data integrity.

**Mitigation**:
- Implement Operational Transformation or CRDTs for inventory updates to ensure arithmetic correctness (e.g., if Device A sells 2 units and Device B sells 3 units offline, final stock = original - 5, preserving all operations)
- Use last-write-wins strategy for non-critical data (customer info, product descriptions)
- Provide manual resolution queue for edge cases that cannot be auto-resolved
- Display sync status clearly so merchants know when data is out of sync
- Maintain complete audit trail of all sync operations for troubleshooting
- Test extensively with multi-device offline scenarios before launch

### Risk 2: Low-End Device Performance Limitations

**Description**: Target devices (low-end Android with 2GB RAM, 3G connectivity) may struggle with PWA performance, especially with large local databases or complex analytics.

**Impact**: Slow app performance, crashes, poor user experience leading to merchant abandonment.

**Mitigation**:
- Implement aggressive local data pruning (archive old transactions to cloud, keep only recent data locally)
- Use virtual scrolling and pagination to avoid rendering large lists
- Optimize SQLite queries with proper indexing and query planning
- Lazy load analytics and reporting features only when needed
- Test on actual low-end devices representative of target market
- Provide "lite mode" that disables heavy features for very low-end devices
- Monitor performance metrics and user feedback to identify bottlenecks

### Risk 3: WhatsApp Business API Access Restrictions

**Description**: WhatsApp Business API requires approval from WhatsApp and may not be available to all tenants or regions. Approval process can take weeks or months, and not all business types are approved.

**Impact**: Tenants cannot use WhatsApp features immediately, reducing platform value proposition and differentiation.

**Mitigation**:
- Make WhatsApp integration optional, not required for core platform functionality
- Provide alternative notification methods (SMS, email, in-app push) as fallback
- Partner with WhatsApp Business Solution Providers to streamline approval process
- Clearly document WhatsApp requirements during tenant onboarding
- Pre-qualify tenants for WhatsApp eligibility based on business type
- Consider using unofficial WhatsApp Web API as temporary workaround (with risk disclosure)

### Risk 4: E-Commerce Platform Sync Complexity

**Description**: Different e-commerce platforms (WooCommerce, Shopify) have different API structures, rate limits, and sync behaviors. Bidirectional sync with real-time inventory can lead to sync loops, conflicts, or API throttling.

**Impact**: Sync failures, inventory discrepancies between POS and online stores, merchant frustration, overselling products.

**Mitigation**:
- Implement platform-specific adapters to normalize differences
- Use webhook subscriptions for real-time updates instead of polling where possible
- Implement exponential backoff and rate limit handling for all API calls
- Provide sync scheduling options (real-time, hourly, daily) based on merchant needs
- Create detailed sync logs visible to merchants for troubleshooting
- Support manual sync triggers and conflict resolution UI
- Test thoroughly with actual WooCommerce and Shopify stores before launch

### Risk 5: AI Chat Agent Hallucinations and Errors

**Description**: AI chat agent may provide incorrect product information, create wrong orders, or fail to understand customer intent, leading to customer dissatisfaction or incorrect transactions.

**Impact**: Customer frustration, incorrect orders requiring refunds, merchant complaints, reduced trust in AI feature.

**Mitigation**:
- Implement strict AI guardrails limiting actions to verified data sources (actual inventory, product catalog)
- Require explicit confirmation before creating or modifying orders via chat
- Provide easy escalation to human merchant for complex queries
- Log all AI interactions for merchant review and quality control
- Implement feedback mechanism to improve AI responses over time
- Start with read-only AI features (product search, availability) before adding transactional capabilities
- Clear disclosure to customers that they are interacting with AI agent

### Risk 6: Payment Gateway Integration Failures

**Description**: Payment gateways (Paystack, Flutterwave) may experience outages, API changes, or integration issues preventing subscription billing or marketplace transaction processing.

**Impact**: Lost revenue for platform and merchants, subscription lapses, inability to process marketplace orders.

**Mitigation**:
- Support multiple payment gateways to provide redundancy
- Implement graceful fallback to cash/manual payment with offline reconciliation
- Queue failed payment attempts for automatic retry
- Provide clear error messages and merchant notifications when payment fails
- Maintain webhook endpoints for payment status updates
- Monitor payment gateway health and switch automatically if possible
- Have manual billing process as ultimate fallback

### Risk 7: Delivery Rider Reliability and Accountability

**Description**: Local bike/bicycle delivery riders may not update status promptly, may fail to complete deliveries, or may provide poor customer service, harming platform reputation.

**Impact**: Inaccurate customer tracking, late or failed deliveries, customer complaints, merchant dissatisfaction.

**Mitigation**:
- Implement rider performance tracking and rating system
- Require proof of delivery (photo, signature, customer confirmation code)
- Provide merchant tools to reassign deliveries to different riders
- Send automated reminders to riders for status updates
- Allow manual status overrides by merchant administrators
- Consider rider onboarding and training program
- Integrate with third-party delivery platforms as alternative to managing riders directly

### Risk 8: Multi-Tenant Data Privacy and Compliance

**Description**: Handling customer data across multiple tenants and ensuring GDPR-like privacy controls in Nigerian context requires careful data management and compliance measures.

**Impact**: Legal liability, regulatory fines, reputational damage, tenant loss, customer trust erosion.

**Mitigation**:
- Implement strong multi-tenant data isolation using Supabase Row Level Security
- Provide tenant administrators with data management tools (customer data export, deletion, consent management)
- Include data processing agreements in tenant terms of service
- Maintain compliance documentation and regular security audits
- Encrypt data at rest and in transit
- Implement data retention policies and automated cleanup
- Stay informed about Nigerian data protection regulations (NDPR) and ensure compliance

### Risk 9: Subscription Non-Payment and Revenue Leakage

**Description**: Tenants may fail to pay subscription fees or marketplace commissions may not be properly calculated/collected, leading to revenue loss for the platform.

**Impact**: Platform revenue loss, unsustainable business model, inability to maintain service quality.

**Mitigation**:
- Implement automated subscription billing with retry logic for failed payments
- Enforce hard limits when subscriptions lapse (block new transactions after grace period)
- Automate commission calculation on every marketplace sale with audit trail
- Provide clear billing transparency and invoicing to tenants
- Offer multiple payment methods to reduce payment friction
- Implement dunning management for failed payments (reminders, grace periods, account suspension)
- Monitor revenue metrics closely and investigate anomalies

### Risk 10: Over-Engineering for Unvalidated Features

**Description**: Building complex features (AI chat, e-commerce sync, advanced analytics) before validating core POS value proposition may waste resources and delay MVP launch.

**Impact**: Extended time to market, wasted development resources, building features users don't want, missing market opportunity.

**Mitigation**:
- Prioritize ruthlessly based on phases defined in roadmap (Core POS first)
- Launch MVP with essential features only, validate with real merchants before adding complexity
- Use feature flags to selectively enable advanced features for beta testers
- Gather user feedback continuously and adjust roadmap based on actual usage
- Design modular architecture allowing features to be added/removed without core refactoring
- Measure feature usage and ROI to justify continued investment
- Be willing to deprecate features that don't deliver value

## Constraints *(mandatory)*

- **Technical**: System must be Progressive Web App (PWA) initially; native iOS and Android apps are future consideration
- **Technical**: Offline-first architecture requires local data storage using SQLite/IndexedDB with automatic cloud sync to Supabase
- **Technical**: Must support low-end Android devices with minimum 2GB RAM and Android 8.0+ running over 3G connectivity
- **Platform**: Initial release uses Supabase as backend (PostgreSQL, Authentication, Realtime, Storage); migration to other backends not supported in V1
- **Geographic**: Nigeria-first UX with phone or email-based OTP authentication, Naira currency, and local payment gateways (Paystack, Flutterwave)
- **Language**: Initial release supports English language only; multi-language support (Yoruba, Hausa, Igbo) deferred to future releases
- **Business Model**: Platform does NOT own inventory or businesses; provides software, payments, delivery orchestration, and marketplace connectivity only
- **Business Scope**: No medical services (prescriptions, doctor consultations, lab tests) in V1; pharmacies sell products only
- **Budget**: No specific budget constraints at this stage; costs will be determined during planning phase
- **Timeline**: MVP (Phase 1: Core POS) required within specific timeframe to be determined during planning; subsequent phases delivered in iterative releases
- **Regulatory**: Tenants are responsible for business registration, tax compliance, and local regulatory requirements
- **Regulatory**: Platform must comply with Nigerian Data Protection Regulation (NDPR) for handling customer personal data
- **Integration**: WhatsApp integration limited to WhatsApp Business API features (templates, notifications, business-initiated messages); requires WhatsApp approval
- **Integration**: E-commerce platform sync limited to supported platforms' REST API capabilities (WooCommerce v3+, Shopify Admin API)
- **Integration**: Platform inter-city delivery requires partnership or API agreement with logistics provider
- **AI**: AI chat agent and AI hooks are architectural provisions; actual AI model training and implementation deferred to post-V1 releases
- **Payment**: Payment processing subject to payment gateway approval, fee structures, and availability in Nigerian market
- **Scalability**: Initial architecture designed for up to 10,000 tenants and 1M transactions/month; larger scale requires infrastructure upgrades

## Development Phases *(mandatory)*

### Phase 1: Core POS (MVP)

**Goal**: Deliver offline-first POS system that allows independent shops to manage inventory, process sales, and operate reliably in low internet conditions.

**Key Features**:
- Offline-first POS with SQLite local storage and Supabase cloud sync
- Multi-tenant architecture with complete data isolation
- Phone or email-based OTP authentication with 5-minute expiration
- Inventory management with expiry alerts
- CSV bulk product import
- Sales transactions (cart, discounts, tax, multiple payment methods)
- Receipt generation with tenant branding
- Staff management with roles and permissions
- Progressive Web App (PWA) optimized for low-end Android

**Success Criteria**:
- Cashiers can process sales completely offline
- 100 offline transactions sync within 2 minutes when online
- PWA loads in under 5 seconds on low-end Android over 3G
- Zero cross-tenant data leaks in multi-tenant testing

**Timeline**: To be determined during planning

---

### Phase 2: Customers & Marketplace

**Goal**: Extend platform from in-store POS to online marketplace enabling businesses to reach nearby customers and manage customer relationships.

**Key Features**:
- Public marketplace storefronts for tenants
- Customer accounts and profiles (phone or email-based OTP authentication)
- Order placement (pickup and delivery options)
- Customer loyalty program with points tracking
- Purchase history and customer insights
- Staff time tracking (clock in/out)
- Staff performance attribution and reports

**Success Criteria**:
- Customers can browse and place orders on merchant storefronts
- Customer loyalty points calculated accurately on all purchases
- Staff clock in/out times recorded with 100% accuracy
- Merchants can view customer insights and purchase patterns

**Timeline**: Post-Phase 1 MVP launch

---

### Phase 3: Delivery

**Goal**: Enable order fulfillment through dual delivery options (local bike/bicycle and platform inter-city delivery) with real-time customer tracking.

**Key Features**:
- Delivery order management
- Dual delivery options (local vs. inter-city based on distance)
- Rider assignment and notifications
- Delivery status tracking workflow
- Customer order tracking with public links
- Proof of delivery capture (photo, signature)
- Delivery performance analytics

**Success Criteria**:
- Delivery orders assigned to riders within 2 minutes of creation
- Customer tracking pages update within 60 seconds of status change
- 90% of deliveries marked complete with proof of delivery
- Merchants can view delivery performance metrics

**Timeline**: Post-Phase 2

---

### Phase 4: Integrations & AI

**Goal**: Integrate with third-party e-commerce platforms, WhatsApp messaging, and AI-powered chat agent for enhanced customer experience.

**Key Features**:
- Third-party e-commerce platform integrations (WooCommerce, Shopify)
- Bidirectional product and inventory sync
- Order import from e-commerce platforms
- WhatsApp Business API integration for notifications
- Unified messaging inbox
- AI chat agent for remote customer purchases
- Conversational product search and order management

**Success Criteria**:
- E-commerce platforms sync 1,000 products within 5 minutes with 95% success rate
- Customers receive WhatsApp notifications within 30 seconds
- AI chat agent handles 80% of customer inquiries without human escalation
- Merchants can manage messages from unified inbox

**Timeline**: Post-Phase 3

---

### Phase 5: Analytics & Payments

**Goal**: Provide comprehensive business intelligence and implement platform monetization through subscriptions and commissions.

**Key Features**:
- Analytics dashboard with key metrics
- Product sales history and trends with graphs
- Category-based product comparisons
- Sales pattern analysis (peak hours, seasonal trends)
- Inventory turnover analysis
- Tiered subscription plans with feature gating
- Commission tracking on marketplace sales
- Automated billing and invoicing

**Success Criteria**:
- Analytics dashboards load within 3 seconds for 10,000 transaction datasets
- Merchants can compare product sales performance across categories
- Subscription billing processes 200 tenants with 100% accuracy
- Platform commission calculated correctly on 10,000 monthly marketplace transactions

**Timeline**: Post-Phase 4

---

**Note**: Each phase is designed as independently deployable increment delivering value to merchants and customers. Phases may overlap in development but deployment follows sequential order ensuring core functionality before advanced features.
