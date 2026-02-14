import { writable } from 'svelte/store';
import { browser } from '$app/environment';

export interface UserProfile {
    id?: string;
    name?: string;
    email?: string;
    phone?: string;
    addresses?: any[];
    isGuest?: boolean;
}

function createUserStore() {
    const { subscribe, set, update } = writable<UserProfile | null>(null);

    if (browser) {
        const stored = localStorage.getItem('kemani_user');
        if (stored) {
            try {
                set(JSON.parse(stored));
            } catch (e) {
                console.error('Failed to parse user', e);
            }
        }
    }

    return {
        subscribe,
        setUser: (user: UserProfile) => {
            set(user);
            if (browser) localStorage.setItem('kemani_user', JSON.stringify(user));
        },
        clearUser: () => {
            set(null);
            if (browser) localStorage.removeItem('kemani_user');
        },
        updateUser: (updates: Partial<UserProfile>) => update(user => {
            if (!user) return null;
            const newUser = { ...user, ...updates };
            if (browser) localStorage.setItem('kemani_user', JSON.stringify(newUser));
            return newUser;
        })
    };
}

export const user = createUserStore();
