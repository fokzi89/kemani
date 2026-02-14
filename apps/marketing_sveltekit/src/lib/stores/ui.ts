import { writable } from 'svelte/store';

export interface Toast {
    id: string;
    message: string;
    type: 'success' | 'error' | 'info';
    duration?: number;
}

function createUIStore() {
    const { subscribe, update } = writable<{ toasts: Toast[] }>({ toasts: [] });

    return {
        subscribe,
        addToast: (message: string, type: 'success' | 'error' | 'info' = 'info', duration = 3000) => {
            const id = Math.random().toString(36).substring(2);
            update(state => ({ ...state, toasts: [...state.toasts, { id, message, type, duration }] }));

            setTimeout(() => {
                update(state => ({ ...state, toasts: state.toasts.filter(t => t.id !== id) }));
            }, duration);
        },
        removeToast: (id: string) => update(state => ({
            ...state,
            toasts: state.toasts.filter(t => t.id !== id)
        }))
    };
}

export const ui = createUIStore();
