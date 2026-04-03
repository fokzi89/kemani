import { writable } from 'svelte/store';

export const isAuthModalOpen = writable(false);

export function openAuthModal() {
    isAuthModalOpen.set(true);
}

export function closeAuthModal() {
    isAuthModalOpen.set(false);
}
