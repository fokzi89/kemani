-- ============================================
-- Migration: Enable RLS and Create Policies
-- Description: Enable Row Level Security on all tenant-scoped tables
-- Created: 2026-01-23
-- Note: This migration assumes core tables already exist
-- ============================================

-- ============================================
-- ENABLE RLS ON ALL TENANT-SCOPED TABLES
-- ============================================

-- Core tables
ALTER TABLE IF EXISTS tenants ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS branches ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS users ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS products ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS sales ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS sale_items ENABLE ROW LEVEL SECURITY;

-- ============================================
-- TENANTS TABLE POLICIES
-- ============================================

-- Users can only see their own tenant
DROP POLICY IF EXISTS "Users can view their own tenant" ON tenants;
CREATE POLICY "Users can view their own tenant"
    ON tenants FOR SELECT
    USING (id = current_tenant_id());

-- Only owners can update tenant settings
DROP POLICY IF EXISTS "Owners can update tenant" ON tenants;
CREATE POLICY "Owners can update tenant"
    ON tenants FOR UPDATE
    USING (id = current_tenant_id() AND current_user_role() = 'tenant_admin');

-- ============================================
-- BRANCHES TABLE POLICIES
-- ============================================

-- Users can view branches in their tenant
DROP POLICY IF EXISTS "Users can view branches in their tenant" ON branches;
CREATE POLICY "Users can view branches in their tenant"
    ON branches FOR SELECT
    USING (tenant_id = current_tenant_id());

-- Owners and admins can manage branches
DROP POLICY IF EXISTS "Admins can manage branches" ON branches;
CREATE POLICY "Admins can manage branches"
    ON branches FOR ALL
    USING (
        tenant_id = current_tenant_id() AND
        current_user_role() IN ('super_admin', 'tenant_admin')
    );

-- ============================================
-- USERS TABLE POLICIES
-- ============================================

-- Users can view other users in their tenant
DROP POLICY IF EXISTS "Users can view users in their tenant" ON users;
CREATE POLICY "Users can view users in their tenant"
    ON users FOR SELECT
    USING (tenant_id = current_tenant_id());

-- Users can update their own profile
DROP POLICY IF EXISTS "Users can update own profile" ON users;
CREATE POLICY "Users can update own profile"
    ON users FOR UPDATE
    USING (id = auth.uid());

-- Managers can create users in their tenant
DROP POLICY IF EXISTS "Managers can create users" ON users;
CREATE POLICY "Managers can create users"
    ON users FOR INSERT
    WITH CHECK (
        tenant_id = current_tenant_id() AND
        can_manage_users()
    );

-- Managers can update users in their tenant
DROP POLICY IF EXISTS "Managers can update users" ON users;
CREATE POLICY "Managers can update users"
    ON users FOR UPDATE
    USING (
        tenant_id = current_tenant_id() AND
        can_manage_users()
    );

-- Admins can delete users
DROP POLICY IF EXISTS "Admins can delete users" ON users;
CREATE POLICY "Admins can delete users"
    ON users FOR DELETE
    USING (
        tenant_id = current_tenant_id() AND
        current_user_role() IN ('super_admin', 'tenant_admin')
    );

-- ============================================
-- PRODUCTS TABLE POLICIES
-- ============================================

-- Users can view products in their tenant
DROP POLICY IF EXISTS "Users can view products in their tenant" ON products;
CREATE POLICY "Users can view products in their tenant"
    ON products FOR SELECT
    USING (tenant_id = current_tenant_id());

-- Managers can manage products
DROP POLICY IF EXISTS "Managers can insert products" ON products;
CREATE POLICY "Managers can insert products"
    ON products FOR INSERT
    WITH CHECK (
        tenant_id = current_tenant_id() AND
        can_manage_products()
    );

DROP POLICY IF EXISTS "Managers can update products" ON products;
CREATE POLICY "Managers can update products"
    ON products FOR UPDATE
    USING (
        tenant_id = current_tenant_id() AND
        can_manage_products()
    );

DROP POLICY IF EXISTS "Managers can delete products" ON products;
CREATE POLICY "Managers can delete products"
    ON products FOR DELETE
    USING (
        tenant_id = current_tenant_id() AND
        can_manage_products()
    );

-- ============================================
-- CUSTOMERS TABLE POLICIES
-- ============================================

-- Users can view customers in their tenant
DROP POLICY IF EXISTS "Users can view customers in their tenant" ON customers;
CREATE POLICY "Users can view customers in their tenant"
    ON customers FOR SELECT
    USING (tenant_id = current_tenant_id());

-- Staff can create customers
DROP POLICY IF EXISTS "Staff can create customers" ON customers;
CREATE POLICY "Staff can create customers"
    ON customers FOR INSERT
    WITH CHECK (tenant_id = current_tenant_id());

-- Staff can update customers
DROP POLICY IF EXISTS "Staff can update customers" ON customers;
CREATE POLICY "Staff can update customers"
    ON customers FOR UPDATE
    USING (tenant_id = current_tenant_id());

-- Managers can delete customers
DROP POLICY IF EXISTS "Managers can delete customers" ON customers;
CREATE POLICY "Managers can delete customers"
    ON customers FOR DELETE
    USING (
        tenant_id = current_tenant_id() AND
        can_manage_users()
    );

-- ============================================
-- SALES TABLE POLICIES
-- ============================================

-- Users can view sales in their tenant
DROP POLICY IF EXISTS "Users can view sales in their tenant" ON sales;
CREATE POLICY "Users can view sales in their tenant"
    ON sales FOR SELECT
    USING (tenant_id = current_tenant_id());

-- Cashiers can create sales
DROP POLICY IF EXISTS "Cashiers can create sales" ON sales;
CREATE POLICY "Cashiers can create sales"
    ON sales FOR INSERT
    WITH CHECK (
        tenant_id = current_tenant_id() AND
        (cashier_id = auth.uid() OR sales_attendant_id = auth.uid())
    );

-- Cashiers can update their own sales (within same day)
DROP POLICY IF EXISTS "Cashiers can update own sales" ON sales;
CREATE POLICY "Cashiers can update own sales"
    ON sales FOR UPDATE
    USING (
        tenant_id = current_tenant_id() AND
        cashier_id = auth.uid() AND
        sale_date = CURRENT_DATE
    );

-- Managers can void sales
DROP POLICY IF EXISTS "Managers can void sales" ON sales;
CREATE POLICY "Managers can void sales"
    ON sales FOR UPDATE
    USING (
        tenant_id = current_tenant_id() AND
        can_void_sales()
    );

-- Managers can delete sales
DROP POLICY IF EXISTS "Managers can delete sales" ON sales;
CREATE POLICY "Managers can delete sales"
    ON sales FOR DELETE
    USING (
        tenant_id = current_tenant_id() AND
        current_user_role() IN ('super_admin', 'tenant_admin', 'branch_manager')
    );

-- ============================================
-- SALE_ITEMS TABLE POLICIES
-- ============================================

-- Users can view sale items in their tenant
DROP POLICY IF EXISTS "Users can view sale items in their tenant" ON sale_items;
CREATE POLICY "Users can view sale items in their tenant"
    ON sale_items FOR SELECT
    USING (tenant_id = current_tenant_id());

-- Cashiers can create sale items (via their sales)
DROP POLICY IF EXISTS "Cashiers can create sale items" ON sale_items;
CREATE POLICY "Cashiers can create sale items"
    ON sale_items FOR INSERT
    WITH CHECK (
        tenant_id = current_tenant_id() AND
        EXISTS (
            SELECT 1 FROM sales
            WHERE sales.id = sale_items.sale_id
            AND (sales.cashier_id = auth.uid() OR sales.sales_attendant_id = auth.uid())
        )
    );

-- Cashiers can update sale items (via their sales, same day)
DROP POLICY IF EXISTS "Cashiers can update sale items" ON sale_items;
CREATE POLICY "Cashiers can update sale items"
    ON sale_items FOR UPDATE
    USING (
        tenant_id = current_tenant_id() AND
        EXISTS (
            SELECT 1 FROM sales
            WHERE sales.id = sale_items.sale_id
            AND sales.cashier_id = auth.uid()
            AND sales.sale_date = CURRENT_DATE
        )
    );

-- Managers can delete sale items
DROP POLICY IF EXISTS "Managers can delete sale items" ON sale_items;
CREATE POLICY "Managers can delete sale items"
    ON sale_items FOR DELETE
    USING (
        tenant_id = current_tenant_id() AND
        current_user_role() IN ('super_admin', 'tenant_admin', 'branch_manager')
    );

-- ============================================
-- COMMENTS
-- ============================================

COMMENT ON POLICY "Users can view their own tenant" ON tenants IS 'Users can only see their own tenant';
COMMENT ON POLICY "Users can view branches in their tenant" ON branches IS 'Users see all branches in their tenant';
COMMENT ON POLICY "Users can view users in their tenant" ON users IS 'Users see all users in their tenant';
COMMENT ON POLICY "Users can view products in their tenant" ON products IS 'Users see all products in their tenant';
COMMENT ON POLICY "Users can view sales in their tenant" ON sales IS 'Users see all sales in their tenant';
