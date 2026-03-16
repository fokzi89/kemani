import { writable, derived } from 'svelte/store';
import { browser } from '$app/environment';

export interface CartItem {
	product_id: string;
	name: string;
	unit_price: number;
	quantity: number;
	image_url?: string;
	sku?: string;
}

export interface Cart {
	items: CartItem[];
	tenant_id: string | null;
}

// Load cart from localStorage
const getInitialCart = (): Cart => {
	if (browser) {
		const stored = localStorage.getItem('cart');
		if (stored) {
			try {
				return JSON.parse(stored);
			} catch {
				return { items: [], tenant_id: null };
			}
		}
	}
	return { items: [], tenant_id: null };
};

function createCartStore() {
	const { subscribe, set, update } = writable<Cart>(getInitialCart());

	// Save to localStorage whenever cart changes
	if (browser) {
		subscribe(cart => {
			localStorage.setItem('cart', JSON.stringify(cart));
		});
	}

	return {
		subscribe,

		addItem: (item: CartItem, tenant_id: string) => update(cart => {
			// If switching tenants, clear cart
			if (cart.tenant_id && cart.tenant_id !== tenant_id) {
				return {
					items: [item],
					tenant_id
				};
			}

			const existingIndex = cart.items.findIndex(i => i.product_id === item.product_id);

			if (existingIndex >= 0) {
				// Update quantity
				cart.items[existingIndex].quantity += item.quantity;
			} else {
				// Add new item
				cart.items.push(item);
			}

			return {
				...cart,
				tenant_id
			};
		}),

		updateQuantity: (product_id: string, quantity: number) => update(cart => {
			const item = cart.items.find(i => i.product_id === product_id);
			if (item) {
				if (quantity <= 0) {
					cart.items = cart.items.filter(i => i.product_id !== product_id);
				} else {
					item.quantity = quantity;
				}
			}
			return cart;
		}),

		removeItem: (product_id: string) => update(cart => ({
			...cart,
			items: cart.items.filter(i => i.product_id !== product_id)
		})),

		clear: () => set({ items: [], tenant_id: null }),

		clearIfDifferentTenant: (tenant_id: string) => update(cart => {
			if (cart.tenant_id && cart.tenant_id !== tenant_id) {
				return { items: [], tenant_id };
			}
			return cart;
		})
	};
}

export const cartStore = createCartStore();

// Derived stores for computed values
export const cartCount = derived(cartStore, $cart =>
	$cart.items.reduce((sum, item) => sum + item.quantity, 0)
);

export const cartSubtotal = derived(cartStore, $cart =>
	$cart.items.reduce((sum, item) => sum + (item.unit_price * item.quantity), 0)
);

export const cartTax = derived(cartSubtotal, $subtotal =>
	$subtotal * 0.075 // 7.5% VAT
);

export const cartTotal = derived(
	[cartSubtotal, cartTax],
	([$subtotal, $tax]) => $subtotal + $tax
);
