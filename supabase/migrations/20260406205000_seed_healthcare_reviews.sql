-- Migration: Seed healthcare reviews for testing
-- Created: 2026-04-06

DO $$
DECLARE
    v_provider_id UUID;
    v_patient_id UUID;
    v_count INT;
BEGIN
    -- Get the first provider
    SELECT id INTO v_provider_id FROM public.healthcare_providers LIMIT 1;
    
    IF v_provider_id IS NOT NULL THEN
        -- Check if reviews already exist
        SELECT COUNT(*) INTO v_count FROM public.healthcare_reviews WHERE provider_id = v_provider_id;
        
        IF v_count = 0 THEN
            -- Create a few reviews
            -- We try to find users from auth.users (excluding the provider's user_id if possible)
            FOR i IN 0..4 LOOP
                SELECT id INTO v_patient_id 
                FROM auth.users 
                WHERE id NOT IN (SELECT user_id FROM public.healthcare_providers WHERE id = v_provider_id)
                OFFSET i LIMIT 1;
                
                IF v_patient_id IS NOT NULL THEN
                    INSERT INTO public.healthcare_reviews (
                        provider_id,
                        patient_id,
                        rating,
                        comment,
                        is_verified,
                        created_at
                    )
                    VALUES (
                        v_provider_id,
                        v_patient_id,
                        CASE (i % 5)
                            WHEN 0 THEN 5 
                            WHEN 1 THEN 4 
                            WHEN 2 THEN 5 
                            WHEN 3 THEN 3 
                            ELSE 5 
                        END,
                        CASE (i % 5)
                            WHEN 0 THEN 'Excellent doctor, very attentive and professional. The consultation was thorough.'
                            WHEN 1 THEN 'Good experience overall. The doctor was knowledgeable, though the clinic was quite busy.'
                            WHEN 2 THEN 'Very helpful consultation. All my questions were answered clearly. Highly recommended!'
                            WHEN 3 THEN 'Decent service, but I felt the appointment was a bit rushed.'
                            ELSE 'Five stars! Best medical professional I have visited in a long time.'
                        END,
                        TRUE,
                        NOW() - (i || ' days')::interval
                    )
                    ON CONFLICT (patient_id, provider_id) DO NOTHING;
                END IF;
            END LOOP;
            
            -- Add one sample reply
            DECLARE
                v_review_id UUID;
            BEGIN
                SELECT id INTO v_review_id 
                FROM public.healthcare_reviews 
                WHERE provider_id = v_provider_id 
                LIMIT 1;
                
                IF v_review_id IS NOT NULL THEN
                    INSERT INTO public.healthcare_review_replies (
                        review_id,
                        provider_id,
                        content,
                        created_at
                    )
                    VALUES (
                        v_review_id,
                        v_provider_id,
                        'Thank you so much for your positive feedback! I''m glad I could help with your recovery.',
                        NOW()
                    )
                    ON CONFLICT (review_id) DO NOTHING;
                END IF;
            END;
        END IF;
    END IF;
END $$;
