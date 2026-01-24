/**
 * Error Handling Utilities
 * Centralized error management for the application
 */

// ============================================
// ERROR TYPES
// ============================================

export enum ErrorCode {
  // Authentication & Authorization (1xxx)
  UNAUTHORIZED = 1001,
  FORBIDDEN = 1002,
  INVALID_TOKEN = 1003,
  TOKEN_EXPIRED = 1004,
  INVALID_OTP = 1005,
  OTP_EXPIRED = 1006,
  PHONE_NOT_VERIFIED = 1007,
  EMAIL_NOT_VERIFIED = 1008,

  // Validation (2xxx)
  VALIDATION_ERROR = 2001,
  INVALID_INPUT = 2002,
  MISSING_REQUIRED_FIELD = 2003,
  INVALID_FORMAT = 2004,
  VALUE_OUT_OF_RANGE = 2005,

  // Business Logic (3xxx)
  RESOURCE_NOT_FOUND = 3001,
  DUPLICATE_RESOURCE = 3002,
  INSUFFICIENT_STOCK = 3003,
  INSUFFICIENT_FUNDS = 3004,
  OPERATION_NOT_ALLOWED = 3005,
  SALE_ALREADY_VOIDED = 3006,
  PRODUCT_INACTIVE = 3007,
  BRANCH_INACTIVE = 3008,

  // Database (4xxx)
  DATABASE_ERROR = 4001,
  QUERY_FAILED = 4002,
  CONNECTION_FAILED = 4003,
  TRANSACTION_FAILED = 4004,
  CONSTRAINT_VIOLATION = 4005,

  // External Services (5xxx)
  PAYMENT_FAILED = 5001,
  SMS_DELIVERY_FAILED = 5002,
  EXTERNAL_API_ERROR = 5003,
  NETWORK_ERROR = 5004,

  // System (6xxx)
  INTERNAL_ERROR = 6001,
  NOT_IMPLEMENTED = 6002,
  SERVICE_UNAVAILABLE = 6003,
  RATE_LIMIT_EXCEEDED = 6004,

  // Tenant & Subscription (7xxx)
  TENANT_NOT_FOUND = 7001,
  SUBSCRIPTION_EXPIRED = 7002,
  FEATURE_NOT_AVAILABLE = 7003,
  QUOTA_EXCEEDED = 7004,
}

// ============================================
// CUSTOM ERROR CLASSES
// ============================================

export class AppError extends Error {
  public readonly code: ErrorCode;
  public readonly statusCode: number;
  public readonly isOperational: boolean;
  public readonly context?: Record<string, any>;
  public readonly timestamp: Date;

  constructor(
    message: string,
    code: ErrorCode,
    statusCode: number = 500,
    isOperational: boolean = true,
    context?: Record<string, any>
  ) {
    super(message);
    this.name = this.constructor.name;
    this.code = code;
    this.statusCode = statusCode;
    this.isOperational = isOperational;
    this.context = context;
    this.timestamp = new Date();

    // Maintains proper stack trace for where error was thrown (V8 only)
    Error.captureStackTrace(this, this.constructor);
  }

  toJSON() {
    return {
      name: this.name,
      message: this.message,
      code: this.code,
      statusCode: this.statusCode,
      context: this.context,
      timestamp: this.timestamp.toISOString(),
    };
  }
}

// Authentication Errors
export class UnauthorizedError extends AppError {
  constructor(message: string = 'Unauthorized access', context?: Record<string, any>) {
    super(message, ErrorCode.UNAUTHORIZED, 401, true, context);
  }
}

export class ForbiddenError extends AppError {
  constructor(message: string = 'Access forbidden', context?: Record<string, any>) {
    super(message, ErrorCode.FORBIDDEN, 403, true, context);
  }
}

export class InvalidTokenError extends AppError {
  constructor(message: string = 'Invalid authentication token', context?: Record<string, any>) {
    super(message, ErrorCode.INVALID_TOKEN, 401, true, context);
  }
}

export class TokenExpiredError extends AppError {
  constructor(message: string = 'Authentication token has expired', context?: Record<string, any>) {
    super(message, ErrorCode.TOKEN_EXPIRED, 401, true, context);
  }
}

export class InvalidOTPError extends AppError {
  constructor(message: string = 'Invalid OTP code', context?: Record<string, any>) {
    super(message, ErrorCode.INVALID_OTP, 400, true, context);
  }
}

// Validation Errors
export class ValidationError extends AppError {
  constructor(message: string = 'Validation failed', context?: Record<string, any>) {
    super(message, ErrorCode.VALIDATION_ERROR, 400, true, context);
  }
}

export class InvalidInputError extends AppError {
  constructor(message: string = 'Invalid input provided', context?: Record<string, any>) {
    super(message, ErrorCode.INVALID_INPUT, 400, true, context);
  }
}

export class MissingFieldError extends AppError {
  constructor(field: string, context?: Record<string, any>) {
    super(`Required field missing: ${field}`, ErrorCode.MISSING_REQUIRED_FIELD, 400, true, {
      field,
      ...context,
    });
  }
}

// Business Logic Errors
export class NotFoundError extends AppError {
  constructor(resource: string, id?: string, context?: Record<string, any>) {
    super(
      `${resource} not found${id ? `: ${id}` : ''}`,
      ErrorCode.RESOURCE_NOT_FOUND,
      404,
      true,
      { resource, id, ...context }
    );
  }
}

export class DuplicateResourceError extends AppError {
  constructor(resource: string, field: string, value: string, context?: Record<string, any>) {
    super(
      `${resource} with ${field} "${value}" already exists`,
      ErrorCode.DUPLICATE_RESOURCE,
      409,
      true,
      { resource, field, value, ...context }
    );
  }
}

export class InsufficientStockError extends AppError {
  constructor(productName: string, requested: number, available: number) {
    super(
      `Insufficient stock for ${productName}. Requested: ${requested}, Available: ${available}`,
      ErrorCode.INSUFFICIENT_STOCK,
      400,
      true,
      { productName, requested, available }
    );
  }
}

export class OperationNotAllowedError extends AppError {
  constructor(operation: string, reason: string, context?: Record<string, any>) {
    super(
      `Operation "${operation}" not allowed: ${reason}`,
      ErrorCode.OPERATION_NOT_ALLOWED,
      403,
      true,
      { operation, reason, ...context }
    );
  }
}

// Database Errors
export class DatabaseError extends AppError {
  constructor(message: string = 'Database operation failed', context?: Record<string, any>) {
    super(message, ErrorCode.DATABASE_ERROR, 500, false, context);
  }
}

export class QueryError extends AppError {
  constructor(message: string = 'Database query failed', context?: Record<string, any>) {
    super(message, ErrorCode.QUERY_FAILED, 500, false, context);
  }
}

// External Service Errors
export class PaymentError extends AppError {
  constructor(message: string = 'Payment processing failed', context?: Record<string, any>) {
    super(message, ErrorCode.PAYMENT_FAILED, 402, true, context);
  }
}

export class SMSDeliveryError extends AppError {
  constructor(message: string = 'SMS delivery failed', context?: Record<string, any>) {
    super(message, ErrorCode.SMS_DELIVERY_FAILED, 500, true, context);
  }
}

export class ExternalAPIError extends AppError {
  constructor(service: string, message: string, context?: Record<string, any>) {
    super(`${service} API error: ${message}`, ErrorCode.EXTERNAL_API_ERROR, 502, true, {
      service,
      ...context,
    });
  }
}

// System Errors
export class InternalError extends AppError {
  constructor(message: string = 'Internal server error', context?: Record<string, any>) {
    super(message, ErrorCode.INTERNAL_ERROR, 500, false, context);
  }
}

export class NotImplementedError extends AppError {
  constructor(feature: string = 'This feature', context?: Record<string, any>) {
    super(`${feature} is not yet implemented`, ErrorCode.NOT_IMPLEMENTED, 501, true, {
      feature,
      ...context,
    });
  }
}

export class RateLimitError extends AppError {
  constructor(retryAfter: number, context?: Record<string, any>) {
    super(
      `Rate limit exceeded. Retry after ${retryAfter} seconds`,
      ErrorCode.RATE_LIMIT_EXCEEDED,
      429,
      true,
      { retryAfter, ...context }
    );
  }
}

// Tenant & Subscription Errors
export class TenantNotFoundError extends AppError {
  constructor(tenantId: string, context?: Record<string, any>) {
    super(`Tenant not found: ${tenantId}`, ErrorCode.TENANT_NOT_FOUND, 404, true, {
      tenantId,
      ...context,
    });
  }
}

export class SubscriptionExpiredError extends AppError {
  constructor(message: string = 'Subscription has expired', context?: Record<string, any>) {
    super(message, ErrorCode.SUBSCRIPTION_EXPIRED, 402, true, context);
  }
}

export class FeatureNotAvailableError extends AppError {
  constructor(feature: string, plan: string, context?: Record<string, any>) {
    super(
      `Feature "${feature}" is not available on ${plan} plan`,
      ErrorCode.FEATURE_NOT_AVAILABLE,
      403,
      true,
      { feature, plan, ...context }
    );
  }
}

export class QuotaExceededError extends AppError {
  constructor(resource: string, limit: number, context?: Record<string, any>) {
    super(
      `Quota exceeded for ${resource}. Limit: ${limit}`,
      ErrorCode.QUOTA_EXCEEDED,
      429,
      true,
      { resource, limit, ...context }
    );
  }
}

// ============================================
// ERROR RESPONSE BUILDERS
// ============================================

export interface ErrorResponse {
  success: false;
  error: {
    message: string;
    code: ErrorCode;
    details?: Record<string, any>;
    timestamp: string;
  };
}

/**
 * Format error for API response
 */
export function formatErrorResponse(error: AppError | Error): ErrorResponse {
  if (error instanceof AppError) {
    return {
      success: false,
      error: {
        message: error.message,
        code: error.code,
        details: error.context,
        timestamp: error.timestamp.toISOString(),
      },
    };
  }

  // Generic error
  return {
    success: false,
    error: {
      message: error.message || 'An unexpected error occurred',
      code: ErrorCode.INTERNAL_ERROR,
      timestamp: new Date().toISOString(),
    },
  };
}

/**
 * Create user-friendly error message
 */
export function getUserFriendlyMessage(error: AppError | Error): string {
  if (error instanceof AppError) {
    // Map technical errors to user-friendly messages
    switch (error.code) {
      case ErrorCode.UNAUTHORIZED:
        return 'Please sign in to continue';
      case ErrorCode.FORBIDDEN:
        return "You don't have permission to perform this action";
      case ErrorCode.INVALID_TOKEN:
      case ErrorCode.TOKEN_EXPIRED:
        return 'Your session has expired. Please sign in again';
      case ErrorCode.INVALID_OTP:
        return 'Invalid verification code. Please try again';
      case ErrorCode.OTP_EXPIRED:
        return 'Verification code has expired. Request a new one';
      case ErrorCode.VALIDATION_ERROR:
      case ErrorCode.INVALID_INPUT:
        return 'Please check your input and try again';
      case ErrorCode.RESOURCE_NOT_FOUND:
        return 'The requested item could not be found';
      case ErrorCode.DUPLICATE_RESOURCE:
        return 'This item already exists';
      case ErrorCode.INSUFFICIENT_STOCK:
        return 'Not enough items in stock';
      case ErrorCode.PAYMENT_FAILED:
        return 'Payment processing failed. Please try again';
      case ErrorCode.SMS_DELIVERY_FAILED:
        return 'Could not send SMS. Please check your phone number';
      case ErrorCode.DATABASE_ERROR:
      case ErrorCode.INTERNAL_ERROR:
        return 'Something went wrong. Please try again later';
      case ErrorCode.RATE_LIMIT_EXCEEDED:
        return 'Too many requests. Please slow down';
      case ErrorCode.SUBSCRIPTION_EXPIRED:
        return 'Your subscription has expired. Please renew to continue';
      case ErrorCode.FEATURE_NOT_AVAILABLE:
        return 'This feature is not available on your current plan';
      case ErrorCode.QUOTA_EXCEEDED:
        return 'You have reached your usage limit';
      default:
        return error.message;
    }
  }

  return 'An unexpected error occurred. Please try again';
}

// ============================================
// ERROR GUARDS
// ============================================

/**
 * Check if error is operational (expected) or programming error
 */
export function isOperationalError(error: Error): boolean {
  if (error instanceof AppError) {
    return error.isOperational;
  }
  return false;
}

/**
 * Check if error is a specific type
 */
export function isErrorCode(error: Error, code: ErrorCode): boolean {
  return error instanceof AppError && error.code === code;
}

/**
 * Check if error is authentication related
 */
export function isAuthError(error: Error): boolean {
  if (!(error instanceof AppError)) return false;
  return [
    ErrorCode.UNAUTHORIZED,
    ErrorCode.FORBIDDEN,
    ErrorCode.INVALID_TOKEN,
    ErrorCode.TOKEN_EXPIRED,
    ErrorCode.INVALID_OTP,
    ErrorCode.OTP_EXPIRED,
  ].includes(error.code);
}

/**
 * Check if error is validation related
 */
export function isValidationError(error: Error): boolean {
  if (!(error instanceof AppError)) return false;
  return [
    ErrorCode.VALIDATION_ERROR,
    ErrorCode.INVALID_INPUT,
    ErrorCode.MISSING_REQUIRED_FIELD,
    ErrorCode.INVALID_FORMAT,
  ].includes(error.code);
}

// ============================================
// SAFE ERROR EXECUTION
// ============================================

/**
 * Safely execute async function with error handling
 */
export async function tryCatch<T>(
  fn: () => Promise<T>,
  errorHandler?: (error: Error) => void
): Promise<[T | null, Error | null]> {
  try {
    const result = await fn();
    return [result, null];
  } catch (error) {
    const err = error instanceof Error ? error : new Error(String(error));
    if (errorHandler) {
      errorHandler(err);
    }
    return [null, err];
  }
}

/**
 * Retry async function with exponential backoff
 */
export async function retry<T>(
  fn: () => Promise<T>,
  options: {
    maxAttempts?: number;
    delay?: number;
    backoff?: number;
    onRetry?: (attempt: number, error: Error) => void;
  } = {}
): Promise<T> {
  const { maxAttempts = 3, delay = 1000, backoff = 2, onRetry } = options;

  let lastError: Error;

  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      return await fn();
    } catch (error) {
      lastError = error instanceof Error ? error : new Error(String(error));

      if (attempt === maxAttempts) {
        throw lastError;
      }

      if (onRetry) {
        onRetry(attempt, lastError);
      }

      const waitTime = delay * Math.pow(backoff, attempt - 1);
      await new Promise((resolve) => setTimeout(resolve, waitTime));
    }
  }

  throw lastError!;
}

// ============================================
// EXPORT ALL
// ============================================

export default {
  // Error classes
  AppError,
  UnauthorizedError,
  ForbiddenError,
  InvalidTokenError,
  TokenExpiredError,
  InvalidOTPError,
  ValidationError,
  InvalidInputError,
  MissingFieldError,
  NotFoundError,
  DuplicateResourceError,
  InsufficientStockError,
  OperationNotAllowedError,
  DatabaseError,
  QueryError,
  PaymentError,
  SMSDeliveryError,
  ExternalAPIError,
  InternalError,
  NotImplementedError,
  RateLimitError,
  TenantNotFoundError,
  SubscriptionExpiredError,
  FeatureNotAvailableError,
  QuotaExceededError,

  // Utilities
  formatErrorResponse,
  getUserFriendlyMessage,
  isOperationalError,
  isErrorCode,
  isAuthError,
  isValidationError,
  tryCatch,
  retry,

  // Enums
  ErrorCode,
};
