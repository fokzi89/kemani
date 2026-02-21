import { writable, derived } from 'svelte/store';

export interface CartItem {
    id: string; // unique key (productId + variantId)
    productId: string;
    variantId?: string | null;
    title: string;
    image?: string;
    price: number;
    quantity: number;
    maxStock: number;
}

interface CartState {
    items: CartItem[];
    isOpen: boolean;
}

const initialState: CartState = {
    items: [],
    isOpen: false
};

function createCart() {
    const { subscribe, set, update } = writable<CartState>(initialState);

    return {
        subscribe,
        addItem: (item: Omit<CartItem, 'id'>) =>
            update((state) => {
                const id = item.variantId
                    ? `${item.productId}-${item.variantId}`
                    : item.productId;
                const existing = state.items.find((i) => i.id === id);

                if (existing) {
                    // Update quantity, respecting max stock
                    const newQty = Math.min(existing.quantity + item.quantity, item.maxStock);
                    return {
                        ...state,
                        items: state.items.map((i) =>
                            i.id === id ? { ...i, quantity: newQty } : i
                        ),
                        isOpen: true
                    };
                }

                return {
                    ...state,
                    items: [...state.items, { ...item, id }],
                    isOpen: true
                };
            }),
        removeItem: (id: string) =>
            update((state) => ({
                ...state,
                items: state.items.filter((i) => i.id !== id)
            })),
        updateQuantity: (id: string, qty: number) =>
            update((state) => ({
                ...state,
                items: state.items.map((i) =>
                    i.id === id
                        ? { ...i, quantity: Math.max(1, Math.min(qty, i.maxStock)) }
                        : i
                )
            })),
        toggle: () => update((s) => ({ ...s, isOpen: !s.isOpen })),
        open: () => update((s) => ({ ...s, isOpen: true })),
        close: () => update((s) => ({ ...s, isOpen: false })),
        clear: () => set(initialState),
        load: (items: CartItem[]) => update((s) => ({ ...s, items }))
    };
}

export const cart = createCart();

export const cartTotal = derived(cart, ($cart) =>
    $cart.items.reduce((sum, item) => sum + item.price * item.quantity, 0)
);

export const cartCount = derived(cart, ($cart) =>
    $cart.items.reduce((sum, item) => sum + item.quantity, 0)
);

// Persistence logic
if (typeof window !== 'undefined') {
    const key = 'kemani-cart-store';
    try {
        const stored = localStorage.getItem(key);
        if (stored) {
            cart.load(JSON.parse(stored));
        }
    } catch (e) {
        console.error('Failed to load cart', e);
    }

    cart.subscribe((value) => {
        try {
            localStorage.setItem(key, JSON.stringify(value.items));
        } catch (e) {
            console.error('Failed to save cart', e);
        }
    });
}
