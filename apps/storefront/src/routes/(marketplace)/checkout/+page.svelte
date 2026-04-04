<script lang="ts">
	import { onMount } from 'svelte';
	import { goto } from '$app/navigation';
	import { authStore, isAuthenticated, currentUser } from '$lib/stores/auth';
	import { PUBLIC_APP_URL } from '$env/static/public';
	import { 
		ShieldCheck, CreditCard, Truck, ArrowLeft, 
		CheckCircle2, Package, Mail, MapPin, ChevronRight, ShoppingBag, ArrowRight, User
	} from 'lucide-svelte';

	export let data;
	import { supabase } from '$lib/supabase';

	$: storefront = data.storefront;
    $: brandColor = storefront?.brand_color || '#4f46e5';

	let orderData: any = null;
	let isLoading = false;
	let error = '';
	let success = '';
    let step = 1; 

	onMount(() => {
		// Wait for auth initialization before checking status
		const unsubscribe = authStore.subscribe(state => {
			if (state.initialized && !$isAuthenticated) {
				const next = window.location.href;
				window.location.href = `${PUBLIC_APP_URL}/auth/portal?next=${encodeURIComponent(next)}`;
			}
		});

		const savedData = localStorage.getItem('checkout_data');
		if (!savedData) {
			goto('/');
			return;
		}
		orderData = JSON.parse(savedData);

		return () => {
			unsubscribe();
		};
	});

	async function completeOrder() {
		isLoading = true;
		error = '';

		try {
			// Format items as required by the RPC
			const formattedItems = orderData.items.map((i: any) => ({
				product_id: i.product_id || i.id,
				product_name: i.product_name || i.name,
				quantity: i.quantity,
				unit_price: i.price,
				subtotal: i.price * i.quantity
			}));

			const { data: orderId, error: rpcError } = await supabase.rpc('checkout_storefront_order', {
				p_tenant_id: storefront.id,
				p_branch_id: orderData.branch_id || storefront.branches?.[0]?.id, // ensure branch_id is present
				p_customer_id: $currentUser?.id,
				p_order_type: orderData.order_type === 'delivery' ? 'delivery' : 'instore', // Default to instore if fallback
				p_fulfillment_type: orderData.order_type === 'delivery' ? 'delivery' : 'pickup',
				p_subtotal: orderData.subtotal,
				p_delivery_fee: orderData.delivery_fee,
				p_tax_amount: orderData.tax,
				p_total_amount: orderData.total,
				p_delivery_address_id: orderData.delivery_address_id || null,
				p_special_instructions: orderData.special_instructions || null,
				p_items: formattedItems
			});

			if (rpcError) throw rpcError;

			localStorage.removeItem('cart');
			localStorage.removeItem('checkout_data');

			success = 'Order placed successfully!';
            step = 3; 

			setTimeout(() => {
				goto(`/profile`);
			}, 3000);
		} catch (err: any) {
			console.error("Checkout Error:", err);
			error = err.message || 'Failed to place order. Please try again.';
		} finally {
			isLoading = false;
		}
	}
</script>

<svelte:head>
	<title>Checkout | {storefront?.name || 'Secure Checkout'}</title>
</svelte:head>

<div class="checkout-page">
	<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-10 md:py-16">
		
		<div class="checkout-layout">
			<!-- Main Content -->
			<div class="checkout-main">
				{#if success}
					<div class="success-screen">
						<div class="success-icon">
							<CheckCircle2 class="w-12 h-12" />
						</div>
						<h2 class="success-title">Your order is secured</h2>
						<p class="success-sub">A confirmation has been sent to your email. Your medics journey continues.</p>
						
                        <div class="success-steps">
                            <div class="step-item">
                                <Package class="step-icon" />
                                <span>Curating your items</span>
                            </div>
                            <div class="step-item">
                                <Truck class="step-icon" />
                                <span>Express priority dispatch</span>
                            </div>
                        </div>

						<button 
							on:click={() => goto('/profile')}
							class="btn-primary success-btn"
						>
							View Collection Status
						</button>
					</div>
				{:else}
					<!-- Process Header -->
					<header class="process-header">
						<div class="process-steps">
							<div class="step {step >= 1 ? 'active' : ''}">Details</div>
							<div class="step-sep"></div>
							<div class="step {step >= 2 ? 'active' : ''}">Payment</div>
						</div>
						<h1 class="page-title">Finalize Order</h1>
					</header>

					{#if error}
						<div class="alert alert-error">
							<ShieldCheck class="w-4 h-4" />
							<span>{error}</span>
						</div>
					{/if}

					<div class="form-sections">
						<!-- Identity Section -->
						<section class="form-section">
							<h3 class="section-label">Identity & Context</h3>
							<div class="info-card">
								<div class="info-item">
									<div class="item-icon-box"><Mail class="w-5 h-5" /></div>
									<div class="item-text">
										<p class="item-label">Account</p>
										<p class="item-val">{$currentUser?.email || 'Guest Session'}</p>
									</div>
								</div>
								<div class="info-item">
									<div class="item-icon-box"><MapPin class="w-5 h-5" /></div>
									<div class="item-text">
										<p class="item-label">Delivery</p>
										<p class="item-val">{orderData?.order_type === 'delivery' ? 'Standard Home Delivery' : 'Self Collection'}</p>
									</div>
								</div>
							</div>
						</section>

						<!-- Payment Section -->
						<section class="form-section">
							<h3 class="section-label">Settlement Method</h3>
							<div class="payment-card active">
								<div class="payment-info">
									<div class="item-icon-box"><CreditCard class="w-5 h-5" /></div>
									<div class="item-text">
										<p class="item-val">Paystack Integrated</p>
										<p class="item-sub">Cards, Transfers, Bank, USSD</p>
									</div>
								</div>
								<div class="payment-check"><CheckCircle2 class="w-4 h-4" /></div>
							</div>
						</section>

						<!-- Quality Notice -->
						<div class="quality-box">
							<ShieldCheck class="quality-icon" />
							<div class="quality-text">
								<p class="quality-title">Secure & Encrypted</p>
								<p class="quality-sub">Your financial data is processed via industrial-grade encryption and never stored locally.</p>
							</div>
						</div>
					</div>
				{/if}
			</div>

			<!-- Sidebar Summary -->
			{#if orderData && !success}
				<aside class="checkout-summary">
					<div class="summary-box">
						<header class="summary-header">
							<h2 class="summary-title">Summary</h2>
							<ShoppingBag class="summary-icon" />
						</header>

						<div class="summary-items">
							{#each orderData.items as item}
								<div class="summary-item">
									<div class="item-img-wrap">
										<img src={item.product_image} alt={item.product_name} class="item-img shadow-sm" />
									</div>
									<div class="item-info">
										<h4 class="item-name">{item.product_name}</h4>
										<p class="item-qty">Qty: {item.quantity}</p>
									</div>
									<p class="item-total">₦{(item.price * item.quantity).toLocaleString()}</p>
								</div>
							{/each}
						</div>

						<div class="summary-rows">
							<div class="summary-row">
								<span>Merchandise</span>
								<span>₦{orderData.subtotal.toLocaleString()}</span>
							</div>
							<div class="summary-row">
								<span>Processing (VAT)</span>
								<span>₦{orderData.tax.toLocaleString(undefined, { maximumFractionDigits: 0 })}</span>
							</div>
							{#if orderData.delivery_fee > 0}
								<div class="summary-row">
									<span>Logistics</span>
									<span>₦{orderData.delivery_fee.toLocaleString()}</span>
								</div>
							{/if}
						</div>

						<div class="summary-total-row">
							<p class="total-label">Subtotal Due</p>
							<p class="total-val">₦{orderData.total.toLocaleString(undefined, { maximumFractionDigits: 0 })}</p>
						</div>

						<button
							on:click={completeOrder}
							disabled={isLoading || !$isAuthenticated}
							class="btn-primary checkout-btn"
						>
							{#if isLoading}
								<div class="loader-dot"></div> Securing...
							{:else}
								Authorize & Pay <ArrowRight class="btn-icon" />
							{/if}
						</button>
                        
                        <a href="/cart" class="btn-back">Modify Selection</a>
					</div>
				</aside>
			{/if}
		</div>
	</div>
</div>

<style>
	/* ─── TOKENS ─── */
	:root {
		--font-display: 'Playfair Display', Georgia, serif;
		--font-body: 'Inter', -apple-system, sans-serif;
		--surface: #faf9f6;
		--on-surface: #1a1c1a;
		--on-surface-muted: #6b7280;
		--border: #f0eeea;
		--accent: #785a1a;
		--radius: 8px;
	}

	.checkout-page {
		background: var(--surface);
		color: var(--on-surface);
		font-family: var(--font-body);
		min-height: 100vh;
	}

	/* ─── LAYOUT ─── */
	.checkout-layout {
		display: grid;
		grid-template-columns: 1fr;
		gap: 4rem;
	}
	@media (min-width: 1024px) {
		.checkout-layout { grid-template-columns: 1fr 380px; gap: 6rem; }
	}

	.checkout-main { display: flex; flex-direction: column; }

	/* ─── SUCCESS SCREEN ─── */
	.success-screen { 
		text-align: center; padding: 6rem 2rem; background: #fff; 
		border-radius: var(--radius); border: 1px solid var(--border);
		animation: fadeIn 0.6s ease;
	}
	@keyframes fadeIn { from { opacity: 0; transform: translateY(10px); } to { opacity: 1; transform: translateY(0); } }
	
	.success-icon { width: 80px; height: 80px; background: #f0fdf4; color: #059669; border-radius: 50%; display: flex; align-items: center; justify-content: center; margin: 0 auto 2rem; }
	.success-title { font-family: var(--font-display); font-size: 3rem; font-weight: 500; margin-bottom: 1rem; }
	.success-sub { font-size: 14px; color: var(--on-surface-muted); max-width: 400px; margin: 0 auto 3rem; line-height: 1.6; }
	
	.success-steps { display: flex; flex-direction: column; gap: 1rem; max-width: 300px; margin: 0 auto 3rem; text-align: left; }
	.step-item { display: flex; align-items: center; gap: 12px; font-size: 12px; font-weight: 600; color: var(--on-surface-muted); }
	.step-icon { width: 16px; height: 16px; color: var(--on-surface); }
	.success-btn { display: inline-flex; width: auto; padding-left: 3rem; padding-right: 3rem; }

	/* ─── HEADER ─── */
	.process-header { margin-bottom: 3.5rem; }
	.process-steps { display: flex; align-items: center; gap: 1rem; margin-bottom: 1.5rem; }
	.step { font-size: 10px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.1em; color: var(--on-surface-muted); }
	.step.active { color: var(--on-surface); border-bottom: 1px solid var(--on-surface); padding-bottom: 2px; }
	.step-sep { width: 24px; height: 1px; background: var(--border); }
	.page-title { font-family: var(--font-display); font-size: 3rem; font-weight: 500; line-height: 1; }

	.alert { margin-bottom: 2rem; padding: 1.25rem; border-radius: 8px; font-size: 12px; display: flex; align-items: center; gap: 10px; }
	.alert-error { background: #fef2f2; border: 1px solid #fee2e2; color: #b91c1c; }

	/* ─── FORM ─── */
	.form-sections { display: flex; flex-direction: column; gap: 3rem; }
	.section-label { font-size: 11px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.1em; color: var(--on-surface-muted); margin-bottom: 1.5rem; }
	
	.info-card { display: flex; flex-direction: column; gap: 1.5rem; padding: 2rem; background: #fff; border: 1px solid var(--border); border-radius: var(--radius); }
	.info-item { display: flex; align-items: center; gap: 1.25rem; }
	.item-icon-box { width: 44px; height: 44px; background: var(--surface); border-radius: 6px; display: flex; align-items: center; justify-content: center; color: var(--on-surface-muted); }
	.item-label { font-size: 10px; font-weight: 700; text-transform: uppercase; color: var(--on-surface-muted); margin-bottom: 2px; }
	.item-val { font-size: 14px; font-weight: 600; color: var(--on-surface); }
	.item-sub { font-size: 11px; color: var(--on-surface-muted); }

	.payment-card { display: flex; justify-content: space-between; align-items: center; padding: 1.5rem; background: #fff; border: 1px solid var(--border); border-radius: var(--radius); cursor: pointer; transition: all 0.2s; }
	.payment-card.active { border-color: var(--on-surface); background: rgba(0,0,0,0.01); }
	.payment-info { display: flex; align-items: center; gap: 1.25rem; }
	.payment-check { color: #059669; }

	.quality-box { display: flex; align-items: center; gap: 1.5rem; padding: 1.5rem; background: var(--on-surface); color: #fff; border-radius: var(--radius); }
	.quality-icon { width: 24px; height: 24px; color: #fff; opacity: 0.5; }
	.quality-title { font-size: 11px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.1em; margin-bottom: 2px; }
	.quality-sub { font-size: 11px; color: rgba(255,255,255,0.6); line-height: 1.5; max-width: 320px; }

	/* ─── SUMMARY ─── */
	.checkout-summary { position: sticky; top: 120px; }
	.summary-box { background: #fff; border: 1px solid var(--border); border-radius: var(--radius); padding: 2rem; box-shadow: 0 4px 30px rgba(0,0,0,0.02); }
	.summary-header { display: flex; justify-content: space-between; align-items: baseline; margin-bottom: 2rem; }
	.summary-title { font-family: var(--font-display); font-size: 1.5rem; }
	.summary-icon { width: 14px; height: 14px; color: #d1d5db; }

	.sidebar-user { display: flex; align-items: center; gap: 1rem; padding-bottom: 2rem; border-bottom: 1px solid var(--border); }
	.summary-items { display: flex; flex-direction: column; gap: 1.5rem; padding-bottom: 1.5rem; border-bottom: 1px solid var(--border); margin-bottom: 1.5rem; max-height: 300px; overflow-y: auto; }
	.summary-item { display: grid; grid-template-columns: 50px 1fr 60px; gap: 1rem; align-items: center; }
	.item-img-wrap { aspect-ratio: 1; border-radius: 4px; overflow: hidden; background: var(--surface); }
	.item-img { width: 100%; height: 100%; object-fit: contain; }
	.item-name { font-size: 12px; font-weight: 600; line-height: 1.3; }
	.item-qty { font-size: 10px; color: var(--on-surface-muted); }
	.item-total { font-size: 12px; font-weight: 700; text-align: right; }

	.summary-rows { display: flex; flex-direction: column; gap: 0.75rem; padding-bottom: 1.5rem; border-bottom: 1px solid var(--border); margin-bottom: 1.5rem; }
	.summary-row { display: flex; justify-content: space-between; font-size: 12px; color: var(--on-surface-muted); font-weight: 500; }

	.summary-total-row { display: flex; flex-direction: column; gap: 4px; margin-bottom: 2rem; }
	.total-label { font-size: 9px; font-weight: 700; text-transform: uppercase; color: var(--on-surface-muted); letter-spacing: 0.15em; }
	.total-val { font-size: 2.5rem; font-weight: 500; line-height: 1; letter-spacing: -0.02em; }

	.btn-primary {
		width: 100%; padding: 18px; border: none; border-radius: 6px;
		background: var(--on-surface); color: #fff;
		font-size: 11px; font-weight: 600; text-transform: uppercase; letter-spacing: 0.15em;
		display: flex; align-items: center; justify-content: center; gap: 8px;
		cursor: pointer; transition: background 0.2s;
	}
	.btn-primary:hover { background: #000; }
	.btn-primary:disabled { opacity: 0.5; cursor: not-allowed; }
	.btn-back { display: block; text-align: center; margin-top: 1.5rem; font-size: 10px; font-weight: 700; text-transform: uppercase; color: var(--on-surface-muted); }

	.loader-dot { width: 8px; height: 8px; border: 2px solid rgba(255,255,255,0.3); border-top-color: #fff; border-radius: 50%; animation: spin 0.8s linear infinite; }
	@keyframes spin { to { transform: rotate(360deg); } }
</style>
