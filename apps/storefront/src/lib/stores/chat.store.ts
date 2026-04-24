import { writable } from 'svelte/store';
import { browser } from '$app/environment';

// The key used for localStorage persistence
const STORAGE_KEY = 'active_chat_conversation_id';

// Initialize from localStorage if in browser
const initialValue = browser ? localStorage.getItem(STORAGE_KEY) : null;

export const activeConversationId = writable<string | null>(initialValue);

// Sync with localStorage
if (browser) {
    activeConversationId.subscribe((value) => {
        if (value) {
            localStorage.setItem(STORAGE_KEY, value);
        } else {
            localStorage.removeItem(STORAGE_KEY);
        }
    });
}

/**
 * Clears the active conversation ID from the store and localStorage
 */
export function clearActiveConversation() {
    activeConversationId.set(null);
}

/**
 * Sets the active conversation ID
 */
export function setActiveConversation(id: string) {
    activeConversationId.set(id);
}
