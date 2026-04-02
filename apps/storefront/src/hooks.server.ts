import { createServerClient } from '@supabase/ssr';
import { type Handle, redirect } from '@sveltejs/kit';
import { sequence } from '@sveltejs/kit/hooks';
import { PUBLIC_SUPABASE_URL, PUBLIC_SUPABASE_ANON_KEY } from '$env/static/public';
import { ReferralSessionService } from '$lib/services/referralSession';

const supabaseHandle: Handle = async ({ event, resolve }) => {
	/**
	 * Creates a Supabase client specific to this server request.
	 */
	event.locals.supabase = createServerClient(PUBLIC_SUPABASE_URL, PUBLIC_SUPABASE_ANON_KEY, {
		cookies: {
			get: (key) => event.cookies.get(key),
			set: (key, value, options) => {
				event.cookies.set(key, value, { ...options, path: '/' });
			},
			remove: (key, options) => {
				event.cookies.delete(key, { ...options, path: '/' });
			}
		}
	});

	/**
	 * Get session from Supabase
	 */
	const {
		data: { session }
	} = await event.locals.supabase.auth.getSession();

	event.locals.session = session;

	/**
	 * Auto-create customer record for OAuth users
	 * When user signs in with Google/Facebook, automatically create
	 * a customer record for the current tenant if it doesn't exist
	 */
	if (session?.user && event.locals.referringTenantId) {
		await ensureCustomerRecordForTenant(
			event.locals.supabase,
			session.user,
			event.locals.referringTenantId
		);
	}

	return resolve(event, {
		filterSerializedResponseHeaders(name) {
			return name === 'content-range';
		}
	});
};

const referralSessionHandle: Handle = async ({ event, resolve }) => {
	/**
	 * Extract subdomain from hostname to determine referring tenant
	 * Examples:
	 *   - fokz.kemani.com → "fokz"
	 *   - localhost:5173 → null (no subdomain)
	 *   - kemani.com → null (base domain)
	 */
	const extractSubdomain = (hostname: string): string | null => {
		// Remove port if present
		const hostWithoutPort = hostname.split(':')[0];

		// Split by dots
		const parts = hostWithoutPort.split('.');

		// For plain "localhost", no subdomain
		if (hostWithoutPort === 'localhost' && parts.length === 1) {
			return null;
		}

		// Support "sub.localhost"
		if (hostWithoutPort.endsWith('.localhost') && parts.length === 2) {
			return parts[0];
		}

		// For domains like "subdomain.domain.com", extract "subdomain"
		if (parts.length >= 3) {
			return parts[0];
		}

		// For "domain.com" (2 parts), no subdomain
		return null;
	};

	const subdomain = extractSubdomain(event.url.hostname);

	// Initialize referringTenantId as null
	event.locals.referringTenantId = null;

	// If there's a subdomain, handle referral session tracking
	if (subdomain) {
		const sessionCookie = event.cookies.get('referral_session');

		if (sessionCookie) {
			// Validate existing session
			const session = await ReferralSessionService.getSessionByToken(sessionCookie);

			if (session) {
				// Session is valid, refresh activity timestamp
				await ReferralSessionService.refreshSession(sessionCookie);
				event.locals.referringTenantId = session.referring_tenant_id;
			} else {
				// Session expired or invalid, create new one
				const tenantId = await lookupTenantBySubdomain(event.locals.supabase, subdomain);

				if (tenantId) {
					// Always set the tenant ID so the storefront loads
					event.locals.referringTenantId = tenantId;
					
					const result = await ReferralSessionService.createSession(
						tenantId,
						event.locals.session?.user?.id || null
					);

					if (result) {
						// Set HTTP-only, secure cookie for 24 hours
						event.cookies.set('referral_session', result.token, {
							path: '/',
							httpOnly: true,
							secure: process.env.NODE_ENV === 'production',
							sameSite: 'lax',
							maxAge: 60 * 60 * 24 // 24 hours
						});
					}
				}
			}
		} else {
			// No session cookie, create new session
			const tenantId = await lookupTenantBySubdomain(event.locals.supabase, subdomain);

			if (tenantId) {
				// Always set the tenant ID so the storefront loads
				event.locals.referringTenantId = tenantId;

				const result = await ReferralSessionService.createSession(
					tenantId,
					event.locals.session?.user?.id || null
				);

				if (result) {
					event.cookies.set('referral_session', result.token, {
						path: '/',
						httpOnly: true,
						secure: process.env.NODE_ENV === 'production',
						sameSite: 'lax',
						maxAge: 60 * 60 * 24
					});
				}
			}
		}
	}

	return resolve(event);
};

/**
 * Helper: Lookup tenant ID by subdomain or slug
 * Queries the tenants table to find tenant_id for a given subdomain
 * Tries subdomain first, then falls back to slug for backwards compatibility
 */
async function lookupTenantBySubdomain(supabase: any, subdomain: string): Promise<string | null> {
	console.log(`[Hooks] Looking up tenant for subdomain: "${subdomain}"`);
	try {
		// Try subdomain first
		const { data: bySubdomain, error: subdomainError } = await supabase
			.from('tenants')
			.select('id')
			.eq('subdomain', subdomain)
			.single();

		if (!subdomainError && bySubdomain) {
			console.log(`[Hooks] Found tenant by subdomain: ${bySubdomain.id}`);
			return bySubdomain.id;
		}

		if (subdomainError && subdomainError.code !== 'PGRST116') {
			console.warn(`[Hooks] Supabase error (subdomain lookup):`, subdomainError);
		}

		// Fall back to slug for backwards compatibility
		const { data: bySlug, error: slugError } = await supabase
			.from('tenants')
			.select('id')
			.eq('slug', subdomain)
			.single();

		if (!slugError && bySlug) {
			console.log(`[Hooks] Found tenant by slug: ${bySlug.id}`);
			return bySlug.id;
		}

		if (slugError && slugError.code !== 'PGRST116') {
			console.warn(`[Hooks] Supabase error (slug lookup):`, slugError);
		}

		console.warn(`[Hooks] No tenant found for subdomain/slug: "${subdomain}"`);
		return null;
	} catch (err) {
		console.error('[Hooks] Exception in lookupTenantBySubdomain:', err);
		return null;
	}
}

/**
 * Helper: Ensure customer record exists for OAuth user on current tenant
 * Creates customer record and links to unified patient profile
 */
async function ensureCustomerRecordForTenant(
	supabase: any,
	user: any,
	tenantId: string
): Promise<void> {
	try {
		// Check if customer record exists for this user + tenant
		const { data: existingCustomer } = await supabase
			.from('customers')
			.select('id')
			.eq('id', user.id)
			.eq('tenant_id', tenantId)
			.single();

		if (existingCustomer) {
			// Customer record already exists for this tenant
			return;
		}

		// Extract user info from OAuth metadata
		const email = user.email;
		const fullName = user.user_metadata?.full_name || user.user_metadata?.name || user.email?.split('@')[0] || 'Customer';
		const phone = user.user_metadata?.phone || user.phone || '';

		// Create customer record for this tenant
		const { error: insertError } = await supabase
			.from('customers')
			.insert({
				id: user.id,
				tenant_id: tenantId,
				email: email,
				full_name: fullName,
				phone: phone,
				loyalty_points: 0
			});

		if (insertError && insertError.code !== '23505') {
			// Ignore duplicate key errors
			console.error('Error creating customer record:', insertError);
			return;
		}

		// Link customer to unified patient profile
		const { error: linkError } = await supabase.rpc('link_customer_to_unified_patient', {
			p_customer_id: user.id,
			p_tenant_id: tenantId,
			p_email: email,
			p_phone: phone || null,
			p_name: fullName,
			p_linked_by: 'oauth'
		});

		if (linkError) {
			console.error('Error linking customer to unified patient:', linkError);
		}
	} catch (err) {
		console.error('Error in ensureCustomerRecordForTenant:', err);
	}
}

const authGuard: Handle = async ({ event, resolve }) => {
	// Define protected routes
	const protectedRoutes = [
		'/checkout',
		'/profile',
		'/orders'
	];

	// Check if the current route is protected
	const isProtectedRoute = protectedRoutes.some((route) =>
		event.url.pathname.startsWith(route)
	);

	// If protected and no session, redirect to login
	if (isProtectedRoute && !event.locals.session) {
		throw redirect(303, `/auth/login?redirect=${encodeURIComponent(event.url.pathname)}`);
	}

	return resolve(event);
};

export const handle: Handle = sequence(supabaseHandle, referralSessionHandle, authGuard);
