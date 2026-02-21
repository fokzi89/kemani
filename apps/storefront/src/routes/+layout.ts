import { createSupabase } from '$lib/services/supabase';
import type { LayoutLoad } from './$types';

export const load: LayoutLoad = async ({ fetch, data, depends }) => {
    depends('supabase:auth');

    const supabase = createSupabase(fetch, data);

    const {
        data: { session },
    } = await supabase.auth.getSession();

    const {
        data: { user },
    } = await supabase.auth.getUser();

    return { supabase, session, user };
};
