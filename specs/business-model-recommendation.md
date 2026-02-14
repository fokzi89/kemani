# Business Model & Pricing Strategy Recommendation

**Objective**: Eliminate costs for Free Plan tenants while maximizing upgrade conversion.

## 1. The "Zero-Cost" Free Plan Strategy

To achieve a near-zero cost basis for Free Plan tenants, we must strictly limit resource consumption (Storage, Compute, Database) and rely on the platform's transactional revenue to cover the minimal remaining overhead.

### A. Strict Resource Limits (The "Solopreneur" Box)
The Free Plan is designed **exclusively** for a single-person business (Owner only). As soon as they grow (hire staff, expand inventory), they *must* upgrade.

| Resource | Free Plan Limit | Cost Impact | Upgrade Trigger |
| :--- | :--- | :--- | :--- |
| **Users** | **1 User (Owner Only)** | Zero staff management overhead. | "Invite Staff" button locks. |
| **Products** | **Max 50 Products** | Minimizes database rows & storage. | "Add Product" button locks at 50. |
| **Images** | **1 Image per Product** | Max ~10MB storage per tenant (assuming 200KB/img). | "Add Gallery Images" locks. |
| **Chat History** | **7 Days Retention** | Aggressive auto-cleanup of old messages. | "View Older Messages" locks. |
| **Branches** | **1 Branch** | Single location logic only. | "Add Branch" locks. |
| **Analytics** | **Last 30 Days Only** | Reduces historical data query load. | "View Last Year" locks. |
| **Support** | **Community / Docs** | No human support cost. | Direct email/chat support is Paid only. |

### B. The "Dormancy" Protocol (Cost Elimination)
A significant cost driver is "zombie" accounts that use storage but generate no revenue.
*   **Policy**: If a Free Plan tenant processes **0 sales** and has **no login activity** for **30 days**:
    1.  **Day 30**: Send warning email.
    2.  **Day 45**: **Hibernate Account** (Data moved to cold storage/archived, Storefront goes offline).
    3.  **To Reactivate**: User must log in (triggers un-archiving).
*   **Result**: You only pay active infrastructure costs for tenants who are potentially generating transaction revenue.

### C. Infrastructure Optimization
*   **Image Compression**: Enforce aggressive compression (WebP, max 800px width) on upload for Free plans.
*   **CDN Caching**: Cache public storefront pages heavily. Invalidate only on product updates.
*   **Database**: Use a shared schema with RLS (Row Level Security) rather than separate schemas/databases.

---

## 2. Recommended Pricing Model

This model shifts from "paying for access" to "paying for growth capabilities."

### Tier 1: **Starter (Free)**
*Target: Side hustles, micro-vendors, instagram sellers.*

*   **Monthly Cost**: **₦0**
*   **Transaction Fee**: **Transaction Fee (₦100) + Commission (5%)**
    *   *Why %?* It captures upside on expensive items and discourages selling very cheap items that cost you money to process.
    *   *(Alternative: Stick to your current N100+N50+N50 fixed model if your margins allow, but 5% is standard for "Free" tiers like Shopify Starter).*
*   **Features**:
    *   1 User (Owner)
    *   100 Products
    *   Simple Storefront (`kemani.store/myshop`)
    *   Standard Checkout
    *   Owner-only Chat
    *   **No** Custom Domain
    *   **No** Staff Accounts
    *   **No** AI Agent
    *   **No** API Access

### Tier 2: **Growth (₦7,500 / month)**
*Target: Small businesses with a helper or two.*

*   **Transaction Fee**: **Standard Fixed (₦100 Transaction + ₦50 Platform)** - *Cheaper than Free for volumes > ₦150k/mo*.
*   **Features (Adds to Starter)**:
    *   **3 Staff Accounts** (Manager, Cashier, Rider)
    *   **500 Products**
    *   Product Variants (Sizes, Colors)
    *   **Custom Domain** (e.g., `www.myshop.com`) - *Major psychological upgrade trigger.*
    *   **5 Image Gallery** per product
    *   **Priority Support** (Email/Chat)
    *   **Rich Analytics** (1 Year History)
    *   **WhatsApp Notifications** (Automated order updates)

### Tier 3: **Business (₦30,000 / month)**
*Target: Established retailers, supermarkets, multi-branch chains.*

*   **Transaction Fee**: **Standard Fixed (₦100 Transaction Only)** - *Waive the N50 platform commission as a perk.*
*   **Features (Adds to Growth)**:
    *   **Unlimited Staff**
    *   **Unlimited Products**
    *   **Multiple Branches** (Inventory per location)
    *   **AI Chat Agent** (24/7 Automated Support)
    *   **API Access** (WooCommerce/Shopify Sync)
    *   **White-Label Receipts** (Remove "Powered by Kemani")
    *   **Dedicated Account Manager**

---

## 3. The Upgrade "Nudges" (Psychological Triggers)

Don't just hide features. Show them locked.

1.  **The "Staff" Trigger**: When a solo owner gets busy, they *need* help. They try to invite their cousin.
    *   *System*: "You're growing! Upgrade to Growth to add staff members and track their sales."
2.  **The "Professional" Trigger**: They want to look legit on Instagram.
    *   *System*: "Get your own `.com` domain and remove 'Powered by Kemani' branding with the Business plan."
3.  **The "Inventory" Trigger**: They hit 50 products.
    *   *System*: "Wow, you're stocking up! Unlock space for 500 products with the Growth plan."
4.  **The "Sleep" Trigger**: They are tired of answering chats at 11 PM.
    *   *System*: "Let our AI Agent handle late-night customer queries. Available on Business plan."
5.  **The "Lost Sales" Trigger**:
    *   *System (Analytics)*: "You missed 5 potential sales from customers who dropped off. Upgrade to Growth to see exactly where they left."

## 4. Cost vs. Revenue Calculator (Estimated)

**Scenario: Active Free Tenant (Micro-vendor)**
*   **Activity**: 10 Orders/month, Avg Order Value ₦5,000.
*   **Revenue to Platform**:
    *   Subscription: ₦0
    *   Commission (Fixed N100+N50+N50): ₦200 * 10 = ₦2,000 / month.
*   **Cost to Platform**:
    *   Hosting/DB: ~₦100 (negligible shared resource).
    *   Support: ₦0 (Community only).
*   **Net Profit**: **+₦1,900 / month**.
*   *Verdict*: **Profitable**. Even a small active user pays for themselves.

**Scenario: Inactive Free Tenant (Zombie)**
*   **Activity**: 0 Orders.
*   **Revenue**: ₦0.
*   **Cost**: Storage for 50 images (~10MB) + DB Rows. ~₦5 / month.
*   **Mitigation**: Hibernation after 30 days = **₦0 cost**.

**Conclusion**:
The proposed model ensures that **Active** free users pay for themselves via transaction fees, and **Inactive** users are cost-controlled via strict resource limits and hibernation policies. The upgrade path is natural: as they succeed, they hit limits (Staff, Inventory) that compel payment.

## 5. Third-Party Service Cost Analysis & Impact

To ensure the "Zero-Cost" strategy holds, we must account for every external API call.

### A. Infrastructure & Messaging Costs (The Hidden Killers)

| Service | Estimated Unit Cost | Free Plan Strategy | Impact on Margin |
| :--- | :--- | :--- | :--- |
| **SMS (OTP)** | ~₦2-₦4 per SMS (Termii/Twilio) | **Strict Limit**: Login OTPs only. No order notifications via SMS. | 1 Login = ~₦3 cost. Covered by 1 transaction commission. |
| **WhatsApp API** | ~₦30-₦50 per conversation (Meta) | **Disabled**. Too expensive for Free tier. | **Paid Plans Only**. Business plan absorbs this cost. |
| **Supabase (DB)** | ~$0.125/GB (Storage) + Egress | **Row Limits**: 50 products max keeps DB size insignificant. | Negligible per-tenant cost (~₦5/mo). |
| **Paystack** | 1.5% + N100 (Capped at N2000) | **Passed to Customer**: The N100 fee is paid by the buyer. | **Zero**. Platform fee is net revenue. |
| **Google Maps** | ~$5 per 1000 requests | **Cached**: Store lat/long on address save. Don't query API on every checkout. | Minimal if cached correctly. |
| **OpenAI (AI)** | ~$0.01 per conversation | **Disabled**. | **Business Plan Only**. |

### B. Revised Profitability Analysis (With 3rd Party Costs)

**Scenario 1: Active Free Tenant (Micro-vendor)**
*   **Activity**: 10 Orders/month, 2 Logins/month.
*   **Revenue**:
    *   Commission (5% of ₦50,000 GMV): +₦2,500
    *   Transaction Fee Markup (N100): +₦1,000
    *   **Total Revenue**: **+₦3,500 / month**
*   **Variable Costs**:
    *   SMS (OTP for 2 logins): -₦8
    *   Hosting/DB (Shared): -₦20
    *   Map Lookups (Address verification): -₦50
*   **Net Profit**: **+₦3,422 / month** (Highly Profitable)

**Scenario 2: Low-Activity Free Tenant (The "Cost Risk")**
*   **Activity**: 0 Orders, 5 Logins (Just checking).
*   **Revenue**: ₦0.
*   **Variable Costs**:
    *   SMS (OTPs): 5 * ₦4 = -₦20.
    *   Hosting: -₦5.
*   **Net Loss**: **-₦25 / month**.
*   *Mitigation*: This is acceptable marketing cost. If they don't sell in 3 months -> Hibernate.

### C. Strategic Safeguards
1.  **No Free SMS Notifications**: Free plan users get email/purchaser-app notifications only. SMS is too expensive to give away.
    *   *System Message*: "Want SMS order alerts? Upgrade to Growth."
2.  **No Free WhatsApp**: WhatsApp messaging is a premium feature.
3.  **Map Caching**: When a user enters an address, geocode it **once** and save the lat/long. Do not re-geocode on every page load.
4.  **Image Optimization**: Use Supabase Image Transformations or a service like Cloudinary (free tier) to serve optimized images, preventing bandwidth spike.

## 6. Final Recommendation

Based on the 3rd party cost analysis:
1.  **Keep the Free Plan Strict**: 100 Products is generous, but ensure **Media** and **Notification** limits are tight.
2.  **Monetize the "Communication" Layer**: Detailed SMS and WhatsApp updates are high-value and high-cost. They are perfect differentiators for the **Growth (₦7,500)** plan.
3.  **AI is Premium**: The token costs for AI Agents are variable and potentially high. This *must* remain in the **Business (₦30,000)** tier to ensure ample margin to cover usage spikes.
