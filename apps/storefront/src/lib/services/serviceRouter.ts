import { supabase } from '$lib/supabase';

/**
 * ServiceRouter - Automatic Service Routing
 * Feature: 004-tenant-referral-commissions
 *
 * Implements automatic routing logic:
 * - If referring tenant offers service → auto-route to them (no directory)
 * - If referring tenant doesn't offer service → show external directory
 *
 * Business Rules:
 * - One subdomain can represent multiple service types
 * - Auto-routing prevents showing directory when tenant can fulfill
 * - Self-provider scenarios have no referral commission
 */

export type ServiceType = 'pharmacy' | 'diagnostic' | 'consultation';

export interface RoutingResult {
	shouldAutoRoute: boolean;
	providerTenantId: string | null;
	providerName: string | null;
	showDirectory: boolean;
	message?: string;
}

export interface TenantServiceCapabilities {
	tenantId: string;
	tenantName: string;
	offersPharmacy: boolean;
	offersDiagnostic: boolean;
	offersConsultation: boolean;
}

export class ServiceRouter {
	/**
	 * Check if tenant offers a specific service
	 *
	 * @param tenantId - UUID of the tenant
	 * @param serviceType - Type of service to check
	 * @returns Boolean indicating if service is offered
	 *
	 * @example
	 * const canProvide = await ServiceRouter.checkTenantOffersService(
	 *   'fokz-uuid',
	 *   'pharmacy'
	 * );
	 * // true if Fokz Pharmacy offers pharmacy services
	 */
	static async checkTenantOffersService(
		tenantId: string,
		serviceType: ServiceType
	): Promise<boolean> {
		try {
			const { data, error } = await supabase.rpc('tenant_offers_service', {
				p_tenant_id: tenantId,
				p_service_type: serviceType
			});

			if (error) {
				console.error('Error checking service:', error);
				return false;
			}

			return data === true;
		} catch (err) {
			console.error('Exception checking tenant service:', err);
			return false;
		}
	}

	/**
	 * Determine routing for a service request
	 *
	 * AUTO-ROUTE: If referring tenant offers service
	 * DIRECTORY: If referring tenant doesn't offer service
	 *
	 * @param referringTenantId - Tenant from subdomain (fokz.kemani.com → Fokz UUID)
	 * @param serviceType - Type of service customer is requesting
	 * @returns RoutingResult with routing decision
	 *
	 * @example
	 * // Customer on fokz.kemani.com wants diagnostic test
	 * const routing = await ServiceRouter.getServiceProvider(
	 *   'fokz-uuid',
	 *   'diagnostic'
	 * );
	 *
	 * if (routing.shouldAutoRoute) {
	 *   // Route to fokz-uuid directly, no directory shown
	 *   redirectToProvider(routing.providerTenantId);
	 * } else {
	 *   // Show directory of diagnostic centers
	 *   showServiceDirectory('diagnostic');
	 * }
	 */
	static async getServiceProvider(
		referringTenantId: string | null,
		serviceType: ServiceType
	): Promise<RoutingResult> {
		// No referring tenant → always show directory
		if (!referringTenantId) {
			return {
				shouldAutoRoute: false,
				providerTenantId: null,
				providerName: null,
				showDirectory: true,
				message: 'No referring tenant - showing directory'
			};
		}

		try {
			const { data, error } = await supabase.rpc('get_service_provider', {
				p_referring_tenant_id: referringTenantId,
				p_service_type: serviceType
			});

			if (error) {
				console.error('Error getting service provider:', error);
				return {
					shouldAutoRoute: false,
					providerTenantId: null,
					providerName: null,
					showDirectory: true,
					message: 'Error occurred - showing directory'
				};
			}

			if (!data || data.length === 0) {
				return {
					shouldAutoRoute: false,
					providerTenantId: null,
					providerName: null,
					showDirectory: true,
					message: 'No routing data - showing directory'
				};
			}

			const result = data[0];

			return {
				shouldAutoRoute: result.should_auto_route,
				providerTenantId: result.provider_tenant_id,
				providerName: result.provider_name,
				showDirectory: !result.should_auto_route,
				message: result.should_auto_route
					? `Auto-routing to ${result.provider_name}`
					: 'Service not offered by referring tenant - showing directory'
			};
		} catch (err) {
			console.error('Exception getting service provider:', err);
			return {
				shouldAutoRoute: false,
				providerTenantId: null,
				providerName: null,
				showDirectory: true,
				message: 'Exception occurred - showing directory'
			};
		}
	}

	/**
	 * Get all service capabilities for a tenant
	 *
	 * @param tenantId - UUID of the tenant
	 * @returns TenantServiceCapabilities with all services offered
	 *
	 * @example
	 * const capabilities = await ServiceRouter.getTenantCapabilities('fokz-uuid');
	 * // { offersPharmacy: true, offersDiagnostic: true, offersConsultation: false }
	 */
	static async getTenantCapabilities(tenantId: string): Promise<TenantServiceCapabilities | null> {
		try {
			const { data, error } = await supabase
				.from('tenants')
				.select('id, name, services_offered')
				.eq('id', tenantId)
				.single();

			if (error || !data) {
				console.error('Error fetching tenant capabilities:', error);
				return null;
			}

			const servicesOffered = data.services_offered || [];

			return {
				tenantId: data.id,
				tenantName: data.name,
				offersPharmacy: servicesOffered.includes('pharmacy'),
				offersDiagnostic: servicesOffered.includes('diagnostic'),
				offersConsultation: servicesOffered.includes('consultation')
			};
		} catch (err) {
			console.error('Exception fetching tenant capabilities:', err);
			return null;
		}
	}

	/**
	 * Update tenant's service offerings
	 *
	 * @param tenantId - UUID of the tenant
	 * @param services - Array of services to offer
	 * @returns Boolean indicating success
	 *
	 * @example
	 * await ServiceRouter.updateTenantServices('fokz-uuid', ['pharmacy', 'diagnostic']);
	 */
	static async updateTenantServices(
		tenantId: string,
		services: ServiceType[]
	): Promise<boolean> {
		try {
			const { error } = await supabase
				.from('tenants')
				.update({ services_offered: services })
				.eq('id', tenantId);

			if (error) {
				console.error('Error updating tenant services:', error);
				return false;
			}

			return true;
		} catch (err) {
			console.error('Exception updating tenant services:', err);
			return false;
		}
	}

	/**
	 * Check if a transaction is a self-provider scenario
	 *
	 * Self-provider: provider_tenant_id === referring_tenant_id
	 * In this case, no referral commission is earned
	 *
	 * @param providerTenantId - Tenant providing the service
	 * @param referringTenantId - Tenant from subdomain/session
	 * @returns Boolean indicating if self-provider
	 *
	 * @example
	 * const isSelf = ServiceRouter.isSelfProvider('fokz-uuid', 'fokz-uuid');
	 * // true - Fokz selling own products, no referral commission
	 */
	static isSelfProvider(
		providerTenantId: string | null,
		referringTenantId: string | null
	): boolean {
		if (!providerTenantId || !referringTenantId) {
			return false;
		}

		return providerTenantId === referringTenantId;
	}

	/**
	 * Determine if referral commission should be awarded
	 *
	 * Commission awarded when:
	 * - Referring tenant exists
	 * - Provider is different from referrer (not self-provider)
	 *
	 * @param providerTenantId - Tenant providing the service
	 * @param referringTenantId - Tenant from subdomain/session
	 * @returns Boolean indicating if referral commission applies
	 */
	static shouldAwardReferralCommission(
		providerTenantId: string | null,
		referringTenantId: string | null
	): boolean {
		if (!referringTenantId) {
			return false; // No referrer at all
		}

		if (!providerTenantId) {
			return false; // No provider
		}

		// Referral commission only when provider ≠ referrer
		return providerTenantId !== referringTenantId;
	}
}
