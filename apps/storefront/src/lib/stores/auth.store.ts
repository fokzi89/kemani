import { writable } from 'svelte/store';
import type { User, Session } from '@supabase/supabase-js';

export interface AuthState {
	user: User | null;
	session: Session | null;
	loading: boolean;
}

function createAuthStore() {
	const { subscribe, set, update } = writable<AuthState>({
		user: null,
		session: null,
		loading: true
	});

	return {
		subscribe,
		setUser: (user: User | null) => update(state => ({ ...state, user })),
		setSession: (session: Session | null) => update(state => ({ ...state, session, user: session?.user || null })),
		setAuth: (user: User, session: Session) => set({ user, session, loading: false }),
		setLoading: (loading: boolean) => update(state => ({ ...state, loading })),
		signOut: () => set({ user: null, session: null, loading: false })
	};
}

export const authStore = createAuthStore();
