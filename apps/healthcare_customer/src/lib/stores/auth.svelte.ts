import { supabase } from '$lib/supabase';
import type { User, Session } from '@supabase/supabase-js';

// Auth state using Svelte 5 runes
let currentUser = $state<User | null>(null);
let currentSession = $state<Session | null>(null);
let isLoading = $state(true);

// Initialize auth state
supabase.auth.getSession().then(({ data: { session } }) => {
	currentSession = session;
	currentUser = session?.user ?? null;
	isLoading = false;
});

// Listen to auth changes
supabase.auth.onAuthStateChange((event, session) => {
	currentSession = session;
	currentUser = session?.user ?? null;
	isLoading = false;
});

export const authStore = {
	get user() {
		return currentUser;
	},
	get session() {
		return currentSession;
	},
	get isLoading() {
		return isLoading;
	},
	get isAuthenticated() {
		return !!currentUser;
	},

	async signIn(email: string, password: string) {
		const { data, error } = await supabase.auth.signInWithPassword({
			email,
			password
		});

		if (error) throw error;
		return data;
	},

	async signUp(email: string, password: string, userData?: any) {
		const { data, error } = await supabase.auth.signUp({
			email,
			password,
			options: {
				data: userData
			}
		});

		if (error) throw error;
		return data;
	},

	async signOut() {
		const { error } = await supabase.auth.signOut();
		if (error) throw error;
	},

	async resetPassword(email: string) {
		const { error } = await supabase.auth.resetPasswordForEmail(email);
		if (error) throw error;
	}
};
