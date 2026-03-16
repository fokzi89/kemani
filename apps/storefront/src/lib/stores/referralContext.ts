import { writable } from 'svelte/store';
import type { ReferralSession } from '$lib/types/commission';

/**
 * Referral Context Store
 * Manages the current referral session context for authentication
 * This allows the auth system to know which tenant the user is signing up from
 */

export interface ReferralContext {
	session: ReferralSession | null;
	referringTenantId: string | null;
	referringTenantName: string | null;
}

function createReferralContextStore() {
	const { subscribe, set, update } = writable<ReferralContext>({
		session: null,
		referringTenantId: null,
		referringTenantName: null
	});

	return {
		subscribe,

		/**
		 * Set the referral session context
		 */
		setSession: (session: ReferralSession | null) => {
			if (session) {
				update((state) => ({
					...state,
					session,
					referringTenantId: session.referring_tenant_id
				}));
			} else {
				set({
					session: null,
					referringTenantId: null,
					referringTenantName: null
				});
			}
		},

		/**
		 * Set tenant name for display
		 */
		setTenantName: (name: string | null) => {
			update((state) => ({ ...state, referringTenantName: name }));
		},

		/**
		 * Clear referral context
		 */
		clear: () => {
			set({
				session: null,
				referringTenantId: null,
				referringTenantName: null
			});
		},

		/**
		 * Get current referring tenant ID (for auth)
		 */
		getTenantId: (): string | null => {
			let tenantId: string | null = null;
			subscribe((state) => {
				tenantId = state.referringTenantId;
			})();
			return tenantId;
		}
	};
}

export const referralContext = createReferralContextStore();

/**
 * Helper function to get referral session from cookie
 * Use this in components to initialize the context
 */
export function getSessionFromCookie(): string | null {
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
