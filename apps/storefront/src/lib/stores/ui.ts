import { writable } from 'svelte/store';

export const isAuthModalOpen = writable(false);
export const isChatOpen = writable(false);
export const chatProduct = writable<any>(null);

export function openAuthModal() {
    isAuthModalOpen.set(true);
}

export function closeAuthModal() {
    isAuthModalOpen.set(false);
}

export function openChat(product: any = null) {
    chatProduct.set(product);
    isChatOpen.set(true);
}

export function closeChat() {
    isChatOpen.set(false);
}
