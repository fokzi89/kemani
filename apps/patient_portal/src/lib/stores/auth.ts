import { writable, derived } from 'svelte/store';
import { supabase } from '$lib/supabase';

const initialState = { user: null, session: null, loading: true, initialized: false };

function createAuthStore() {
  const { subscribe, set, update } = writable(initialState);
  return {
    subscribe,
    async initialize() {
      update(s => ({ ...s, loading: true }));
      const { data: { session } } = await supabase.auth.getSession();
      update(s => ({ ...s, user: session?.user || null, session, loading: false, initialized: true }));
      supabase.auth.onAuthStateChange((_event, session) => {
        update(s => ({ ...s, user: session?.user || null, session, loading: false }));
      });
    },
    clearAuth() { set({ user: null, session: null, loading: false, initialized: true }); }
  };
}

export const authStore = createAuthStore();
export const isAuthenticated = derived(authStore, $a => $a.user !== null);
export const currentUser = derived(authStore, $a => $a.user);
