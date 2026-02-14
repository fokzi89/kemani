# Feature Specification: Ecommerce Storefront for Tenant Branches

**Feature Branch**: `002-ecommerce-storefront`
**Created**: 2026-02-11
**Status**: Draft
**Input**: User description: "Ecommerce storefront for tenant branches with customer authentication (Google/Apple sign-in and guest checkout), product list page with search and filtering (branch filter for higher plans), product detail page with live/AI agent chat button (AI agent for higher plans only), and checkout flow supporting both authenticated and guest customers. Customers can be affiliated with multiple tenant branches."

## Clarifications

### Session 2026-02-11

- Q: How should shopping carts be scoped when customers browse multiple branches? → A: Separate cart per branch - Each branch maintains its own cart, customer sees branch indicator, must checkout separately per branch
- Q: What should happen when products in cart become unavailable before checkout completes? → A: Remove with notification - Automatically remove out-of-stock items from cart and show notification listing removed products
- Q: How should the system handle phone number conflicts between guest orders and existing authenticated accounts? → A: Auto-link to account - Automatically associate the guest order with existing authenticated customer account matching the phone number
- Q: What should happen when customers try to chat but all live agents are occupied? → A: Hybrid approach - Growth plan shows queue position; Business plan automatically activates AI agent as fallback, with option to configure AI agent as primary handler (escalate to human only when customer requests)
- Q: How should products with multiple options (sizes, colors, etc.) be structured and displayed? → A: Variant selector - Single product listing with dropdown/button selectors for size, color, etc.; each combination maps to unique SKU backend

**Additional Scope Added**:
- Delivery options during checkout - Self Pick Up, Bicycle delivery, Motor Bike delivery, and Platform delivery for inter-city orders
- Chat attachment capabilities - Customers and agents can share images (5MB max), voice notes (2min max), PDF documents (10MB max), and product cards within live chat. AI agents (Business plan) can recognize products from customer-shared images.
- Payment integration - Paystack payment gateway for all transactions with N100 transaction fee, N50 platform commission (customer portion), and N100 delivery fee addition billed to customers. Merchants pay N50 platform commission deducted from revenue.
- Free plan support - Ecommerce storefront and chat available to Free plan with owner/admin-only chat responses (no dedicated agents, no AI)

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Guest Product Browsing & Checkout (Priority: P1)

A first-time visitor discovers a tenant's online store through a shared link or social media. They want to browse available products, search for specific items, view product details, and complete a purchase without creating an account.

**Why this priority**: This is the core storefront functionality that delivers immediate value. Without this, there is no ecommerce capability at all. Guest checkout removes friction and maximizes conversion for first-time buyers.

**Independent Test**: Can be fully tested by visiting a storefront URL, browsing products, adding items to cart, and completing checkout with guest information (name, phone, delivery address). Delivers a complete purchase flow without authentication.

**Acceptance Scenarios**:

1. **Given** a guest visitor lands on a branch's storefront URL, **When** they view the page, **Then** they see all available products for that branch with images, names, and prices
2. **Given** products are displayed, **When** the guest uses the search bar to find a product by name, **Then** matching products are shown in real-time
3. **Given** a product is displayed in the list, **When** the guest clicks on it, **Then** they see the full product details page with description, price, images, and "Add to Cart" button
4. **Given** a guest is on a product detail page, **When** they click "Add to Cart", **Then** the product is added to their cart and cart count updates
5. **Given** items are in the cart, **When** the guest clicks "Checkout", **Then** they are shown a form to enter delivery information (name, phone, address) and select a delivery method without requiring sign-in
6. **Given** guest is on checkout page, **When** they view delivery options, **Then** they see available options: Self Pick Up, Bicycle, Motor Bike, and Platform Delivery (for inter-city)
7. **Given** guest is on checkout page, **When** they view order summary, **Then** they see product subtotal, delivery fee (calculated + N100 addition), platform commission (N50), transaction fee (N100), and total amount
8. **Given** guest has entered delivery information and selected delivery method, **When** they click "Pay Now", **Then** they are redirected to Paystack payment page
9. **Given** guest completes payment on Paystack, **When** payment is successful, **Then** they are redirected back to storefront with order confirmation showing order number, payment status, and delivery details
10. **Given** guest payment fails on Paystack, **When** they return to storefront, **Then** order is marked as pending payment and they can retry payment

---

### User Story 2 - Customer Authentication with Google/Apple (Priority: P2)

A returning customer wants to sign in using their Google or Apple account to save their delivery information, track past orders, and checkout faster on future visits.

**Why this priority**: Authentication improves the customer experience for repeat buyers by saving their information and enabling order history. Google and Apple sign-in reduce friction compared to traditional email/password.

**Independent Test**: Can be tested by clicking "Sign In" on the storefront, choosing Google or Apple, authenticating, and verifying that customer information is saved. Delivers value by enabling faster repeat purchases.

**Acceptance Scenarios**:

1. **Given** a guest is on the storefront, **When** they click "Sign In with Google", **Then** they are redirected to Google authentication and returned to the storefront signed in
2. **Given** a guest is on the storefront, **When** they click "Sign In with Apple", **Then** they are redirected to Apple authentication and returned to the storefront signed in
3. **Given** a customer is signed in, **When** they proceed to checkout, **Then** their saved delivery information auto-fills the form
4. **Given** a signed-in customer completes an order, **When** they visit "My Orders" page, **Then** they see their order history with order numbers, dates, and statuses
5. **Given** a signed-in customer, **When** they visit a different tenant branch's storefront, **Then** they remain signed in and can use the same account

---

### User Story 3 - Product Search and Filtering (Priority: P3)

A customer browsing a large product catalog wants to quickly find specific items using search and narrow down options using filters to find exactly what they need.

**Why this priority**: Search and filtering become critical when product catalogs grow beyond a few items. This improves discovery and reduces time to purchase for customers who know what they want.

**Independent Test**: Can be tested by entering search terms and applying filters (category, price range, availability) to verify results update correctly. Delivers value by enabling efficient product discovery.

**Acceptance Scenarios**:

1. **Given** a customer is on the product list page, **When** they type a product name in the search bar, **Then** the product list filters to show only matching products
2. **Given** search results are displayed, **When** the customer clears the search, **Then** all products are shown again
3. **Given** a customer is on the product list page, **When** they apply a category filter, **Then** only products in that category are displayed
4. **Given** filters are applied, **When** the customer applies additional filters (e.g., price range), **Then** results narrow to match all active filters
5. **Given** a Business plan tenant with multiple branches, **When** a customer views the storefront, **Then** they see a branch location filter to narrow products by specific branches

---

### User Story 4 - Live Chat Support (Priority: P4)

A customer browsing products or during checkout has questions and wants immediate assistance from a live agent without leaving the storefront. They may need to share images, voice notes, receipts, or specific products to get better support.

**Why this priority**: Live chat support improves conversion by answering questions in real-time, reducing cart abandonment. Rich media sharing enables customers to show issues visually and agents to reference specific products, improving support quality.

**Independent Test**: Can be tested by clicking the chat button on any product page or checkout, sending messages with attachments (text, images, voice, PDF, product links), and receiving responses from a connected agent. Delivers value by providing instant, context-rich customer support.

**Acceptance Scenarios**:

1. **Given** a customer is viewing a product detail page, **When** they click the "Chat with Agent" button, **Then** a chat window opens
2. **Given** the chat window is open, **When** the customer types a message and sends it, **Then** the message is delivered to an available live agent
3. **Given** the chat window is open, **When** the customer attaches an image (product photo, screenshot, etc.) and sends it, **Then** the image is delivered to the agent and displayed in the chat
4. **Given** the chat window is open, **When** the customer records and sends a voice note, **Then** the voice note is delivered to the agent who can play it back
5. **Given** the chat window is open, **When** the customer uploads a PDF receipt or document, **Then** the PDF is delivered to the agent and can be downloaded/viewed
6. **Given** the chat window is open, **When** the customer or agent shares a product from the catalog, **Then** a product card with image, name, price appears in the chat with link to product page
7. **Given** a live agent receives the message, **When** they respond with text or attachments, **Then** the customer sees the response in real-time in the chat window
8. **Given** a Growth plan tenant, **When** a customer opens chat, **Then** they are connected to the single available live agent for that branch
9. **Given** a Business plan tenant, **When** multiple customers open chat simultaneously, **Then** they are distributed among multiple available live agents

---

### User Story 5 - AI Agent Chat (Business Plan Only) (Priority: P5)

A Business plan tenant wants to provide 24/7 automated customer support using an AI agent to answer common questions about products, orders, and delivery even when live agents are unavailable. The AI agent can handle text queries and recognize products from shared images.

**Why this priority**: AI agents extend support coverage beyond business hours and reduce the load on human agents. Image recognition enables customers to get product information by sharing photos. This is a premium feature that justifies the Business plan pricing.

**Independent Test**: Can be tested by clicking chat on a Business plan tenant's storefront when live agents are offline and verifying the AI agent responds to common questions and can identify products from images. Delivers value through always-available, context-aware support.

**Acceptance Scenarios**:

1. **Given** a Business plan tenant has enabled AI agent, **When** a customer opens chat and no live agents are available, **Then** the AI agent greets them and offers to help
2. **Given** an AI agent conversation is active, **When** the customer asks about product details, **Then** the AI agent provides relevant information based on the product catalog
3. **Given** an AI agent conversation is active, **When** the customer shares an image of a product, **Then** the AI agent identifies the product and provides details or suggests similar items from catalog
4. **Given** an AI agent conversation is active, **When** the customer asks about order status, **Then** the AI agent retrieves and displays their order information
5. **Given** an AI agent cannot answer a question, **When** the issue is complex, **Then** the AI agent offers to create a support ticket or transfer to a live agent when available
6. **Given** a Growth plan tenant, **When** customers try to access chat, **Then** they only see live agent option (no AI agent option displayed)

---

### User Story 6 - Multi-Branch Customer Affiliation (Priority: P6)

A customer shops from multiple branches of the same tenant (e.g., different neighborhood locations) and wants to use the same account across all branches, maintaining a unified order history and saved preferences.

**Why this priority**: This improves customer experience for tenants with multiple branches by creating a seamless cross-branch shopping experience. Lower priority because it's valuable but not essential for initial launch.

**Independent Test**: Can be tested by signing in on one branch's storefront, placing an order, then visiting a different branch's storefront and verifying the same account is active with order history visible. Delivers value through unified customer profiles.

**Acceptance Scenarios**:

1. **Given** a customer signed in on Branch A's storefront, **When** they visit Branch B's storefront URL (same tenant), **Then** they remain signed in with the same account
2. **Given** a customer has ordered from multiple branches, **When** they view "My Orders" page, **Then** they see orders from all branches in a unified list
3. **Given** a customer updates their delivery address on one branch's storefront, **When** they checkout on a different branch, **Then** the updated address is available
4. **Given** a Business plan tenant, **When** a customer searches products, **Then** they can filter by which branch(es) they want to order from
5. **Given** a Growth plan tenant (single branch), **When** a customer visits the storefront, **Then** no branch filter is shown (all products are from the single branch)

---

### Edge Cases

- When a customer adds items to cart from Branch A and then navigates to Branch B's storefront, Branch A's cart is preserved and Branch B shows an empty cart (separate carts per branch)
- When products in cart become out-of-stock before checkout, the system automatically removes them and displays a notification listing the removed products
- When a guest completes checkout with a phone number matching an existing authenticated customer, the system automatically links the order to that customer account
- When all live agents are busy, Growth plan shows queue position and wait time; Business plan activates AI agent as fallback (or as primary handler if configured that way)
- Products with variants (size, color, etc.) display as single product listings with variant selectors; each combination maps to a unique SKU for inventory tracking
- When customer selects Self Pick Up, delivery address field is optional/hidden since no delivery needed
- When customer's delivery address is outside local delivery range, only Platform Delivery and Self Pick Up options are available (Bicycle and Motor Bike hidden)
- Delivery fee is recalculated if customer changes delivery address or delivery method before order confirmation
- When customer attempts to upload file exceeding size limits (>5MB image, >10MB PDF, >2min voice), system rejects with clear error message indicating limit
- When customer uploads unsupported file type in chat, system rejects and displays supported formats
- When network interruption occurs during file upload, system shows upload failed message and allows retry
- Chat attachments are stored with the chat session and remain accessible for session duration and in chat history
- Product cards shared in chat always link to current product page; if product is deleted/unavailable, card shows "no longer available" message
- When Paystack payment is successful but callback fails to reach system, webhook retry mechanism updates order status
- When customer abandons payment on Paystack page, order remains as pending and customer can resume payment from order history
- Order total calculation: Product Subtotal + (Delivery Base Fee + N100) + Platform Commission (N50) + Transaction Fee (N100) = Total Amount
- For Self Pick Up orders: Product Subtotal + (N0 + N100) + N50 + N100 = Total (N100 delivery + N50 commission + N100 transaction = N250 fees)
- Transaction fee (N100), platform commission (N50 customer + N50 merchant), and delivery addition (N100) are applied to all plans (Free, Growth, and Business)
- What happens when a customer's Google/Apple sign-in fails or is revoked? (Allow continued browsing as guest, show error message?)
- What happens when a Business plan tenant downgrades to Growth plan mid-month? (AI agent disabled immediately, or grace period?)

## Requirements *(mandatory)*

### Functional Requirements

#### Customer Authentication
- **FR-001**: System MUST support customer sign-in via Google OAuth
- **FR-002**: System MUST support customer sign-in via Apple Sign In
- **FR-003**: System MUST allow guest checkout without requiring authentication
- **FR-004**: System MUST persist customer information (name, phone, delivery address) for authenticated customers
- **FR-005**: System MUST automatically link guest orders to existing authenticated customer accounts when phone numbers match
- **FR-006**: System MUST maintain customer sessions across different branch storefronts of the same tenant
- **FR-007**: System MUST link customers to multiple tenant branches when they shop from different branches

#### Product Browsing & Search
- **FR-008**: System MUST display products for a branch when accessed via branch-specific storefront URL
- **FR-009**: Growth plan storefronts MUST load products filtered by branch_id (single branch)
- **FR-010**: Business plan storefronts MUST load products filtered by tenant_id with optional branch filters (multi-branch)
- **FR-011**: System MUST provide real-time search functionality for products by name
- **FR-012**: System MUST support filtering products by category
- **FR-013**: System MUST support filtering products by price range
- **FR-014**: Business plan storefronts MUST display branch location filter when multiple branches exist
- **FR-015**: System MUST display product images, names, prices, and availability status on product list page

#### Product Detail & Cart
- **FR-016**: System MUST display comprehensive product details (description, images, price, availability) on product detail page
- **FR-017**: System MUST display variant selectors (dropdowns/buttons) for products with multiple options (size, color, etc.)
- **FR-018**: System MUST update product price and availability based on selected variant combination
- **FR-019**: System MUST map each variant combination to a unique SKU for inventory management
- **FR-020**: System MUST allow customers to add products to cart from product detail page
- **FR-021**: System MUST maintain cart state for both guest and authenticated customers
- **FR-022**: System MUST maintain separate shopping carts per branch (cart items are branch-specific)
- **FR-023**: System MUST display current branch indicator in cart view
- **FR-024**: System MUST display cart item count and allow cart access from any page
- **FR-025**: System MUST allow customers to modify cart quantities or remove items

#### Checkout Flow
- **FR-026**: System MUST collect delivery information (name, phone, address) during checkout
- **FR-027**: System MUST display delivery method selection during checkout
- **FR-028**: System MUST offer Self Pick Up as a delivery option (customer collects from branch)
- **FR-029**: System MUST offer Bicycle delivery as a delivery option for local deliveries
- **FR-030**: System MUST offer Motor Bike delivery as a delivery option for local deliveries
- **FR-031**: System MUST offer Platform Delivery as a delivery option for inter-city orders
- **FR-032**: System MUST calculate delivery fee based on selected delivery method and delivery distance
- **FR-033**: System MUST add N100 to the calculated delivery fee for all orders (except Self Pick Up which has base fee N0 + N100 = N100)
- **FR-034**: System MUST add N50 platform commission (customer portion) to all orders
- **FR-035**: System MUST add N100 transaction fee to all orders
- **FR-036**: System MUST deduct N50 platform commission (merchant portion) from merchant revenue for all completed orders
- **FR-037**: System MUST display order summary showing: product subtotal, delivery fee (calculated + N100), platform commission (N50), transaction fee (N100), and total amount
- **FR-038**: System MUST auto-fill delivery information for authenticated customers
- **FR-039**: System MUST validate product availability before checkout and automatically remove out-of-stock items with notification
- **FR-040**: System MUST validate delivery information before order submission (not required for Self Pick Up)
- **FR-041**: System MUST validate delivery method selection before order submission

#### Payment Processing
- **FR-042**: System MUST integrate with Paystack payment gateway for all transactions
- **FR-043**: System MUST redirect customers to Paystack payment page when they click "Pay Now" at checkout
- **FR-044**: System MUST pass order total (subtotal + delivery fee + N100 + platform commission N50 + transaction fee N100) to Paystack
- **FR-045**: System MUST handle Paystack payment success callback and mark order as paid
- **FR-046**: System MUST handle Paystack payment failure callback and mark order as pending payment
- **FR-047**: System MUST allow customers to retry payment for pending orders
- **FR-048**: System MUST create orders with unique order numbers upon checkout initiation (before payment)
- **FR-049**: System MUST update order status to "paid" when Paystack confirms successful payment
- **FR-050**: System MUST display order confirmation with order number, payment status, delivery method, and delivery details
- **FR-051**: System MUST send order confirmation push notification to customer after successful payment (Growth and Business plans only)
- **FR-052**: System MUST link orders to customer accounts for authenticated customers

#### Live Chat Support
- **FR-053**: System MUST display "Chat with Agent" button on product detail pages for all plans
- **FR-054**: Free plan branches MUST allow only the tenant owner/admin to respond to customer chats
- **FR-055**: Free plan MUST route all customer chats to the tenant owner/admin account
- **FR-056**: Growth plan branches MUST support connection to 1 live chat agent
- **FR-057**: Growth plan MUST display queue position and estimated wait time when live agent is busy
- **FR-058**: Business plan branches MUST support connections to multiple live chat agents
- **FR-059**: System MUST route chat messages between customers and available live agents in real-time
- **FR-060**: System MUST display chat availability status (online/offline agents)
- **FR-061**: System MUST allow customers to attach and send images (JPG, PNG, max 5MB) in chat
- **FR-062**: System MUST allow customers to record and send voice notes (max 2 minutes, audio format) in chat
- **FR-063**: System MUST allow customers to upload and send PDF documents (max 10MB) in chat
- **FR-064**: System MUST allow customers and agents to share product cards from catalog in chat with clickable link to product page
- **FR-065**: System MUST allow agents to attach and send images, voice notes, PDFs, and product cards to customers
- **FR-066**: System MUST display attached media inline in chat interface (images visible, voice playable, PDFs downloadable)
- **FR-067**: System MUST validate file types and sizes before upload and reject invalid attachments with error message
- **FR-068**: System MUST store chat attachments securely with access limited to participants of that chat session

#### AI Agent Chat (Business Plan)
- **FR-069**: Business plan branches MUST have option to enable AI agent chat
- **FR-070**: System MUST activate AI agent automatically when all live agents are busy (Business plan only)
- **FR-071**: Business plan MUST provide configuration option to set AI agent as primary chat handler
- **FR-072**: When AI agent is primary handler, system MUST allow customer-initiated escalation to live agent
- **FR-073**: AI agent MUST be able to answer questions about products using the branch's catalog
- **FR-074**: AI agent MUST be able to retrieve customer order status
- **FR-075**: AI agent MUST be able to process images sent by customers and identify products from the branch catalog
- **FR-076**: AI agent MUST be able to share product cards in response to customer queries
- **FR-077**: System MUST NOT display AI agent option for Free and Growth plan tenants

#### Plan-Based Access Control
- **FR-078**: System MUST enforce plan-based feature access (Free, Growth, Business)
- **FR-079**: System MUST provide ecommerce storefront access to all subscription plans (Free, Growth, Business)
- **FR-080**: System MUST provide live chat support to all subscription plans (Free, Growth, Business)
- **FR-081**: System MUST restrict Free plan chat to owner/admin responders only (1 User limit)
- **FR-082**: System MUST restrict Free plan push notifications (no push notifications or SMS/WhatsApp for Free plan)
- **FR-083**: System MUST enable push notifications and WhatsApp integration for Growth and Business plans
- **FR-084**: System MUST restrict Growth plan to 3 Staff accounts (Manager, Cashier, Rider)
- **FR-085**: System MUST restrict multi-branch product filtering to Business plan only
- **FR-086**: System MUST restrict AI agent access to Business plan only
- **FR-087**: System MUST allow unlimited live chat agents and staff for Business plan
- **FR-095**: System MUST enforce a limit of 100 products for Free plan tenants
- **FR-096**: System MUST allow unlimited products for Growth and Business plan tenants
- **FR-097**: System MUST implement a dormancy protocol to hibernate Free plan accounts after 30 days of inactivity (0 sales, no logins) to save costs
- **FR-098**: System MUST restrict Free plan to 1 branch only

#### Progressive Web App (PWA)
- **FR-088**: System MUST provide Progressive Web App (PWA) functionality for all plans
- **FR-089**: System MUST allow customers to install storefront as an app on their device home screen
- **FR-090**: System MUST provide offline fallback page when network is unavailable
- **FR-091**: System MUST cache static assets for faster loading on repeat visits
- **FR-092**: System MUST display app-like UI without browser chrome when launched from home screen
- **FR-093**: System MUST include Web App Manifest with brand colors, icons, and display settings
- **FR-094**: System MUST register Service Worker for offline support and push notifications

### Key Entities

- **Customer**: Online shoppers who visit tenant branch storefronts. Can be authenticated (via Google/Apple) or guests. Customers have delivery information (name, phone, address) and can be affiliated with multiple branches of the same tenant. Authenticated customers have order history and saved preferences.

- **Storefront**: Public-facing ecommerce site for a specific tenant branch. Each branch has a unique URL. Displays products, handles product search/filtering, manages shopping cart, and processes checkout. Storefront features vary based on tenant's subscription plan.

- **Product**: Items available for purchase on the storefront. Products belong to a branch and have name, description, price, images, category, and availability status. Products may have variants (size, color, etc.) displayed through selectors; each variant combination maps to a unique SKU for inventory tracking. Products can be searched and filtered by customers.

- **Shopping Cart**: Temporary collection of products a customer intends to purchase from a specific branch. Each branch maintains its own separate cart. Persists during the session for both guest and authenticated customers. Contains product references, quantities, branch identifier, and subtotal. When a customer switches between branches, the previous branch's cart is preserved.

- **Order**: Record of a purchase transaction. Contains customer delivery information, ordered products with quantities and prices, selected delivery method, fee breakdown (delivery base fee + N100 addition, platform commission N50, transaction fee N100), order subtotal, order total, order number, timestamp, payment status (pending/paid/failed), Paystack transaction reference, and order fulfillment status. Linked to customer account if authenticated.

- **Payment Transaction**: Record of Paystack payment for an order. Contains order reference, Paystack transaction reference, amount paid, payment method used, payment status, transaction timestamp, and callback data from Paystack. Standard fees: N100 transaction fee per order, N100 platform commission (N50 from customer + N50 from merchant), N100 addition to delivery fee.

- **Delivery Method**: Fulfillment option selected during checkout. All delivery methods have N100 added to base calculated fee. Four types available:
  - **Self Pick Up**: Customer collects order from branch location (base fee N0, total with addition: N100, no delivery address required)
  - **Bicycle Delivery**: Local delivery via bicycle courier (base fee calculated for nearby addresses + N100 addition)
  - **Motor Bike Delivery**: Local delivery via motorbike courier (base fee calculated for city/local deliveries + N100 addition)
  - **Platform Delivery**: Inter-city delivery through third-party logistics platform (base fee calculated based on distance + N100 addition)

- **Live Chat Session**: Real-time conversation between a customer and either a tenant owner/admin, live agent, or AI agent. Contains message history (text, images, voice notes, PDFs, product cards), participant information, attachment metadata, and session status. Both customers and agents can share rich media attachments. AI agents (Business plan only) can recognize products from images. Plan-based chat access:
  - **Free Plan**: Owner/admin only can respond to customer chats (no dedicated agents)
  - **Growth Plan**: Up to 3 staff accounts, no AI agent
  - **Business Plan**: Multiple live agents with AI agent fallback when all busy, or AI agent as primary handler with customer-initiated escalation

- **Chat Attachment**: Media or file shared within a chat session. Supported types include:
  - **Images**: JPG, PNG formats (max 5MB) - displayed inline in chat, used by AI for product recognition
  - **Voice Notes**: Audio recordings (max 2 minutes) - playable in chat interface
  - **PDF Documents**: Receipts, invoices, or other documents (max 10MB) - downloadable from chat
  - **Product Cards**: Rich preview of catalog products with image, name, price, and link to product page

- **Tenant Subscription Plan**: Defines feature access for a tenant. Ecommerce storefront and live chat are available to all plans with Paystack payment integration and standard fees (N100 transaction fee + N50 platform commission + N100 added to delivery). Plan tiers:
  - **All Plans**: Ecommerce storefront, Paystack payment (N100 fee + N50 commission), N100 delivery addition.
  - **Free Plan (Starter)**: Max 100 products, 1 User (Owner only), 1 Branch, No SMS/WhatsApp/Push notifications, 7-day chat retention. Hibernates after 30 days inactivity.
  - **Growth Plan (N7,500/month)**: Unlimited products, 3 Staff accounts, Custom Domain support, Priority Support, WhatsApp notifications enabled, 1-year analytics.
  - **Business Plan (N30,000/month)**: Unlimited Staff, Unlimited Products, Multi-branch support, AI Chat Agent, API Access, Dedicated Account Manager.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Guest customers can browse products and complete checkout in under 3 minutes without authentication
- **SC-002**: Customer authentication via Google or Apple completes in under 30 seconds
- **SC-003**: Product search returns relevant results in under 1 second for catalogs up to 1000 products
- **SC-004**: 90% of customers successfully complete checkout on first attempt (authenticated or guest)
- **SC-005**: Live chat messages are delivered to agents in under 2 seconds
- **SC-006**: Business plan AI agent responds to customer questions in under 5 seconds
- **SC-007**: Storefront pages load in under 3 seconds on standard broadband connections
- **SC-008**: Cart abandonment rate decreases by 30% with live chat support enabled
- **SC-009**: Authenticated customers complete checkout 50% faster than guest customers due to auto-filled information
- **SC-010**: Customers successfully filter products by branch on Business plan storefronts with 95% accuracy
- **SC-011**: Customers can view and select delivery options with delivery fees displayed in under 2 seconds during checkout
- **SC-012**: 85% of customers successfully complete delivery method selection without assistance or errors
- **SC-013**: Chat attachments (images, voice notes, PDFs) upload and display to recipient in under 5 seconds on standard connections
- **SC-014**: AI agent successfully identifies products from customer-shared images with 80% accuracy
- **SC-015**: 90% of customers successfully share attachments in chat without file size or format errors
- **SC-016**: Storefront achieves Lighthouse PWA score above 90 (performance, accessibility, best practices)
- **SC-017**: Repeat visitors experience 50% faster page loads due to service worker caching
- **SC-018**: 80% of mobile customers successfully install PWA on home screen when prompted
- **SC-019**: Offline fallback page displays within 1 second when network is unavailable

## Assumptions

- Each tenant branch has a unique subdomain or path for their storefront (e.g., `branch-a.tenant.com` or `tenant.com/branch-a`)
- Paystack payment gateway integration is used for all online transactions
- Paystack API keys (public and secret) are configured per tenant or globally
- Standard transaction fee is N100 per order, billed to customer
- Standard platform commission is N100 per order total (N50 billed to customer, N50 deducted from merchant revenue)
- Standard delivery fee addition is N100, added to calculated delivery fee and billed to customer
- Push notifications are handled via Firebase Cloud Messaging (FCM) for both web and mobile platforms
- Free plan does not have access to push notifications; Growth and Business plans have push notifications enabled
- Progressive Web App (PWA) functionality is available to all plans with no additional cost
- PWA icons and splash screens are generated at 192x192px, 512x512px, and maskable variants
- Service Worker provides offline fallback and caching for static assets (JS, CSS, images)
- PWA manifest uses tenant brand colors and logo for customized app experience
- Browsers that support PWA will show "Add to Home Screen" prompt after repeat visits
- Paystack handles payment method selection (card, bank transfer, USSD, etc.) on their hosted payment page
- Paystack webhooks are configured to send payment success/failure callbacks to the system
- Product inventory is managed through existing POS system and synced to storefront
- Customer phone numbers are unique identifiers for guest checkout
- Live chat agents access a separate agent dashboard (not part of storefront interface)
- AI agent has access to product catalog and order data for the specific branch
- AI agent has image recognition capabilities to identify products from customer-shared photos
- Chat attachments are stored temporarily for the duration of chat session plus retention period for chat history
- Chat attachment file size limits (5MB images, 10MB PDFs, 2min voice) are enforced at application level
- Voice notes are recorded in standard audio formats compatible with web browsers
- Growth plan tenants operate single branches; Business plan tenants may operate multiple branches
- Google and Apple OAuth applications are already configured or will be set up during implementation
- Delivery fee calculation logic for each delivery method (Bicycle, Motor Bike, Platform) is defined elsewhere or will be configured per tenant
- Platform delivery integrates with third-party logistics providers for inter-city fulfillment
- Bicycle and Motor Bike delivery couriers are managed through existing delivery management system
- Self Pick Up requires no delivery logistics (customer collects from branch)
- Tax calculations follow standard rules defined elsewhere in the system

## Non-Functional Considerations

- **Performance**: Storefront must handle traffic spikes during promotions (up to 10x normal traffic)
- **Security**: Customer authentication tokens must be securely stored and transmitted
- **Privacy**: Customer data (delivery info, order history) must be isolated per tenant
- **Accessibility**: Storefront must be navigable via keyboard and screen readers
- **Mobile Responsiveness**: Storefront must work on mobile devices (50%+ of traffic expected from mobile)
- **SEO**: Product pages should be indexable by search engines for organic traffic

## Dependencies

- Existing tenant subscription/plan management system to determine plan tier (Free, Growth, or Business)
- Product catalog and inventory data from existing POS system
- Paystack payment gateway API (public and secret keys) for transaction processing
- Paystack webhook endpoint configuration for payment callbacks
- Google OAuth and Apple Sign In API credentials
- Live chat infrastructure for agent connections
- AI agent service (for Business plan) with natural language processing and image recognition capabilities
- File storage service for chat attachments (images, voice notes, PDFs) with secure access control
- Media processing service for image optimization and voice note encoding
- Delivery fee calculation service or configuration system for Bicycle, Motor Bike, and Platform delivery rates
- Third-party platform delivery API for inter-city logistics
- Existing delivery management system for Bicycle and Motor Bike courier dispatch

## Out of Scope

- Paystack payment processing internals (handled by Paystack gateway)
- Product inventory management (managed through existing POS)
- Live chat agent dashboard/interface (agents use separate system)
- Video calls or screen sharing in chat (only text, images, voice notes, PDFs, and product cards supported)
- Real-time typing indicators or read receipts in chat
- Chat message editing or deletion after sending
- Chat transcript download or export functionality for customers
- Automated chat translation between languages
- Courier dispatch and route optimization for Bicycle/Motor Bike deliveries (handled by existing delivery management system)
- Real-time delivery tracking (customers receive order confirmation but not live tracking)
- Delivery time slot selection (deliveries use standard fulfillment windows)
- Product reviews and ratings
- Wishlist or saved items for later
- Multi-currency support
- International shipping
- Promotional codes or discount system
- Customer loyalty programs
