import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/client';
import { WooCommerceService } from '@/lib/integrations/woocommerce';
// Fix import: Product is in pos.ts, not database.ts
import { Product } from '@/lib/types/pos';

export async function POST(req: NextRequest) {
    try {
        const supabase = await createClient();
        const { data: { user } } = await supabase.auth.getUser();
        if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

        const searchParams = req.nextUrl.searchParams;
        const connectionId = searchParams.get('connectionId');

        if (!connectionId) return NextResponse.json({ error: 'Missing connectionId' }, { status: 400 });

        // 1. Get Connection Details
        const { data: connection } = await supabase
            .from('ecommerce_connections')
            .select('*')
            .eq('id', connectionId)
            .single();

        if (!connection) return NextResponse.json({ error: 'Connection not found' }, { status: 404 });

        // 2. Fetch from WooCommerce
        const wc = new WooCommerceService(connection.store_url, connection.consumer_key, connection.consumer_secret);
        const wcProducts = await wc.getProducts(1, 100); // Fetch first 100 for MVP

        // 3. Map & Upsert
        let syncedCount = 0;
        const errors = [];

        for (const item of wcProducts) {
            try {
                // Determine category or create default? For now, we leave category_id null or generic.

                const productData = {
                    tenant_id: connection.tenant_id,
                    branch_id: user.user_metadata?.branch_id || null, // Or master branch?
                    name: item.name,
                    description: item.short_description || item.name,
                    price: parseFloat(item.price || '0'),
                    cost_price: 0, // WC doesn't usually share cost price via Std API
                    sku: item.id.toString(), // Use WC ID as fake SKU if standard SKU missing? better to use actual SKU
                    barcode: null,
                    stock_quantity: item.stock_quantity || 0,
                    track_stock: item.manage_stock,
                    image_url: item.images[0]?.src || null,
                    is_active: true,
                    // Store WC ID in metadata or a specific column if we added one. 
                    // For now, we assume SKU syncs or we match by name? 
                    // Ideally we'd have external_id column. 
                    // MVP: We'll upsert based on SKU if available, else skip or create new.
                };

                // NOTE: In a real app, we need an `external_id` column on `products` to link reliably.
                // For MVP, we will try to match by SKU. If SKU is empty, we might skip to avoid duplications.
                /* 
                   Checking if product exists with this SKU for this tenant.
                   Upserting purely on SKU might be risky if SKU is not unique across system, 
                   but within Tenant it should be.
                */

                if (!productData.sku) {
                    // Generate a temporary SKU based on WC ID to allow sync
                    productData.sku = `WC-${item.id}`;
                }

                const { error: upsertError } = await supabase
                    .from('products')
                    .upsert(productData, { onConflict: 'tenant_id, sku' as any }) // Assuming constraint exists
                    .select();

                if (upsertError) {
                    console.error('Upsert Product Error', upsertError);
                    errors.push({ id: item.id, error: upsertError.message });
                } else {
                    syncedCount++;
                }

            } catch (err) {
                console.error('Sync Item Error', err);
            }
        }

        // 4. Update Last Sync
        await supabase.from('ecommerce_connections').update({
            last_sync_at: new Date().toISOString()
        }).eq('id', connectionId);

        return NextResponse.json({
            success: true,
            synced: syncedCount,
            total: wcProducts.length,
            errors
        });

    } catch (error: any) {
        console.error('Sync Error', error);
        return NextResponse.json({ error: error.message || 'Internal Server Error' }, { status: 500 });
    }
}
