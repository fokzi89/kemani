import { z } from 'zod';

export const tenantSchema = z.object({
    name: z.string().min(2, "Name must be at least 2 characters"),
    email: z.string().email(),
    phone: z.string().min(10, "Phone number required"),
    brand_color: z.string().regex(/^#[0-9A-Fa-f]{6}$/, "Invalid color hex code").optional(),
});

export const userSchema = z.object({
    email: z.string().email().optional(),
    phone: z.string().min(10).optional(),
    full_name: z.string().min(2),
    role: z.enum(['platform_admin', 'tenant_admin', 'branch_manager', 'cashier', 'driver']),
}).refine(data => data.email || data.phone, {
    message: "Either email or phone is required",
    path: ["email"]
});

export const productSchema = z.object({
    name: z.string().min(2),
    unit_price: z.number().positive(),
    cost_price: z.number().nonnegative().optional(),
    stock_quantity: z.number().int().nonnegative(),
    sku: z.string().optional(),
    barcode: z.string().optional(),
    low_stock_threshold: z.number().int().nonnegative().default(10),
});

export const saleSchema = z.object({
    items: z.array(z.object({
        product_id: z.string().uuid(),
        quantity: z.number().int().positive(),
    })).min(1),
    payment_method: z.enum(['cash', 'card', 'bank_transfer', 'mobile_money']),
});
