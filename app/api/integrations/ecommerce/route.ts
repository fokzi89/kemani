import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/client';
import { WooCommerceService } from '@/lib/integrations/woocommerce';

export async function GET(req: NextRequest) {
    const supabase = await createClient();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

    const { data: userProfile } = await supabase.from('users').select('tenant_id').eq('id', user.id).single();
    if (!userProfile?.tenant_id) return NextResponse.json({ error: 'Tenant context missing' }, { status: 400 });

    const { data, error } = await supabase
        .from('ecommerce_connections')
        .select('*')
        .eq('tenant_id', userProfile.tenant_id);

    if (error) {
        // If table doesn't exist, return empty array (Graceful degradation for MVP if migration missed)
        if (error.code === '42P01') return NextResponse.json([]);
        return NextResponse.json({ error: error.message }, { status: 500 });
    }

    return NextResponse.json(data);
}

export async function POST(req: NextRequest) {
    try {
        const supabase = await createClient();
        const { data: { user } } = await supabase.auth.getUser();
        if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

        const { data: userProfile } = await supabase.from('users').select('tenant_id').eq('id', user.id).single();
        if (!userProfile?.tenant_id) return NextResponse.json({ error: 'Tenant context missing' }, { status: 400 });

        const body = await req.json();
        const { platform, storeUrl, consumerKey, consumerSecret } = body;

        // 1. Validation
        if (!storeUrl || !consumerKey || !consumerSecret) {
            return NextResponse.json({ error: 'Missing credentials' }, { status: 400 });
        }

        // 2. Test Connection
        if (platform === 'woocommerce') {
            const wc = new WooCommerceService(storeUrl, consumerKey, consumerSecret);
            const isValid = await wc.testConnection();
            if (!isValid) {
                return NextResponse.json({ error: 'Connection failed. Please check credentials and URL.' }, { status: 400 });
            }
        }

        // 3. Save to DB
        const { data, error } = await supabase.from('ecommerce_connections').insert({
            tenant_id: userProfile.tenant_id,
            platform,
            store_url: storeUrl,
            consumer_key: consumerKey,
            consumer_secret: consumerSecret,
            is_active: true
        }).select().single();

        if (error) throw error;

        return NextResponse.json(data);
    } catch (error: any) {
        console.error('Create Integration Error', error);
        return NextResponse.json({ error: error.message || 'Internal Server Error' }, { status: 500 });
    }
}

export async function DELETE(req: NextRequest) {
    const supabase = await createClient();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

    const id = req.nextUrl.searchParams.get('id');
    if (!id) return NextResponse.json({ error: 'Missing ID' }, { status: 400 });

    const { error } = await supabase
        .from('ecommerce_connections')
        .delete()
        .eq('id', id);

    if (error) return NextResponse.json({ error: error.message }, { status: 500 });
    return NextResponse.json({ success: true });
}
