# Logger Usage Examples

This document shows how to use the logging infrastructure in different scenarios.

---

## Table of Contents

1. [Basic Logging](#basic-logging)
2. [Contextual Logging](#contextual-logging)
3. [API Route Logging](#api-route-logging)
4. [Database Query Logging](#database-query-logging)
5. [Performance Monitoring](#performance-monitoring)
6. [Error Logging](#error-logging)
7. [Business Events](#business-events)

---

## Basic Logging

### Simple Logging

```typescript
import logger from '@/lib/utils/logger';

// Debug log (only in development)
logger.debug('User session started');

// Info log
logger.info('Product created successfully');

// Warning log
logger.warn('Low stock alert');

// Error log
logger.error('Payment processing failed', error);

// Fatal log (critical errors)
logger.fatal('Database connection lost', error);
```

### Logging with Context

```typescript
import logger from '@/lib/utils/logger';

logger.info('Sale completed', {
  saleId: 'sale_123',
  amount: 15000,
  items: 5,
  payment: 'card',
});

logger.error('Product not found', error, {
  productId: 'prod_456',
  requestedBy: 'user_789',
});
```

---

## Contextual Logging

### Component Logger

```typescript
import logger from '@/lib/utils/logger';

// Create logger for specific component
const authLogger = logger.component('Auth');

authLogger.info('OTP sent to user', { phone: '+2348012345678' });
authLogger.warn('Invalid OTP attempt', { attempts: 3 });
authLogger.error('SMS delivery failed', error);
```

### Request Logger

```typescript
import logger from '@/lib/utils/logger';

export async function GET(request: Request) {
  const requestId = crypto.randomUUID();
  const userId = await getCurrentUserId(request);
  const tenantId = await getCurrentTenantId(request);

  // Create logger with request context
  const requestLogger = logger.request(requestId, userId, tenantId);

  requestLogger.info('Fetching products');

  try {
    const products = await fetchProducts();
    requestLogger.info('Products fetched successfully', { count: products.length });
    return successResponse(products);
  } catch (error) {
    requestLogger.error('Failed to fetch products', error as Error);
    return errorResponse(error as Error);
  }
}
```

### Child Logger with Additional Context

```typescript
import logger from '@/lib/utils/logger';

const saleLogger = logger.component('Sales');

async function processSale(saleData: any) {
  // Create child logger for this specific sale
  const log = saleLogger.child({ saleId: saleData.id, amount: saleData.total });

  log.info('Processing sale');

  // Check stock
  log.debug('Checking stock availability');
  const stockCheck = await checkStock(saleData.items);

  if (!stockCheck.available) {
    log.warn('Insufficient stock', { missing: stockCheck.missing });
    throw new InsufficientStockError(/*...*/);
  }

  // Process payment
  log.info('Processing payment');
  const payment = await processPayment(saleData.payment);

  if (!payment.success) {
    log.error('Payment failed', undefined, { reason: payment.error });
    throw new PaymentError(payment.error);
  }

  log.info('Sale completed successfully');
  return payment;
}
```

---

## API Route Logging

### API Request/Response Logging

```typescript
// app/api/products/route.ts
import { NextRequest } from 'next/server';
import { asyncHandler, successResponse } from '@/lib/utils/api-error-handler';
import { logRequest } from '@/lib/utils/logger';
import logger from '@/lib/utils/logger';

export const GET = asyncHandler(async (request: NextRequest) => {
  const start = Date.now();
  const requestLogger = logger.request(crypto.randomUUID());

  try {
    requestLogger.info('GET /api/products');

    const products = await fetchProducts();

    const duration = Date.now() - start;
    logRequest('GET', '/api/products', 200, duration, {
      count: products.length,
    });

    return successResponse(products);
  } catch (error) {
    const duration = Date.now() - start;
    logRequest('GET', '/api/products', 500, duration, {
      error: (error as Error).message,
    });
    throw error;
  }
});
```

### Logging Middleware

```typescript
// middleware.ts
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';
import { logRequest } from '@/lib/utils/logger';

export function middleware(request: NextRequest) {
  const start = Date.now();
  const requestId = crypto.randomUUID();

  // Add request ID to headers
  const requestHeaders = new Headers(request.headers);
  requestHeaders.set('x-request-id', requestId);

  const response = NextResponse.next({
    request: {
      headers: requestHeaders,
    },
  });

  // Log after response
  const duration = Date.now() - start;
  logRequest(
    request.method,
    request.nextUrl.pathname,
    response.status,
    duration,
    { requestId }
  );

  return response;
}
```

---

## Database Query Logging

### Query Performance Logging

```typescript
import { logQuery } from '@/lib/utils/logger';

async function fetchProducts() {
  const start = Date.now();
  const query = 'SELECT * FROM products WHERE is_active = true';

  try {
    const result = await db.query(query);
    const duration = Date.now() - start;

    logQuery(query, duration, result.rowCount);

    return result.rows;
  } catch (error) {
    const duration = Date.now() - start;
    logQuery(query, duration);
    throw error;
  }
}
```

### Slow Query Detection

```typescript
import logger from '@/lib/utils/logger';

async function executeQuery(query: string, params?: any[]) {
  const start = Date.now();

  const result = await db.query(query, params);
  const duration = Date.now() - start;

  // Warn if query takes longer than 1 second
  if (duration > 1000) {
    logger.warn('Slow query detected', {
      query,
      duration: `${duration}ms`,
      rowCount: result.rowCount,
      params,
    });
  } else {
    logger.debug('Query executed', {
      query,
      duration: `${duration}ms`,
      rowCount: result.rowCount,
    });
  }

  return result;
}
```

---

## Performance Monitoring

### Measuring Function Execution Time

```typescript
import { measureTime } from '@/lib/utils/logger';

async function complexOperation() {
  return measureTime('Complex Operation', async () => {
    await step1();
    await step2();
    await step3();
    return result;
  });
}

// Logs:
// "Complex Operation started"
// "Complex Operation completed" { duration: "1234ms" }
```

### Tracking Multiple Operations

```typescript
import logger from '@/lib/utils/logger';

async function processSale(saleData: any) {
  const timings: Record<string, number> = {};

  // Track stock check
  let start = Date.now();
  await checkStock(saleData.items);
  timings.stockCheck = Date.now() - start;

  // Track payment
  start = Date.now();
  await processPayment(saleData.payment);
  timings.payment = Date.now() - start;

  // Track inventory update
  start = Date.now();
  await updateInventory(saleData.items);
  timings.inventory = Date.now() - start;

  // Log all timings
  logger.info('Sale processed', {
    saleId: saleData.id,
    timings,
    total: Object.values(timings).reduce((a, b) => a + b, 0),
  });
}
```

### Custom Metrics

```typescript
import { logMetric } from '@/lib/utils/logger';

// Log response time
logMetric('api.response_time', 450, 'ms', { endpoint: '/api/products' });

// Log memory usage
logMetric('memory.heap_used', process.memoryUsage().heapUsed, 'bytes');

// Log cache hit rate
logMetric('cache.hit_rate', 87.5, '%', { cache: 'redis' });

// Log database pool size
logMetric('db.pool_size', 10, 'connections');
```

---

## Error Logging

### Structured Error Logging

```typescript
import logger from '@/lib/utils/logger';
import { AppError } from '@/lib/utils/errors';

try {
  const result = await riskyOperation();
} catch (error) {
  if (error instanceof AppError) {
    logger.error('Operation failed', error, {
      code: error.code,
      statusCode: error.statusCode,
      isOperational: error.isOperational,
      context: error.context,
    });
  } else {
    logger.error('Unexpected error', error as Error);
  }
}
```

### Error with User Context

```typescript
import logger from '@/lib/utils/logger';

async function processUserAction(userId: string, action: string) {
  const userLogger = logger.child({ userId, action });

  try {
    userLogger.info('Processing user action');
    await performAction(action);
    userLogger.info('Action completed successfully');
  } catch (error) {
    userLogger.error('Action failed', error as Error, {
      timestamp: new Date().toISOString(),
      userAgent: request.headers.get('user-agent'),
    });
    throw error;
  }
}
```

---

## Business Events

### Authentication Events

```typescript
import { logAuth } from '@/lib/utils/logger';

// User login
logAuth('login', userId, {
  method: 'otp',
  phone: user.phone,
  ipAddress: request.ip,
});

// Failed login
logAuth('failed', undefined, {
  phone: '+2348012345678',
  reason: 'invalid_otp',
  attempts: 3,
});

// User registration
logAuth('register', userId, {
  method: 'phone',
  referralCode: data.referral,
});

// Phone verification
logAuth('verify', userId, {
  verificationType: 'phone',
});
```

### Payment Events

```typescript
import { logPayment } from '@/lib/utils/logger';

// Payment initiated
logPayment('initiated', 15000, 'PAY_123', 'paystack', {
  userId,
  saleId,
  channel: 'card',
});

// Payment successful
logPayment('successful', 15000, 'PAY_123', 'paystack', {
  userId,
  saleId,
  transactionId: 'TXN_456',
});

// Payment failed
logPayment('failed', 15000, 'PAY_123', 'paystack', {
  userId,
  saleId,
  error: 'insufficient_funds',
});

// Payment refunded
logPayment('refunded', 15000, 'PAY_123', 'paystack', {
  userId,
  reason: 'customer_request',
});
```

### Custom Business Events

```typescript
import { logEvent } from '@/lib/utils/logger';

// Product created
logEvent('product.created', {
  productId: product.id,
  name: product.name,
  price: product.price,
  createdBy: userId,
});

// Sale completed
logEvent('sale.completed', {
  saleId: sale.id,
  amount: sale.total,
  items: sale.items.length,
  paymentMethod: sale.payment_method,
  branch: sale.branch_id,
});

// Stock alert
logEvent('stock.low', {
  productId: product.id,
  currentStock: product.quantity,
  reorderLevel: product.reorder_level,
});

// Subscription expired
logEvent('subscription.expired', {
  tenantId: tenant.id,
  plan: tenant.subscription_tier,
  expiryDate: tenant.subscription_end,
});
```

---

## Production Configuration

### Setup for Production

```typescript
// app/api/configure-logger/route.ts
import { configureProductionLogger, LogLevel } from '@/lib/utils/logger';

// Call this during app initialization
configureProductionLogger({
  remoteEndpoint: process.env.LOG_ENDPOINT!, // e.g., Logtail, Datadog, etc.
  level: LogLevel.INFO, // Don't log debug messages in production
});
```

### Flush Logs Before Shutdown

```typescript
// Called when app is shutting down
import { flushLogs } from '@/lib/utils/logger';

process.on('SIGTERM', async () => {
  console.log('Flushing logs before shutdown...');
  await flushLogs();
  process.exit(0);
});
```

---

## Environment Variables

```env
# .env.local

# Log level (DEBUG, INFO, WARN, ERROR, FATAL)
LOG_LEVEL=INFO

# Remote logging endpoint (optional)
LOG_ENDPOINT=https://in.logtail.com/...

# Environment
NODE_ENV=production
```

---

## Integration with External Services

### Logtail (BetterStack)

```typescript
import { configureProductionLogger } from '@/lib/utils/logger';

configureProductionLogger({
  remoteEndpoint: `https://in.logtail.com?source=${process.env.LOGTAIL_SOURCE_TOKEN}`,
});
```

### Sentry

```typescript
import * as Sentry from '@sentry/nextjs';
import logger from '@/lib/utils/logger';

// Override logger to also send to Sentry
const originalError = logger.error.bind(logger);
logger.error = (message: string, error?: Error, context?: any) => {
  originalError(message, error, context);

  if (error) {
    Sentry.captureException(error, {
      extra: { message, ...context },
    });
  }
};
```

---

## Best Practices

1. **Use appropriate log levels**
   - DEBUG: Detailed debugging information
   - INFO: General informational messages
   - WARN: Warning messages (something might be wrong)
   - ERROR: Error messages (something is wrong)
   - FATAL: Critical errors (system is unusable)

2. **Include context in logs**
   ```typescript
   logger.info('Sale created', { saleId, tenantId, amount });
   ```

3. **Use contextual loggers for related operations**
   ```typescript
   const requestLogger = logger.request(requestId, userId);
   ```

4. **Don't log sensitive information**
   ```typescript
   // Bad
   logger.info('User logged in', { password: user.password });

   // Good
   logger.info('User logged in', { userId: user.id });
   ```

5. **Log errors with full context**
   ```typescript
   logger.error('Payment failed', error, {
     userId,
     amount,
     reference,
     provider,
   });
   ```

---

## Next Steps

- Set up remote logging service (Logtail, Datadog, etc.)
- Configure log aggregation and analysis
- Set up alerts for critical errors
- Create log dashboards for monitoring
- Implement log rotation (if using file logging)
