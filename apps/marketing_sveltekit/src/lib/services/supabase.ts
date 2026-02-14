import { createClient } from '@supabase/supabase-js';

// For now, using placeholder values
// In production, these should come from environment variables
const SUPABASE_URL = import.meta.env.PUBLIC_SUPABASE_URL || 'https://placeholder.supabase.co';
const SUPABASE_ANON_KEY = import.meta.env.PUBLIC_SUPABASE_ANON_KEY || 'placeholder-key';

export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
