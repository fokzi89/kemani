import { Database } from '@/types/database.types';

// Temporary fallback until T010 is run by user
export type Product = any;
export type InventoryTransaction = any;
export type Sale = any;
export type SaleItem = any;

export interface ProductInput {
    name: string;
    description?: string;
    sku?: string;
    barcode?: string;
    category?: string;
    unit_price: number;
    cost_price?: number;
    stock_quantity: number;
    low_stock_threshold?: number;
    expiry_date?: string;
    expiry_alert_days?: number;
    image_url?: string;
    is_active: boolean;
}

export interface SaleInput {
    customer_id?: string;
    subtotal: number;
    tax_amount: number;
    discount_amount: number;
    total_amount: number;
    payment_method: 'cash' | 'card' | 'bank_transfer' | 'mobile_money';
    payment_reference?: string;
    items: SaleItemInput[];
}

export interface SaleItemInput {
    product_id: string;
    product_name: string;
    quantity: number;
    unit_price: number;
    discount_percent: number;
    discount_amount: number;
    subtotal: number;
}

export interface Receipt {
    sale: Sale;
    items: SaleItem[];
    tenant_name: string;
    tenant_address?: string;
    tenant_phone?: string;
    branch_name: string;
    branch_address?: string;
    cashier_name: string;
}
