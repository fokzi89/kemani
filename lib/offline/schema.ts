import { column, Schema, Table } from '@powersync/web';

export const products = new Table({
    name: column.text,
    description: column.text,
    unit_price: column.integer, // Store as integer (kobo) or use real/text. PowerSync supports text/integer/real.
    stock_quantity: column.integer,
    sku: column.text,
    barcode: column.text,
    category: column.text,
    tenant_id: column.text,
    branch_id: column.text,
    created_at: column.text,
    updated_at: column.text,
});

export const customers = new Table({
    full_name: column.text,
    phone: column.text,
    email: column.text,
    loyalty_points: column.integer,
    tenant_id: column.text,
    created_at: column.text,
    updated_at: column.text,
});

export const sales = new Table({
    sale_number: column.text,
    subtotal: column.real,
    total_amount: column.real,
    payment_method: column.text,
    status: column.text,
    tenant_id: column.text,
    branch_id: column.text,
    cashier_id: column.text,
    customer_id: column.text,
    is_synced: column.integer, // boolean 0/1
    created_at: column.text,
    updated_at: column.text,
});

export const sale_items = new Table({
    sale_id: column.text,
    product_id: column.text,
    quantity: column.integer,
    unit_price: column.real,
    subtotal: column.real,
    product_name: column.text,
});

export const inventory_transactions = new Table({
    product_id: column.text,
    quantity_delta: column.integer,
    new_quantity: column.integer,
    previous_quantity: column.integer,
    transaction_type: column.text,
    notes: column.text,
    tenant_id: column.text,
    branch_id: column.text,
    staff_id: column.text,
    created_at: column.text,
});

export const AppSchema = new Schema({
    products,
    customers,
    sales,
    sale_items,
    inventory_transactions,
});
