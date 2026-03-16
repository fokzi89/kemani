# Commission API Contracts

**Purpose**: Query commission earnings, calculate commissions, track payment status

---

## Endpoints

### 1. GET /commissions

**Purpose**: List commissions for the authenticated tenant (as referrer or provider)

**Authorization**: Requires `tenant_admin` or `platform_admin` role

**Query Parameters**:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `page` | integer | No | Page number (default: 1) |
| `per_page` | integer | No | Items per page (default: 50, max: 100) |
| `status` | string | No | Filter by status (`pending`, `processed`, `paid_out`) |
| `transaction_type` | string | No | Filter by type (`consultation`, `product_sale`, `diagnostic_test`) |
| `role` | string | No | Filter by tenant role (`referrer`, `provider`) - see commissions earned vs. paid |
| `date_from` | string (ISO 8601) | No | Start date (inclusive) |
| `date_to` | string (ISO 8601) | No | End date (inclusive) |
| `sort_by` | string | No | Sort field (`created_at`, `amount`, `status`) (default: `created_at`) |
| `sort_order` | string | No | Sort order (`asc`, `desc`) (default: `desc`) |

**Request Example**:
```http
GET /commissions?status=paid_out&role=referrer&date_from=2026-03-01&date_to=2026-03-31&sort_by=created_at&sort_order=desc
Authorization: Bearer <jwt_token>
```

**Response Example** (200 OK):
```json
{
  "data": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "transaction_id": "660e8400-e29b-41d4-a716-446655440000",
      "transaction_type": "consultation",
      "provider_tenant_id": "770e8400-e29b-41d4-a716-446655440000",
      "provider_tenant_name": "Dr. Kome Medical Practice",
      "referrer_tenant_id": "880e8400-e29b-41d4-a716-446655440000",
      "referrer_tenant_name": "Fokz Pharmacy",
      "customer_id": "990e8400-e29b-41d4-a716-446655440000",
      "base_amount": 1000.00,
      "customer_paid": 1100.00,
      "provider_amount": 900.00,
      "referrer_amount": 100.00,
      "platform_amount": 100.00,
      "status": "paid_out",
      "created_at": "2026-03-15T14:30:00Z",
      "processed_at": "2026-03-15T14:30:05Z",
      "paid_at": "2026-03-20T09:00:00Z"
    }
  ],
  "meta": {
    "page": 1,
    "per_page": 50,
    "total": 1,
    "total_pages": 1,
    "timestamp": "2026-03-13T10:30:00Z"
  }
}
```

---

### 2. GET /commissions/:id

**Purpose**: Get details of a specific commission

**Authorization**: Requires tenant to be referrer or provider of the commission

**Path Parameters**:
| Parameter | Type | Description |
|-----------|------|-------------|
| `id` | UUID | Commission ID |

**Request Example**:
```http
GET /commissions/550e8400-e29b-41d4-a716-446655440000
Authorization: Bearer <jwt_token>
```

**Response Example** (200 OK):
```json
{
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "transaction_id": "660e8400-e29b-41d4-a716-446655440000",
    "transaction_type": "consultation",
    "provider_tenant_id": "770e8400-e29b-41d4-a716-446655440000",
    "provider_tenant_name": "Dr. Kome Medical Practice",
    "referrer_tenant_id": "880e8400-e29b-41d4-a716-446655440000",
    "referrer_tenant_name": "Fokz Pharmacy",
    "customer_id": "990e8400-e29b-41d4-a716-446655440000",
    "base_amount": 1000.00,
    "customer_paid": 1100.00,
    "provider_amount": 900.00,
    "referrer_amount": 100.00,
    "platform_amount": 100.00,
    "status": "paid_out",
    "created_at": "2026-03-15T14:30:00Z",
    "processed_at": "2026-03-15T14:30:05Z",
    "paid_at": "2026-03-20T09:00:00Z",
    "calculation_metadata": {
      "formula": "service_commission",
      "has_referrer": true,
      "markup_rate": 0.10,
      "provider_rate": 0.90,
      "referrer_rate": 0.10,
      "platform_rate": 0.10
    },
    "transaction": {
      "type": "consultation",
      "payment_reference": "PAY-12345678",
      "created_at": "2026-03-15T14:30:00Z"
    }
  },
  "meta": {
    "timestamp": "2026-03-13T10:30:00Z"
  }
}
```

**Error Response** (403 Forbidden):
```json
{
  "error": {
    "code": "FORBIDDEN",
    "message": "You do not have permission to view this commission"
  }
}
```

---

### 3. POST /commissions/calculate

**Purpose**: Preview commission calculation for a transaction (before checkout)

**Authorization**: Requires authenticated user

**Request Body**:
```json
{
  "transaction_type": "consultation",
  "base_price": 1000.00,
  "has_referrer": true
}
```

**Request Example**:
```http
POST /commissions/calculate
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
  "transaction_type": "consultation",
  "base_price": 1000.00,
  "has_referrer": true
}
```

**Response Example** (200 OK):
```json
{
  "data": {
    "transaction_type": "consultation",
    "base_price": 1000.00,
    "customer_pays": 1100.00,
    "breakdown": {
      "provider_gets": 900.00,
      "referrer_gets": 100.00,
      "platform_gets": 100.00
    },
    "formula_used": "service_commission",
    "markup_applied": true,
    "markup_percentage": 10.0
  },
  "meta": {
    "timestamp": "2026-03-13T10:30:00Z"
  }
}
```

**Validation Errors** (400 Bad Request):
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid request parameters",
    "details": {
      "base_price": "Must be a positive number",
      "transaction_type": "Must be one of: consultation, product_sale, diagnostic_test"
    }
  }
}
```

---

### 4. GET /commissions/summary

**Purpose**: Get aggregated commission summary for dashboard

**Authorization**: Requires `tenant_admin` role

**Query Parameters**:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `date_from` | string (ISO 8601) | No | Start date (default: 30 days ago) |
| `date_to` | string (ISO 8601) | No | End date (default: today) |
| `role` | string | No | Filter by role (`referrer`, `provider`) |

**Request Example**:
```http
GET /commissions/summary?date_from=2026-03-01&date_to=2026-03-31&role=referrer
Authorization: Bearer <jwt_token>
```

**Response Example** (200 OK):
```json
{
  "data": {
    "total_earned": 8250.00,
    "total_pending": 1200.00,
    "total_processed": 2500.00,
    "total_paid_out": 4550.00,
    "transaction_count": 85,
    "avg_commission": 97.06,
    "by_transaction_type": {
      "consultation": {
        "total": 5000.00,
        "count": 50,
        "avg": 100.00
      },
      "product_sale": {
        "total": 2250.00,
        "count": 20,
        "avg": 112.50
      },
      "diagnostic_test": {
        "total": 1000.00,
        "count": 15,
        "avg": 66.67
      }
    },
    "by_status": {
      "pending": {
        "total": 1200.00,
        "count": 12
      },
      "processed": {
        "total": 2500.00,
        "count": 28
      },
      "paid_out": {
        "total": 4550.00,
        "count": 45
      }
    },
    "daily_trend": [
      {
        "date": "2026-03-01",
        "total_earned": 250.00,
        "count": 3
      },
      {
        "date": "2026-03-02",
        "total_earned": 400.00,
        "count": 5
      }
    ]
  },
  "meta": {
    "date_range": {
      "from": "2026-03-01",
      "to": "2026-03-31"
    },
    "timestamp": "2026-03-13T10:30:00Z"
  }
}
```

---

### 5. GET /commissions/export

**Purpose**: Export commissions to CSV for accounting/reconciliation

**Authorization**: Requires `tenant_admin` role

**Query Parameters**:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `format` | string | No | Export format (`csv`, `json`) (default: `csv`) |
| `date_from` | string (ISO 8601) | Yes | Start date |
| `date_to` | string (ISO 8601) | Yes | End date |
| `status` | string | No | Filter by status |

**Request Example**:
```http
GET /commissions/export?format=csv&date_from=2026-03-01&date_to=2026-03-31&status=paid_out
Authorization: Bearer <jwt_token>
```

**Response Example** (200 OK):
```http
Content-Type: text/csv
Content-Disposition: attachment; filename="commissions_2026-03-01_2026-03-31.csv"

id,transaction_id,transaction_type,provider_tenant,referrer_tenant,customer_id,base_amount,customer_paid,provider_amount,referrer_amount,platform_amount,status,created_at,processed_at,paid_at
550e8400-e29b-41d4-a716-446655440000,660e8400-e29b-41d4-a716-446655440000,consultation,Dr. Kome Medical Practice,Fokz Pharmacy,990e8400-e29b-41d4-a716-446655440000,1000.00,1100.00,900.00,100.00,100.00,paid_out,2026-03-15T14:30:00Z,2026-03-15T14:30:05Z,2026-03-20T09:00:00Z
```

---

### 6. POST /commissions/:id/dispute

**Purpose**: Report a commission calculation discrepancy

**Authorization**: Requires `tenant_admin` role

**Path Parameters**:
| Parameter | Type | Description |
|-----------|------|-------------|
| `id` | UUID | Commission ID |

**Request Body**:
```json
{
  "reason": "Incorrect commission calculation",
  "expected_amount": 150.00,
  "actual_amount": 100.00,
  "notes": "Should be 15% commission, not 10%"
}
```

**Request Example**:
```http
POST /commissions/550e8400-e29b-41d4-a716-446655440000/dispute
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
  "reason": "Incorrect commission calculation",
  "expected_amount": 150.00,
  "actual_amount": 100.00,
  "notes": "Should be 15% commission, not 10%"
}
```

**Response Example** (201 Created):
```json
{
  "data": {
    "dispute_id": "aa0e8400-e29b-41d4-a716-446655440000",
    "commission_id": "550e8400-e29b-41d4-a716-446655440000",
    "status": "open",
    "reason": "Incorrect commission calculation",
    "expected_amount": 150.00,
    "actual_amount": 100.00,
    "notes": "Should be 15% commission, not 10%",
    "created_at": "2026-03-13T10:30:00Z"
  },
  "meta": {
    "timestamp": "2026-03-13T10:30:00Z"
  }
}
```

---

## Error Codes

| Code | HTTP Status | Description |
|------|-------------|-------------|
| `COMMISSION_NOT_FOUND` | 404 | Commission record not found |
| `UNAUTHORIZED_ACCESS` | 403 | Tenant not authorized to view this commission |
| `INVALID_TRANSACTION_TYPE` | 400 | Transaction type must be consultation, product_sale, or diagnostic_test |
| `INVALID_BASE_PRICE` | 400 | Base price must be positive number |
| `CALCULATION_ERROR` | 500 | Error calculating commission (contact support) |
| `EXPORT_TOO_LARGE` | 400 | Date range too large for export (max 12 months) |

---

## Database Functions Used

- `calculate_service_commission(base_price, has_referrer)` → Returns commission breakdown
- `calculate_product_commission(product_price, has_referrer)` → Returns commission breakdown
- `get_commission_summary(tenant_id, date_from, date_to)` → Returns aggregated stats
