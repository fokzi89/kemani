import { writable } from 'svelte/store';
import type { User, Session } from '@supabase/supabase-js';
import { AuthService } from '$lib/services/auth';

interface AuthState {
	user: User | null;
	session: Session | null;
	loading: boolean;
	initialized: boolean;
}

const initialState: AuthState = {
	user: null,
	session: null,
	loading: true,
	initialized: false
};

function createAuthStore() {
	const { subscribe, set, update } = writable<AuthState>(initialState);

	return {
		subscribe,

		/**
		 * Initialize auth state
		 */
		async initialize() {
			update(state => ({ ...state, loading: true }));

			const { session } = await AuthService.getSession();
			const { user } = await AuthService.getUser();

			update(state => ({
				...state,
				user,
				session,
				loading: false,
				initialized: true
			}));

			// Subscribe to auth changes
			AuthService.onAuthStateChange((event, session) => {
				update(state => ({
					...state,
					user: session?.user || null,
					session,
					loading: false
				}));
			});
		},

		/**
		 * Set user after sign in/up
		 */
		setAuth(user: User | null, session: Session | null) {
			update(state => ({
				...state,
				user,
				session,
				loading: false
			}));
		},

		/**
		 * Clear auth state
		 */
		clearAuth() {
			set({
				user: null,
				session: null,
				loading: false,
				initialized: true
			});
		},

		/**
		 * Set loading state
		 */
		setLoading(loading: boolean) {
			update(state => ({ ...state, loading }));
		}
	};
}

export const authStore = createAuthStore();

// Derived stores for convenience
import { derived } from 'svelte/store';

export const isAuthenticated = derived(
	authStore,
	$authStore => $authStore.user !== null
);

export const currentUser = derived(
	authStore,
	$authStore => $authStore.user
);

export const isCustomer = derived(
	authStore,
	$authStore => $authStore.user?.user_metadata?.user_type === 'customer'
);

export const isMerchant = derived(
	authStore,
	$authStore => $authStore.user?.user_metadata?.user_type === 'merchant'
);
