import { writable, derived } from 'svelte/store';
import type { Session, User, SupabaseClient } from '@supabase/supabase-js';

interface AuthState {
    user: User | null;
    session: Session | null;
    loading: boolean;
}

const initialState: AuthState = {
    user: null,
    session: null,
    loading: true
};

function createAuthStore() {
    const { subscribe, set, update } = writable<AuthState>(initialState);

    return {
        subscribe,
        setSession: (session: Session | null, user: User | null) =>
            update((s) => ({ ...s, session, user, loading: false })),
        setLoading: (loading: boolean) => update((s) => ({ ...s, loading })),
        clear: () => set({ ...initialState, loading: false }),

        /**
         * Sign in with Google OAuth
         */
        signInWithGoogle: async (supabase: SupabaseClient) => {
            const { error } = await supabase.auth.signInWithOAuth({
                provider: 'google',
                options: {
                    redirectTo: `${window.location.origin}/auth/callback`
                }
            });
            if (error) throw error;
        },

        /**
         * Sign in with Apple OAuth
         */
        signInWithApple: async (supabase: SupabaseClient) => {
            const { error } = await supabase.auth.signInWithOAuth({
                provider: 'apple',
                options: {
                    redirectTo: `${window.location.origin}/auth/callback`
                }
            });
            if (error) throw error;
        },

        /**
         * Sign in with email magic link (passwordless)
         */
        signInWithEmail: async (supabase: SupabaseClient, email: string) => {
            const { error } = await supabase.auth.signInWithOtp({
                email,
                options: {
                    emailRedirectTo: `${window.location.origin}/auth/callback`
                }
            });
            if (error) throw error;
        },

        /**
         * Sign out
         */
        signOut: async (supabase: SupabaseClient) => {
            const { error } = await supabase.auth.signOut();
            if (error) throw error;
            set({ ...initialState, loading: false });
        }
    };
}

export const auth = createAuthStore();

export const isAuthenticated = derived(auth, ($auth) => !!$auth.user);
export const currentUser = derived(auth, ($auth) => $auth.user);
