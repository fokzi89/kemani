# Error Handling Usage Examples

This document shows how to use the error handling utilities in different scenarios.

---

## Table of Contents

1. [API Routes](#api-routes)
2. [Server Actions](#server-actions)
3. [Client Components](#client-components)
4. [Error Boundary](#error-boundary)
5. [Async Operations](#async-operations)

---

## API Routes

### Basic API Route with Error Handling

```typescript
// app/api/products/route.ts
import { NextRequest } from 'next/server';
import {
  asyncHandler,
  successResponse,
  parseBody,
  parsePagination,
  paginatedResponse,
} from '@/lib/utils/api-error-handler';
import { NotFoundError, ValidationError } from '@/lib/utils/errors';
import { createProductSchema } from '@/lib/validation/schemas';

// GET /api/products - List products with pagination
export const GET = asyncHandler(async (request: NextRequest) => {
  const query = parseQuery(request);
  const pagination = parsePagination(query, 10, 100);

  // Fetch products from database
  const { data, total } = await fetchProducts(pagination);

  return paginatedResponse(data, pagination, total);
});

// POST /api/products - Create product
export const POST = asyncHandler(async (request: NextRequest) => {
  // Parse and validate request body
  const body = await parseBody(request);
  const validation = createProductSchema.safeParse(body);

  if (!validation.success) {
    throw new ValidationError('Invalid product data', {
      errors: validation.error.errors,
    });
  }

  // Create product
  const product = await createProduct(validation.data);

  return createdResponse(product, 'Product created successfully');
});
```

### API Route with Path Parameters

```typescript
// app/api/products/[id]/route.ts
import { asyncHandler, successResponse, noContentResponse } from '@/lib/utils/api-error-handler';
import { NotFoundError, ForbiddenError } from '@/lib/utils/errors';

// GET /api/products/:id
export const GET = asyncHandler(async (request: NextRequest, { params }: any) => {
  const { id } = params;

  const product = await findProductById(id);

  if (!product) {
    throw new NotFoundError('Product', id);
  }

  return successResponse(product);
});

// DELETE /api/products/:id
export const DELETE = asyncHandler(async (request: NextRequest, { params }: any) => {
  const { id } = params;

  // Check permissions
  const canDelete = await checkPermission(request, 'delete:products');
  if (!canDelete) {
    throw new ForbiddenError('You cannot delete products');
  }

  await deleteProduct(id);

  return noContentResponse();
});
```

### API Route with Custom Error Handling

```typescript
// app/api/sales/route.ts
import { asyncHandler, successResponse } from '@/lib/utils/api-error-handler';
import {
  InsufficientStockError,
  PaymentError,
  OperationNotAllowedError,
} from '@/lib/utils/errors';

export const POST = asyncHandler(async (request: NextRequest) => {
  const body = await parseBody(request);

  // Check stock availability
  for (const item of body.items) {
    const product = await findProduct(item.product_id);

    if (product.quantity < item.quantity) {
      throw new InsufficientStockError(product.name, item.quantity, product.quantity);
    }
  }

  // Process payment
  const payment = await processPayment(body.payment);

  if (!payment.success) {
    throw new PaymentError(payment.error_message, {
      reference: payment.reference,
      provider: payment.provider,
    });
  }

  // Create sale
  const sale = await createSale(body, payment);

  return createdResponse(sale, 'Sale completed successfully');
});
```

---

## Server Actions

### Using Errors in Server Actions

```typescript
// app/actions/products.ts
'use server';

import { revalidatePath } from 'next/cache';
import { NotFoundError, DatabaseError } from '@/lib/utils/errors';
import { tryCatch } from '@/lib/utils/errors';

export async function updateProduct(id: string, data: any) {
  // Use tryCatch helper for safe execution
  const [result, error] = await tryCatch(async () => {
    const product = await db.product.findUnique({ where: { id } });

    if (!product) {
      throw new NotFoundError('Product', id);
    }

    const updated = await db.product.update({
      where: { id },
      data,
    });

    revalidatePath('/products');
    return updated;
  });

  if (error) {
    // Return error to client
    return {
      success: false,
      error: {
        message: error.message,
        code: error instanceof AppError ? error.code : ErrorCode.INTERNAL_ERROR,
      },
    };
  }

  return { success: true, data: result };
}
```

### Server Action with Retry

```typescript
// app/actions/sms.ts
'use server';

import { retry, SMSDeliveryError } from '@/lib/utils/errors';

export async function sendOTP(phone: string) {
  try {
    // Retry up to 3 times with exponential backoff
    const result = await retry(
      async () => {
        const response = await fetch('https://api.termii.com/api/sms/otp/send', {
          method: 'POST',
          body: JSON.stringify({ phone }),
        });

        if (!response.ok) {
          throw new SMSDeliveryError('Failed to send OTP');
        }

        return response.json();
      },
      {
        maxAttempts: 3,
        delay: 1000,
        backoff: 2,
        onRetry: (attempt, error) => {
          console.log(`Retry attempt ${attempt}:`, error.message);
        },
      }
    );

    return { success: true, data: result };
  } catch (error) {
    return {
      success: false,
      error: {
        message: 'Could not send OTP. Please try again.',
      },
    };
  }
}
```

---

## Client Components

### Using Error Handler Hook

```typescript
'use client';

import { useState } from 'react';
import { useErrorHandler } from '@/components/error-boundary';
import { NotFoundError } from '@/lib/utils/errors';

export function ProductPage({ id }: { id: string }) {
  const [product, setProduct] = useState(null);
  const handleError = useErrorHandler();

  async function fetchProduct() {
    try {
      const response = await fetch(`/api/products/${id}`);
      const data = await response.json();

      if (!data.success) {
        // Throw error to be caught by error boundary
        handleError(new NotFoundError('Product', id));
        return;
      }

      setProduct(data.data);
    } catch (error) {
      handleError(error as Error);
    }
  }

  return <div>{/* Product UI */}</div>;
}
```

### Custom Error Display

```typescript
'use client';

import { useState } from 'react';
import { getUserFriendlyMessage, isAuthError } from '@/lib/utils/errors';

export function LoginForm() {
  const [error, setError] = useState<Error | null>(null);

  async function handleSubmit(formData: FormData) {
    try {
      const response = await fetch('/api/auth/login', {
        method: 'POST',
        body: JSON.stringify({
          phone: formData.get('phone'),
          otp: formData.get('otp'),
        }),
      });

      const data = await response.json();

      if (!data.success) {
        // Create error from response
        const error = new Error(data.error.message);
        setError(error);
        return;
      }

      // Success - redirect
      window.location.href = '/dashboard';
    } catch (error) {
      setError(error as Error);
    }
  }

  return (
    <form action={handleSubmit}>
      {error && (
        <div className="error-banner">
          <p>{getUserFriendlyMessage(error)}</p>
          {isAuthError(error) && (
            <button onClick={() => window.location.href = '/auth/signin'}>
              Sign in again
            </button>
          )}
        </div>
      )}

      {/* Form fields */}
    </form>
  );
}
```

---

## Error Boundary

### Wrapping App with Error Boundary

```typescript
// app/layout.tsx
import { ErrorBoundary } from '@/components/error-boundary';

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>
        <ErrorBoundary
          fallback={(error, reset) => (
            <div className="error-page">
              <h1>Application Error</h1>
              <p>{error.message}</p>
              <button onClick={reset}>Try Again</button>
            </div>
          )}
          onError={(error, errorInfo) => {
            // Send to error logging service
            console.error('App error:', error, errorInfo);
          }}
        >
          {children}
        </ErrorBoundary>
      </body>
    </html>
  );
}
```

### Per-Page Error Boundary

```typescript
// app/dashboard/page.tsx
import { ErrorBoundary } from '@/components/error-boundary';

export default function DashboardPage() {
  return (
    <ErrorBoundary>
      <DashboardContent />
    </ErrorBoundary>
  );
}
```

### HOC for Component Error Boundary

```typescript
import { withErrorBoundary } from '@/components/error-boundary';

function ProductList() {
  // Component that might throw errors
  return <div>{/* Product list */}</div>;
}

// Wrap with error boundary
export default withErrorBoundary(ProductList, (error, reset) => (
  <div>
    <p>Failed to load products</p>
    <button onClick={reset}>Retry</button>
  </div>
));
```

---

## Async Operations

### Safe Async Execution

```typescript
import { tryCatch } from '@/lib/utils/errors';

async function saveData() {
  const [result, error] = await tryCatch(async () => {
    const response = await fetch('/api/data', { method: 'POST' });
    return response.json();
  });

  if (error) {
    console.error('Failed to save:', error);
    return null;
  }

  return result;
}
```

### Retry with Exponential Backoff

```typescript
import { retry } from '@/lib/utils/errors';

async function fetchWithRetry() {
  return retry(
    async () => {
      const response = await fetch('/api/unstable-endpoint');

      if (!response.ok) {
        throw new Error('Request failed');
      }

      return response.json();
    },
    {
      maxAttempts: 5,
      delay: 1000,
      backoff: 2,
      onRetry: (attempt, error) => {
        console.log(`Retry ${attempt}/5:`, error.message);
      },
    }
  );
}
```

---

## Best Practices

1. **Always use specific error types**
   ```typescript
   // Good
   throw new NotFoundError('Product', id);

   // Bad
   throw new Error('Product not found');
   ```

2. **Include context in errors**
   ```typescript
   throw new InsufficientStockError(product.name, requested, available);
   ```

3. **Use asyncHandler for all API routes**
   ```typescript
   export const GET = asyncHandler(async (request) => {
     // Your code here
   });
   ```

4. **Validate input before processing**
   ```typescript
   const validation = schema.safeParse(data);
   if (!validation.success) {
     throw new ValidationError('Invalid data', { errors: validation.error });
   }
   ```

5. **Return user-friendly messages**
   ```typescript
   const message = getUserFriendlyMessage(error);
   ```

6. **Log errors appropriately**
   ```typescript
   if (!isOperationalError(error)) {
     console.error('Unexpected error:', error);
     // Send to error tracking service
   }
   ```

---

## Error Codes Reference

| Code Range | Category | Examples |
|------------|----------|----------|
| 1xxx | Auth & Authorization | UNAUTHORIZED, INVALID_OTP |
| 2xxx | Validation | VALIDATION_ERROR, INVALID_INPUT |
| 3xxx | Business Logic | RESOURCE_NOT_FOUND, INSUFFICIENT_STOCK |
| 4xxx | Database | DATABASE_ERROR, QUERY_FAILED |
| 5xxx | External Services | PAYMENT_FAILED, SMS_DELIVERY_FAILED |
| 6xxx | System | INTERNAL_ERROR, RATE_LIMIT_EXCEEDED |
| 7xxx | Tenant & Subscription | SUBSCRIPTION_EXPIRED, QUOTA_EXCEEDED |

---

## Next Steps

- Integrate with error logging service (Sentry, LogRocket)
- Add error metrics and monitoring
- Create custom error pages
- Implement error recovery strategies
- Add error analytics dashboard
