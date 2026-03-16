import { supabase } from '$lib/supabase';

/**
 * Tenant Detection Service
 * Automatically detects the current tenant from the subdomain or custom domain
 */

export interface TenantInfo {
	id: string;
	slug: string;
	subdomain: string | null;
	business_name: string;
	services_offered: string[];
	city: string | null;
}

export class TenantDetectionService {
	/**
	 * Extract subdomain from hostname
	 * Examples:
	 * - fokz.kemani.com → fokz
	 * - clinic.kemani.com → clinic
	 * - localhost:5173 → null
	 * - kemani.com → null
	 */
	static extractSubdomain(hostname: string): string | null {
		// Remove port if present
		const domain = hostname.split(':')[0];

		// Split by dots
		const parts = domain.split('.');

		// If localhost or IP address, no subdomain
		if (domain === 'localhost' || /^\d+\.\d+\.\d+\.\d+$/.test(domain)) {
			return null;
		}

		// If only 2 parts (e.g., kemani.com), no subdomain
		if (parts.length <= 2) {
			return null;
		}

		// Return first part as subdomain (e.g., fokz from fokz.kemani.com)
		return parts[0];
	}

	/**
	 * Detect tenant from current hostname
	 * Works with both subdomains and custom domains
	 */
	static async detectTenant(hostname: string): Promise<TenantInfo | null> {
		try {
			const subdomain = this.extractSubdomain(hostname);
			const fullDomain = hostname.split(':')[0]; // Remove port

			// Try to find tenant by subdomain first
			if (subdomain) {
				const { data: tenantBySubdomain, error: subdomainError } = await supabase
					.from('tenants')
					.select('id, slug, subdomain, business_name, services_offered, city')
					.eq('subdomain', subdomain)
					.single();

				if (!subdomainError && tenantBySubdomain) {
					return tenantBySubdomain as TenantInfo;
				}

				// Also try by slug for backwards compatibility
				const { data: tenantBySlug, error: slugError } = await supabase
					.from('tenants')
					.select('id, slug, subdomain, business_name, services_offered, city')
					.eq('slug', subdomain)
					.single();

				if (!slugError && tenantBySlug) {
					return tenantBySlug as TenantInfo;
				}
			}

			// Try to find tenant by custom domain
			// TODO: Add custom_domain column to tenants table in future migration
			// For now, we'll use subdomain/slug matching only

			return null;
		} catch (err) {
			console.error('Error detecting tenant:', err);
			return null;
		}
	}

	/**
	 * Get tenant from browser window location
	 * Client-side only
	 */
	static async detectTenantFromWindow(): Promise<TenantInfo | null> {
		if (typeof window === 'undefined') {
			return null;
		}

		return this.detectTenant(window.location.hostname);
	}

	/**
	 * Create referral session for detected tenant
	 * Automatically sets up referral tracking when visiting a tenant subdomain
	 */
	static async createReferralSession(tenantId: string): Promise<string | null> {
		try {
			const { data, error } = await supabase.rpc('create_referral_session', {
				p_referring_tenant_id: tenantId,
				p_source: 'subdomain_visit'
			});

			if (error) {
				console.error('Error creating referral session:', error);
				return null;
			}

			return data; // Returns session token
		} catch (err) {
			console.error('Error creating referral session:', err);
			return null;
		}
	}

	/**
	 * Set referral session cookie
	 * This makes the referral persist across page visits
	 */
	static setReferralCookie(sessionToken: string, expiresInHours: number = 24): void {
		if (typeof document === 'undefined') return;

		const expiryDate = new Date();
		expiryDate.setHours(expiryDate.getHours() + expiresInHours);

		document.cookie = `referral_session=${sessionToken}; expires=${expiryDate.toUTCString()}; path=/; SameSite=Lax`;
	}

	/**
	 * Get current referral session token from cookie
	 */
	static getReferralCookie(): string | null {
		if (typeof document === 'undefined') return null;

		const cookies = document.cookie.split(';');
		for (const cookie of cookies) {
			const [name, value] = cookie.trim().split('=');
			if (name === 'referral_session') {
				return value;
			}
		}
		return null;
	}

	/**
	 * Initialize tenant detection and referral tracking
	 * Call this on app startup (in +layout.svelte)
	 */
	static async initializeTenantTracking(): Promise<{
		tenant: TenantInfo | null;
		sessionToken: string | null;
	}> {
		// Check if we already have a referral session
		const existingSession = this.getReferralCookie();

		if (existingSession) {
			// Validate existing session is still for current tenant
			const tenant = await this.detectTenantFromWindow();
			return { tenant, sessionToken: existingSession };
		}

		// Detect current tenant
		const tenant = await this.detectTenantFromWindow();

		if (!tenant) {
			// No tenant detected (e.g., localhost without subdomain)
			return { tenant: null, sessionToken: null };
		}

		// Create referral session for this tenant
		const sessionToken = await this.createReferralSession(tenant.id);

		if (sessionToken) {
			// Set cookie to persist referral across pages
			this.setReferralCookie(sessionToken, 24); // 24 hour session
		}

		return { tenant, sessionToken };
	}
}
