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
		const hostname = locals.hostname || '';
		console.warn(`[Marketplace Layout] No tenantId found. hostname: ${hostname}`);

		// Extract subdomain from hostname (e.g. "ade-ventures.localhost:5173" → "ade-ventures")
		const hostWithoutPort = hostname.split(':')[0];
		const parts = hostWithoutPort.split('.');
		let subdomainFromHost: string | null = null;
		if (hostWithoutPort.endsWith('.localhost') && parts.length === 2) {
			subdomainFromHost = parts[0];
		} else if (parts.length >= 3) {
			subdomainFromHost = parts[0];
		}

		if (subdomainFromHost) {
			// Try subdomain column, then slug column
			const { data: bySubdomain } = await supabase.from('tenants').select('id').eq('subdomain', subdomainFromHost).single();
			if (bySubdomain) {
				tenantId = bySubdomain.id;
			} else {
				const { data: bySlug } = await supabase.from('tenants').select('id').eq('slug', subdomainFromHost).single();
				if (bySlug) tenantId = bySlug.id;
			}
		}

		// Last-resort fallback: first tenant (bare localhost with no subdomain)
		if (!tenantId && hostname.includes('localhost')) {
			const { data: defaultTenant } = await supabase.from('tenants').select('id').limit(1).single();
			if (defaultTenant) tenantId = defaultTenant.id;
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
			allowDoctorPartnerShip, ai_is_enabled,
			slogan, hero_title, hero_subtitle, about_us,
			branches!tenant_id(id, name, address, tax_rate, delivery_enabled)
		`)
		.eq('id', tenantId)
		.is('deleted_at', null)
		.single();

	if (tenantError || !tenant) {
		console.error('[Marketplace Layout] Tenant Fetch Error:', tenantError);
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
			ai_is_enabled: tenant.ai_is_enabled ?? false,
			services_offered: tenant.services_offered || [],
			ecommerce_settings: tenant.ecommerce_settings || {},
			allowDoctorPartnerShip: tenant.allowDoctorPartnerShip ?? true,
			banner_url: (tenant.ecommerce_settings as any)?.banner_url || null,
			description: (tenant.ecommerce_settings as any)?.description || 'Your neighborhood store.',
			slogan: tenant.slogan,
			hero_title: tenant.hero_title,
			hero_subtitle: tenant.hero_subtitle,
			about_us: tenant.about_us,
			branches: ((tenant.branches as any[]) || []).map((b: any) => ({
				id: b.id,
				name: b.name,
				address: b.address,
				tax_rate: b.tax_rate || 0,
				delivery_enabled: b.delivery_enabled ?? true
			}))
		}
	};
}
