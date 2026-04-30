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
				const cart = JSON.parse(stored);
				if (cart && Array.isArray(cart.items)) {
					// Filter out any items with invalid quantity
					cart.items = cart.items.filter((item: any) => 
						item && 
						typeof item.quantity === 'number' && 
						item.quantity > 0 &&
						(item.product_id || item.id)
					);
					return cart;
				}
			} catch (e) {
				console.error('Failed to parse cart from localStorage:', e);
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
	$cart.items.reduce((sum, item: any) => sum + ((item.unit_price || item.price || 0) * item.quantity), 0)
);

export const cartTax = derived(cartSubtotal, $subtotal =>
	$subtotal * 0.075 // 7.5% VAT
);

export const calculateServiceCharge = (amount: number) => {
	if (amount <= 0) return 0;
	if (amount <= 4999) return 30;
	if (amount <= 10000) return 50;
	if (amount <= 100000) return 100;
	return 150;
};

export const cartServiceCharge = derived(cartSubtotal, $subtotal => 
	calculateServiceCharge($subtotal)
);

export const cartTotal = derived(
	[cartSubtotal, cartTax, cartServiceCharge],
	([$subtotal, $tax, $serviceCharge]) => $subtotal + $tax + $serviceCharge
);
