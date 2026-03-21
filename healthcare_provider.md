# Healthcare System Pages & UI Prompt

This document contains a complete list of pages across the Healthcare Medic, Customer, and Storefront applications, along with a comprehensive AI prompt for generating the UI.

## 1. Healthcare Provider (Medic) Pages
**Location:** `apps/healthcare_medic/src/routes/`

- `/` (Dashboard / Overview)
- `/analytics` (Analytics & Reports)
- `/auth/login` (Provider Login)
- `/auth/signup` (Provider Signup)
- `/availability` (Schedule & Availability Management)
- `/chats` (Messages & Chat History)
- `/chats/[id]` (Active Chat Session)
- `/chats/new` (Start New Chat)
- `/commissions` (Earnings & Referral Commissions)
- `/consultations` (Consultation History & Management)
- `/patients` (Patient Directory)
- `/patients/[id]/lab-test` (Order Lab Tests for Patient)
- `/patients/[id]/prescribe` (Create Prescription for Patient)
- `/patients/[id]/schedule` (Schedule Patient Follow-up)
- `/patients/add` (Add New Patient)
- `/prescriptions` (Issued Prescriptions History)


## 2. Healthcare Customer Pages
**Location:** `apps/healthcare_customer/src/routes/`

- `/` (Customer Dashboard)
- `/auth/login` (Customer Login)
- `/auth/signup` (Customer Signup)
- `/book/[slug]` (Book Specific Provider)
- `/consultations` (My Consultations)
- `/consultations/[id]` (Consultation Session Details)
- `/notifications` (Alerts and Notifications)
- `/prescriptions` (My Prescriptions)
- `/profile` (Customer User Profile)
- `/providers` (Browse & Search Healthcare Providers)


## 3. Storefront & Health Ecommerce Pages
**Location:** `apps/storefront/src/routes/`

- `/consultations` (Consultation Booking Services)
- `/diagnostics` (Diagnostics & Lab Tests Services)
- `/products` (Pharmacy & Health Products)
- `/checkout` (Shopping Cart Checkout)
- `/orders` (Order History)
- `/track/[orderId]` (Order Tracking)
- `/customers` (Storefront Customer Info)
- `/payment/callback` (Payment Verification)
- `/(marketplace)/[tenantId]` (Tenant Pharmacy Storefront Home)
- `/(marketplace)/[tenantId]/cart` (Tenant Cart)
- `/(marketplace)/[tenantId]/profile` (Tenant Specific Customer Profile)
- `/(marketplace)/[tenantId]/products/[productId]` (Tenant Product Detail)


---

## AI Prompt to Build the UI

Copy and paste the prompt below into your AI tool to generate visually stunning UIs for the pages listed above. Keep the prompt structured so the code can systematically "stitch" the pages together.

```text
You are an expert Frontend Developer and UX/UI Designer. I need you to implement the user interface for a multi-tenant healthcare ecosystem consisting of a Healthcare Provider app, a Customer Portal, and an E-commerce Storefront. The stack uses SvelteKit, TailwindCSS, and lucide-svelte for icons.

I am going to provide you with the name of a specific page from my route structure (e.g., "Customer Dashboard" or "Provider Patients List"). For that page, please generate the complete, production-ready `+page.svelte` code.

When designing the UI, adhere STRICTLY to the following requirements:

1. Premium Medical Aesthetics: 
   - Use a modern, calming, and highly professional color palette (e.g., trust-inspiring greens, teals, soft primary blues, and crisp whites/grays).
   - Use soft shadows (`shadow-sm`, `shadow-md`), rounded corners (`rounded-xl` or `rounded-2xl`), and plenty of white space.

2. Dynamic & Responsive Layouts:
   - For auth pages (login/signup), use a striking split-screen layout with form elements on one side and brand messaging/testimonials on the other.
   - For internal dashboard pages, assume a sophisticated sidebar/navbar structure. Provide the main content wrapper layout.
   - Ensure the views are fully responsive (mobile-friendly stacking to spacious desktop grid/flex layouts).

3. Advanced Interactivity & State:
   - Include realistic placeholder data and mock states for loading, empty states, and errors.
   - Use subtle micro-animations (e.g., `transition-all duration-200 hover:scale-[1.02] hover:-translate-y-1` on cards or buttons).
   - Use `lucide-svelte` icons to enrich inputs, buttons, and section headers.

4. Component Structure:
   - Write clean, semantic HTML5 elements.
   - Group visually related elements into cards with distinct borders or background colors (`bg-white border border-gray-100`).
   - Where necessary, mock Svelte 5 state variables (using `$state()`) to demonstrate interactive UI features like tabs, search filtering, or expanding rows.

Please generate the code for the [INSERT PAGE NAME HERE] page. Focus entirely on creating a 'wow' factor that feels completely premium and seamlessly stitches into a professional healthcare ecosystem.
```
