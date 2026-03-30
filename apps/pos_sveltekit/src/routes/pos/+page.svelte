<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase';
	import {
		Search, ShoppingCart, Plus, Minus, Trash2, CreditCard,
		Banknote, Smartphone, X, CheckCircle, Tag, User, AlertTriangle,
		RotateCcw, PackageSearch, ChevronDown
	} from 'lucide-svelte';

	// ── Types ──────────────────────────────────────────────────────────────────
	type CartItem = {
		product_id: string; name: string; price: number; qty: number;
		batch_id: string; batch_stock: number; batch_expiry: string | null;
		image_url?: string; near_expiry?: boolean;
	};
	type CartTab = { id: number; items: CartItem[]; customerName: string; discount: number; };

	// ── State ─────────────────────────────────────────────────────────────────
	let products         = $state<any[]>([]);
	let batches          = $state<Record<string, any[]>>({});
	let filteredProducts = $state<any[]>([]);
	let searchQuery      = $state('');
	let selectedCategory = $state('all');
	let categories       = $state<string[]>([]);
	let tenantId         = $state('');
	let userBranchId     = $state('');
	let loading          = $state(true);

	// ── Multi-cart tabs ────────────────────────────────────────────────────────
	let carts = $state<CartTab[]>([
		{ id: 1, items: [], customerName: '', discount: 0 },
		{ id: 2, items: [], customerName: '', discount: 0 },
		{ id: 3, items: [], customerName: '', discount: 0 },
		{ id: 4, items: [], customerName: '', discount: 0 },
	]);
	let activeCartIdx = $state(0);

	// ── Mobile bottom sheet ───────────────────────────────────────────────────
	let showProductSheet = $state(false);

	// ── Checkout state ────────────────────────────────────────────────────────
	let checkoutOpen      = $state(false);
	let paymentMethod     = $state<'cash' | 'card' | 'transfer'>('cash');
	let cashReceived      = $state('');
	let saleSuccess       = $state(false);
	let lastSale          = $state<any>(null);
	let processingPayment = $state(false);

	// ── Derived ───────────────────────────────────────────────────────────────
	let activeItems = $derived(carts[activeCartIdx].items);
	let subtotal    = $derived(activeItems.reduce((s, i) => s + i.price * i.qty, 0));
	let discountPct = $derived(carts[activeCartIdx].discount);
	let discountAmt = $derived(subtotal * (discountPct / 100));
	let total       = $derived(subtotal - discountAmt);
	let change      = $derived(paymentMethod === 'cash' ? Math.max(0, parseFloat(cashReceived || '0') - total) : 0);
	function cartCount(c: CartTab) { return c.items.reduce((s, i) => s + i.qty, 0); }
	let activeCount = $derived(cartCount(carts[activeCartIdx]));

	// ── Boot ──────────────────────────────────────────────────────────────────
	onMount(async () => {
		const { data: { session } } = await supabase.auth.getSession();
		if (!session) return;
		const { data: user } = await supabase
			.from('users').select('tenant_id, branch_id').eq('id', session.user.id).single();
		if (user) {
			tenantId = user.tenant_id;
			userBranchId = user.branch_id;
			if (userBranchId) await loadProducts();
		}
		loading = false;
	});

	async function loadProducts() {
		if (!userBranchId) return;
		const { data, error } = await supabase
			.from('branch_inventory')
			.select('*, products(*)')
			.eq('branch_id', userBranchId)
			.eq('is_active', true)
			.gt('stock_quantity', 0)
			.order('expiry_date', { ascending: true, nullsFirst: false });

		if (error) { console.error(error); return; }

		const bmap: Record<string, any[]> = {};
		for (const row of data || []) {
			if (!bmap[row.product_id]) bmap[row.product_id] = [];
			bmap[row.product_id].push(row);
		}
		batches = bmap;

		const seen = new Set<string>();
		const display: any[] = [];
		for (const row of data || []) {
			if (seen.has(row.product_id)) continue;
			seen.add(row.product_id);
			const fifo = bmap[row.product_id][0];
			display.push({
				...row.products,
				product_id:    row.product_id,
				stock_quantity: bmap[row.product_id].reduce((s, b) => s + b.stock_quantity, 0),
				price:         fifo.unit_cost || 0,
				expiry_date:   fifo.expiry_date,
				near_expiry:   isNearExpiry(fifo.expiry_date)
			});
		}
		products   = display;
		categories = [...new Set(display.map(p => p.category).filter(Boolean))];
		filterProducts();
	}

	function isNearExpiry(d: string | null) {
		if (!d) return false;
		return (new Date(d).getTime() - Date.now()) / 86_400_000 <= 30;
	}

	function filterProducts() {
		let r = products;
		if (selectedCategory !== 'all') r = r.filter(p => p.category === selectedCategory);
		if (searchQuery) r = r.filter(p =>
			p.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
			(p.barcode && p.barcode.toLowerCase().includes(searchQuery.toLowerCase()))
		);
		filteredProducts = r;
	}
	$effect(() => { searchQuery; selectedCategory; filterProducts(); });

	// ── Cart ops ──────────────────────────────────────────────────────────────
	function addToCart(product: any) {
		const fifo = (batches[product.product_id] || [])[0];
		if (!fifo) return;
		const tab    = carts[activeCartIdx];
		const exists = tab.items.find(i => i.product_id === product.product_id);
		if (exists) {
			if (exists.qty < fifo.stock_quantity) exists.qty++;
		} else {
			tab.items = [...tab.items, {
				product_id: product.product_id, name: product.name,
				price: parseFloat(String(fifo.unit_cost || 0)), qty: 1,
				batch_id: fifo.id, batch_stock: fifo.stock_quantity,
				batch_expiry: fifo.expiry_date, image_url: product.image_url,
				near_expiry: product.near_expiry
			}];
		}
	}

	function updateQty(product_id: string, delta: number) {
		const tab = carts[activeCartIdx];
		tab.items = tab.items.map(i => {
			if (i.product_id !== product_id) return i;
			const nq = i.qty + delta;
			if (nq <= 0) return null;
			return { ...i, qty: Math.min(nq, i.batch_stock) };
		}).filter(Boolean) as CartItem[];
	}

	function removeFromCart(product_id: string) {
		carts[activeCartIdx].items = carts[activeCartIdx].items.filter(i => i.product_id !== product_id);
	}

	function clearCart(idx: number) {
		carts[idx].items = []; carts[idx].customerName = ''; carts[idx].discount = 0;
	}

	async function processSale() {
		const tab = carts[activeCartIdx];
		if (tab.items.length === 0) return;
		processingPayment = true;
		try {
			const { data: { session } } = await supabase.auth.getSession();
			const sale_number = `SALE-${Date.now().toString().slice(-6)}`;
			const { data: sale, error: saleErr } = await supabase.from('sales').insert({
				tenant_id: tenantId, branch_id: userBranchId, cashier_id: session?.user.id,
				sale_number, subtotal, discount_amount: discountAmt, total_amount: total,
				payment_method: paymentMethod, cash_received: parseFloat(cashReceived) || null,
				change_given: change || null, customer_name: tab.customerName || null, status: 'completed'
			}).select().single();
			if (saleErr) throw saleErr;

			await supabase.from('sale_items').insert(
				tab.items.map(i => ({
					sale_id: sale.id, product_id: i.product_id, product_name: i.name,
					quantity: i.qty, unit_price: i.price, total_price: i.price * i.qty
				}))
			);
			for (const item of tab.items) {
				await supabase.from('branch_inventory')
					.update({ stock_quantity: Math.max(0, item.batch_stock - item.qty), updated_at: new Date().toISOString() })
					.eq('id', item.batch_id);
			}
			lastSale = { id: sale.id, total_amount: total };
			saleSuccess = true; checkoutOpen = false;
			clearCart(activeCartIdx); cashReceived = '';
			await loadProducts();
		} catch (err: any) {
			alert('Sale failed: ' + err.message);
		} finally { processingPayment = false; }
	}

	function fmt(n: number) { return '₦' + n.toLocaleString('en-NG', { minimumFractionDigits: 2 }); }
	function fmtDate(d: string | null) {
		if (!d) return null;
		return new Date(d).toLocaleDateString('en-GB', { day: 'numeric', month: 'short', year: '2-digit' });
	}
</script>

<svelte:head><title>POS – Kemani POS</title></svelte:head>

<!-- ══════════════════════════════════════════════════════════════════════════
     LAYOUT: Desktop = [Products | Cart]   Mobile = [Cart full-screen]
     ══════════════════════════════════════════════════════════════════════════ -->
<div class="h-screen flex overflow-hidden bg-gray-50">

	<!-- ── Products Panel (desktop only) ────────────────────────────────────── -->
	<div class="hidden md:flex flex-1 flex-col overflow-hidden">
		<!-- Search + Categories -->
		<div class="bg-white border-b px-4 py-3 flex items-center gap-3">
			<div class="relative flex-1 max-w-md">
				<Search class="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
				<input type="text" bind:value={searchQuery} placeholder="Search products or scan barcode..."
					class="w-full pl-9 pr-4 py-2 text-sm border border-gray-200 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500" />
			</div>
			<div class="flex gap-2 overflow-x-auto tab-scroll-bar shrink-0 max-w-xs">
				<button onclick={() => selectedCategory = 'all'}
					class="px-3 py-1.5 text-sm rounded-full whitespace-nowrap transition-colors {selectedCategory === 'all' ? 'bg-indigo-600 text-white' : 'bg-gray-100 text-gray-600 hover:bg-gray-200'}">All</button>
				{#each categories as cat}
					<button onclick={() => selectedCategory = cat}
						class="px-3 py-1.5 text-sm rounded-full whitespace-nowrap transition-colors {selectedCategory === cat ? 'bg-indigo-600 text-white' : 'bg-gray-100 text-gray-600 hover:bg-gray-200'}">{cat}</button>
				{/each}
			</div>
		</div>
		<!-- Product Grid -->
		{@render productGrid()}
	</div>

	<!-- ── Cart Panel (full-width on mobile, sidebar on desktop) ────────────── -->
	<div class="relative flex flex-col w-full md:w-80 xl:w-96 md:flex-none bg-white md:border-l md:shadow-lg">

		<!-- Cart Tab Bar -->
		<div class="bg-indigo-700 shrink-0">
			<div class="flex overflow-x-auto tab-scroll-bar">
				{#each carts as tab, idx}
					{@const count = cartCount(tab)}
					<button onclick={() => activeCartIdx = idx}
						class="flex items-center justify-center gap-1.5 py-2.5 text-sm font-semibold whitespace-nowrap border-b-2 transition-all shrink-0 min-w-[90px]
							{activeCartIdx === idx
								? 'border-white text-white bg-indigo-600'
								: count > 0
									? 'border-indigo-400 text-indigo-100 hover:bg-indigo-600/50'
									: 'border-transparent text-indigo-300 hover:bg-indigo-600/30'}">
						<ShoppingCart class="h-3.5 w-3.5 shrink-0" />
						<span>Cart {tab.id}</span>
						{#if count > 0}
							<span class="bg-white text-indigo-700 text-[10px] font-black rounded-full w-4 h-4 flex items-center justify-center shrink-0">{count}</span>
						{/if}
					</button>
				{/each}
			</div>
			<div class="flex items-center justify-between px-3 py-1.5 bg-indigo-800/40">
				<span class="text-[11px] text-indigo-200 font-medium truncate max-w-[170px]">
					{carts[activeCartIdx].customerName || 'No customer'}
				</span>
				<button onclick={() => clearCart(activeCartIdx)} disabled={activeItems.length === 0}
					class="flex items-center gap-1 text-[11px] text-indigo-300 hover:text-white disabled:opacity-30 transition-colors">
					<RotateCcw class="h-3 w-3" /> Clear
				</button>
			</div>
		</div>

		<!-- Customer + Discount -->
		<div class="px-4 py-3 border-b bg-gray-50 space-y-2 shrink-0">
			<div class="relative">
				<User class="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
				<input type="text" bind:value={carts[activeCartIdx].customerName}
					placeholder="Customer name (optional)"
					class="w-full pl-9 pr-3 py-2 text-sm border border-gray-200 rounded-lg bg-white focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500" />
			</div>
			<div class="relative">
				<Tag class="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
				<input type="number" bind:value={carts[activeCartIdx].discount} min="0" max="100" placeholder="Discount %"
					class="w-full pl-9 pr-3 py-2 text-sm border border-gray-200 rounded-lg bg-white focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500" />
			</div>
		</div>

		<!-- Cart Items -->
		<div class="flex-1 overflow-y-auto px-4 py-2">
			{#if activeItems.length === 0}
				<div class="flex flex-col items-center justify-center h-full text-gray-300 py-8 gap-3">
					<ShoppingCart class="h-12 w-12" />
					<div class="text-center">
						<p class="text-sm font-medium">Cart {carts[activeCartIdx].id} is empty</p>
						<p class="text-xs mt-1">
							<span class="hidden md:inline">Click products on the left to add them</span>
							<span class="md:hidden">Tap "Browse Products" below to add items</span>
						</p>
					</div>
				</div>
			{:else}
				<div class="space-y-2 py-1">
					{#each activeItems as item (item.product_id)}
						<div class="bg-gray-50 rounded-lg p-3 flex items-start gap-3">
							<div class="flex-1 min-w-0">
								<p class="text-sm font-medium text-gray-800 truncate">{item.name}</p>
								<p class="text-xs text-indigo-600 font-semibold">{fmt(item.price * item.qty)}</p>
								{#if item.batch_expiry}
									<p class="text-[10px] text-amber-600 font-medium mt-0.5 flex items-center gap-1">
										<AlertTriangle class="h-2.5 w-2.5 shrink-0" />
										Exp: {fmtDate(item.batch_expiry)} · max {item.batch_stock}
									</p>
								{/if}
							</div>
							<div class="flex items-center gap-1 shrink-0">
								<button onclick={() => updateQty(item.product_id, -1)}
									class="w-7 h-7 rounded-full bg-gray-200 hover:bg-gray-300 flex items-center justify-center transition-colors">
									<Minus class="h-3 w-3" />
								</button>
								<span class="w-7 text-center text-sm font-semibold">{item.qty}</span>
								<button onclick={() => updateQty(item.product_id, 1)}
									disabled={item.qty >= item.batch_stock}
									class="w-7 h-7 rounded-full bg-indigo-100 hover:bg-indigo-200 flex items-center justify-center transition-colors disabled:opacity-40">
									<Plus class="h-3 w-3 text-indigo-600" />
								</button>
								<button onclick={() => removeFromCart(item.product_id)}
									class="ml-1 w-7 h-7 flex items-center justify-center text-red-400 hover:text-red-600">
									<Trash2 class="h-3.5 w-3.5" />
								</button>
							</div>
						</div>
					{/each}
				</div>
			{/if}
		</div>

		<!-- Totals + Checkout + Mobile "Browse Products" btn -->
		<div class="px-4 py-4 border-t bg-gray-50 space-y-2 shrink-0">
			<div class="flex justify-between text-sm text-gray-600">
				<span>Subtotal</span><span>{fmt(subtotal)}</span>
			</div>
			{#if discountPct > 0}
				<div class="flex justify-between text-sm text-green-600">
					<span>Discount ({discountPct}%)</span><span>-{fmt(discountAmt)}</span>
				</div>
			{/if}
			<div class="flex justify-between text-lg font-bold text-gray-900 border-t pt-2">
				<span>Total</span><span class="text-indigo-600">{fmt(total)}</span>
			</div>

			<!-- Mobile: Browse Products button -->
			<button onclick={() => showProductSheet = true}
				class="md:hidden w-full flex items-center justify-center gap-2 border-2 border-indigo-300 text-indigo-700 font-semibold py-2.5 rounded-xl hover:bg-indigo-50 transition-colors text-sm">
				<PackageSearch class="h-4 w-4" />
				Browse Products
				{#if activeCount > 0}
					<span class="bg-indigo-100 text-indigo-700 text-xs font-bold px-2 py-0.5 rounded-full">{activeCount} in cart</span>
				{/if}
			</button>

			<button onclick={() => checkoutOpen = true} disabled={activeItems.length === 0}
				class="w-full bg-indigo-600 hover:bg-indigo-700 disabled:bg-gray-300 disabled:cursor-not-allowed text-white font-bold py-3 rounded-xl transition-colors text-base">
				Charge {fmt(total)}
			</button>
		</div>
	</div>
</div>

<!-- ══════════════════════════════════════════════════════════════════════════
     MOBILE: Product Bottom Sheet (95vh slide-up)
     ══════════════════════════════════════════════════════════════════════════ -->
{#if showProductSheet}
	<!-- Backdrop -->
	<button
		class="fixed inset-0 z-40 bg-black/50 md:hidden"
		onclick={() => showProductSheet = false}
		aria-label="Close product sheet"
	></button>

	<!-- Sheet -->
	<div class="fixed inset-x-0 bottom-0 z-50 h-[95vh] bg-white rounded-t-2xl flex flex-col md:hidden shadow-2xl sheet-enter">
		<!-- Drag handle + header -->
		<div class="shrink-0 pt-3 pb-2 px-4">
			<div class="w-10 h-1 bg-gray-300 rounded-full mx-auto mb-3"></div>
			<div class="flex items-center justify-between">
				<div>
					<h2 class="text-base font-bold text-gray-900">Products</h2>
					<p class="text-xs text-gray-400">Adding to Cart {carts[activeCartIdx].id}</p>
				</div>
				<button onclick={() => showProductSheet = false}
					class="p-2 rounded-full bg-gray-100 hover:bg-gray-200 transition-colors">
					<ChevronDown class="h-5 w-5 text-gray-600" />
				</button>
			</div>
		</div>

		<!-- Search -->
		<div class="shrink-0 px-4 pb-3">
			<div class="relative">
				<Search class="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
				<input type="text" bind:value={searchQuery} placeholder="Search products..."
					class="w-full pl-9 pr-4 py-2.5 text-sm border border-gray-200 rounded-xl focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 bg-gray-50" />
			</div>
		</div>

		<!-- Category chips -->
		<div class="shrink-0 px-4 pb-3 flex gap-2 overflow-x-auto tab-scroll-bar">
			<button onclick={() => selectedCategory = 'all'}
				class="px-3 py-1.5 text-sm rounded-full whitespace-nowrap shrink-0 transition-colors {selectedCategory === 'all' ? 'bg-indigo-600 text-white' : 'bg-gray-100 text-gray-600'}">All</button>
			{#each categories as cat}
				<button onclick={() => selectedCategory = cat}
					class="px-3 py-1.5 text-sm rounded-full whitespace-nowrap shrink-0 transition-colors {selectedCategory === cat ? 'bg-indigo-600 text-white' : 'bg-gray-100 text-gray-600'}">{cat}</button>
			{/each}
		</div>

		<!-- Divider -->
		<div class="shrink-0 h-px bg-gray-100 mx-4"></div>

		<!-- Product Grid (scrollable) -->
		<div class="flex-1 overflow-y-auto">
			{@render productGrid(true)}
		</div>

		<!-- Bottom action bar -->
		<div class="shrink-0 px-4 py-3 border-t bg-white safe-bottom">
			<button onclick={() => showProductSheet = false}
				disabled={activeItems.length === 0}
				class="w-full bg-indigo-600 hover:bg-indigo-700 disabled:bg-gray-300 disabled:cursor-not-allowed text-white font-bold py-3 rounded-xl transition-colors flex items-center justify-center gap-2">
				<CheckCircle class="h-5 w-5" />
				Done · {activeCount} item{activeCount !== 1 ? 's' : ''} · {fmt(total)}
			</button>
		</div>
	</div>
{/if}

<!-- ══════════════════════════════════════════════════════════════════════════
     SHARED: Product grid snippet
     ══════════════════════════════════════════════════════════════════════════ -->
{#snippet productGrid(mobile = false)}
	<div class="flex-1 overflow-y-auto p-4 {mobile ? '' : 'h-full'}">
		{#if loading}
			<div class="flex items-center justify-center h-48">
				<div class="animate-spin rounded-full h-10 w-10 border-b-2 border-indigo-600"></div>
			</div>
		{:else if !userBranchId}
			<div class="flex flex-col items-center justify-center h-48 text-gray-400 text-center gap-3">
				<ShoppingCart class="h-14 w-14 opacity-30" />
				<p class="text-sm font-medium">No branch assigned</p>
				<p class="text-xs">Ask your admin to assign you to a branch.</p>
			</div>
		{:else if filteredProducts.length === 0}
			<div class="flex flex-col items-center justify-center h-48 text-gray-400 gap-2">
				<ShoppingCart class="h-14 w-14 opacity-30" />
				<p class="font-medium">No products found</p>
				<p class="text-sm">Try a different search</p>
			</div>
		{:else}
			<div class="grid grid-cols-3 sm:grid-cols-4 md:grid-cols-4 lg:grid-cols-5 xl:grid-cols-6 gap-3">
				{#each filteredProducts as product}
					{@const inCart = carts[activeCartIdx].items.find(i => i.product_id === product.product_id)}
					<button onclick={() => { addToCart(product); }}
						class="bg-white rounded-xl border-2 p-2.5 text-left hover:border-indigo-400 hover:shadow-md transition-all relative
							{inCart ? 'border-indigo-500 bg-indigo-50' : product.near_expiry ? 'border-amber-300' : 'border-gray-100'}">
						<div class="w-full aspect-square bg-gradient-to-br from-gray-100 to-gray-50 rounded-lg mb-2 flex items-center justify-center overflow-hidden">
							{#if product.image_url}
								<img src={product.image_url} alt={product.name} class="w-full h-full object-cover rounded-lg" />
							{:else}
								<Tag class="h-6 w-6 text-gray-300" />
							{/if}
						</div>
						<p class="text-xs font-semibold text-gray-800 leading-tight truncate">{product.name}</p>
						<p class="text-xs text-indigo-600 font-bold mt-1">{fmt(product.price)}</p>
						<p class="text-[10px] text-gray-400 mt-0.5">Qty: {product.stock_quantity}</p>
						{#if product.near_expiry}
							<div class="flex items-center gap-0.5 mt-1">
								<AlertTriangle class="h-2.5 w-2.5 text-amber-500 shrink-0" />
								<span class="text-[9px] text-amber-600 font-bold truncate">Exp: {fmtDate(product.expiry_date)}</span>
							</div>
						{/if}
						{#if inCart}
							<div class="absolute top-1.5 right-1.5 bg-indigo-600 text-white text-[10px] rounded-full w-5 h-5 flex items-center justify-center font-bold shadow">
								{inCart.qty}
							</div>
						{/if}
					</button>
				{/each}
			</div>
		{/if}
	</div>
{/snippet}

<!-- ── Checkout Modal ──────────────────────────────────────────────────────── -->
{#if checkoutOpen}
	<div class="fixed inset-0 bg-black/50 z-50 flex items-end sm:items-center justify-center p-0 sm:p-4">
		<div class="bg-white rounded-t-2xl sm:rounded-2xl shadow-2xl w-full sm:max-w-md max-h-[95vh] overflow-y-auto">
			<div class="flex items-center justify-between p-5 border-b sticky top-0 bg-white z-10">
				<div>
					<h2 class="text-lg font-bold text-gray-900">Complete Payment</h2>
					<p class="text-xs text-gray-400 mt-0.5">
						Cart {carts[activeCartIdx].id}
						{#if carts[activeCartIdx].customerName}· {carts[activeCartIdx].customerName}{/if}
					</p>
				</div>
				<button onclick={() => checkoutOpen = false} class="p-2 rounded-lg hover:bg-gray-100">
					<X class="h-5 w-5 text-gray-500" />
				</button>
			</div>
			<div class="p-5 space-y-5">
				<div class="bg-indigo-50 rounded-xl p-4">
					<div class="flex justify-between text-sm text-gray-600 mb-1"><span>Subtotal</span><span>{fmt(subtotal)}</span></div>
					{#if discountPct > 0}
						<div class="flex justify-between text-sm text-green-600 mb-1"><span>Discount</span><span>-{fmt(discountAmt)}</span></div>
					{/if}
					<div class="flex justify-between text-xl font-bold text-indigo-700 border-t border-indigo-200 pt-2">
						<span>Total</span><span>{fmt(total)}</span>
					</div>
				</div>
				<div>
					<p class="text-sm font-medium text-gray-700 mb-2">Payment Method</p>
					<div class="grid grid-cols-3 gap-2">
						{#each [{ id: 'cash', label: 'Cash', icon: Banknote }, { id: 'card', label: 'Card', icon: CreditCard }, { id: 'transfer', label: 'Transfer', icon: Smartphone }] as method}
							{@const Icon = method.icon}
							<button onclick={() => paymentMethod = method.id as any}
								class="flex flex-col items-center gap-1.5 py-3 rounded-xl border-2 transition-all {paymentMethod === method.id ? 'border-indigo-500 bg-indigo-50 text-indigo-700' : 'border-gray-200 text-gray-600 hover:border-gray-300'}">
								<Icon class="h-5 w-5" /><span class="text-xs font-medium">{method.label}</span>
							</button>
						{/each}
					</div>
				</div>
				{#if paymentMethod === 'cash'}
					<div>
						<label for="cash_in" class="block text-sm font-medium text-gray-700 mb-1">Cash Received</label>
						<input id="cash_in" type="number" bind:value={cashReceived} placeholder="0.00" step="0.01"
							class="w-full px-4 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 text-lg font-bold" />
						{#if parseFloat(cashReceived) >= total}
							<div class="flex justify-between mt-2 text-green-600 font-semibold">
								<span>Change:</span><span>{fmt(change)}</span>
							</div>
						{/if}
					</div>
				{/if}
				<button onclick={processSale}
					disabled={processingPayment || (paymentMethod === 'cash' && parseFloat(cashReceived || '0') < total)}
					class="w-full bg-green-600 hover:bg-green-700 disabled:bg-gray-300 disabled:cursor-not-allowed text-white font-bold py-3.5 rounded-xl transition-colors text-base flex items-center justify-center gap-2">
					<CheckCircle class="h-5 w-5" />
					{processingPayment ? 'Processing...' : 'Complete Sale'}
				</button>
			</div>
		</div>
	</div>
{/if}

<!-- ── Sale Success Toast ───────────────────────────────────────────────────── -->
{#if saleSuccess}
	<div class="fixed bottom-6 right-4 left-4 sm:left-auto sm:w-auto sm:max-w-sm bg-green-600 text-white rounded-xl shadow-2xl p-4 z-[60] flex items-center gap-3">
		<CheckCircle class="h-6 w-6 flex-shrink-0" />
		<div class="flex-1">
			<p class="font-semibold">Sale Completed!</p>
			<p class="text-sm text-green-100">Total: {fmt(lastSale?.total_amount || 0)}</p>
		</div>
		<button onclick={() => saleSuccess = false} class="text-green-200 hover:text-white">
			<X class="h-4 w-4" />
		</button>
	</div>
{/if}

<style>
	.tab-scroll-bar { scrollbar-width: thin; scrollbar-color: rgba(165,180,252,0.5) transparent; }
	.tab-scroll-bar::-webkit-scrollbar { height: 3px; }
	.tab-scroll-bar::-webkit-scrollbar-thumb { background: rgba(165,180,252,0.5); border-radius: 99px; }

	/* Slide-up animation for the product sheet */
	.sheet-enter {
		animation: slideUp 0.32s cubic-bezier(0.32, 0.72, 0, 1) both;
	}
	@keyframes slideUp {
		from { transform: translateY(100%); }
		to   { transform: translateY(0); }
	}

	/* Safe area padding for iOS home bar */
	.safe-bottom { padding-bottom: max(0.75rem, env(safe-area-inset-bottom)); }
</style>
