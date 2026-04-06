-- Migration: Update Healthcare Provider Enhancements
-- Created: 2026-04-04

-- 1. Add missing columns to healthcare_providers table
ALTER TABLE public.healthcare_providers
ADD COLUMN IF NOT EXISTS medic_subscription_id UUID REFERENCES public.medic_subscriptions(id) ON DELETE SET NULL,
ADD COLUMN IF NOT EXISTS work_schedule JSONB DEFAULT '[]'::JSONB,
ADD COLUMN IF NOT EXISTS slot_settings JSONB DEFAULT '{"buffer": 0, "duration": 30, "breakTimes": []}'::JSONB,
ADD COLUMN IF NOT EXISTS marked_up_fees JSONB DEFAULT '{"chat": 0, "audio": 0, "video": 0, "office_visit": 0}'::JSONB,
ADD COLUMN IF NOT EXISTS sub_specialty TEXT,
ADD COLUMN IF NOT EXISTS preferred_languages TEXT[];

-- 2. Create the healthcare_reviews table
CREATE TABLE IF NOT EXISTS public.healthcare_reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    provider_id UUID NOT NULL REFERENCES public.healthcare_providers(id) ON DELETE CASCADE,
    patient_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    consultation_id UUID REFERENCES public.consultations(id) ON DELETE SET NULL,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    is_verified BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- Constraints
    CONSTRAINT unique_patient_provider_review UNIQUE (patient_id, provider_id)
);

-- 3. Performance Indexes
CREATE INDEX IF NOT EXISTS idx_reviews_provider_id ON public.healthcare_reviews(provider_id);
CREATE INDEX IF NOT EXISTS idx_reviews_patient_id ON public.healthcare_reviews(patient_id);
CREATE INDEX IF NOT EXISTS idx_reviews_rating ON public.healthcare_reviews(rating);
CREATE INDEX IF NOT EXISTS idx_reviews_created_at ON public.healthcare_reviews(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_providers_medic_subscription_id ON public.healthcare_providers(medic_subscription_id);
CREATE INDEX IF NOT EXISTS idx_providers_work_schedule ON public.healthcare_providers USING GIN (work_schedule);
CREATE INDEX IF NOT EXISTS idx_providers_slot_settings ON public.healthcare_providers USING GIN (slot_settings);
CREATE INDEX IF NOT EXISTS idx_providers_marked_up_fees ON public.healthcare_providers USING GIN (marked_up_fees);
CREATE INDEX IF NOT EXISTS idx_providers_languages ON public.healthcare_providers USING GIN (preferred_languages);

-- 4. Row-Level Security (RLS)
ALTER TABLE public.healthcare_reviews ENABLE ROW LEVEL SECURITY;

-- Public read access for verified reviews
DROP POLICY IF EXISTS "Anyone can view verified reviews" ON public.healthcare_reviews;
CREATE POLICY "Anyone can view verified reviews"
    ON public.healthcare_reviews FOR SELECT
    USING (is_verified = TRUE);

-- Patients can manage their own reviews
DROP POLICY IF EXISTS "Patients can create own reviews" ON public.healthcare_reviews;
CREATE POLICY "Patients can create own reviews"
    ON public.healthcare_reviews FOR INSERT
    WITH CHECK (auth.uid() = patient_id);

DROP POLICY IF EXISTS "Patients can update own reviews" ON public.healthcare_reviews;
CREATE POLICY "Patients can update own reviews"
    ON public.healthcare_reviews FOR UPDATE
    USING (auth.uid() = patient_id);

DROP POLICY IF EXISTS "Patients can delete own reviews" ON public.healthcare_reviews;
CREATE POLICY "Patients can delete own reviews"
    ON public.healthcare_reviews FOR DELETE
    USING (auth.uid() = patient_id);

-- 5. Synchronization Functions & Triggers
-- Automatically update provider stats (average_rating, total_reviews)
CREATE OR REPLACE FUNCTION update_provider_review_stats()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        UPDATE public.healthcare_providers
        SET 
            total_reviews = total_reviews + 1,
            average_rating = (
                SELECT ROUND(AVG(rating)::NUMERIC, 2)
                FROM public.healthcare_reviews
                WHERE provider_id = NEW.provider_id
            )
        WHERE id = NEW.provider_id;
    ELSIF (TG_OP = 'UPDATE') THEN
        UPDATE public.healthcare_providers
        SET 
            average_rating = (
                SELECT ROUND(AVG(rating)::NUMERIC, 2)
                FROM public.healthcare_reviews
                WHERE provider_id = NEW.provider_id
            )
        WHERE id = NEW.provider_id;
    ELSIF (TG_OP = 'DELETE') THEN
        UPDATE public.healthcare_providers
        SET 
            total_reviews = GREATEST(0, total_reviews - 1),
            average_rating = (
                SELECT COALESCE(ROUND(AVG(rating)::NUMERIC, 2), 0.00)
                FROM public.healthcare_reviews
                WHERE provider_id = OLD.provider_id
            )
        WHERE id = OLD.provider_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create the trigger
DROP TRIGGER IF EXISTS trg_update_provider_stats ON public.healthcare_reviews;
CREATE TRIGGER trg_update_provider_stats
    AFTER INSERT OR UPDATE OR DELETE ON public.healthcare_reviews
    FOR EACH ROW
    EXECUTE FUNCTION update_provider_review_stats();

-- 6. Comments
COMMENT ON TABLE public.healthcare_reviews IS 'Patient reviews and ratings for healthcare providers.';
COMMENT ON COLUMN public.healthcare_reviews.rating IS 'Numerical rating from 1 to 5.';
COMMENT ON COLUMN public.healthcare_reviews.is_verified IS 'Whether the review is verified (e.g. following a completed consultation).';
