
// this file is generated — do not edit it


declare module "svelte/elements" {
	export interface HTMLAttributes<T> {
		'data-sveltekit-keepfocus'?: true | '' | 'off' | undefined | null;
		'data-sveltekit-noscroll'?: true | '' | 'off' | undefined | null;
		'data-sveltekit-preload-code'?:
			| true
			| ''
			| 'eager'
			| 'viewport'
			| 'hover'
			| 'tap'
			| 'off'
			| undefined
			| null;
		'data-sveltekit-preload-data'?: true | '' | 'hover' | 'tap' | 'off' | undefined | null;
		'data-sveltekit-reload'?: true | '' | 'off' | undefined | null;
		'data-sveltekit-replacestate'?: true | '' | 'off' | undefined | null;
	}
}

export {};


declare module "$app/types" {
	type MatcherParam<M> = M extends (param : string) => param is (infer U extends string) ? U : string;

	export interface AppTypes {
		RouteId(): "/(marketplace)" | "/" | "/api" | "/api/customers" | "/api/customers/auth" | "/api/customers/[id]" | "/api/customers/[id]/addresses" | "/api/marketplace" | "/api/marketplace/[tenantId]" | "/api/marketplace/[tenantId]/products" | "/api/marketplace/[tenantId]/products/[productId]" | "/api/orders" | "/api/orders/[id]" | "/api/orders/[id]/status" | "/api/payment" | "/api/payment/initialize" | "/api/payment/verify" | "/api/track" | "/api/track/[id]" | "/auth" | "/auth/callback" | "/auth/login" | "/checkout" | "/consultations" | "/customers" | "/diagnostics" | "/orders" | "/payment" | "/payment/callback" | "/products" | "/track" | "/track/[orderId]" | "/(marketplace)/[tenantId]" | "/(marketplace)/[tenantId]/cart" | "/(marketplace)/[tenantId]/products" | "/(marketplace)/[tenantId]/products/[productId]" | "/(marketplace)/[tenantId]/profile";
		RouteParams(): {
			"/api/customers/[id]": { id: string };
			"/api/customers/[id]/addresses": { id: string };
			"/api/marketplace/[tenantId]": { tenantId: string };
			"/api/marketplace/[tenantId]/products": { tenantId: string };
			"/api/marketplace/[tenantId]/products/[productId]": { tenantId: string; productId: string };
			"/api/orders/[id]": { id: string };
			"/api/orders/[id]/status": { id: string };
			"/api/track/[id]": { id: string };
			"/track/[orderId]": { orderId: string };
			"/(marketplace)/[tenantId]": { tenantId: string };
			"/(marketplace)/[tenantId]/cart": { tenantId: string };
			"/(marketplace)/[tenantId]/products": { tenantId: string };
			"/(marketplace)/[tenantId]/products/[productId]": { tenantId: string; productId: string };
			"/(marketplace)/[tenantId]/profile": { tenantId: string }
		};
		LayoutParams(): {
			"/(marketplace)": { tenantId?: string; productId?: string };
			"/": { id?: string; tenantId?: string; productId?: string; orderId?: string };
			"/api": { id?: string; tenantId?: string; productId?: string };
			"/api/customers": { id?: string };
			"/api/customers/auth": Record<string, never>;
			"/api/customers/[id]": { id: string };
			"/api/customers/[id]/addresses": { id: string };
			"/api/marketplace": { tenantId?: string; productId?: string };
			"/api/marketplace/[tenantId]": { tenantId: string; productId?: string };
			"/api/marketplace/[tenantId]/products": { tenantId: string; productId?: string };
			"/api/marketplace/[tenantId]/products/[productId]": { tenantId: string; productId: string };
			"/api/orders": { id?: string };
			"/api/orders/[id]": { id: string };
			"/api/orders/[id]/status": { id: string };
			"/api/payment": Record<string, never>;
			"/api/payment/initialize": Record<string, never>;
			"/api/payment/verify": Record<string, never>;
			"/api/track": { id?: string };
			"/api/track/[id]": { id: string };
			"/auth": Record<string, never>;
			"/auth/callback": Record<string, never>;
			"/auth/login": Record<string, never>;
			"/checkout": Record<string, never>;
			"/consultations": Record<string, never>;
			"/customers": Record<string, never>;
			"/diagnostics": Record<string, never>;
			"/orders": Record<string, never>;
			"/payment": Record<string, never>;
			"/payment/callback": Record<string, never>;
			"/products": Record<string, never>;
			"/track": { orderId?: string };
			"/track/[orderId]": { orderId: string };
			"/(marketplace)/[tenantId]": { tenantId: string; productId?: string };
			"/(marketplace)/[tenantId]/cart": { tenantId: string };
			"/(marketplace)/[tenantId]/products": { tenantId: string; productId?: string };
			"/(marketplace)/[tenantId]/products/[productId]": { tenantId: string; productId: string };
			"/(marketplace)/[tenantId]/profile": { tenantId: string }
		};
		Pathname(): "/" | "/api/customers" | "/api/customers/auth" | `/api/customers/${string}` & {} | `/api/customers/${string}/addresses` & {} | `/api/marketplace/${string}/products` & {} | `/api/marketplace/${string}/products/${string}` & {} | "/api/orders" | `/api/orders/${string}` & {} | `/api/orders/${string}/status` & {} | "/api/payment/initialize" | "/api/payment/verify" | `/api/track/${string}` & {} | "/auth/callback" | "/auth/login" | "/checkout" | "/consultations" | "/customers" | "/diagnostics" | "/orders" | "/payment/callback" | "/products" | `/track/${string}` & {} | `/${string}` & {} | `/${string}/cart` & {} | `/${string}/products/${string}` & {} | `/${string}/profile` & {};
		ResolvedPathname(): `${"" | `/${string}`}${ReturnType<AppTypes['Pathname']>}`;
		Asset(): string & {};
	}
}