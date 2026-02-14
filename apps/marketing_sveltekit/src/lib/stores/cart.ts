import { writable, get } from 'svelte/store';
import { browser } from '$app/environment';

export interface CartItem {
    id: string; // Product ID
    variantId?: string;
    name: string;
    price: number;
    image: string;
    quantity: number;
    branchId: string;
}

export interface CartState {
    items: CartItem[];
    isOpen: boolean;
}

const initialState: CartState = {
    items: [],
    isOpen: false
};

function createCartStore() {
    const { subscribe, set, update } = writable<CartState>(initialState);

    // Load from localStorage on client side
    if (browser) {
        const stored = localStorage.getItem('kemani_cart');
        if (stored) {
            try {
                set(JSON.parse(stored));
            } catch (e) {
                console.error('Failed to parse cart', e);
            }
        }
    }

    return {
        subscribe,
        addItem: (item: Omit<CartItem, 'quantity'>) => update(state => {
            const existing = state.items.find(i => i.id === item.id && i.variantId === item.variantId);
            let newItems;
            if (existing) {
                newItems = state.items.map(i =>
                    (i.id === item.id && i.variantId === item.variantId)
                        ? { ...i, quantity: i.quantity + 1 }
                        : i
                );
            } else {
                newItems = [...state.items, { ...item, quantity: 1 }];
            }

            const newState = { ...state, items: newItems, isOpen: true };
            if (browser) localStorage.setItem('kemani_cart', JSON.stringify(newState));
            return newState;
        }),
        removeItem: (itemId: string, variantId?: string) => update(state => {
            const newItems = state.items.filter(i => !(i.id === itemId && i.variantId === variantId));
            const newState = { ...state, items: newItems };
            if (browser) localStorage.setItem('kemani_cart', JSON.stringify(newState));
            return newState;
        }),
        updateQuantity: (itemId: string, quantity: number, variantId?: string) => update(state => {
            if (quantity <= 0) {
                // Remove item if quantity is 0 or less
                const newItems = state.items.filter(i => !(i.id === itemId && i.variantId === variantId));
                const newState = { ...state, items: newItems };
                if (browser) localStorage.setItem('kemani_cart', JSON.stringify(newState));
                return newState;
            }
            const newItems = state.items.map(i =>
                (i.id === itemId && i.variantId === variantId) ? { ...i, quantity } : i
            );
            const newState = { ...state, items: newItems };
            if (browser) localStorage.setItem('kemani_cart', JSON.stringify(newState));
            return newState;
        }),
        clear: () => {
            set(initialState);
            if (browser) localStorage.removeItem('kemani_cart');
        },
        toggle: () => update(state => ({ ...state, isOpen: !state.isOpen })),
        open: () => update(state => ({ ...state, isOpen: true })),
        close: () => update(state => ({ ...state, isOpen: false }))
    };
}

export const cart = createCartStore();
