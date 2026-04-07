-- Migration: Create healthcare_review_replies table
-- Created: 2026-04-06

CREATE TABLE IF NOT EXISTS public.healthcare_review_replies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    review_id UUID NOT NULL REFERENCES public.healthcare_reviews(id) ON DELETE CASCADE,
    provider_id UUID NOT NULL REFERENCES public.healthcare_providers(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- Constraints: Only one reply per review
    CONSTRAINT unique_review_reply UNIQUE (review_id)
);

-- Performance Indexes
CREATE INDEX IF NOT EXISTS idx_review_replies_review_id ON public.healthcare_review_replies(review_id);
CREATE INDEX IF NOT EXISTS idx_review_replies_provider_id ON public.healthcare_review_replies(provider_id);

-- Row-Level Security (RLS)
ALTER TABLE public.healthcare_review_replies ENABLE ROW LEVEL SECURITY;

-- Anyone can view replies to verified reviews
DROP POLICY IF EXISTS "Anyone can view replies" ON public.healthcare_review_replies;
CREATE POLICY "Anyone can view replies"
    ON public.healthcare_review_replies FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM public.healthcare_reviews 
        WHERE id = review_id AND is_verified = TRUE
    ));

-- Providers can manage their own replies
DROP POLICY IF EXISTS "Providers can create own replies" ON public.healthcare_review_replies;
CREATE POLICY "Providers can create own replies"
    ON public.healthcare_review_replies FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.healthcare_providers
            WHERE id = provider_id AND user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Providers can update own replies" ON public.healthcare_review_replies;
CREATE POLICY "Providers can update own replies"
    ON public.healthcare_review_replies FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM public.healthcare_providers
            WHERE id = provider_id AND user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Providers can delete own replies" ON public.healthcare_review_replies;
CREATE POLICY "Providers can delete own replies"
    ON public.healthcare_review_replies FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM public.healthcare_providers
            WHERE id = provider_id AND user_id = auth.uid()
        )
    );

-- Functions
CREATE OR REPLACE FUNCTION update_review_reply_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger
CREATE TRIGGER trg_update_review_reply_timestamp
    BEFORE UPDATE ON public.healthcare_review_replies
    FOR EACH ROW
    EXECUTE FUNCTION update_review_reply_timestamp();
