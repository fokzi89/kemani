-- ============================================================
-- Migration 008: Row Level Security Policies
-- ============================================================
-- Purpose: Enable RLS and create helper functions and policies

-- Enable RLS on all tenant-scoped tables
ALTER TABLE tenants ENABLE ROW LEVEL SECURITY;
ALTER TABLE branches ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE inter_branch_transfers ENABLE ROW LEVEL SECURITY;
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE sales ENABLE ROW LEVEL SECURITY;
ALTER TABLE sale_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE deliveries ENABLE ROW LEVEL SECURITY;
ALTER TABLE riders ENABLE ROW LEVEL SECURITY;
ALTER TABLE staff_attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE ecommerce_connections ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE whatsapp_messages ENABLE ROW LEVEL SECURITY;

-- Helper functions for RLS policies
CREATE OR REPLACE FUNCTION current_tenant_id() RETURNS UUID AS $$
    SELECT tenant_id FROM users WHERE id = auth.uid();
$$ LANGUAGE SQL SECURITY DEFINER;

CREATE OR REPLACE FUNCTION current_user_role() RETURNS user_role AS $$
    SELECT role FROM users WHERE id = auth.uid();
$$ LANGUAGE SQL SECURITY DEFINER;

CREATE OR REPLACE FUNCTION current_user_branch_id() RETURNS UUID AS $$
    SELECT branch_id FROM users WHERE id = auth.uid();
$$ LANGUAGE SQL SECURITY DEFINER;

-- Tenants: Users see only their tenant
CREATE POLICY "Users can view own tenant" ON tenants
    FOR SELECT USING (id = current_tenant_id());

CREATE POLICY "Users can update own tenant" ON tenants
    FOR UPDATE USING (id = current_tenant_id() AND current_user_role() = 'tenant_admin');

-- Branches: Tenant isolation
CREATE POLICY "Tenant branch isolation" ON branches
    FOR ALL USING (tenant_id = current_tenant_id());

-- Products: Branch-level access control
CREATE POLICY "Product tenant isolation" ON products
    FOR ALL USING (tenant_id = current_tenant_id());

CREATE POLICY "Product branch access" ON products
    FOR SELECT USING (
        current_user_role() = 'tenant_admin' OR
        branch_id = current_user_branch_id()
    );

-- Sales: Branch-level access
CREATE POLICY "Sale tenant isolation" ON sales
    FOR ALL USING (tenant_id = current_tenant_id());

CREATE POLICY "Sale branch access" ON sales
    FOR SELECT USING (
        current_user_role() = 'tenant_admin' OR
        branch_id = current_user_branch_id()
    );

-- Customers: Tenant-wide (shared across branches)
CREATE POLICY "Customer tenant isolation" ON customers
    FOR ALL USING (tenant_id = current_tenant_id());

-- Orders: Branch-level access
CREATE POLICY "Order tenant isolation" ON orders
    FOR ALL USING (tenant_id = current_tenant_id());

CREATE POLICY "Order branch access" ON orders
    FOR SELECT USING (
        current_user_role() = 'tenant_admin' OR
        branch_id = current_user_branch_id()
    );

-- Deliveries: Branch and rider access
CREATE POLICY "Delivery tenant isolation" ON deliveries
    FOR ALL USING (tenant_id = current_tenant_id());

CREATE POLICY "Delivery rider access" ON deliveries
    FOR SELECT USING (
        current_user_role() IN ('tenant_admin', 'branch_manager') OR
        rider_id IN (SELECT id FROM riders WHERE user_id = auth.uid())
    );
