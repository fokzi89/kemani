-- ============================================================
-- CREATE LAB REQUESTS TABLES
-- ============================================================

-- 1. Create lab_requests table
CREATE TABLE IF NOT EXISTS lab_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Link to healthcare provider and patient
    healthcare_provider_id UUID NOT NULL REFERENCES healthcare_providers(id) ON DELETE CASCADE,
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    
    -- Clinical Context
    clinical_notes TEXT,
    diagnosis TEXT,
    priority TEXT DEFAULT 'normal' CHECK (priority IN ('normal', 'urgent', 'emergency')),
    
    -- Status
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'sample_collected', 'in_progress', 'completed', 'cancelled')),
    
    -- Progress tracking
    is_paid BOOLEAN DEFAULT false,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Create lab_request_items table
CREATE TABLE IF NOT EXISTS lab_request_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lab_request_id UUID NOT NULL REFERENCES lab_requests(id) ON DELETE CASCADE,
    diagnostic_test_id UUID NOT NULL REFERENCES diagnostic_tests(id) ON DELETE RESTRICT,
    
    -- Item status
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'collected', 'processing', 'completed', 'failed')),
    
    -- Results
    result_text TEXT,
    result_value TEXT,
    result_unit TEXT,
    reference_range TEXT,
    result_file_url TEXT,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Add indexes
CREATE INDEX idx_lab_requests_provider ON lab_requests(healthcare_provider_id);
CREATE INDEX idx_lab_requests_patient ON lab_requests(patient_id);
CREATE INDEX idx_lab_requests_status ON lab_requests(status);
CREATE INDEX idx_lab_request_items_request ON lab_request_items(lab_request_id);
CREATE INDEX idx_lab_request_items_test ON lab_request_items(diagnostic_test_id);

-- 4. Enable RLS
ALTER TABLE lab_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE lab_request_items ENABLE ROW LEVEL SECURITY;

-- 5. RLS Policies
-- Providers can view their own lab requests
CREATE POLICY "Providers can view their lab requests"
ON lab_requests FOR SELECT
USING (
    healthcare_provider_id IN (
        SELECT id FROM healthcare_providers WHERE user_id = auth.uid()
    )
);

-- Providers can insert lab requests
CREATE POLICY "Providers can insert lab requests"
ON lab_requests FOR INSERT
WITH CHECK (
    healthcare_provider_id IN (
        SELECT id FROM healthcare_providers WHERE user_id = auth.uid()
    )
);

-- Similar for items
CREATE POLICY "Providers can view lab request items"
ON lab_request_items FOR SELECT
USING (
    lab_request_id IN (
        SELECT id FROM lab_requests WHERE healthcare_provider_id IN (
            SELECT id FROM healthcare_providers WHERE user_id = auth.uid()
        )
    )
);

CREATE POLICY "Providers can insert lab request items"
ON lab_request_items FOR INSERT
WITH CHECK (
    lab_request_id IN (
        SELECT id FROM lab_requests WHERE healthcare_provider_id IN (
            SELECT id FROM healthcare_providers WHERE user_id = auth.uid()
        )
    )
);
