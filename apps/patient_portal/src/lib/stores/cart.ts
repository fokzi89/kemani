
import { writable, get, derived } from 'svelte/store';
import { browser } from '$app/environment';

export interface CartItem {
    id: string; // product_id
    inventory_id: string;
    branch_id: string;
    pharmacy_name: string;
    name: string;
    price: number;
    quantity: number;
    image_url?: string;
    unit_of_measure?: string;
}

interface CartStore {
    items: CartItem[];
    branchId: string | null;
    pharmacyName: string | null;
}

const initialState: CartStore = {
    items: [],
    branchId: null,
    pharmacyName: null
};

// Load from localStorage on init
const savedCart = browser ? localStorage.getItem('kemani_cart') : null;
const cart = writable<CartStore>(savedCart ? JSON.parse(savedCart) : initialState);

// Persist to localStorage on change
if (browser) {
    cart.subscribe(value => {
        localStorage.setItem('kemani_cart', JSON.stringify(value));
    });
}

export const cartStore = {
    subscribe: cart.subscribe,
    
    addItem: (product: any, pharmacy: any, quantity: number = 1) => {
        cart.update(state => {
            // Check if adding from a different pharmacy
            if (state.branchId && state.branchId !== pharmacy.branch_id) {
                // Return original state, UI should handle confirmation
                return state;
            }

            const existingIndex = state.items.findIndex(i => i.id === product.id);
            const newItems = [...state.items];

            if (existingIndex > -1) {
                newItems[existingIndex].quantity += quantity;
            } else {
                newItems.push({
                    id: product.id,
                    inventory_id: product.inventory_id,
                    branch_id: pharmacy.branch_id,
                    pharmacy_name: pharmacy.name,
                    name: product.name,
                    price: product.unit_price,
                    quantity: quantity,
                    image_url: product.image_url,
                    unit_of_measure: product.unit_of_measure
                });
            }

            return {
                ...state,
                items: newItems,
                branchId: pharmacy.branch_id,
                pharmacyName: pharmacy.name
            };
        });
    },

    updateQuantity: (productId: string, quantity: number) => {
        cart.update(state => {
            const newItems = state.items.map(item => 
                item.id === productId ? { ...item, quantity: Math.max(1, quantity) } : item
            );
            return { ...state, items: newItems };
        });
    },

    removeItem: (productId: string) => {
        cart.update(state => {
            const newItems = state.items.filter(i => i.id !== productId);
            if (newItems.length === 0) {
                return initialState;
            }
            return { ...state, items: newItems };
        });
    },

    clearCart: () => {
        cart.set(initialState);
    }
};

// Derived stores
export const cartTotalItems = derived(cart, $cart => $cart.items.length);
export const cartTotalPrice = derived(cart, $cart => $cart.items.reduce((acc, item) => acc + (item.price * item.quantity), 0));
