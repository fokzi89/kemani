<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase';
	import {
		Search, ShoppingCart, Plus, Minus, Trash2, CreditCard,
		Banknote, Smartphone, X, CheckCircle, Tag, User, Printer
	} from 'lucide-svelte';

	// State
	let products = $state<any[]>([]);
	let filteredProducts = $state<any[]>([]);
	let cart = $state<any[]>([]);
	let searchQuery = $state('');
	let selectedCategory = $state('all');
	let categories = $state<string[]>([]);
	let tenantId = $state('');
	let userBranchId = $state('');
	let loading = $state(true);
	let checkoutOpen = $state(false);
	let paymentMethod = $state<'cash' | 'card' | 'transfer'>('cash');
	let cashReceived = $state('');
	let saleSuccess = $state(false);
	let lastSale = $state<any>(null);
	let customerName = $state('');
	let discount = $state(0);
	let processingPayment = $state(false);

	// Computed
	let subtotal = $derived(cart.reduce((sum, item) => sum + item.price * item.qty, 0));
	let discountAmt = $derived(subtotal * (discount / 100));
	let total = $derived(subtotal - discountAmt);
	let change = $derived(paymentMethod === 'cash' ? Math.max(0, parseFloat(cashReceived || '0') - total) : 0);
	let cartCount = $derived(cart.reduce((sum, item) => sum + item.qty, 0));

	onMount(async () => {
		const { data: { session } } = await supabase.auth.getSession();
		if (!session) return;

		const { data: userData } = await supabase
			.from('users').select('tenant_id, branch_id').eq('id', session.user.id).single();
		
		if (userData) {
			tenantId = userData.tenant_id;
			userBranchId = userData.branch_id;
			if (userBranchId) await loadProducts();
		}
		loading = false;
	});

	async function loadProducts() {
		if (!userBranchId) return;
		const { data } = await supabase
			.from('branch_inventory')
			.select('*, products(*)')
			.eq('branch_id', userBranchId)
			.eq('is_active', true)
			.gt('stock_quantity', 0);
			
		products = (data || []).map(bi => ({
			...bi.products,
			stock_quantity: bi.stock_quantity,
			price: bi.unit_cost || 0
		}));
		filteredProducts = products;
		const cats = [...new Set(products.map(p => p.category).filter(Boolean))];
		categories = cats;
		filterProducts();
	}

	function filterProducts() {
		let result = products;
		if (selectedCategory !== 'all') result = result.filter(p => p.category === selectedCategory);
		if (searchQuery) result = result.filter(p =>
			p.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
			(p.barcode && p.barcode.toLowerCase().includes(searchQuery.toLowerCase()))
		);
		filteredProducts = result;
	}

	$effect(() => { searchQuery; selectedCategory; filterProducts(); });

	function addToCart(product: any) {
		const existing = cart.find(i => i.id === product.id);
		if (existing) {
			if (existing.qty < product.stock_quantity) existing.qty++;
		} else {
			cart = [...cart, { ...product, qty: 1, price: parseFloat(product.price) }];
		}
	}

	function updateQty(id: string, delta: number) {
		cart = cart.map(item => {
			if (item.id === id) {
				const newQty = item.qty + delta;
				if (newQty <= 0) return null;
				return { ...item, qty: Math.min(newQty, item.stock_quantity) };
			}
			return item;
		}).filter(Boolean) as any[];
	}

	function removeFromCart(id: string) { cart = cart.filter(i => i.id !== id); }
	function clearCart() { cart = []; customerName = ''; discount = 0; }

	async function processSale() {
		if (cart.length === 0) return;
		processingPayment = true;
		try {
			const saleData = {
				tenant_id: tenantId,
				subtotal,
				discount_amount: discountAmt,
				total_amount: total,
				payment_method: paymentMethod,
				cash_received: paymentMethod === 'cash' ? parseFloat(cashReceived) : null,
				change_given: paymentMethod === 'cash' ? change : null,
				customer_name: customerName || null,
				status: 'completed',
				items: cart.map(i => ({ product_id: i.id, name: i.name, qty: i.qty, unit_price: i.price, total: i.price * i.qty }))
			};

			const { data: { session } } = await supabase.auth.getSession();
			const sale_number = `SALE-${Date.now().toString().slice(-6)}`;
			
			const { data: sale, error } = await supabase.from('sales').insert({
				tenant_id: tenantId,
				branch_id: userBranchId,
				cashier_id: session?.user.id,
				sale_number: sale_number,
				subtotal,
				discount_amount: discountAmt,
				total_amount: total,
				payment_method: paymentMethod,
				cash_received: parseFloat(cashReceived) || null,
				change_given: change || null,
				customer_name: customerName || null,
				status: 'completed'
			}).select().single();

			if (error) throw error;

			if (sale) {
				await supabase.from('sale_items').insert(
					cart.map(i => ({
						sale_id: sale.id,
						product_id: i.id,
						product_name: i.name,
						quantity: i.qty,
						unit_price: i.price,
						total_price: i.price * i.qty
					}))
				);

				// Update stock in branch_inventory
				for (const item of cart) {
					await supabase.from('branch_inventory')
						.update({ 
							stock_quantity: Math.max(0, item.stock_quantity - item.qty),
							updated_at: new Date().toISOString()
						})
						.eq('branch_id', userBranchId)
						.eq('product_id', item.id);
				}
			}

			lastSale = { ...saleData, id: sale?.id, date: new Date() };
			saleSuccess = true;
			checkoutOpen = false;
			clearCart();
			await loadProducts();
		} catch (err: any) {
			alert('Sale failed: ' + err.message);
		} finally {
			processingPayment = false;
		}
	}

	function formatCurrency(amount: number) {
		return '₦' + amount.toLocaleString('en-NG', { minimumFractionDigits: 2 });
	}
</script>

<svelte:head><title>POS – Kemani POS</title></svelte:head>

<div class="h-screen flex overflow-hidden bg-gray-50">
	<!-- Products Panel -->
	<div class="flex-1 flex flex-col overflow-hidden">
		<!-- Top Bar -->
		<div class="bg-white border-b px-4 py-3 flex items-center gap-3">
			<div class="relative flex-1 max-w-md">
				<Search class="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
				<input type="text" bind:value={searchQuery} placeholder="Search products or scan barcode..."
					class="w-full pl-9 pr-4 py-2 text-sm border border-gray-200 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500" />
			</div>
			<!-- Category tabs -->
			<div class="flex gap-2 overflow-x-auto">
				<button onclick={() => selectedCategory = 'all'}
					class="px-3 py-1.5 text-sm rounded-full whitespace-nowrap transition-colors {selectedCategory === 'all' ? 'bg-indigo-600 text-white' : 'bg-gray-100 text-gray-600 hover:bg-gray-200'}">
					All
				</button>
				{#each categories as cat}
					<button onclick={() => selectedCategory = cat}
						class="px-3 py-1.5 text-sm rounded-full whitespace-nowrap transition-colors {selectedCategory === cat ? 'bg-indigo-600 text-white' : 'bg-gray-100 text-gray-600 hover:bg-gray-200'}">
						{cat}
					</button>
				{/each}
			</div>
		</div>

		<!-- Products Grid -->
		<div class="flex-1 overflow-y-auto p-4">
			{#if loading}
				<div class="flex items-center justify-center h-full">
					<div class="animate-spin rounded-full h-10 w-10 border-b-2 border-indigo-600"></div>
				</div>
			{:else if filteredProducts.length === 0}
				<div class="flex flex-col items-center justify-center h-full text-gray-400">
					<ShoppingCart class="h-16 w-16 mb-3 opacity-30" />
					<p class="text-lg font-medium">No products found</p>
					<p class="text-sm">Try a different search or category</p>
				</div>
			{:else}
				<div class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 xl:grid-cols-6 gap-3">
					{#each filteredProducts as product}
						{@const inCart = cart.find(i => i.id === product.id)}
						<button onclick={() => addToCart(product)}
							class="bg-white rounded-xl border-2 p-3 text-left hover:border-indigo-400 hover:shadow-md transition-all relative {inCart ? 'border-indigo-500 bg-indigo-50' : 'border-gray-100'}">
							<!-- Product image placeholder -->
							<div class="w-full aspect-square bg-gradient-to-br from-gray-100 to-gray-50 rounded-lg mb-2 flex items-center justify-center">
								{#if product.image_url}
									<img src={product.image_url} alt={product.name} class="w-full h-full object-cover rounded-lg" />
								{:else}
									<Tag class="h-8 w-8 text-gray-300" />
								{/if}
							</div>
							<p class="text-xs font-semibold text-gray-800 leading-tight truncate">{product.name}</p>
							<p class="text-xs text-indigo-600 font-bold mt-1">{formatCurrency(product.price)}</p>
							<p class="text-xs text-gray-400 mt-0.5">Stock: {product.stock_quantity}</p>
							{#if inCart}
								<div class="absolute top-2 right-2 bg-indigo-600 text-white text-xs rounded-full w-5 h-5 flex items-center justify-center font-bold">
									{inCart.qty}
								</div>
							{/if}
						</button>
					{/each}
				</div>
			{/if}
		</div>
	</div>

	<!-- Cart Panel -->
	<div class="w-80 xl:w-96 bg-white border-l flex flex-col shadow-lg">
		<!-- Cart Header -->
		<div class="px-4 py-3 border-b flex items-center justify-between bg-indigo-600 text-white">
			<div class="flex items-center gap-2">
				<ShoppingCart class="h-5 w-5" />
				<h2 class="font-semibold">Cart ({cartCount} items)</h2>
			</div>
			{#if cart.length > 0}
				<button onclick={clearCart} class="text-indigo-200 hover:text-white text-sm transition-colors">Clear</button>
			{/if}
		</div>

		<!-- Customer + Discount -->
		<div class="px-4 py-3 border-b bg-gray-50 space-y-2">
			<div class="relative">
				<User class="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
				<input type="text" bind:value={customerName} placeholder="Customer name (optional)"
					class="w-full pl-9 pr-3 py-2 text-sm border border-gray-200 rounded-lg bg-white focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500" />
			</div>
			<div class="relative">
				<Tag class="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
				<input type="number" bind:value={discount} min="0" max="100" placeholder="Discount %"
					class="w-full pl-9 pr-3 py-2 text-sm border border-gray-200 rounded-lg bg-white focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500" />
			</div>
		</div>

		<!-- Cart Items -->
		<div class="flex-1 overflow-y-auto px-4 py-2">
			{#if cart.length === 0}
				<div class="flex flex-col items-center justify-center h-full text-gray-300 py-8">
					<ShoppingCart class="h-12 w-12 mb-2" />
					<p class="text-sm">Cart is empty</p>
					<p class="text-xs mt-1">Click products to add them</p>
				</div>
			{:else}
				<div class="space-y-2">
					{#each cart as item}
						<div class="bg-gray-50 rounded-lg p-3 flex items-center gap-3">
							<div class="flex-1 min-w-0">
								<p class="text-sm font-medium text-gray-800 truncate">{item.name}</p>
								<p class="text-xs text-indigo-600 font-semibold">{formatCurrency(item.price * item.qty)}</p>
							</div>
							<div class="flex items-center gap-1">
								<button onclick={() => updateQty(item.id, -1)} class="w-6 h-6 rounded-full bg-gray-200 hover:bg-gray-300 flex items-center justify-center transition-colors">
									<Minus class="h-3 w-3" />
								</button>
								<span class="w-6 text-center text-sm font-semibold">{item.qty}</span>
								<button onclick={() => updateQty(item.id, 1)} class="w-6 h-6 rounded-full bg-indigo-100 hover:bg-indigo-200 flex items-center justify-center transition-colors">
									<Plus class="h-3 w-3 text-indigo-600" />
								</button>
								<button onclick={() => removeFromCart(item.id)} class="ml-1 w-6 h-6 flex items-center justify-center text-red-400 hover:text-red-600 transition-colors">
									<Trash2 class="h-3.5 w-3.5" />
								</button>
							</div>
						</div>
					{/each}
				</div>
			{/if}
		</div>

		<!-- Totals + Checkout -->
		<div class="px-4 py-4 border-t bg-gray-50 space-y-2">
			<div class="flex justify-between text-sm text-gray-600">
				<span>Subtotal</span><span>{formatCurrency(subtotal)}</span>
			</div>
			{#if discount > 0}
				<div class="flex justify-between text-sm text-green-600">
					<span>Discount ({discount}%)</span><span>-{formatCurrency(discountAmt)}</span>
				</div>
			{/if}
			<div class="flex justify-between text-lg font-bold text-gray-900 border-t pt-2">
				<span>Total</span><span class="text-indigo-600">{formatCurrency(total)}</span>
			</div>
			<button onclick={() => checkoutOpen = true} disabled={cart.length === 0}
				class="w-full bg-indigo-600 hover:bg-indigo-700 disabled:bg-gray-300 disabled:cursor-not-allowed text-white font-bold py-3 rounded-xl transition-colors text-base">
				Charge {formatCurrency(total)}
			</button>
		</div>
	</div>
</div>

<!-- Checkout Modal -->
{#if checkoutOpen}
	<div class="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
		<div class="bg-white rounded-2xl shadow-2xl w-full max-w-md">
			<div class="flex items-center justify-between p-5 border-b">
				<h2 class="text-lg font-bold text-gray-900">Complete Payment</h2>
				<button onclick={() => checkoutOpen = false} class="p-1 rounded-lg hover:bg-gray-100 transition-colors">
					<X class="h-5 w-5 text-gray-500" />
				</button>
			</div>

			<div class="p-5 space-y-5">
				<!-- Order Summary -->
				<div class="bg-indigo-50 rounded-xl p-4">
					<div class="flex justify-between text-sm text-gray-600 mb-1">
						<span>Subtotal</span><span>{formatCurrency(subtotal)}</span>
					</div>
					{#if discount > 0}
						<div class="flex justify-between text-sm text-green-600 mb-1">
							<span>Discount</span><span>-{formatCurrency(discountAmt)}</span>
						</div>
					{/if}
					<div class="flex justify-between text-xl font-bold text-indigo-700 border-t border-indigo-200 pt-2">
						<span>Total</span><span>{formatCurrency(total)}</span>
					</div>
				</div>

				<!-- Payment Method -->
				<div>
					<p class="text-sm font-medium text-gray-700 mb-2">Payment Method</p>
					<div class="grid grid-cols-3 gap-2">
						{#each [
							{ id: 'cash', label: 'Cash', icon: Banknote },
							{ id: 'card', label: 'Card', icon: CreditCard },
							{ id: 'transfer', label: 'Transfer', icon: Smartphone }
						] as method}
							{@const Icon = method.icon}
							<button onclick={() => paymentMethod = method.id as any}
								class="flex flex-col items-center gap-1.5 py-3 rounded-xl border-2 transition-all {paymentMethod === method.id ? 'border-indigo-500 bg-indigo-50 text-indigo-700' : 'border-gray-200 text-gray-600 hover:border-gray-300'}">
								<Icon class="h-5 w-5" /><span class="text-xs font-medium">{method.label}</span>
							</button>
						{/each}
					</div>
				</div>

				<!-- Cash Received -->
				{#if paymentMethod === 'cash'}
					<div>
						<label for="cash_received" class="block text-sm font-medium text-gray-700 mb-1">Cash Received</label>
						<input id="cash_received" type="number" bind:value={cashReceived} placeholder="0.00" step="0.01"
							class="w-full px-4 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-lg font-bold" />
						{#if parseFloat(cashReceived) >= total}
							<div class="flex justify-between mt-2 text-green-600 font-semibold">
								<span>Change:</span><span>{formatCurrency(change)}</span>
							</div>
						{/if}
					</div>
				{/if}

				<button onclick={processSale} disabled={processingPayment || (paymentMethod === 'cash' && parseFloat(cashReceived || '0') < total)}
					class="w-full bg-green-600 hover:bg-green-700 disabled:bg-gray-300 disabled:cursor-not-allowed text-white font-bold py-3.5 rounded-xl transition-colors text-base flex items-center justify-center gap-2">
					<CheckCircle class="h-5 w-5" />
					{processingPayment ? 'Processing...' : 'Complete Sale'}
				</button>
			</div>
		</div>
	</div>
{/if}

<!-- Sale Success Toast -->
{#if saleSuccess}
	<div class="fixed bottom-6 right-6 bg-green-600 text-white rounded-xl shadow-2xl p-4 z-50 flex items-center gap-3 max-w-sm animate-in slide-in-from-right">
		<CheckCircle class="h-6 w-6 flex-shrink-0" />
		<div class="flex-1">
			<p class="font-semibold">Sale Completed!</p>
			<p class="text-sm text-green-100">Total: {formatCurrency(lastSale?.total_amount || 0)}</p>
		</div>
		<button onclick={() => saleSuccess = false} class="text-green-200 hover:text-white">
			<X class="h-4 w-4" />
		</button>
	</div>
{/if}
