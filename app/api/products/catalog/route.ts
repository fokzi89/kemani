import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';
import { catalogService } from '@/lib/services/catalogService';

export async function GET(req: NextRequest) {
    try {
        const supabase = await createClient();
        const { data: { user }, error } = await supabase.auth.getUser();

        if (error || !user) {
            return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
        }

        const tenantId = user.user_metadata.tenant_id;
        if (!tenantId) {
            return NextResponse.json({ error: 'Tenant ID missing' }, { status: 400 });
        }

        const products = await catalogService.getCatalogProducts(tenantId);
        return NextResponse.json(products);

    } catch (error: any) {
        console.error('Catalog API Error', error);
        return NextResponse.json({ error: error.message || 'Internal Server Error' }, { status: 500 });
    }
}
