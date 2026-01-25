# Webhook Documentation: Multi-Tenant POS Platform

**Feature**: Multi-Tenant POS-First Super App Platform
**Branch**: `001-multi-tenant-pos`
**Version**: 1.0.0
**Last Updated**: 2026-01-24

## Overview

This document describes all webhook integrations for the Kemani multi-tenant POS platform, including:
- **Incoming webhooks**: Events received from external platforms (payment gateways, e-commerce, WhatsApp)
- **Outgoing webhooks**: Events sent to tenants and integrations

All webhooks use **HTTPS POST** requests with **JSON payloads** and **HMAC signature verification** for security.

---

## Table of Contents

1. [Incoming Webhooks](#incoming-webhooks)
   - [Payment Gateway Webhooks](#payment-gateway-webhooks)
   - [E-Commerce Platform Webhooks](#e-commerce-platform-webhooks)
   - [WhatsApp Webhooks](#whatsapp-webhooks)
2. [Outgoing Webhooks](#outgoing-webhooks)
   - [Marketplace Order Events](#marketplace-order-events)
   - [Delivery Status Events](#delivery-status-events)
   - [Inventory Alerts](#inventory-alerts)
   - [Sync Conflict Events](#sync-conflict-events)
3. [Security](#security)
4. [Retry Policy](#retry-policy)
5. [Testing Webhooks](#testing-webhooks)

---

## Incoming Webhooks

These are webhooks that the Kemani platform **receives** from external services.

### Payment Gateway Webhooks

#### 1. Paystack Webhooks

**Endpoint**: `POST /api/webhooks/paystack`

**Purpose**: Receive payment status updates from Paystack for subscription billing and marketplace transactions.

**Supported Events**:
- `charge.success` - Payment completed successfully
- `charge.failed` - Payment failed
- `subscription.create` - Subscription created
- `subscription.disable` - Subscription cancelled
- `transfer.success` - Payout to merchant succeeded
- `transfer.failed` - Payout failed

**Payload Example** (`charge.success`):

```json
{
  "event": "charge.success",
  "data": {
    "id": 123456789,
    "domain": "live",
    "status": "success",
    "reference": "KEMANI-TXN-20240124-001",
    "amount": 500000,
    "currency": "NGN",
    "paid_at": "2024-01-24T10:30:45.000Z",
    "created_at": "2024-01-24T10:30:00.000Z",
    "channel": "card",
    "customer": {
      "id": 987654,
      "email": "customer@example.com",
      "customer_code": "CUS_xxx"
    },
    "metadata": {
      "tenant_id": "550e8400-e29b-41d4-a716-446655440000",
      "order_id": "660e8400-e29b-41d4-a716-446655440001",
      "custom_fields": []
    }
  }
}
```

**Response**:
- **200 OK**: Webhook processed successfully
- **400 Bad Request**: Invalid payload
- **401 Unauthorized**: Invalid signature

**Processing Logic**:
1. Verify webhook signature using Paystack secret key
2. Extract `tenant_id` and `order_id` from metadata
3. Update order payment status to `paid`
4. Trigger order confirmation workflow (send WhatsApp notification, update inventory)
5. Log webhook event for audit trail

**Signature Verification**:
```javascript
const crypto = require('crypto');

function verifyPaystackSignature(payload, signature) {
  const secret = process.env.PAYSTACK_SECRET_KEY;
  const hash = crypto
    .createHmac('sha512', secret)
    .update(JSON.stringify(payload))
    .digest('hex');
  return hash === signature;
}
```

---

#### 2. Flutterwave Webhooks

**Endpoint**: `POST /api/webhooks/flutterwave`

**Purpose**: Receive payment notifications from Flutterwave.

**Supported Events**:
- `charge.completed` - Payment successful
- `charge.failed` - Payment failed
- `transfer.completed` - Payout completed

**Payload Example** (`charge.completed`):

```json
{
  "event": "charge.completed",
  "data": {
    "id": 123456,
    "tx_ref": "KEMANI-TXN-20240124-002",
    "flw_ref": "FLW-MOCK-XXXXX",
    "amount": 5000,
    "currency": "NGN",
    "charged_amount": 5000,
    "status": "successful",
    "payment_type": "card",
    "created_at": "2024-01-24T10:30:00.000Z",
    "customer": {
      "email": "customer@example.com",
      "phone_number": "+2348012345678"
    },
    "meta": {
      "tenant_id": "550e8400-e29b-41d4-a716-446655440000",
      "order_id": "660e8400-e29b-41d4-a716-446655440001"
    }
  }
}
```

**Signature Verification**:
```javascript
function verifyFlutterwaveSignature(payload, signature) {
  const secret = process.env.FLUTTERWAVE_SECRET_HASH;
  const hash = crypto
    .createHmac('sha256', secret)
    .update(JSON.stringify(payload))
    .digest('hex');
  return hash === signature;
}
```

---

### E-Commerce Platform Webhooks

#### 3. WooCommerce Webhooks

**Endpoint**: `POST /api/webhooks/woocommerce`

**Purpose**: Sync product updates, inventory changes, and new orders from WooCommerce stores.

**Supported Topics**:
- `product.created` - New product added
- `product.updated` - Product modified
- `product.deleted` - Product removed
- `order.created` - New order placed
- `order.updated` - Order status changed

**Payload Example** (`order.created`):

```json
{
  "id": 12345,
  "parent_id": 0,
  "status": "processing",
  "currency": "NGN",
  "date_created": "2024-01-24T10:30:00",
  "date_modified": "2024-01-24T10:30:00",
  "total": "5000.00",
  "customer_id": 1,
  "billing": {
    "first_name": "John",
    "last_name": "Doe",
    "email": "john@example.com",
    "phone": "+2348012345678"
  },
  "shipping": {
    "first_name": "John",
    "last_name": "Doe",
    "address_1": "123 Main Street",
    "city": "Lagos",
    "state": "LA",
    "postcode": "100001"
  },
  "line_items": [
    {
      "id": 1,
      "name": "Paracetamol 500mg",
      "product_id": 789,
      "variation_id": 0,
      "quantity": 2,
      "subtotal": "1000.00",
      "total": "1000.00",
      "sku": "PARA-500"
    }
  ],
  "meta_data": [
    {
      "key": "_kemani_connection_id",
      "value": "770e8400-e29b-41d4-a716-446655440000"
    }
  ]
}
```

**Response**: `200 OK`

**Processing Logic**:
1. Verify webhook signature using WooCommerce secret
2. Extract `_kemani_connection_id` from metadata to identify tenant
3. Map WooCommerce product IDs to Kemani product IDs
4. Create order in Kemani system with `order_source = 'woocommerce'`
5. Sync inventory changes bidirectionally
6. Handle conflicts using configured resolution strategy

**Signature Verification**:
WooCommerce uses HMAC-SHA256 with webhook secret sent in `X-WC-Webhook-Signature` header.

```javascript
function verifyWooCommerceSignature(payload, signature, secret) {
  const hash = crypto
    .createHmac('sha256', secret)
    .update(payload)
    .digest('base64');
  return hash === signature;
}
```

---

#### 4. Shopify Webhooks

**Endpoint**: `POST /api/webhooks/shopify`

**Purpose**: Sync products and orders from Shopify stores.

**Supported Topics**:
- `products/create` - Product created
- `products/update` - Product updated
- `products/delete` - Product deleted
- `orders/create` - New order
- `inventory_levels/update` - Inventory changed

**Payload Example** (`orders/create`):

```json
{
  "id": 123456789,
  "email": "customer@example.com",
  "created_at": "2024-01-24T10:30:00Z",
  "updated_at": "2024-01-24T10:30:00Z",
  "number": 1001,
  "total_price": "5000.00",
  "currency": "NGN",
  "financial_status": "paid",
  "fulfillment_status": null,
  "customer": {
    "id": 987654,
    "email": "customer@example.com",
    "first_name": "Jane",
    "last_name": "Smith",
    "phone": "+2348098765432"
  },
  "shipping_address": {
    "address1": "456 Market Road",
    "city": "Lagos",
    "province": "Lagos",
    "country": "Nigeria",
    "zip": "100001"
  },
  "line_items": [
    {
      "id": 111,
      "product_id": 222,
      "variant_id": 333,
      "title": "Ibuprofen 400mg",
      "quantity": 3,
      "price": "500.00",
      "sku": "IBU-400"
    }
  ],
  "note_attributes": [
    {
      "name": "_kemani_connection_id",
      "value": "880e8400-e29b-41d4-a716-446655440000"
    }
  ]
}
```

**Signature Verification**:
Shopify uses HMAC-SHA256 with shared secret sent in `X-Shopify-Hmac-SHA256` header.

```javascript
function verifyShopifySignature(payload, signature, secret) {
  const hash = crypto
    .createHmac('sha256', secret)
    .update(payload, 'utf8')
    .digest('base64');
  return hash === signature;
}
```

---

### WhatsApp Webhooks

#### 5. WhatsApp Cloud API Webhooks

**Endpoint**: `POST /api/webhooks/whatsapp`

**Purpose**: Receive incoming messages and delivery status updates from WhatsApp Business API.

**Supported Event Types**:
- `messages` - Incoming customer message
- `message_status` - Delivery status update (sent, delivered, read, failed)

**Payload Example** (Incoming Message):

```json
{
  "object": "whatsapp_business_account",
  "entry": [
    {
      "id": "WHATSAPP_BUSINESS_ACCOUNT_ID",
      "changes": [
        {
          "value": {
            "messaging_product": "whatsapp",
            "metadata": {
              "display_phone_number": "+2349012345678",
              "phone_number_id": "PHONE_NUMBER_ID"
            },
            "contacts": [
              {
                "profile": {
                  "name": "Customer Name"
                },
                "wa_id": "2348012345678"
              }
            ],
            "messages": [
              {
                "from": "2348012345678",
                "id": "wamid.XXX",
                "timestamp": "1706097000",
                "text": {
                  "body": "Do you have paracetamol in stock?"
                },
                "type": "text"
              }
            ]
          },
          "field": "messages"
        }
      ]
    }
  ]
}
```

**Payload Example** (Status Update):

```json
{
  "object": "whatsapp_business_account",
  "entry": [
    {
      "changes": [
        {
          "value": {
            "messaging_product": "whatsapp",
            "metadata": {
              "phone_number_id": "PHONE_NUMBER_ID"
            },
            "statuses": [
              {
                "id": "wamid.XXX",
                "status": "delivered",
                "timestamp": "1706097100",
                "recipient_id": "2348012345678"
              }
            ]
          },
          "field": "messages"
        }
      ]
    }
  ]
}
```

**Webhook Verification** (GET request):
WhatsApp sends a GET request with challenge token for verification.

```javascript
// GET /api/webhooks/whatsapp?hub.mode=subscribe&hub.challenge=XXX&hub.verify_token=YYY
app.get('/api/webhooks/whatsapp', (req, res) => {
  const mode = req.query['hub.mode'];
  const token = req.query['hub.verify_token'];
  const challenge = req.query['hub.challenge'];

  if (mode === 'subscribe' && token === process.env.WHATSAPP_VERIFY_TOKEN) {
    res.status(200).send(challenge);
  } else {
    res.sendStatus(403);
  }
});
```

**Processing Logic**:
1. Verify webhook token (GET) or signature (POST)
2. Extract phone number and message text
3. Identify tenant by WhatsApp business number
4. Create or update chat conversation
5. Store message in `chat_messages` table
6. If AI agent enabled, process message and generate response
7. Update WhatsApp message status in database

---

## Outgoing Webhooks

These are webhooks that Kemani **sends** to tenants or external systems when events occur.

### Marketplace Order Events

#### 6. New Order Created

**Event**: `order.created`

**Trigger**: Customer places order on marketplace

**Payload**:

```json
{
  "event": "order.created",
  "timestamp": "2024-01-24T10:30:00Z",
  "tenant_id": "550e8400-e29b-41d4-a716-446655440000",
  "data": {
    "order_id": "660e8400-e29b-41d4-a716-446655440001",
    "order_number": "ORD-2024-00123",
    "order_date": "2024-01-24T10:30:00Z",
    "customer": {
      "id": "770e8400-e29b-41d4-a716-446655440002",
      "name": "John Doe",
      "phone": "+2348012345678",
      "email": "john@example.com"
    },
    "items": [
      {
        "product_id": "880e8400-e29b-41d4-a716-446655440003",
        "product_name": "Paracetamol 500mg",
        "sku": "PARA-500",
        "quantity": 2,
        "unit_price": 500.00,
        "subtotal": 1000.00
      }
    ],
    "subtotal": 1000.00,
    "tax_amount": 75.00,
    "delivery_fee": 500.00,
    "total_amount": 1575.00,
    "payment_status": "pending",
    "fulfillment_type": "local_delivery",
    "delivery_address": {
      "address_line1": "123 Main Street",
      "city": "Lagos",
      "state": "Lagos",
      "postal_code": "100001"
    }
  }
}
```

**Expected Response**: `200 OK` within 30 seconds

**Retry Policy**: See [Retry Policy](#retry-policy) section

---

#### 7. Order Status Changed

**Event**: `order.status_changed`

**Trigger**: Order status updates (confirmed, preparing, ready, delivered, cancelled)

**Payload**:

```json
{
  "event": "order.status_changed",
  "timestamp": "2024-01-24T11:00:00Z",
  "tenant_id": "550e8400-e29b-41d4-a716-446655440000",
  "data": {
    "order_id": "660e8400-e29b-41d4-a716-446655440001",
    "order_number": "ORD-2024-00123",
    "previous_status": "confirmed",
    "new_status": "preparing",
    "changed_by": {
      "user_id": "990e8400-e29b-41d4-a716-446655440004",
      "user_name": "Staff Member"
    },
    "notes": "Order is being prepared"
  }
}
```

---

### Delivery Status Events

#### 8. Delivery Status Updated

**Event**: `delivery.status_changed`

**Trigger**: Delivery rider updates delivery status

**Payload**:

```json
{
  "event": "delivery.status_changed",
  "timestamp": "2024-01-24T12:00:00Z",
  "tenant_id": "550e8400-e29b-41d4-a716-446655440000",
  "data": {
    "delivery_id": "aa0e8400-e29b-41d4-a716-446655440005",
    "order_id": "660e8400-e29b-41d4-a716-446655440001",
    "tracking_number": "TRK-2024-00456",
    "previous_status": "picked_up",
    "new_status": "in_transit",
    "rider": {
      "id": "bb0e8400-e29b-41d4-a716-446655440006",
      "name": "Rider Name",
      "phone": "+2348098765432"
    },
    "estimated_delivery_time": "2024-01-24T14:00:00Z",
    "current_location": {
      "latitude": 6.5244,
      "longitude": 3.3792
    }
  }
}
```

**Use Case**: Tenant can forward this to their own tracking system or display real-time updates to customers.

---

#### 9. Delivery Completed

**Event**: `delivery.completed`

**Trigger**: Rider marks delivery as delivered with proof

**Payload**:

```json
{
  "event": "delivery.completed",
  "timestamp": "2024-01-24T13:45:00Z",
  "tenant_id": "550e8400-e29b-41d4-a716-446655440000",
  "data": {
    "delivery_id": "aa0e8400-e29b-41d4-a716-446655440005",
    "order_id": "660e8400-e29b-41d4-a716-446655440001",
    "tracking_number": "TRK-2024-00456",
    "actual_delivery_time": "2024-01-24T13:45:00Z",
    "proof_of_delivery": {
      "type": "photo",
      "url": "https://cdn.kemani.ng/proof/xxx.jpg",
      "recipient_name": "John Doe",
      "signature_url": null
    },
    "delivery_duration_minutes": 105
  }
}
```

---

### Inventory Alerts

#### 10. Low Stock Alert

**Event**: `inventory.low_stock`

**Trigger**: Product stock falls below threshold

**Payload**:

```json
{
  "event": "inventory.low_stock",
  "timestamp": "2024-01-24T14:00:00Z",
  "tenant_id": "550e8400-e29b-41d4-a716-446655440000",
  "data": {
    "product_id": "880e8400-e29b-41d4-a716-446655440003",
    "product_name": "Paracetamol 500mg",
    "sku": "PARA-500",
    "current_stock": 8,
    "low_stock_threshold": 10,
    "recommended_reorder_quantity": 100
  }
}
```

---

#### 11. Expiry Alert

**Event**: `inventory.expiry_alert`

**Trigger**: Product approaching expiry date (within configured threshold)

**Payload**:

```json
{
  "event": "inventory.expiry_alert",
  "timestamp": "2024-01-24T06:00:00Z",
  "tenant_id": "550e8400-e29b-41d4-a716-446655440000",
  "data": {
    "product_id": "880e8400-e29b-41d4-a716-446655440003",
    "product_name": "Amoxicillin 250mg",
    "sku": "AMOX-250",
    "expiry_date": "2024-02-15",
    "days_until_expiry": 22,
    "current_stock": 50,
    "alert_level": "warning"
  }
}
```

---

### Sync Conflict Events

#### 12. Sync Conflict Detected

**Event**: `sync.conflict_detected`

**Trigger**: Offline sync detects conflicting changes that cannot be auto-resolved

**Payload**:

```json
{
  "event": "sync.conflict_detected",
  "timestamp": "2024-01-24T15:00:00Z",
  "tenant_id": "550e8400-e29b-41d4-a716-446655440000",
  "data": {
    "conflict_id": "cc0e8400-e29b-41d4-a716-446655440007",
    "table_name": "products",
    "record_id": "880e8400-e29b-41d4-a716-446655440003",
    "conflict_type": "concurrent_update",
    "local_version": 5,
    "server_version": 6,
    "local_changes": {
      "selling_price": 600.00,
      "updated_at": "2024-01-24T14:55:00Z"
    },
    "server_changes": {
      "selling_price": 550.00,
      "updated_at": "2024-01-24T14:58:00Z"
    },
    "resolution_required": true
  }
}
```

**Use Case**: Admin receives notification to manually resolve conflict in dashboard.

---

## Security

### Signature Verification

All incoming webhooks MUST verify signatures to prevent spoofing attacks.

**General Process**:
1. Extract signature from HTTP header (header name varies by provider)
2. Compute HMAC hash of request body using shared secret
3. Compare computed hash with provided signature (constant-time comparison)
4. Reject request if signatures don't match

**Example** (Generic):

```javascript
const crypto = require('crypto');
const timingSafeEqual = require('crypto').timingSafeEqual;

function verifyWebhookSignature(payload, signature, secret, algorithm = 'sha256') {
  const computedSignature = crypto
    .createHmac(algorithm, secret)
    .update(payload)
    .digest('hex');

  // Use timing-safe comparison to prevent timing attacks
  const signatureBuffer = Buffer.from(signature, 'hex');
  const computedBuffer = Buffer.from(computedSignature, 'hex');

  if (signatureBuffer.length !== computedBuffer.length) {
    return false;
  }

  return timingSafeEqual(signatureBuffer, computedBuffer);
}
```

### Outgoing Webhook Signatures

For outgoing webhooks (events sent to tenants), Kemani generates HMAC-SHA256 signatures.

**Header**: `X-Kemani-Signature`

**Secret**: Each tenant has unique webhook secret (configured in tenant settings)

**Verification** (Tenant Side):

```javascript
function verifyKemaniWebhook(payload, signature, tenantSecret) {
  const hash = crypto
    .createHmac('sha256', tenantSecret)
    .update(JSON.stringify(payload))
    .digest('hex');
  return hash === signature;
}
```

### IP Whitelisting

For enhanced security, tenants can whitelist Kemani's webhook IP addresses:

**Production IPs**:
- `52.31.xxx.xxx`
- `54.77.xxx.xxx`

**Staging IPs**:
- `3.248.xxx.xxx`

---

## Retry Policy

### Incoming Webhooks

**No retries** - External platforms handle their own retry logic. Kemani responds immediately:
- `200 OK` if processed successfully
- `400 Bad Request` if payload invalid
- `401 Unauthorized` if signature verification fails
- `500 Internal Server Error` if temporary processing error (provider will retry)

### Outgoing Webhooks

**Exponential Backoff Retry**:

1. **Initial Attempt**: Send webhook immediately
2. **Retry 1**: After 30 seconds if failed
3. **Retry 2**: After 2 minutes
4. **Retry 3**: After 10 minutes
5. **Retry 4**: After 1 hour
6. **Retry 5**: After 6 hours

**Failure Criteria**:
- HTTP status >= 500 (server error)
- HTTP status = 429 (rate limited)
- Network timeout (30 seconds)
- Connection refused

**Success Criteria**:
- HTTP status 200-299

**Abandonment**:
- After 5 failed attempts, webhook marked as failed
- Tenant admin receives notification
- Manual retry available in dashboard

**Idempotency**:
- Each webhook includes unique `event_id` in payload
- Tenants should store processed event IDs to prevent duplicate processing

---

## Testing Webhooks

### Incoming Webhook Testing

Use webhook testing tools to simulate external platform webhooks:

**Tools**:
- [Webhook.site](https://webhook.site) - Inspect incoming webhooks
- [ngrok](https://ngrok.com) - Expose localhost for local testing
- [Postman](https://postman.com) - Manual webhook requests

**Test Example** (Paystack):

```bash
curl -X POST https://api.kemani.ng/api/webhooks/paystack \
  -H "Content-Type: application/json" \
  -H "X-Paystack-Signature: <computed_signature>" \
  -d '{
    "event": "charge.success",
    "data": {
      "reference": "TEST-REF-001",
      "amount": 100000,
      "status": "success",
      "metadata": {
        "tenant_id": "550e8400-e29b-41d4-a716-446655440000"
      }
    }
  }'
```

### Outgoing Webhook Testing

**Dashboard**: Tenants can configure webhook URLs and test with sample events:

1. Navigate to **Settings > Webhooks**
2. Add webhook URL
3. Click **Test Webhook** button
4. Select event type (e.g., `order.created`)
5. View request/response logs

**Local Testing** (Development):

```bash
# Start local webhook receiver
npx webhook-relay forward http://localhost:4000/webhooks/kemani

# Configure tenant webhook URL to relay URL
# Trigger event in Kemani platform
# Observe webhook received at local endpoint
```

---

## Webhook Event Reference Summary

| Event | Direction | Trigger | Payload Size |
|-------|-----------|---------|--------------|
| `charge.success` | Incoming | Payment completed | ~500 bytes |
| `order.created` (WooCommerce) | Incoming | New WooCommerce order | ~2KB |
| `messages` (WhatsApp) | Incoming | Customer WhatsApp message | ~300 bytes |
| `order.created` | Outgoing | Marketplace order placed | ~1.5KB |
| `delivery.status_changed` | Outgoing | Rider updates delivery | ~800 bytes |
| `inventory.low_stock` | Outgoing | Stock below threshold | ~400 bytes |
| `sync.conflict_detected` | Outgoing | Sync conflict occurs | ~600 bytes |

---

## Implementation Checklist

### For Incoming Webhooks

- [ ] Implement signature verification for all providers
- [ ] Log all webhook events for audit trail
- [ ] Handle idempotency (detect duplicate webhooks)
- [ ] Validate payload schema before processing
- [ ] Respond within 5 seconds to avoid timeouts
- [ ] Queue heavy processing for background jobs
- [ ] Monitor webhook failure rates
- [ ] Implement rate limiting to prevent abuse

### For Outgoing Webhooks

- [ ] Generate HMAC signatures for all events
- [ ] Implement exponential backoff retry logic
- [ ] Store webhook delivery logs (request, response, status)
- [ ] Provide webhook testing UI in tenant dashboard
- [ ] Include unique `event_id` for idempotency
- [ ] Monitor delivery success rates
- [ ] Alert tenants of webhook failures
- [ ] Support webhook URL rotation

---

## Support

For webhook-related issues:

**Documentation**: [https://docs.kemani.ng/webhooks](https://docs.kemani.ng/webhooks)
**Email**: webhooks@kemani.ng
**Slack**: #webhook-support

**SLA**:
- Incoming webhook processing: < 5 seconds (99.9%)
- Outgoing webhook delivery: < 30 seconds (99%)
- Webhook failure notification: < 5 minutes

---

**End of Webhook Documentation**
