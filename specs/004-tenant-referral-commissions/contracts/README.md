# API Contracts: Multi-Tenant Referral Commission System

**Feature**: Multi-Tenant Referral Commission System
**Branch**: `004-tenant-referral-commissions`
**Created**: 2026-03-13

## Overview

This directory contains API contract specifications for the referral commission system. All endpoints use RESTful conventions and return JSON responses. Authentication is handled via Supabase Auth with JWT tokens containing `tenant_id` and `role` claims.

## Endpoint Categories

### 1. Referral Session Management
- **File**: `referral-session-api.md`
- **Purpose**: Track customer browsing sessions and referring tenants
- **Endpoints**: 4 endpoints (create, get, update, expire)

### 2. Commission Management
- **File**: `commission-api.md`
- **Purpose**: Query commission earnings, calculate commissions, track payouts
- **Endpoints**: 6 endpoints (list, get, calculate, summary, export)

### 3. Fulfillment Routing
- **File**: `fulfillment-routing-api.md`
- **Purpose**: Auto-route prescriptions/tests, get fulfillment status
- **Endpoints**: 3 endpoints (route, status, history)

## Authentication

All endpoints require authentication via Supabase Auth. Include JWT token in Authorization header:

```http
Authorization: Bearer <jwt_token>
```

JWT claims used for authorization:
- `tenant_id`: UUID of the tenant making the request
- `role`: User role (`customer`, `tenant_admin`, `platform_admin`)

## Base URL

**Production**: `https://your-project.supabase.co/rest/v1/`
**Local Development**: `http://localhost:54321/rest/v1/`

## Response Format

### Success Response
```json
{
  "data": { /* response payload */ },
  "meta": {
    "timestamp": "2026-03-13T10:30:00Z",
    "request_id": "uuid"
  }
}
```

### Error Response
```json
{
  "error": {
    "code": "COMMISSION_CALCULATION_ERROR",
    "message": "Human-readable error message",
    "details": { /* optional error details */ }
  },
  "meta": {
    "timestamp": "2026-03-13T10:30:00Z",
    "request_id": "uuid"
  }
}
```

## Common HTTP Status Codes

- `200 OK`: Successful request
- `201 Created`: Resource created successfully
- `400 Bad Request`: Invalid request parameters
- `401 Unauthorized`: Missing or invalid authentication token
- `403 Forbidden`: Authenticated but not authorized for this resource
- `404 Not Found`: Resource not found
- `409 Conflict`: Resource conflict (e.g., duplicate session)
- `429 Too Many Requests`: Rate limit exceeded
- `500 Internal Server Error`: Server-side error

## Rate Limiting

- **Commission queries**: 100 requests/minute per tenant
- **Session creation**: 1000 requests/minute (high volume for browsing)
- **Calculation endpoints**: 50 requests/minute (more expensive operations)

Rate limit headers included in responses:
```http
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1678705800
```

## Pagination

List endpoints support pagination via query parameters:

```http
GET /commissions?page=2&per_page=50
```

Response includes pagination metadata:
```json
{
  "data": [...],
  "meta": {
    "page": 2,
    "per_page": 50,
    "total": 500,
    "total_pages": 10
  }
}
```

## Filtering and Sorting

List endpoints support filtering and sorting:

**Filtering**:
```http
GET /commissions?status=paid_out&transaction_type=consultation&date_from=2026-03-01&date_to=2026-03-31
```

**Sorting**:
```http
GET /commissions?sort_by=created_at&sort_order=desc
```

## Webhook Events

Certain actions trigger webhook events (if configured):

- `commission.calculated`: New commission record created
- `commission.paid_out`: Commission payment distributed
- `fulfillment.routed`: Prescription/test auto-routed to referrer

Webhook payload format:
```json
{
  "event": "commission.calculated",
  "data": { /* event-specific payload */ },
  "timestamp": "2026-03-13T10:30:00Z",
  "tenant_id": "uuid"
}
```

## Next Steps

Refer to individual contract files for detailed endpoint specifications:
- `referral-session-api.md` - Session tracking
- `commission-api.md` - Commission management
- `fulfillment-routing-api.md` - Prescription/test routing
