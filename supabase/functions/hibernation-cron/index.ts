import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3'

// Access environment variables
const SUPABASE_URL = Deno.env.get('SUPABASE_URL') || '';
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || '';

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

const HIBERNATION_THRESHOLD_DAYS = 90;

Deno.serve(async (req) => {
    try {
        // 1. Calculate threshold date
        const thresholdDate = new Date();
        thresholdDate.setDate(thresholdDate.getDate() - HIBERNATION_THRESHOLD_DAYS);
        const thresholdISO = thresholdDate.toISOString();

        console.log(`Running Hibernation Protocol. Threshold: ${thresholdISO}`);

        // 2. Identify active tenants with no recent activity
        // We assume 'tenants' has 'last_activity_at' and 'status'
        // If 'last_activity_at' is missing, we check 'updated_at' or rely on order history

        // First, find tenants who are currently 'active'
        const { data: activeTenants, error: fetchError } = await supabase
            .from('tenants')
            .select('id, business_name, last_activity_at')
            .eq('status', 'active')
            .lt('last_activity_at', thresholdISO);

        if (fetchError) {
            throw fetchError;
        }

        if (!activeTenants || activeTenants.length === 0) {
            return new Response(JSON.stringify({ message: 'No tenants to hibernate' }), {
                headers: { 'Content-Type': 'application/json' },
            });
        }

        console.log(`Found ${activeTenants.length} tenants eligible for hibernation.`);

        // 3. Hibernate them
        const updates = activeTenants.map(async (tenant) => {
            // Update status
            const { error: updateError } = await supabase
                .from('tenants')
                .update({ status: 'dormant', updated_at: new Date().toISOString() })
                .eq('id', tenant.id);

            if (updateError) {
                console.error(`Failed to hibernate tenant ${tenant.id}:`, updateError);
                return { id: tenant.id, status: 'failed', error: updateError.message };
            }

            // Notify owner (implied T051 logic call or direct email)
            // For now, just log
            console.log(`Hibernated tenant: ${tenant.business_name} (${tenant.id})`);
            return { id: tenant.id, status: 'hibernated' };
        });

        const results = await Promise.all(updates);

        return new Response(JSON.stringify({
            message: 'Hibernation protocol complete',
            processed: results.length,
            results
        }), {
            headers: { 'Content-Type': 'application/json' },
        });

    } catch (error) {
        console.error('Hibernation Error:', error);
        return new Response(JSON.stringify({ error: error.message }), {
            status: 500,
            headers: { 'Content-Type': 'application/json' },
        });
    }
})
