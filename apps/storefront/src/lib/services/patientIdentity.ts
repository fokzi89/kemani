import { supabase } from '$lib/supabase';

/**
 * Patient Identity Service
 * Manages unified patient profiles across multiple tenants
 */

export interface UnifiedPatientProfile {
	id: string;
	primary_email: string | null;
	primary_phone: string | null;
	primary_name: string | null;
	first_seen_at: string;
	last_seen_at: string;
	total_accounts: number;
	match_confidence: number;
	match_method: string;
	created_at: string;
	updated_at: string;
}

export interface PatientAccountLink {
	id: string;
	unified_patient_id: string;
	customer_id: string;
	tenant_id: string;
	email_at_link: string | null;
	phone_at_link: string | null;
	name_at_link: string | null;
	is_primary_account: boolean;
	linked_at: string;
	linked_by: string;
}

export interface CrossTenantConsent {
	id: string;
	unified_patient_id: string;
	share_medical_history: boolean;
	share_prescriptions: boolean;
	share_consultation_notes: boolean;
	share_purchase_history: boolean;
	share_with_pharmacies: boolean;
	share_with_labs: boolean;
	share_with_doctors: boolean;
	consented_at: string;
	consent_method: string;
	consent_version: string;
	updated_at: string;
}

export interface LinkedAccount {
	customer_id: string;
	tenant_id: string;
	tenant_name: string;
	email: string;
	phone: string;
	linked_at: string;
}

export interface PatientHistoryEvent {
	event_type: 'consultation' | 'purchase';
	event_id: string;
	event_date: string;
	tenant_name: string;
	description: string;
	amount: number;
}

export class PatientIdentityService {
	/**
	 * Get unified patient profile for a customer
	 */
	static async getUnifiedProfile(customerId: string): Promise<UnifiedPatientProfile | null> {
		try {
			// First get the unified patient ID
			const { data: link } = await supabase
				.from('patient_account_links')
				.select('unified_patient_id')
				.eq('customer_id', customerId)
				.single();

			if (!link) {
				return null;
			}

			// Get the unified profile
			const { data: profile, error } = await supabase
				.from('unified_patient_profiles')
				.select('*')
				.eq('id', link.unified_patient_id)
				.single();

			if (error) {
				console.error('Error fetching unified profile:', error);
				return null;
			}

			return profile;
		} catch (err) {
			console.error('Error in getUnifiedProfile:', err);
			return null;
		}
	}

	/**
	 * Get all linked accounts for a customer across all tenants
	 */
	static async getAllLinkedAccounts(customerId: string): Promise<LinkedAccount[]> {
		try {
			const { data, error } = await supabase.rpc('get_all_customer_ids_for_patient', {
				p_customer_id: customerId
			});

			if (error) {
				console.error('Error fetching linked accounts:', error);
				return [];
			}

			return data || [];
		} catch (err) {
			console.error('Error in getAllLinkedAccounts:', err);
			return [];
		}
	}

	/**
	 * Get unified patient history across all tenants (consultations, purchases, etc.)
	 */
	static async getUnifiedHistory(customerId: string): Promise<PatientHistoryEvent[]> {
		try {
			const { data, error } = await supabase.rpc('get_unified_patient_history', {
				p_customer_id: customerId
			});

			if (error) {
				console.error('Error fetching unified history:', error);
				return [];
			}

			return data || [];
		} catch (err) {
			console.error('Error in getUnifiedHistory:', err);
			return [];
		}
	}

	/**
	 * Get patient's cross-tenant consent settings
	 */
	static async getConsent(customerId: string): Promise<CrossTenantConsent | null> {
		try {
			// First get the unified patient ID
			const { data: link } = await supabase
				.from('patient_account_links')
				.select('unified_patient_id')
				.eq('customer_id', customerId)
				.single();

			if (!link) {
				return null;
			}

			// Get consent settings
			const { data: consent, error } = await supabase
				.from('cross_tenant_consents')
				.select('*')
				.eq('unified_patient_id', link.unified_patient_id)
				.single();

			if (error) {
				console.error('Error fetching consent:', error);
				return null;
			}

			return consent;
		} catch (err) {
			console.error('Error in getConsent:', err);
			return null;
		}
	}

	/**
	 * Update patient's cross-tenant consent settings
	 */
	static async updateConsent(
		customerId: string,
		consentUpdates: Partial<CrossTenantConsent>
	): Promise<{ success: boolean; error: any }> {
		try {
			// First get the unified patient ID
			const { data: link } = await supabase
				.from('patient_account_links')
				.select('unified_patient_id')
				.eq('customer_id', customerId)
				.single();

			if (!link) {
				return { success: false, error: 'No unified profile found' };
			}

			// Update consent
			const { error } = await supabase
				.from('cross_tenant_consents')
				.update({
					...consentUpdates,
					updated_at: new Date().toISOString()
				})
				.eq('unified_patient_id', link.unified_patient_id);

			if (error) {
				console.error('Error updating consent:', error);
				return { success: false, error };
			}

			return { success: true, error: null };
		} catch (err) {
			console.error('Error in updateConsent:', err);
			return { success: false, error: err };
		}
	}

	/**
	 * Check if patient can share specific data type
	 */
	static async canShareData(
		customerId: string,
		dataType: 'medical_history' | 'prescriptions' | 'consultation_notes' | 'purchase_history'
	): Promise<boolean> {
		try {
			const { data, error } = await supabase.rpc('can_share_patient_data', {
				p_customer_id: customerId,
				p_data_type: dataType
			});

			if (error) {
				console.error('Error checking data sharing consent:', error);
				return false;
			}

			return data || false;
		} catch (err) {
			console.error('Error in canShareData:', err);
			return false;
		}
	}

	/**
	 * Link a customer account to unified patient profile
	 * (Usually called automatically by AuthService, but can be called manually)
	 */
	static async linkAccount(
		customerId: string,
		tenantId: string,
		email: string,
		phone: string | null,
		name: string,
		linkedBy: 'auto' | 'manual' | 'user_merge' = 'auto'
	): Promise<{ success: boolean; unified_patient_id?: string; error?: any }> {
		try {
			const { data, error } = await supabase.rpc('link_customer_to_unified_patient', {
				p_customer_id: customerId,
				p_tenant_id: tenantId,
				p_email: email,
				p_phone: phone,
				p_name: name,
				p_linked_by: linkedBy
			});

			if (error) {
				console.error('Error linking account:', error);
				return { success: false, error };
			}

			return { success: true, unified_patient_id: data };
		} catch (err) {
			console.error('Error in linkAccount:', err);
			return { success: false, error: err };
		}
	}

	/**
	 * Get patient account links (all accounts for this unified patient)
	 */
	static async getPatientLinks(customerId: string): Promise<PatientAccountLink[]> {
		try {
			// First get the unified patient ID
			const { data: link } = await supabase
				.from('patient_account_links')
				.select('unified_patient_id')
				.eq('customer_id', customerId)
				.single();

			if (!link) {
				return [];
			}

			// Get all links for this unified patient
			const { data: links, error } = await supabase
				.from('patient_account_links')
				.select('*')
				.eq('unified_patient_id', link.unified_patient_id)
				.order('linked_at', { ascending: false });

			if (error) {
				console.error('Error fetching patient links:', error);
				return [];
			}

			return links || [];
		} catch (err) {
			console.error('Error in getPatientLinks:', err);
			return [];
		}
	}

	/**
	 * Calculate total lifetime value across all tenant accounts
	 */
	static async getTotalLifetimeValue(customerId: string): Promise<{
		total_spent: number;
		total_points: number;
		total_accounts: number;
	} | null> {
		try {
			const linkedAccounts = await this.getAllLinkedAccounts(customerId);

			if (linkedAccounts.length === 0) {
				return null;
			}

			const customerIds = linkedAccounts.map((acc) => acc.customer_id);

			// Get all customer records
			const { data: customers, error } = await supabase
				.from('customers')
				.select('total_purchases, loyalty_points')
				.in('id', customerIds);

			if (error) {
				console.error('Error calculating lifetime value:', error);
				return null;
			}

			const totalSpent = customers?.reduce((sum, c) => sum + (c.total_purchases || 0), 0) || 0;
			const totalPoints = customers?.reduce((sum, c) => sum + (c.loyalty_points || 0), 0) || 0;

			return {
				total_spent: totalSpent,
				total_points: totalPoints,
				total_accounts: linkedAccounts.length
			};
		} catch (err) {
			console.error('Error in getTotalLifetimeValue:', err);
			return null;
		}
	}
}
