import { NextRequest, NextResponse } from 'next/server';
import { createAdminClient } from '@/lib/supabase/server';
import { createClient } from '@/lib/supabase/server';

// POST - Customer OTP Request & Verification
export async function POST(request: NextRequest) {
    try {
        const { action, identifier, otp, tenantId } = await request.json();

        if (!action || !identifier || !tenantId) {
            return NextResponse.json(
                { error: 'Action, identifier, and tenantId are required' },
                { status: 400 }
            );
        }

        // 1. Send OTP
        if (action === 'send-otp') {
            // For Customer Auth, we might use a custom OTP system or Supabase Auth.
            // Using Supabase Auth creates "User" records in auth.users. 
            // We ideally want Customers to be in public.customers and not pollute auth.users which is for staff.
            // HOWEVER, for secure auth, using auth.users is best.
            // Strategy: Create auth user with metadata { role: 'customer', tenant_id: ... }
            // BUT, a customer might shop at multiple tenants. 
            // This complicates "Multi-Tenant" isolation if creating single auth user.
            // OR we use "Passwordless" via magic link/OTP for transient sessions.

            // SIMPLIFIED APPROACH for US3:
            // Use a simple custom OTP stored in the DB (hashed) or a temporary table.
            // Since we already have Termii for SMS and Supabase for Email, 
            // we can reuse them but manage the session manually via JWT or customized cookie?
            // Or simpler: Use Supabase Auth "Magic Link" / OTP but tag user as 'customer'.

            // Let's use Supabase Auth for robustness.
            const supabase = await createClient();

            const { error } = await supabase.auth.signInWithOtp({
                email: identifier, // Assuming email for now. Phone needs formatting.
                options: {
                    data: {
                        is_customer: true,
                        shopping_tenant_id: tenantId // Store context
                    }
                }
            });

            if (error) throw error;

            return NextResponse.json({ success: true, message: 'OTP sent' });
        }

        // 2. Verify OTP
        if (action === 'verify-otp') {
            if (!otp) {
                return NextResponse.json({ error: 'OTP is required' }, { status: 400 });
            }

            const supabase = await createClient();

            const { data: { session }, error } = await supabase.auth.verifyOtp({
                email: identifier,
                token: otp,
                type: 'email'
            });

            if (error) throw error;
            if (!session) throw new Error('Failed to create session');

            // Check if customer record exists, if not create it
            const adminClient = await createAdminClient();

            // Check existing profile
            const { data: customer } = await adminClient
                .from('customers')
                .select('id')
                .eq('email', identifier)
                .eq('tenant_id', tenantId) // Customers are scoped to tenant in this model?
                // "Multi-Tenant": Yes, usually customers are owned by the tenant.
                .maybeSingle();

            if (!customer) {
                // Create new customer profile
                // Note: This relies on Auth User ID not colliding if we use it?
                // Auth User ID is global. If customer shops at 2 stores, they are 1 Auth User.
                // But we need 2 Customer records (one per tenant). 
                // So we can't key Customer ID = Auth User ID directly if 1:N.
                // We should auto-generate Customer ID and link `auth_user_id` FK if we added it.
                // Check Customer model: We didn't add auth_user_id in T091. 
                // So we just rely on email matching for now or add it.
                // Let's just create the customer record by email if missing.

                await adminClient.from('customers').insert({
                    tenant_id: tenantId,
                    email: identifier,
                    full_name: 'Guest Customer', // Placeholder
                });
            }

            // Return session
            return NextResponse.json({ success: true, session });
        }

        return NextResponse.json({ error: 'Invalid action' }, { status: 400 });

    } catch (error: any) {
        console.error('Customer auth error:', error);
        return NextResponse.json(
            { error: error.message || 'Authentication failed' },
            { status: 500 }
        );
    }
}
