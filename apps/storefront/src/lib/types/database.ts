import { z } from 'zod';

// UUID Helper
export const UuidSchema = z.string().uuid();

// ----------------------------------------------------------------------------
// 1. Storefront Customers
// ----------------------------------------------------------------------------
export const CustomerSchema = z.object({
    id: UuidSchema.optional(),
    user_id: UuidSchema.nullable().optional(),
    email: z.string().email().nullable().optional(),
    phone: z.string().regex(/^\+?[0-9]{10,15}$/, 'Invalid phone format'),
    name: z.string().min(1, 'Name is required'),
    delivery_address: z.record(z.any()).nullable().optional(),
    delivery_coordinates: z.string().nullable().optional(), // Point as string or object?
    created_at: z.string().datetime().optional(),
    updated_at: z.string().datetime().optional(),
    last_order_at: z.string().datetime().nullable().optional(),
    total_orders: z.number().int().default(0),
});

export type Customer = z.infer<typeof CustomerSchema>;

// ----------------------------------------------------------------------------
// 2. Storefront Products
// ----------------------------------------------------------------------------
export const ProductSchema = z.object({
    id: UuidSchema.optional(),
    catalog_product_id: UuidSchema.nullable().optional(),
    tenant_id: UuidSchema,
    branch_id: UuidSchema,
    product_id: UuidSchema.nullable().optional(),
    sku: z.string(),
    price: z.number().min(0),
    compare_at_price: z.number().min(0).nullable().optional(),
    cost_price: z.number().min(0).nullable().optional(),
    stock_quantity: z.number().int().min(0).default(0),
    low_stock_threshold: z.number().int().default(10),
    is_available: z.boolean().default(true),
    custom_name: z.string().nullable().optional(),
    custom_description: z.string().nullable().optional(),
    custom_images: z.array(z.string().url()).nullable().optional(),
    has_variants: z.boolean().default(false),
    created_at: z.string().datetime().optional(),
    updated_at: z.string().datetime().optional(),
    synced_at: z.string().datetime().optional(),
});

export type Product = z.infer<typeof ProductSchema>;

// ----------------------------------------------------------------------------
// 3. Product Variants
// ----------------------------------------------------------------------------
export const VariantSchema = z.object({
    id: UuidSchema.optional(),
    product_id: UuidSchema,
    variant_name: z.string(),
    options: z.record(z.any()), // JSONB
    sku: z.string(),
    price_adjustment: z.number().default(0),
    stock_quantity: z.number().int().min(0).default(0),
    is_available: z.boolean().default(true),
    image_url: z.string().url().nullable().optional(),
    created_at: z.string().datetime().optional(),
    updated_at: z.string().datetime().optional(),
});

export type Variant = z.infer<typeof VariantSchema>;

// ----------------------------------------------------------------------------
// 4. Shopping Carts
// ----------------------------------------------------------------------------
export const CartSchema = z.object({
    id: UuidSchema.optional(),
    customer_id: UuidSchema.nullable().optional(),
    session_id: z.string(),
    branch_id: UuidSchema,
    tenant_id: UuidSchema,
    created_at: z.string().datetime().optional(),
    updated_at: z.string().datetime().optional(),
    expires_at: z.string().datetime().optional(),
});

export type Cart = z.infer<typeof CartSchema>;

// ----------------------------------------------------------------------------
// 5. Cart Items
// ----------------------------------------------------------------------------
export const CartItemSchema = z.object({
    id: UuidSchema.optional(),
    cart_id: UuidSchema,
    product_id: UuidSchema,
    variant_id: UuidSchema.nullable().optional(),
    quantity: z.number().int().min(1),
    unit_price: z.number().min(0),
    added_at: z.string().datetime().optional(),
    updated_at: z.string().datetime().optional(),
});

export type CartItem = z.infer<typeof CartItemSchema>;

// ----------------------------------------------------------------------------
// 6. Storefront Orders
// ----------------------------------------------------------------------------
export const OrderStatusEnum = z.enum([
    'pending', 'confirmed', 'preparing', 'ready', 'dispatched', 'delivered', 'cancelled'
]);

export const PaymentStatusEnum = z.enum([
    'pending', 'paid', 'failed', 'refunded'
]);

export const DeliveryMethodEnum = z.enum([
    'self_pickup', 'bicycle', 'motorbike', 'platform'
]);

export const OrderSchema = z.object({
    id: UuidSchema.optional(),
    order_number: z.string(),
    customer_id: UuidSchema,
    branch_id: UuidSchema,
    tenant_id: UuidSchema,
    delivery_name: z.string(),
    delivery_phone: z.string(),
    delivery_address: z.record(z.any()).nullable().optional(),
    delivery_coordinates: z.string().nullable().optional(),
    delivery_method: DeliveryMethodEnum,
    delivery_instructions: z.string().nullable().optional(),
    subtotal: z.number().min(0),
    delivery_base_fee: z.number().min(0).default(0),
    delivery_fee_addition: z.number().min(0).default(100),
    platform_commission: z.number().min(0).default(50),
    transaction_fee: z.number().min(0).default(100),
    total_amount: z.number().min(0),
    payment_status: PaymentStatusEnum.default('pending'),
    payment_method: z.string().nullable().optional(),
    paystack_reference: z.string().nullable().optional(),
    order_status: OrderStatusEnum.default('pending'),
    created_at: z.string().datetime().optional(),
    updated_at: z.string().datetime().optional(),
    paid_at: z.string().datetime().nullable().optional(),
    confirmed_at: z.string().datetime().nullable().optional(),
    completed_at: z.string().datetime().nullable().optional(),
});

export type Order = z.infer<typeof OrderSchema>;

// ----------------------------------------------------------------------------
// 7. Storefront Order Items
// ----------------------------------------------------------------------------
export const OrderItemSchema = z.object({
    id: UuidSchema.optional(),
    order_id: UuidSchema,
    product_id: UuidSchema,
    variant_id: UuidSchema.nullable().optional(),
    product_name: z.string(),
    product_sku: z.string(),
    variant_name: z.string().nullable().optional(),
    unit_price: z.number().min(0),
    quantity: z.number().int().min(1),
    line_total: z.number().min(0),
    created_at: z.string().datetime().optional(),
});

export type OrderItem = z.infer<typeof OrderItemSchema>;

// ----------------------------------------------------------------------------
// 9. Chat Sessions
// ----------------------------------------------------------------------------
export const ChatSessionSchema = z.object({
    id: UuidSchema.optional(),
    customer_id: UuidSchema.nullable().optional(),
    session_token: z.string(),
    branch_id: UuidSchema,
    tenant_id: UuidSchema,
    agent_id: UuidSchema.nullable().optional(),
    agent_type: z.enum(['live', 'ai', 'owner']).default('live'),
    status: z.enum(['active', 'resolved', 'abandoned']).default('active'),
    created_at: z.string().datetime().optional(),
    updated_at: z.string().datetime().optional(),
    last_message_at: z.string().datetime().nullable().optional(),
    resolved_at: z.string().datetime().nullable().optional(),
});

export type ChatSession = z.infer<typeof ChatSessionSchema>;

// ----------------------------------------------------------------------------
// 10. Chat Messages
// ----------------------------------------------------------------------------
export const ChatMessageSchema = z.object({
    id: UuidSchema.optional(),
    session_id: UuidSchema,
    sender_type: z.enum(['customer', 'agent', 'ai']),
    sender_id: UuidSchema.nullable().optional(),
    sender_name: z.string(),
    message_type: z.enum(['text', 'image', 'voice', 'pdf', 'product_card']).default('text'),
    content: z.string(),
    product_id: UuidSchema.nullable().optional(),
    created_at: z.string().datetime().optional(),
    read_at: z.string().datetime().nullable().optional(),
});

export type ChatMessage = z.infer<typeof ChatMessageSchema>;

// ----------------------------------------------------------------------------
// 12. Tenant Branding
// ----------------------------------------------------------------------------
export const BrandingSchema = z.object({
    id: UuidSchema.optional(),
    tenant_id: UuidSchema,
    branch_id: UuidSchema.nullable().optional(),
    business_name: z.string(),
    logo_url: z.string().url().nullable().optional(),
    brand_color: z.string().regex(/^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$/, 'Invalid hex color').default('#0ea5e9'),
    background_color: z.string().regex(/^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$/, 'Invalid hex color').default('#ffffff'),
    font_family: z.string().default('Inter'),
    created_at: z.string().datetime().optional(),
    updated_at: z.string().datetime().optional(),
});

export type Branding = z.infer<typeof BrandingSchema>;
