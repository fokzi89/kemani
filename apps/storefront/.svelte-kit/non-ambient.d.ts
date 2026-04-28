
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
		RouteId(): "/(marketplace)" | "/" | "/api" | "/api/customers" | "/api/customers/auth" | "/api/customers/[id]" | "/api/customers/[id]/addresses" | "/api/marketplace" | "/api/marketplace/categories" | "/api/marketplace/info" | "/api/marketplace/products" | "/api/marketplace/products/[productId]" | "/api/orders" | "/api/orders/[id]" | "/api/orders/[id]/status" | "/api/payment" | "/api/payment/initialize" | "/api/payment/verify" | "/api/track" | "/api/track/[id]" | "/auth" | "/auth/callback" | "/auth/portal" | "/(marketplace)/cart" | "/(marketplace)/chat" | "/(marketplace)/checkout" | "/consultations" | "/diagnostics" | "/(marketplace)/medics" | "/(marketplace)/medics/[medicId]" | "/(marketplace)/products" | "/(marketplace)/products/[productId]" | "/(marketplace)/profile";
		RouteParams(): {
			"/api/customers/[id]": { id: string };
			"/api/customers/[id]/addresses": { id: string };
			"/api/marketplace/products/[productId]": { productId: string };
			"/api/orders/[id]": { id: string };
			"/api/orders/[id]/status": { id: string };
			"/api/track/[id]": { id: string };
			"/(marketplace)/medics/[medicId]": { medicId: string };
			"/(marketplace)/products/[productId]": { productId: string }
		};
		LayoutParams(): {
			"/(marketplace)": { medicId?: string; productId?: string };
			"/": { id?: string; productId?: string; medicId?: string };
			"/api": { id?: string; productId?: string };
			"/api/customers": { id?: string };
			"/api/customers/auth": Record<string, never>;
			"/api/customers/[id]": { id: string };
			"/api/customers/[id]/addresses": { id: string };
			"/api/marketplace": { productId?: string };
			"/api/marketplace/categories": Record<string, never>;
			"/api/marketplace/info": Record<string, never>;
			"/api/marketplace/products": { productId?: string };
			"/api/marketplace/products/[productId]": { productId: string };
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
			"/auth/portal": Record<string, never>;
			"/(marketplace)/cart": Record<string, never>;
			"/(marketplace)/chat": Record<string, never>;
			"/(marketplace)/checkout": Record<string, never>;
			"/consultations": Record<string, never>;
			"/diagnostics": Record<string, never>;
			"/(marketplace)/medics": { medicId?: string };
			"/(marketplace)/medics/[medicId]": { medicId: string };
			"/(marketplace)/products": { productId?: string };
			"/(marketplace)/products/[productId]": { productId: string };
			"/(marketplace)/profile": Record<string, never>
		};
		Pathname(): "/" | "/api/customers" | "/api/customers/auth" | `/api/customers/${string}` & {} | `/api/customers/${string}/addresses` & {} | "/api/marketplace/categories" | "/api/marketplace/info" | "/api/marketplace/products" | `/api/marketplace/products/${string}` & {} | "/api/orders" | `/api/orders/${string}` & {} | `/api/orders/${string}/status` & {} | "/api/payment/initialize" | "/api/payment/verify" | `/api/track/${string}` & {} | "/auth/callback" | "/auth/portal" | "/cart" | "/chat" | "/checkout" | "/consultations" | "/diagnostics" | "/medics" | `/medics/${string}` & {} | `/products/${string}` & {} | "/profile";
		ResolvedPathname(): `${"" | `/${string}`}${ReturnType<AppTypes['Pathname']>}`;
		Asset(): string & {};
	}
}