-- Doctor Strike Logs Table
-- Logs reasons for strikes given to partner doctors
CREATE TABLE public.doctor_strike_logs (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    doctor_id uuid NOT NULL REFERENCES public.healthcare_providers(id) ON DELETE CASCADE,
    primary_doctor_id uuid NOT NULL REFERENCES public.healthcare_providers(id) ON DELETE CASCADE,
    reason text NOT NULL,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT doctor_strike_logs_pkey PRIMARY KEY (id)
);

-- Index for searching log history
CREATE INDEX idx_doctor_strike_logs_doctor ON public.doctor_strike_logs (doctor_id);
CREATE INDEX idx_doctor_strike_logs_primary ON public.doctor_strike_logs (primary_doctor_id);

-- Enable RLS
ALTER TABLE public.doctor_strike_logs ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Primary doctors can see their own logs, admins can see all
CREATE POLICY "Primary doctors see their own strike logs" 
ON public.doctor_strike_logs FOR SELECT 
USING (
    primary_doctor_id IN (
        SELECT id FROM public.healthcare_providers 
        WHERE user_id = auth.uid()
    )
);

CREATE POLICY "Primary doctors can create strike logs"
ON public.doctor_strike_logs FOR INSERT
WITH CHECK (
    primary_doctor_id IN (
        SELECT id FROM public.healthcare_providers 
        WHERE user_id = auth.uid()
    )
);

-- Grant permissions
GRANT ALL ON public.doctor_strike_logs TO authenticated;
GRANT ALL ON public.doctor_strike_logs TO service_role;
