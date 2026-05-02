import { json } from '@sveltejs/kit';
import { supabase } from '$lib/supabase';

export async function GET({ locals }) {
    const { data: { session } } = await supabase.auth.getSession();
    if (!session) return json({ error: 'No session' });

    const { data: user } = await supabase
        .from('users')
        .select('*')
        .eq('id', session.user.id)
        .single();

    if (!user) return json({ error: 'No profile found for user', userId: session.user.id });

    if (!user.branch_id) return json({ error: 'No branch_id assigned to user', user });

    const { data: inventory, error: invError } = await supabase
        .from('branch_inventory')
        .select('*, products(*)')
        .eq('branch_id', user.branch_id)
        .limit(10);

    return json({
        status: 'success',
        userId: session.user.id,
        userProfile: user,
        inventoryCount: inventory?.length || 0,
        inventorySample: inventory,
        invError
    });
}
