-- Migration: Create healthcare_review_reports table
-- Created: 2026-04-18

CREATE TABLE IF NOT EXISTS public.healthcare_review_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    review_id UUID NOT NULL REFERENCES public.healthcare_reviews(id) ON DELETE CASCADE,
    reporter_id UUID NOT NULL REFERENCES public.healthcare_providers(id) ON DELETE CASCADE,
    reason TEXT NOT NULL,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'reviewed', 'resolved', 'dismissed')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Performance Indexes
CREATE INDEX IF NOT EXISTS idx_review_reports_review_id ON public.healthcare_review_reports(review_id);
CREATE INDEX IF NOT EXISTS idx_review_reports_reporter_id ON public.healthcare_review_reports(reporter_id);

-- Row-Level Security (RLS)
ALTER TABLE public.healthcare_review_reports ENABLE ROW LEVEL SECURITY;

-- Providers can manage their own reports
DROP POLICY IF EXISTS "Providers can create own reports" ON public.healthcare_review_reports;
CREATE POLICY "Providers can create own reports"
    ON public.healthcare_review_reports FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.healthcare_providers
            WHERE id = reporter_id AND user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Providers can view own reports" ON public.healthcare_review_reports;
CREATE POLICY "Providers can view own reports"
    ON public.healthcare_review_reports FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.healthcare_providers
            WHERE id = reporter_id AND user_id = auth.uid()
        )
    );

-- Functions
CREATE OR REPLACE FUNCTION update_review_report_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger
CREATE TRIGGER trg_update_review_report_timestamp
    BEFORE UPDATE ON public.healthcare_review_reports
    FOR EACH ROW
    EXECUTE FUNCTION update_review_report_timestamp();
