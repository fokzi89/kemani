import { supabase } from '$lib/supabase';
import type { User, Session, AuthError } from '@supabase/supabase-js';

export interface AuthResponse {
	user: User | null;
	session: Session | null;
	error: AuthError | null;
}

export interface SignUpData {
	email: string;
	password?: string;
	full_name: string;
	phone?: string;
	tenant_id?: string; // Optional tenant context from referral
}

export interface SignInData {
	email: string;
	password?: string;
	tenant_id?: string; // Optional tenant context from referral
}

export interface OTPSignInData {
	email: string;
	full_name?: string;
	phone?: string;
	tenant_id?: string; // Optional tenant context from referral
}

/**
 * Auth Service
 * Handles all authentication operations for customers and merchants
 */
export class AuthService {
	/**
	 * Sign up a new customer with email and password
	 */
	static async signUp(data: SignUpData): Promise<AuthResponse> {
		try {
			const { data: authData, error } = await supabase.auth.signUp({
				email: data.email,
				password: data.password,
				options: {
					data: {
						full_name: data.full_name,
						phone: data.phone,
						user_type: 'customer'
					}
				}
			});

			if (error) {
				return { user: null, session: null, error };
			}

			// Create customer record in database
			if (authData.user) {
				await this.createCustomerRecord(authData.user.id, data);
			}

			return {
				user: authData.user,
				session: authData.session,
				error: null
			};
		} catch (err) {
			return {
				user: null,
				session: null,
				error: err as AuthError
			};
		}
	}

	/**
	 * Sign in with email and password
	 */
	static async signIn(data: SignInData): Promise<AuthResponse> {
		try {
			const { data: authData, error } = await supabase.auth.signInWithPassword({
				email: data.email,
				password: data.password!
			});

			return {
				user: authData.user,
				session: authData.session,
				error
			};
		} catch (err) {
			return {
				user: null,
				session: null,
				error: err as AuthError
			};
		}
	}

	/**
	 * Send OTP to email for passwordless authentication
	 */
	static async sendOTP(data: OTPSignInData): Promise<{ success: boolean; error: AuthError | null }> {
		try {
			const { error } = await supabase.auth.signInWithOtp({
				email: data.email,
				options: {
					shouldCreateUser: true,
					data: {
						full_name: data.full_name,
						phone: data.phone,
						user_type: 'customer'
					},
					emailRedirectTo: `${window.location.origin}/auth/callback`
				}
			});

			if (error) {
				return { success: false, error };
			}

			return { success: true, error: null };
		} catch (err) {
			return {
				success: false,
				error: err as AuthError
			};
		}
	}

	/**
	 * Verify OTP code
	 */
	static async verifyOTP(
		email: string,
		token: string
	): Promise<AuthResponse> {
		try {
			const { data, error } = await supabase.auth.verifyOtp({
				email,
				token,
				type: 'email'
			});

			if (error) {
				return { user: null, session: null, error };
			}

			// Create customer record if it doesn't exist
			// Extract tenant_id from OTP data if provided
			if (data.user) {
				await this.ensureCustomerRecord(data.user, token as any); // Will get tenant from context
			}

			return {
				user: data.user,
				session: data.session,
				error: null
			};
		} catch (err) {
			return {
				user: null,
				session: null,
				error: err as AuthError
			};
		}
	}

	/**
	 * Sign out current user
	 */
	static async signOut(): Promise<{ error: AuthError | null }> {
		const { error } = await supabase.auth.signOut();
		return { error };
	}

	/**
	 * Get current session
	 */
	static async getSession(): Promise<{ session: Session | null; error: AuthError | null }> {
		const { data, error } = await supabase.auth.getSession();
		return { session: data.session, error };
	}

	/**
	 * Get current user
	 */
	static async getUser(): Promise<{ user: User | null; error: AuthError | null }> {
		const { data, error } = await supabase.auth.getUser();
		return { user: data.user, error };
	}

	/**
	 * Reset password (send reset email)
	 */
	static async resetPassword(email: string): Promise<{ error: AuthError | null }> {
		const { error } = await supabase.auth.resetPasswordForEmail(email, {
			redirectTo: `${window.location.origin}/auth/reset-password`
		});
		return { error };
	}

	/**
	 * Update password
	 */
	static async updatePassword(newPassword: string): Promise<{ error: AuthError | null }> {
		const { error } = await supabase.auth.updateUser({
			password: newPassword
		});
		return { error };
	}

	/**
	 * Check if user is authenticated
	 */
	static async isAuthenticated(): Promise<boolean> {
		const { session } = await this.getSession();
		return session !== null;
	}

	/**
	 * Get user type from metadata
	 */
	static async getUserType(): Promise<'customer' | 'merchant' | null> {
		const { user } = await this.getUser();
		return user?.user_metadata?.user_type || null;
	}

	/**
	 * Create customer record in database after signup
	 * Now includes multi-tenant patient identity linking
	 */
	private static async createCustomerRecord(userId: string, data: SignUpData): Promise<void> {
		try {
			// Get tenant_id from context or use first available tenant
			let tenantId = data.tenant_id;

			if (!tenantId) {
				const { data: tenants } = await supabase
					.from('tenants')
					.select('id')
					.limit(1)
					.single();

				if (!tenants) {
					console.error('No tenant found');
					return;
				}
				tenantId = tenants.id;
			}

			// Create customer record
			const { error: customerError } = await supabase.from('customers').insert({
				id: userId,
				tenant_id: tenantId,
				full_name: data.full_name,
				email: data.email,
				phone: data.phone,
				loyalty_points: 0
			});

			if (customerError) {
				console.error('Error creating customer record:', customerError);
				return;
			}

			// Link customer to unified patient profile
			const { error: linkError } = await supabase.rpc('link_customer_to_unified_patient', {
				p_customer_id: userId,
				p_tenant_id: tenantId,
				p_email: data.email,
				p_phone: data.phone || null,
				p_name: data.full_name,
				p_linked_by: 'auto'
			});

			if (linkError) {
				console.error('Error linking customer to unified patient:', linkError);
			}
		} catch (err) {
			console.error('Error in createCustomerRecord:', err);
		}
	}

	/**
	 * Ensure customer record exists in database (create if missing)
	 * Now includes multi-tenant patient identity linking
	 */
	private static async ensureCustomerRecord(user: User, tenantId?: string): Promise<void> {
		try {
			// Check if customer record exists for this tenant
			let existingCustomer = null;

			if (tenantId) {
				const { data } = await supabase
					.from('customers')
					.select('id')
					.eq('id', user.id)
					.eq('tenant_id', tenantId)
					.single();
				existingCustomer = data;
			} else {
				// Check if customer exists for any tenant
				const { data } = await supabase
					.from('customers')
					.select('id, tenant_id')
					.eq('id', user.id)
					.limit(1)
					.single();

				if (data) {
					existingCustomer = data;
					tenantId = data.tenant_id;
				}
			}

			if (existingCustomer) {
				// Customer record exists, ensure it's linked to unified profile
				const metadata = user.user_metadata || {};
				const phone = metadata.phone || user.phone || '';
				const fullName = metadata.full_name || user.email?.split('@')[0] || 'Customer';

				await supabase.rpc('link_customer_to_unified_patient', {
					p_customer_id: user.id,
					p_tenant_id: tenantId,
					p_email: user.email,
					p_phone: phone || null,
					p_name: fullName,
					p_linked_by: 'auto'
				});

				return;
			}

			// Get tenant_id if not provided
			if (!tenantId) {
				const { data: tenants } = await supabase
					.from('tenants')
					.select('id')
					.limit(1)
					.single();

				if (!tenants) {
					console.error('No tenant found');
					return;
				}
				tenantId = tenants.id;
			}

			// Extract user data from metadata
			const metadata = user.user_metadata || {};
			const phone = metadata.phone || user.phone || '';
			const fullName = metadata.full_name || user.email?.split('@')[0] || 'Customer';

			// Create customer record
			const { error: customerError } = await supabase.from('customers').insert({
				id: user.id,
				tenant_id: tenantId,
				full_name: fullName,
				email: user.email,
				phone: phone,
				loyalty_points: 0
			});

			if (customerError && customerError.code !== '23505') {
				// Ignore duplicate key errors
				console.error('Error creating customer record:', customerError);
				return;
			}

			// Link customer to unified patient profile
			const { error: linkError } = await supabase.rpc('link_customer_to_unified_patient', {
				p_customer_id: user.id,
				p_tenant_id: tenantId,
				p_email: user.email,
				p_phone: phone || null,
				p_name: fullName,
				p_linked_by: 'auto'
			});

			if (linkError) {
				console.error('Error linking customer to unified patient:', linkError);
			}
		} catch (err) {
			console.error('Error in ensureCustomerRecord:', err);
		}
	}

	/**
	 * Subscribe to auth state changes
	 */
	static onAuthStateChange(
		callback: (event: string, session: Session | null) => void
	) {
		return supabase.auth.onAuthStateChange(callback);
	}
}
