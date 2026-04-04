import { error } from '@sveltejs/kit';
import { supabase } from '$lib/supabase';

export async function load({ locals, params }) {
	// Identify the tenant for the entire marketplace section
	let tenantId = locals.referringTenantId;
	let slug = params.slug;

	if (!tenantId && slug) {
		const isUUID = /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/.test(slug);
		const { data: tenantRef } = isUUID 
		  ? await supabase.from('tenants').select('id').eq('id', slug).single()
		  : await supabase.from('tenants').select('id').eq('slug', slug).single();
		  
		if (tenantRef) tenantId = tenantRef.id;
	}

	if (!tenantId) {
		console.warn(`[Marketplace Layout] No tenantId found. locals.referringTenantId: ${locals.referringTenantId}, slug: ${slug}, hostname: ${locals.hostname || 'unknown'}`);
		
		// Fallback for local development if no tenant found
		if (locals.hostname?.includes('localhost')) {
			console.log('[Marketplace Layout] Localhost detected, attempting fallback to default tenant...');
			const { data: defaultTenant } = await supabase.from('tenants').select('id').limit(1).single();
			if (defaultTenant) {
				tenantId = defaultTenant.id;
				console.log(`[Marketplace Layout] Fallback successful: ${tenantId}`);
			}
		}
	}

	if (!tenantId) {
		throw error(404, 'Storefront context not found. Please visit via a valid store subdomain or path.');
	}

	// Fetch full tenant data for the layout (Header, Footer, Branding)
	const { data: tenant, error: tenantError } = await supabase
		.from('tenants')
		.select(`
			id, name, slug, logo_url, brand_color,
			ecommerce_enabled, subdomain, custom_domain,
			ecommerce_settings, services_offered,
			branches!tenant_id(id, name, address)
		`)
		.eq('id', tenantId)
		.is('deleted_at', null)
		.single();

	if (tenantError || !tenant) {
		throw error(404, 'Storefront data not found');
	}

	return {
		storefront: {
			id: tenant.id,
			slug: tenant.slug,
			name: tenant.name,
			logo_url: tenant.logo_url,
			brand_color: tenant.brand_color || '#4f46e5',
			subdomain: tenant.subdomain,
			services_offered: tenant.services_offered || [],
			ecommerce_settings: tenant.ecommerce_settings || {},
			banner_url: (tenant.ecommerce_settings as any)?.banner_url || null,
			description: (tenant.ecommerce_settings as any)?.description || 'Your neighborhood store.',
			branches: ((tenant.branches as any[]) || []).map((b: any) => ({
				id: b.id,
				name: b.name,
				address: b.address
			}))
		}
	};
}
