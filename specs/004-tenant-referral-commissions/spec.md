# Feature Specification: Multi-Tenant Referral Commission System

**Feature Branch**: `004-tenant-referral-commissions`
**Created**: 2026-03-13
**Status**: Draft
**Input**: Multi-tenant referral commission and fulfillment system

## User Scenarios & Testing

### User Story 1 - Session-Based Referral Attribution (Priority: P1)

When a customer accesses a service provider through a tenant's page, that tenant becomes the referrer for all transactions in that session and earns commission on every service purchased.

**Why this priority**: This is the foundational business model that enables the marketplace revenue-sharing system. Without it, tenants have no incentive to cross-promote services, and the platform loses its core value proposition.

**Independent Test**: Can be fully tested by having a customer visit `fokz.kemani.com/medic-directory`, select a doctor, complete a consultation, and verify that Fokz Pharmacy receives the correct referral commission (10% of consultation base fee). Delivers immediate value by enabling the first commission transaction.

**Acceptance Scenarios**:

1. **Given** Eliz is browsing `fokz.kemani.com`, **When** she navigates to the medic directory and books a consultation with Dr. Kome (base fee ₦1,000), **Then** the system records Fokz Pharmacy as the referrer and Fokz earns ₦100 commission while the customer pays ₦1,100 total
2. **Given** Kelly visits `kome.kemani.com/medic` directly (no referrer), **When** she books a consultation with Dr. Kome (base fee ₦1,000), **Then** the system records no referrer and the platform earns ₦200 (double share) while Dr. Kome gets ₦900
3. **Given** Bello is browsing `rilwan.kemani.com/medic-directory`, **When** he books a consultation with Dr. Kome through Dr. Rilwan's page, **Then** the system records Dr. Rilwan as the referrer (not Fokz, even if Bello was previously a Fokz customer)
4. **Given** Eliz previously consulted through Fokz Pharmacy, **When** she later visits `kome.kemani.com` directly, **Then** the system does NOT attribute this visit to Fokz (no persistent ownership)

---

### User Story 2 - Accurate Commission Calculation and Distribution (Priority: P1)

The platform automatically calculates and distributes commissions based on transaction type (service vs product) with different commission rates and markup models.

**Why this priority**: This is critical for financial integrity and tenant trust. Incorrect commission calculations lead to revenue loss and tenant disputes. Must be implemented from day one.

**Independent Test**: Can be tested by processing a sample consultation (service-based) and drug purchase (product-based) transaction, then verifying the exact commission amounts match the formulas: services get 10% markup with 90/10/10 split, products have no markup with 94/4.5/1.5 split.

**Acceptance Scenarios**:

1. **Given** a customer books a consultation with base fee ₦1,000 through a referrer's page, **When** payment is processed, **Then** the customer pays ₦1,100, the doctor receives ₦900, the referrer receives ₦100, and the platform receives ₦100
2. **Given** a customer purchases medication worth ₦5,000 through a referrer's page, **When** payment is processed, **Then** the customer pays ₦5,000 (no markup), the pharmacy receives ₦4,700 (94%), the referrer receives ₦225 (4.5%), and the platform receives ₦75 (1.5%)
3. **Given** a customer books a diagnostic test with base cost ₦5,000 through a referrer's page, **When** payment is processed, **Then** the customer pays ₦5,500 (10% markup), the diagnostic center receives ₦4,500, the referrer receives ₦500, and the platform receives ₦500
4. **Given** a customer purchases medication worth ₦5,000 directly from a pharmacy (no referrer), **When** payment is processed, **Then** the customer pays ₦5,100 (₦5,000 + ₦100 fixed charge), the pharmacy receives ₦4,700, and the platform receives ₦75 + ₦100 = ₦175

---

### User Story 3 - Multi-Service Commission in Single Session (Priority: P2)

When a customer accesses through a referrer's page and purchases multiple services (consultation, drugs, tests) in the same session, the referrer earns commission on ALL services.

**Why this priority**: This significantly increases the value proposition for referring tenants and incentivizes them to create comprehensive service offerings on their pages. Differentiates the platform from simple affiliate programs.

**Independent Test**: Can be tested by having a customer access through Fokz Pharmacy's page, book a consultation, purchase medication, and order a lab test in one session, then verifying Fokz receives commissions for all three transactions.

**Acceptance Scenarios**:

1. **Given** Eliz visits `fokz.kemani.com/medic-directory`, **When** she consults Dr. Kome (₦1,100), purchases drugs (₦5,000), and orders a malaria test (₦5,500) in the same session, **Then** Fokz Pharmacy earns ₦100 (consultation) + ₦225 (drugs) + ₦500 (test) = ₦825 total commission
2. **Given** Bello accesses through `rilwan.kemani.com`, **When** he consults Dr. Kome and the consultation generates a prescription and test request, **Then** Dr. Rilwan earns commission on the consultation, the fulfilled prescription, and the completed test
3. **Given** a customer is in an active session with a referrer, **When** they navigate between different services (pharmacy → diagnostic → back to medic), **Then** the original referrer continues to receive commission as long as they stay within the referrer's subdomain

---

### User Story 4 - Guaranteed Fulfillment Routing for Pharmacy and Lab Referrers (Priority: P2)

When a customer accesses through a pharmacy or diagnostic center's page and receives a prescription or test request, that prescription/test is automatically routed to the referring pharmacy/lab for fulfillment.

**Why this priority**: This protects the referring tenant's investment in marketing and provides a strong incentive for pharmacies and labs to promote doctors. Without this, referrers lose the guaranteed order fulfillment benefit.

**Independent Test**: Can be tested by having a customer access through `fokz.kemani.com`, consult a doctor who issues a prescription, and verify the prescription is automatically sent to Fokz Pharmacy (customer doesn't choose).

**Acceptance Scenarios**:

1. **Given** a customer accesses through `fokz.kemani.com/medic-directory` and consults Dr. Kome, **When** Dr. Kome issues a prescription, **Then** the prescription is automatically routed to Fokz Pharmacy for fulfillment and the customer does NOT see a pharmacy selection screen
2. **Given** a customer accesses through `medymed.kemani.com/medic-directory` and consults Dr. Kome, **When** Dr. Kome orders a lab test, **Then** the test request is automatically routed to Medy Med Diagnostic and the customer does NOT choose the lab
3. **Given** a customer accesses through a doctor's page directly (e.g., `kome.kemani.com/medic`) and receives a prescription, **When** the prescription is ready to fulfill, **Then** the system shows a pharmacy directory filtered by the customer's city and allows them to choose
4. **Given** a customer accesses through a doctor's page directly and receives a test request, **When** the test is ready to order, **Then** the system shows a diagnostic center directory filtered by the customer's city and allows them to choose

---

### User Story 5 - Commission Tracking and Reporting (Priority: P3)

Tenants can view their earned commissions, pending commissions, and commission history in their dashboard with detailed breakdowns by transaction type and referral source.

**Why this priority**: While not required for the core transaction flow to work, this transparency builds trust and helps tenants track their earnings. Can be implemented after the core commission system is functional.

**Independent Test**: Can be tested by generating sample transactions for a tenant, then verifying their dashboard shows accurate commission totals, breakdowns by service type (consultation/drugs/tests), and transaction history.

**Acceptance Scenarios**:

1. **Given** Fokz Pharmacy has referred 10 customers this month, **When** they view their commission dashboard, **Then** they see total earned (₦X), pending (₦Y), and paid out (₦Z) commissions with a breakdown by transaction type
2. **Given** Dr. Rilwan earned commissions from consultations, drug sales, and diagnostic tests, **When** he views his commission report, **Then** he sees separate line items for each transaction type with amounts and dates
3. **Given** a tenant views their commission history, **When** they click on a specific commission entry, **Then** they see the full transaction details including customer (anonymized if needed), service provider, transaction date, and commission calculation breakdown

---

### Edge Cases

- What happens when a customer accesses through a referrer's page but abandons the transaction and returns later directly? (No commission to original referrer - session-based attribution only)
- How does the system handle when a doctor refers to another doctor who then issues a prescription? (Referrer gets commission on both consultation and prescription fulfillment)
- What if a pharmacy referrer is out of stock for a prescribed medication? (Prescription is still routed to them, they must handle fulfillment or communicate with customer)
- How are refunds handled for commissioned transactions? (Commission clawback mechanism needed - reduce referrer and platform commission proportionally)
- What happens if a tenant changes their pricing during an active customer session? (Use price locked at time of service selection, not checkout)
- How does the system prevent commission fraud (e.g., tenant creating fake accounts to self-refer)? (Out of scope for this spec - address in security/fraud detection feature)

## Requirements

### Functional Requirements

- **FR-001**: System MUST track the referring tenant for each customer session based on the subdomain/page they are currently browsing (e.g., `fokz.kemani.com` → Fokz Pharmacy is referrer)
- **FR-002**: System MUST calculate commission for service-based transactions (consultations, diagnostic tests) using the formula: Customer Pays = Base × 1.10, Provider Gets = Base × 0.90, Referrer Gets = Base × 0.10, Platform Gets = Base × 0.10
- **FR-003**: System MUST calculate commission for product-based transactions (pharmacy drugs) using the formula: Customer Pays = Price (no markup), Provider Gets = Price × 0.94, Referrer Gets = Price × 0.045, Platform Gets = Price × 0.015
- **FR-004**: System MUST handle "no referrer" scenarios differently: for services, Platform Gets = Base × 0.20 (double share); for products, Platform Gets = Price × 0.015 + ₦100 fixed charge
- **FR-005**: System MUST attribute ALL services purchased in a single session to the same referrer (multi-service commission)
- **FR-006**: System MUST automatically route prescriptions to the referring pharmacy when the customer accessed through a pharmacy's page
- **FR-007**: System MUST automatically route test requests to the referring diagnostic center when the customer accessed through a diagnostic center's page
- **FR-008**: System MUST display a city-filtered pharmacy directory when a prescription is issued and there is no pharmacy referrer (customer accessed through doctor's page directly)
- **FR-009**: System MUST display a city-filtered diagnostic center directory when a test is requested and there is no diagnostic center referrer
- **FR-010**: System MUST persist referral attribution data for each transaction including: customer ID, referring tenant ID, referred tenant (service provider) ID, transaction type, commission amounts
- **FR-011**: System MUST support multiple tenant types with different commission eligibility: Medic Tenants (doctors, pharmacists) and POS Tenants (diagnostic centers, pharmacies, supermarkets, retail)
- **FR-012**: System MUST prevent multi-level referral commissions (only the immediate referrer whose page customer is on receives commission, no chaining)
- **FR-013**: System MUST allow different providers to set different prices for the same medication/service (free market pricing model)
- **FR-014**: System MUST record commission status for each transaction: pending, processed, paid_out
- **FR-015**: System MUST provide tenants visibility into their earned commissions via dashboard

### Key Entities

- **Referral Session**: Represents a customer's current browsing session, tracking which tenant's page they are on (the referrer). Attributes: customer ID, referrer tenant ID, session start time, active status
- **Commission Record**: Represents a single commission transaction. Attributes: transaction ID, transaction type (consultation/product/diagnostic), provider tenant ID, referrer tenant ID (nullable), customer ID, base amount, customer paid amount, provider amount, referrer amount, platform amount, commission rate, status (pending/processed/paid_out), created timestamp
- **Transaction**: Represents a customer purchase (consultation, drug purchase, or diagnostic test). Attributes: transaction ID, type, provider tenant ID, customer ID, referring tenant ID (nullable), base price, final price paid by customer, payment status, timestamp
- **Prescription**: Represents a medication prescription issued by a doctor. Attributes: prescription ID, doctor ID, customer ID, fulfilling pharmacy ID (auto-assigned if referrer is pharmacy), medication details, status (pending/fulfilled), issue timestamp
- **Test Request**: Represents a diagnostic test order. Attributes: test request ID, doctor ID, customer ID, fulfilling diagnostic center ID (auto-assigned if referrer is diagnostic center), test details, status (pending/completed), order timestamp
- **Tenant**: Represents a business on the platform. Attributes: tenant ID, tenant type (doctor/pharmacist/pharmacy/diagnostic/supermarket/retail), business name, subdomain (e.g., "fokz" for fokz.kemani.com), commission settings, payment details

## Success Criteria

### Measurable Outcomes

- **SC-001**: Tenants can view their earned commissions within 5 seconds of accessing their dashboard
- **SC-002**: Commission calculations are 100% accurate with zero discrepancies between expected and actual amounts based on the defined formulas
- **SC-003**: Session-based attribution correctly identifies the referrer in 100% of transactions based on the subdomain/page accessed
- **SC-004**: Multi-service sessions correctly attribute all services to the same referrer with 100% accuracy
- **SC-005**: Prescription routing to referring pharmacies happens automatically in 100% of cases where customer accessed through pharmacy's page
- **SC-006**: Test routing to referring diagnostic centers happens automatically in 100% of cases where customer accessed through diagnostic center's page
- **SC-007**: No-referrer scenarios (direct access) correctly display city-filtered directories in 100% of cases
- **SC-008**: Platform increases tenant cross-promotion by 40% within 3 months of launch (measured by number of referral sessions initiated)
- **SC-009**: Average transaction value increases by 25% due to multi-service bundling in single sessions
- **SC-010**: Tenant commission earnings are transparently visible with detailed breakdowns, reducing commission-related support tickets by 60%

## Assumptions

1. **Payment Processing**: Assumes the platform collects all customer payments first, then distributes commissions to providers and referrers (platform-managed payment model, not split payment at checkout)
2. **Session Duration**: A customer "session" is defined by continuous browsing within a tenant's subdomain; navigating away or closing browser ends the session
3. **Currency**: All amounts are in Nigerian Naira (₦)
4. **Pricing Authority**: Each provider sets their own base prices; the platform only applies markup percentages, not fixed amounts
5. **Refund Handling**: Commission clawback mechanics will be defined in a separate specification (out of scope for initial implementation)
6. **Fraud Prevention**: Assumes basic fraud detection (e.g., preventing self-referrals) will be handled by separate fraud detection system
7. **Inventory Visibility**: Level of inventory visibility to customers (full stock count vs. in-stock indicator) to be determined during implementation
8. **Payment Gateway**: Assumes existing payment gateway integration (Paystack/Flutterwave) is already in place
9. **City Filtering**: Customer's city for directory filtering is determined from their profile or can be manually selected during checkout
10. **Commission Payout Frequency**: Frequency of commission payouts to tenants (daily/weekly/monthly) to be determined during implementation planning

## Non-Goals

This feature specification explicitly EXCLUDES:

- Multi-level or pyramid-style commission structures (only immediate referrer earns commission)
- Persistent customer "ownership" (no first-touch attribution model)
- Custom commission rates per tenant relationship (all commissions use standard platform rates)
- Affiliate marketing with external (non-tenant) referrers
- Commission negotiation or bidding systems
- Customer loyalty points or rewards programs
- White-label commission tracking for third-party platforms
