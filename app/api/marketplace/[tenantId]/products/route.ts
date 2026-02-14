import { NextRequest, NextResponse } from 'next/server';
import { MarketplaceService } from '@/lib/pos/marketplace';

// GET - Public product listing for a tenant
export async function GET(
    request: NextRequest,
    { params }: { params: Promise<{ tenantId: string }> }
) {
    try {
        const { tenantId } = await params;

        // Optional: Support lookup by slug if tenantId param is actually a slug
        // But route is [tenantId], so typically it's ID. 
        // If the frontend uses slug, we might need to resolve it.
        // For now, let's assume the frontend passes the ID or we try to resolve if it looks like a slug.
        // Actually, safer to treat as ID. If we want slug support, we'd check if it's a UUID.
        // Let's implement a simple check: if not UUID, treat as slug.

        const isUuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(tenantId);

        let resolvedTenantId = tenantId;

        if (!isUuid) {
            try {
                resolvedTenantId = await MarketplaceService.getTenantIdBySlug(tenantId);
            } catch (e) {
                return NextResponse.json(
                    { error: 'Store not found' },
                    { status: 404 }
                );
            }
        }

        const { searchParams } = new URL(request.url);
        const category = searchParams.get('category') || undefined;

        const products = await MarketplaceService.getStorefrontProducts(resolvedTenantId, category);

        // Also fetch storefront branding details to return in metadata or separate call? 
        // Usually separate call or combined. Let's return just products here as the endpoint is .../products.

        return NextResponse.json({ products });
    } catch (error: any) {
        console.error('Get storefront products error:', error);
        return NextResponse.json(
            { error: error.message || 'Failed to get products' },
            { status: 500 }
        );
    }
}
