-- ============================================================
-- Migration: Expense Tracker System
-- ============================================================
-- Description: Implements comprehensive expense tracking, 
-- recurring bills, and delegated financial permissions.
-- ============================================================

-- 1. Update Users Table for Permission Delegation
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS can_manage_expenses BOOLEAN DEFAULT FALSE;

-- 2. Create Enums
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'expense_status') THEN
        CREATE TYPE expense_status AS ENUM ('pending', 'approved', 'rejected', 'paid', 'cancelled');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'recurrence_interval') THEN
        CREATE TYPE recurrence_interval AS ENUM ('none', 'weekly', 'monthly', 'quarterly', 'yearly');
    END IF;
END$$;

-- 3. Create Expense Types Table
CREATE TABLE IF NOT EXISTS expense_types (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE, -- NULL for global defaults
    name VARCHAR(100) NOT NULL,
    is_auto_approve BOOLEAN DEFAULT FALSE,
    is_default BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- RLS for expense_types
ALTER TABLE expense_types ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view relevant expense types" ON expense_types;
CREATE POLICY "Users can view relevant expense types"
    ON expense_types FOR SELECT
    USING (tenant_id IS NULL OR tenant_id IN (SELECT tenant_id FROM users WHERE id = auth.uid()));

DROP POLICY IF EXISTS "Admins can manage expense types" ON expense_types;
CREATE POLICY "Admins can manage expense types"
    ON expense_types FOR ALL
    USING (
        tenant_id IN (SELECT tenant_id FROM users WHERE id = auth.uid() AND role = 'tenant_admin')
    );

-- 4. Create Expenses Table
CREATE TABLE IF NOT EXISTS expenses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
    expense_type_id UUID NOT NULL REFERENCES expense_types(id),
    
    -- Basic Info
    amount DECIMAL(12,2) NOT NULL CHECK (amount >= 0),
    description TEXT NOT NULL,
    expense_date DATE NOT NULL DEFAULT CURRENT_DATE,
    status expense_status DEFAULT 'pending',
    
    -- Tracking
    raised_by UUID NOT NULL REFERENCES users(id),
    approved_by UUID REFERENCES users(id),
    paid_by UUID REFERENCES users(id),
    rejection_reason TEXT,
    
    -- Supplier & PO Link
    supplier_id UUID REFERENCES suppliers(id) ON DELETE SET NULL,
    po_id UUID REFERENCES purchase_orders(id) ON DELETE SET NULL,
    invoice_number VARCHAR(100),
    raised_date DATE,
    due_date DATE,
    payment_terms TEXT,
    
    -- Payment Details
    payment_collected_by TEXT,
    bank_name TEXT,
    bank_account_number TEXT,
    receipt_url TEXT, -- Path to original bill in storage
    payment_evidence_url TEXT, -- Path to proof of payment in storage
    
    -- Recurrence Logic
    is_recurring BOOLEAN DEFAULT FALSE,
    recur_interval recurrence_interval DEFAULT 'none',
    next_recur_date DATE,
    parent_recurring_id UUID REFERENCES expenses(id) ON DELETE SET NULL,
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- RLS for expenses
ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view expenses in their tenant" ON expenses;
CREATE POLICY "Users can view expenses in their tenant"
    ON expenses FOR SELECT
    USING (tenant_id IN (SELECT tenant_id FROM users WHERE id = auth.uid()));

DROP POLICY IF EXISTS "Staff can insert expenses" ON expenses;
CREATE POLICY "Staff can insert expenses"
    ON expenses FOR INSERT
    WITH CHECK (tenant_id IN (SELECT tenant_id FROM users WHERE id = auth.uid()));

DROP POLICY IF EXISTS "Admins and managers can update expenses" ON expenses;
CREATE POLICY "Admins and managers can update expenses"
    ON expenses FOR UPDATE
    USING (
        tenant_id IN (
            SELECT tenant_id FROM users 
            WHERE id = auth.uid() 
            AND (role = 'tenant_admin' OR can_manage_expenses = TRUE)
        )
    );

-- 5. Auto-Approval Trigger
CREATE OR REPLACE FUNCTION trigger_auto_approve_expense()
RETURNS TRIGGER AS $$
DECLARE
    v_auto BOOLEAN;
BEGIN
    SELECT is_auto_approve INTO v_auto FROM expense_types WHERE id = NEW.expense_type_id;
    
    IF v_auto THEN
        NEW.status := 'approved';
        NEW.approved_by := NEW.raised_by; -- Self-approved if category allows
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER auto_approve_expense_trigger
BEFORE INSERT ON expenses
FOR EACH ROW
EXECUTE FUNCTION trigger_auto_approve_expense();

-- 6. Seed Default Expense Types
INSERT INTO expense_types (name, is_auto_approve, is_default) VALUES
('Product Purchase', FALSE, TRUE),
('Rent', FALSE, TRUE),
('Utilities', FALSE, TRUE),
('Salaries', FALSE, TRUE),
('Maintenance', FALSE, TRUE),
('Marketing', FALSE, TRUE),
('Internet', TRUE, TRUE),
('Petty Cash', TRUE, TRUE);

-- 7. Recurring Expense Generation Function
-- To be called by a cron job or manual trigger
CREATE OR REPLACE FUNCTION generate_recurring_expenses()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_count INTEGER := 0;
    v_expense RECORD;
    v_new_date DATE;
BEGIN
    FOR v_expense IN 
        SELECT * FROM expenses 
        WHERE is_recurring = TRUE 
          AND next_recur_date <= CURRENT_DATE
          AND parent_recurring_id IS NULL -- Only original templates
    LOOP
        -- Calculate next date
        v_new_date := CASE v_expense.recur_interval
            WHEN 'weekly' THEN v_expense.next_recur_date + INTERVAL '7 days'
            WHEN 'monthly' THEN v_expense.next_recur_date + INTERVAL '1 month'
            WHEN 'quarterly' THEN v_expense.next_recur_date + INTERVAL '3 months'
            WHEN 'yearly' THEN v_expense.next_recur_date + INTERVAL '1 year'
            ELSE NULL
        END;

        -- Create new pending instance
        INSERT INTO expenses (
            tenant_id, branch_id, expense_type_id, amount, description, 
            expense_date, status, raised_by, supplier_id, po_id, 
            is_recurring, recur_interval, parent_recurring_id
        ) VALUES (
            v_expense.tenant_id, v_expense.branch_id, v_expense.expense_type_id, v_expense.amount, v_expense.description,
            v_expense.next_recur_date, 'pending', v_expense.raised_by, v_expense.supplier_id, v_expense.po_id,
            FALSE, 'none', v_expense.id
        );

        -- Update the template's next date
        UPDATE expenses 
        SET next_recur_date = v_new_date,
            updated_at = NOW()
        WHERE id = v_expense.id;

        v_count := v_count + 1;
    END LOOP;

    RETURN v_count;
END;
$$;

-- Standard updated_at trigger
DROP TRIGGER IF EXISTS set_updated_at ON expense_types;
CREATE TRIGGER set_updated_at BEFORE UPDATE ON expense_types FOR EACH ROW EXECUTE FUNCTION trigger_set_timestamp();

DROP TRIGGER IF EXISTS set_updated_at ON expenses;
CREATE TRIGGER set_updated_at BEFORE UPDATE ON expenses FOR EACH ROW EXECUTE FUNCTION trigger_set_timestamp();
