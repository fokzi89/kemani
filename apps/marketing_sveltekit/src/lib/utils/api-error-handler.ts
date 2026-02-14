/**
 * API Error Handler
 * Utilities for handling errors in Next.js API routes
 */

import { NextResponse } from 'next/server';
import { ZodError } from 'zod';
import {
  AppError,
  ErrorCode,
  ValidationError,
  formatErrorResponse,
  InternalError,
} from './errors';

// ============================================
// TYPES
// ============================================

export interface ApiSuccessResponse<T = any> {
  success: true;
  data: T;
  message?: string;
  meta?: Record<string, any>;
}

export interface ApiErrorResponse {
  success: false;
  error: {
    message: string;
    code: ErrorCode;
    details?: Record<string, any>;
    timestamp: string;
  };
}

export type ApiResponse<T = any> = ApiSuccessResponse<T> | ApiErrorResponse;

// ============================================
// SUCCESS RESPONSES
// ============================================

/**
 * Create success response
 */
export function successResponse<T>(
  data: T,
  message?: string,
  meta?: Record<string, any>
): NextResponse<ApiSuccessResponse<T>> {
  return NextResponse.json(
    {
      success: true,
      data,
      message,
      meta,
    },
    { status: 200 }
  );
}

/**
 * Create created response (201)
 */
export function createdResponse<T>(
  data: T,
  message: string = 'Resource created successfully'
): NextResponse<ApiSuccessResponse<T>> {
  return NextResponse.json(
    {
      success: true,
      data,
      message,
    },
    { status: 201 }
  );
}

/**
 * Create no content response (204)
 */
export function noContentResponse(): NextResponse {
  return new NextResponse(null, { status: 204 });
}

// ============================================
// ERROR RESPONSES
// ============================================

/**
 * Handle and format error response
 */
export function errorResponse(error: Error | AppError | ZodError): NextResponse<ApiErrorResponse> {
  // Handle Zod validation errors
  if (error instanceof ZodError) {
    const validationError = new ValidationError('Validation failed', {
      errors: error.errors.map((err) => ({
        path: err.path.join('.'),
        message: err.message,
        code: err.code,
      })),
    });
    return NextResponse.json(formatErrorResponse(validationError), {
      status: validationError.statusCode,
    });
  }

  // Handle AppError instances
  if (error instanceof AppError) {
    return NextResponse.json(formatErrorResponse(error), {
      status: error.statusCode,
    });
  }

  // Handle unknown errors
  console.error('Unhandled error:', error);
  const internalError = new InternalError('An unexpected error occurred');
  return NextResponse.json(formatErrorResponse(internalError), {
    status: internalError.statusCode,
  });
}

// ============================================
// ASYNC HANDLER WRAPPER
// ============================================

/**
 * Wrap async API route handler with error handling
 *
 * @example
 * export const GET = asyncHandler(async (request) => {
 *   const data = await fetchData();
 *   return successResponse(data);
 * });
 */
export function asyncHandler<T = any>(
  handler: (request: Request, context?: any) => Promise<NextResponse<T>>
) {
  return async (request: Request, context?: any): Promise<NextResponse> => {
    try {
      return await handler(request, context);
    } catch (error) {
      if (error instanceof Error || error instanceof AppError || error instanceof ZodError) {
        return errorResponse(error);
      }
      return errorResponse(new InternalError(String(error)));
    }
  };
}

// ============================================
// VALIDATION HELPERS
// ============================================

/**
 * Parse and validate request body
 */
export async function parseBody<T>(request: Request): Promise<T> {
  try {
    const contentType = request.headers.get('content-type');

    if (!contentType?.includes('application/json')) {
      throw new ValidationError('Content-Type must be application/json');
    }

    const body = await request.json();
    return body as T;
  } catch (error) {
    if (error instanceof ValidationError) {
      throw error;
    }
    throw new ValidationError('Invalid JSON in request body');
  }
}

/**
 * Parse and validate query parameters
 */
export function parseQuery(request: Request): Record<string, string> {
  const url = new URL(request.url);
  const params: Record<string, string> = {};

  url.searchParams.forEach((value, key) => {
    params[key] = value;
  });

  return params;
}

/**
 * Extract path parameters from URL
 */
export function parsePathParams(request: Request, pattern: string): Record<string, string> {
  const url = new URL(request.url);
  const pathname = url.pathname;

  // Simple path parameter extraction
  const patternParts = pattern.split('/');
  const pathParts = pathname.split('/');

  const params: Record<string, string> = {};

  patternParts.forEach((part, index) => {
    if (part.startsWith(':')) {
      const paramName = part.slice(1);
      params[paramName] = pathParts[index] || '';
    }
  });

  return params;
}

// ============================================
// PAGINATION HELPERS
// ============================================

export interface PaginationParams {
  page: number;
  limit: number;
  offset: number;
}

export interface PaginationMeta {
  page: number;
  limit: number;
  total: number;
  totalPages: number;
  hasNext: boolean;
  hasPrev: boolean;
}

/**
 * Parse pagination parameters from query string
 */
export function parsePagination(
  query: Record<string, string>,
  defaultLimit: number = 10,
  maxLimit: number = 100
): PaginationParams {
  const page = Math.max(1, parseInt(query.page || '1', 10));
  const limit = Math.min(maxLimit, Math.max(1, parseInt(query.limit || String(defaultLimit), 10)));
  const offset = (page - 1) * limit;

  return { page, limit, offset };
}

/**
 * Create pagination metadata
 */
export function createPaginationMeta(
  page: number,
  limit: number,
  total: number
): PaginationMeta {
  const totalPages = Math.ceil(total / limit);

  return {
    page,
    limit,
    total,
    totalPages,
    hasNext: page < totalPages,
    hasPrev: page > 1,
  };
}

/**
 * Create paginated response
 */
export function paginatedResponse<T>(
  data: T[],
  pagination: PaginationParams,
  total: number
): NextResponse<ApiSuccessResponse<T[]>> {
  const meta = createPaginationMeta(pagination.page, pagination.limit, total);

  return NextResponse.json({
    success: true,
    data,
    meta,
  });
}

// ============================================
// CORS HELPERS
// ============================================

/**
 * Add CORS headers to response
 */
export function withCors(
  response: NextResponse,
  options: {
    origin?: string | string[];
    methods?: string[];
    headers?: string[];
    credentials?: boolean;
  } = {}
): NextResponse {
  const {
    origin = '*',
    methods = ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    headers = ['Content-Type', 'Authorization'],
    credentials = true,
  } = options;

  const allowOrigin = Array.isArray(origin) ? origin.join(',') : origin;

  response.headers.set('Access-Control-Allow-Origin', allowOrigin);
  response.headers.set('Access-Control-Allow-Methods', methods.join(','));
  response.headers.set('Access-Control-Allow-Headers', headers.join(','));

  if (credentials) {
    response.headers.set('Access-Control-Allow-Credentials', 'true');
  }

  return response;
}

/**
 * Handle OPTIONS preflight request
 */
export function handleOptions(
  corsOptions?: Parameters<typeof withCors>[1]
): NextResponse {
  const response = new NextResponse(null, { status: 204 });
  return withCors(response, corsOptions);
}

// ============================================
// RATE LIMITING HELPERS
// ============================================

const rateLimitStore = new Map<string, { count: number; resetAt: number }>();

/**
 * Simple in-memory rate limiter
 * For production, use Redis or a proper rate limiting service
 */
export function checkRateLimit(
  identifier: string,
  limit: number = 100,
  windowMs: number = 60000
): { allowed: boolean; remaining: number; resetAt: number } {
  const now = Date.now();
  const record = rateLimitStore.get(identifier);

  // Clean up expired records
  if (record && record.resetAt < now) {
    rateLimitStore.delete(identifier);
  }

  if (!record || record.resetAt < now) {
    const resetAt = now + windowMs;
    rateLimitStore.set(identifier, { count: 1, resetAt });
    return { allowed: true, remaining: limit - 1, resetAt };
  }

  if (record.count >= limit) {
    return { allowed: false, remaining: 0, resetAt: record.resetAt };
  }

  record.count++;
  return { allowed: true, remaining: limit - record.count, resetAt: record.resetAt };
}

// ============================================
// EXPORT ALL
// ============================================

export default {
  // Success responses
  successResponse,
  createdResponse,
  noContentResponse,

  // Error responses
  errorResponse,
  asyncHandler,

  // Parsing
  parseBody,
  parseQuery,
  parsePathParams,

  // Pagination
  parsePagination,
  createPaginationMeta,
  paginatedResponse,

  // CORS
  withCors,
  handleOptions,

  // Rate limiting
  checkRateLimit,
};
