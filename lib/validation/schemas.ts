/**
 * Zod Validation Schemas
 * Comprehensive validation for all entities in the system
 */

import { z } from 'zod';

// ============================================
// COMMON SCHEMAS
// ============================================

export const uuidSchema = z.string().uuid('Invalid UUID format');

export const phoneSchema = z
  .string()
  .regex(/^\+?[1-9]\d{1,14}$/, 'Invalid phone number format')
  .transform((val) => val.replace(/\s/g, '')); // Remove spaces

export const emailSchema = z.string().email('Invalid email address');

export const positiveDecimalSchema = z
  .number()
  .positive('Must be a positive number')
  .finite('Must be a finite number');

export const nonNegativeDecimalSchema = z
  .number()
  .nonnegative('Must be zero or positive')
  .finite('Must be a finite number');

export const percentageSchema = z
  .number()
  .min(0, 'Percentage must be between 0 and 100')
  .max(100, 'Percentage must be between 0 and 100');

export const dateStringSchema = z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'Invalid date format (YYYY-MM-DD)');

// ============================================
// TENANT SCHEMAS
// ============================================

export const createTenantSchema = z.object({
  name: z.string().min(2, 'Name must be at least 2 characters').max(255),
  business_type: z.enum(['retail', 'wholesale', 'restaurant', 'services', 'other']).optional(),
  address: z.string().max(500).optional(),
  phone: phoneSchema.optional(),
  email: emailSchema.optional(),
  logo_url: z.string().url('Invalid URL').optional(),
  settings: z.record(z.any()).optional(),
});

export const updateTenantSchema = createTenantSchema.partial();

// ============================================
// BRANCH SCHEMAS
// ============================================

export const createBranchSchema = z.object({
  tenant_id: uuidSchema,
  name: z.string().min(2).max(255),
  code: z.string().max(50).optional(),
  address: z.string().max(500).optional(),
  phone: phoneSchema.optional(),
  email: emailSchema.optional(),
  is_active: z.boolean().default(true),
});

export const updateBranchSchema = createBranchSchema.partial().omit({ tenant_id: true });

// ============================================
// USER SCHEMAS
// ============================================

export const userRoleSchema = z.enum(['super_admin', 'tenant_admin', 'branch_manager', 'staff', 'rider']);

export const createUserSchema = z.object({
  tenant_id: uuidSchema,
  branch_id: uuidSchema.optional(),
  email: emailSchema,
  phone: phoneSchema.optional(),
  full_name: z.string().min(2).max(255),
  role: userRoleSchema,
  is_active: z.boolean().default(true),
});

export const updateUserSchema = createUserSchema.partial().omit({ tenant_id: true });

// ============================================
// PRODUCT SCHEMAS
// ============================================

export const createProductSchema = z.object({
  tenant_id: uuidSchema,
  branch_id: uuidSchema.optional(),
  name: z.string().min(1).max(255),
  sku: z.string().min(1).max(100),
  barcode: z.string().max(100).optional(),
  brand_id: uuidSchema.optional(),
  category_id: uuidSchema.optional(),
  cost_price: positiveDecimalSchema.optional(),
  selling_price: positiveDecimalSchema,
  quantity: nonNegativeDecimalSchema.default(0),
  unit_of_measure: z.string().max(20).default('piece'),
  reorder_level: nonNegativeDecimalSchema.default(0),
  description: z.string().optional(),
  is_active: z.boolean().default(true),
  is_taxable: z.boolean().default(true),
});

export const updateProductSchema = createProductSchema.partial().omit({ tenant_id: true });

// ============================================
// BRAND SCHEMAS
// ============================================

export const createBrandSchema = z.object({
  tenant_id: uuidSchema,
  name: z.string().min(1).max(255),
  code: z.string().max(50).optional(),
  description: z.string().optional(),
  logo_url: z.string().url().optional(),
  tier: z.enum(['premium', 'mid-range', 'budget']).optional(),
  is_house_brand: z.boolean().default(false),
  is_active: z.boolean().default(true),
});

export const updateBrandSchema = createBrandSchema.partial().omit({ tenant_id: true });

// ============================================
// CATEGORY SCHEMAS
// ============================================

export const createCategorySchema = z.object({
  tenant_id: uuidSchema,
  name: z.string().min(1).max(255),
  code: z.string().max(50).optional(),
  parent_category_id: uuidSchema.optional(),
  description: z.string().optional(),
  sort_order: z.number().int().default(0),
  is_active: z.boolean().default(true),
});

export const updateCategorySchema = createCategorySchema.partial().omit({ tenant_id: true });

// ============================================
// CUSTOMER SCHEMAS
// ============================================

export const createCustomerSchema = z.object({
  tenant_id: uuidSchema,
  email: emailSchema.optional(),
  phone: phoneSchema,
  full_name: z.string().min(2).max(255),
  address: z.string().max(500).optional(),
  loyalty_points: z.number().int().nonnegative().default(0),
  is_active: z.boolean().default(true),
});

export const updateCustomerSchema = createCustomerSchema.partial().omit({ tenant_id: true });

// ============================================
// SALE SCHEMAS
// ============================================

export const paymentMethodSchema = z.enum(['cash', 'card', 'transfer', 'mobile_money', 'split']);

export const saleStatusSchema = z.enum(['pending', 'completed', 'void', 'refunded', 'partial_refund']);

export const saleTypeSchema = z.enum(['pos', 'online', 'marketplace', 'delivery']);

export const channelSchema = z.enum(['in-store', 'online', 'mobile-app', 'whatsapp']);

export const createSaleSchema = z.object({
  tenant_id: uuidSchema,
  branch_id: uuidSchema,
  customer_id: uuidSchema.optional(),
  customer_type: z.enum(['walk-in', 'registered', 'marketplace', 'new']).default('walk-in'),
  cashier_id: uuidSchema,
  sales_attendant_id: uuidSchema.optional(),
  subtotal: positiveDecimalSchema,
  discount_amount: nonNegativeDecimalSchema.default(0),
  tax_amount: nonNegativeDecimalSchema.default(0),
  delivery_fee: nonNegativeDecimalSchema.default(0),
  total_amount: positiveDecimalSchema,
  amount_paid: positiveDecimalSchema,
  change_amount: nonNegativeDecimalSchema.default(0),
  payment_method: paymentMethodSchema,
  payment_status: saleStatusSchema.default('completed'),
  payment_reference: z.string().max(100).optional(),
  sale_type: saleTypeSchema.default('pos'),
  channel: channelSchema.default('in-store'),
  sale_status: saleStatusSchema.default('completed'),
  receipt_number: z.string().max(50).optional(),
  items: z.array(
    z.object({
      product_id: uuidSchema,
      quantity: positiveDecimalSchema,
      unit_price: positiveDecimalSchema,
      line_total: positiveDecimalSchema,
      discount_amount: nonNegativeDecimalSchema.default(0),
      tax_amount: nonNegativeDecimalSchema.default(0),
    })
  ).min(1, 'Sale must have at least one item'),
});

export const voidSaleSchema = z.object({
  void_reason: z.string().min(5, 'Void reason must be at least 5 characters'),
});

// ============================================
// SALE ITEM SCHEMAS
// ============================================

export const createSaleItemSchema = z.object({
  sale_id: uuidSchema,
  tenant_id: uuidSchema,
  product_id: uuidSchema,
  product_variant_id: uuidSchema.optional(),
  quantity: positiveDecimalSchema,
  unit_of_measure: z.string().max(20).default('piece'),
  unit_price: positiveDecimalSchema,
  original_price: positiveDecimalSchema.optional(),
  discount_percentage: percentageSchema.default(0),
  discount_amount: nonNegativeDecimalSchema.default(0),
  tax_percentage: percentageSchema.default(0),
  tax_amount: nonNegativeDecimalSchema.default(0),
  line_total: positiveDecimalSchema,
  discount_type: z.enum(['percentage', 'fixed_amount', 'promo_code', 'loyalty_points', 'bulk_discount']).optional(),
  discount_code: z.string().max(50).optional(),
  notes: z.string().optional(),
});

// ============================================
// AUTHENTICATION SCHEMAS
// ============================================

export const sendOTPSchema = z.object({
  identifier: z.union([emailSchema, phoneSchema]),
  type: z.enum(['email', 'sms']),
});

export const verifyOTPSchema = z.object({
  identifier: z.union([emailSchema, phoneSchema]),
  otp: z.string().length(6, 'OTP must be 6 digits').regex(/^\d{6}$/, 'OTP must be numeric'),
});

export const registerSchema = z.object({
  email: emailSchema.optional(),
  phone: phoneSchema.optional(),
  full_name: z.string().min(2).max(255),
  business_name: z.string().min(2).max(255),
  business_type: z.enum(['retail', 'wholesale', 'restaurant', 'services', 'other']).optional(),
}).refine(
  (data) => data.email || data.phone,
  'Either email or phone number is required'
);

// ============================================
// PAYMENT SCHEMAS
// ============================================

export const initializePaymentSchema = z.object({
  amount: positiveDecimalSchema,
  email: emailSchema,
  reference: z.string().optional(),
  callback_url: z.string().url().optional(),
  metadata: z.record(z.any()).optional(),
});

export const verifyPaymentSchema = z.object({
  reference: z.string().min(1, 'Reference is required'),
});

// ============================================
// ANALYTICS SCHEMAS
// ============================================

export const dateRangeSchema = z.object({
  start_date: dateStringSchema,
  end_date: dateStringSchema,
}).refine(
  (data) => new Date(data.start_date) <= new Date(data.end_date),
  'Start date must be before or equal to end date'
);

export const analyticsQuerySchema = dateRangeSchema.extend({
  branch_id: uuidSchema.optional(),
  product_id: uuidSchema.optional(),
  category_id: uuidSchema.optional(),
  brand_id: uuidSchema.optional(),
  staff_id: uuidSchema.optional(),
  limit: z.number().int().positive().max(1000).default(10),
  offset: z.number().int().nonnegative().default(0),
});

// ============================================
// DELIVERY SCHEMAS
// ============================================

export const createDeliverySchema = z.object({
  tenant_id: uuidSchema,
  order_id: uuidSchema,
  rider_id: uuidSchema.optional(),
  delivery_type: z.enum(['local', 'intercity']),
  pickup_address: z.string().min(5).max(500),
  delivery_address: z.string().min(5).max(500),
  recipient_name: z.string().min(2).max(255),
  recipient_phone: phoneSchema,
  distance_km: positiveDecimalSchema.optional(),
  delivery_fee: positiveDecimalSchema,
  status: z.enum(['pending', 'assigned', 'picked_up', 'in_transit', 'delivered', 'cancelled']).default('pending'),
});

export const updateDeliveryStatusSchema = z.object({
  status: z.enum(['assigned', 'picked_up', 'in_transit', 'delivered', 'cancelled']),
  notes: z.string().max(500).optional(),
});

// ============================================
// HELPER FUNCTIONS
// ============================================

/**
 * Validates data against a schema and returns typed result
 */
export function validateData<T>(schema: z.ZodSchema<T>, data: unknown): { success: true; data: T } | { success: false; errors: z.ZodError } {
  const result = schema.safeParse(data);

  if (result.success) {
    return { success: true, data: result.data };
  } else {
    return { success: false, errors: result.error };
  }
}

/**
 * Formats Zod errors for API responses
 */
export function formatZodErrors(error: z.ZodError): Record<string, string[]> {
  const formatted: Record<string, string[]> = {};

  error.errors.forEach((err) => {
    const path = err.path.join('.');
    if (!formatted[path]) {
      formatted[path] = [];
    }
    formatted[path].push(err.message);
  });

  return formatted;
}
