-- ============================================================
-- Migration 007: Indexes
-- ============================================================
-- Purpose: Create performance indexes for all tables

-- Tenants
CREATE INDEX idx_tenants_slug ON tenants(slug);
CREATE INDEX idx_tenants_email ON tenants(email) WHERE email IS NOT NULL;
CREATE INDEX idx_tenants_deleted ON tenants(deleted_at) WHERE deleted_at IS NULL;

-- Branches
CREATE INDEX idx_branches_tenant ON branches(tenant_id, deleted_at) WHERE deleted_at IS NULL;
CREATE INDEX idx_branches_location ON branches USING GIST(geography(ST_MakePoint(longitude, latitude)))
    WHERE latitude IS NOT NULL AND longitude IS NOT NULL;

-- Users
CREATE INDEX idx_users_tenant ON users(tenant_id, deleted_at) WHERE deleted_at IS NULL;
CREATE INDEX idx_users_branch ON users(branch_id, deleted_at) WHERE deleted_at IS NULL;
CREATE UNIQUE INDEX idx_users_email ON users(email) WHERE email IS NOT NULL AND deleted_at IS NULL;
CREATE UNIQUE INDEX idx_users_phone ON users(phone) WHERE phone IS NOT NULL AND deleted_at IS NULL;

-- Products
CREATE INDEX idx_products_tenant_branch ON products(tenant_id, branch_id, deleted_at) WHERE deleted_at IS NULL;
CREATE INDEX idx_products_sku ON products(tenant_id, sku) WHERE sku IS NOT NULL AND deleted_at IS NULL;
CREATE INDEX idx_products_barcode ON products(tenant_id, barcode) WHERE barcode IS NOT NULL AND deleted_at IS NULL;
CREATE INDEX idx_products_expiry ON products(expiry_date) WHERE expiry_date IS NOT NULL AND deleted_at IS NULL;
CREATE INDEX idx_products_low_stock ON products(branch_id)
    WHERE stock_quantity <= low_stock_threshold AND deleted_at IS NULL;
CREATE INDEX idx_products_name_search ON products USING gin(to_tsvector('english', name));

-- Inventory Transactions
CREATE INDEX idx_inventory_txn_branch_product ON inventory_transactions(branch_id, product_id, created_at DESC);
CREATE INDEX idx_inventory_txn_reference ON inventory_transactions(reference_type, reference_id);
CREATE INDEX idx_inventory_txn_type ON inventory_transactions(transaction_type, created_at DESC);

-- Transfers
CREATE INDEX idx_transfers_tenant ON inter_branch_transfers(tenant_id, created_at DESC);
CREATE INDEX idx_transfers_source ON inter_branch_transfers(source_branch_id, status);
CREATE INDEX idx_transfers_destination ON inter_branch_transfers(destination_branch_id, status);

-- Customers
CREATE UNIQUE INDEX idx_customers_tenant_phone ON customers(tenant_id, phone) WHERE deleted_at IS NULL;
CREATE INDEX idx_customers_email ON customers(email) WHERE email IS NOT NULL AND deleted_at IS NULL;
CREATE INDEX idx_customers_loyalty ON customers(tenant_id, loyalty_points DESC);

-- Sales
CREATE INDEX idx_sales_tenant_branch ON sales(tenant_id, branch_id, created_at DESC);
CREATE INDEX idx_sales_cashier ON sales(cashier_id, created_at DESC);
CREATE INDEX idx_sales_customer ON sales(customer_id, created_at DESC) WHERE customer_id IS NOT NULL;
CREATE INDEX idx_sales_status ON sales(status, created_at DESC);
CREATE INDEX idx_sales_sync ON sales(is_synced) WHERE is_synced = FALSE;
CREATE UNIQUE INDEX idx_sales_number ON sales(tenant_id, sale_number);

-- Orders
CREATE INDEX idx_orders_tenant_branch ON orders(tenant_id, branch_id, created_at DESC);
CREATE INDEX idx_orders_customer ON orders(customer_id, created_at DESC);
CREATE INDEX idx_orders_status ON orders(order_status, created_at DESC);
CREATE UNIQUE INDEX idx_orders_number ON orders(tenant_id, order_number);
CREATE INDEX idx_orders_ecommerce ON orders(ecommerce_platform, ecommerce_order_id)
    WHERE ecommerce_platform IS NOT NULL;

-- Deliveries
CREATE UNIQUE INDEX idx_deliveries_tracking ON deliveries(tracking_number);
CREATE INDEX idx_deliveries_tenant_branch ON deliveries(tenant_id, branch_id, delivery_status);
CREATE INDEX idx_deliveries_rider ON deliveries(rider_id, delivery_status) WHERE rider_id IS NOT NULL;
CREATE INDEX idx_deliveries_status ON deliveries(delivery_status, created_at DESC);

-- Staff Attendance
CREATE INDEX idx_attendance_staff ON staff_attendance(staff_id, shift_date DESC);
CREATE INDEX idx_attendance_branch ON staff_attendance(branch_id, shift_date DESC);
CREATE INDEX idx_attendance_open ON staff_attendance(staff_id) WHERE clock_out_at IS NULL;

-- Chat
CREATE INDEX idx_chat_tenant_branch ON chat_conversations(tenant_id, branch_id, started_at DESC);
CREATE INDEX idx_chat_customer ON chat_conversations(customer_id, started_at DESC);
CREATE INDEX idx_chat_status ON chat_conversations(status) WHERE status = 'active';

-- Commissions
CREATE INDEX idx_commissions_tenant ON commissions(tenant_id, settlement_status);
CREATE INDEX idx_commissions_settlement ON commissions(settlement_status, created_at DESC);

-- WhatsApp
CREATE INDEX idx_whatsapp_tenant_customer ON whatsapp_messages(tenant_id, customer_id, created_at DESC);
CREATE INDEX idx_whatsapp_order ON whatsapp_messages(order_id) WHERE order_id IS NOT NULL;
CREATE INDEX idx_whatsapp_delivery ON whatsapp_messages(delivery_status, created_at DESC);
