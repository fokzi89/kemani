import { supabase } from '$lib/supabase';
import type { AuthError } from '@supabase/supabase-js';

/**
 * OTP Service - Email-based passwordless authentication
 * Uses Supabase Auth + Resend for email delivery
 */
export class OTPService {
	/**
	 * Send OTP to email (magic link or OTP code)
	 */
	static async sendOTP(
		email: string,
		options?: {
			shouldCreateUser?: boolean;
			data?: Record<string, any>;
			redirectTo?: string;
		}
	): Promise<{ success: boolean; error: AuthError | null }> {
		try {
			const { error } = await supabase.auth.signInWithOtp({
				email,
				options: {
					shouldCreateUser: options?.shouldCreateUser ?? true,
					data: options?.data,
					emailRedirectTo: options?.redirectTo || `${window.location.origin}/auth/callback`
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
	): Promise<{ success: boolean; error: AuthError | null }> {
		try {
			const { error } = await supabase.auth.verifyOtp({
				email,
				token,
				type: 'email'
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
	 * Resend OTP
	 */
	static async resendOTP(email: string): Promise<{ success: boolean; error: AuthError | null }> {
		return this.sendOTP(email);
	}
}
