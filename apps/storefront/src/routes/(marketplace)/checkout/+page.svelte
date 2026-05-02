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
	import { MonnifyService } from '$lib/services/monnify';

	$: storefront = data.storefront;
    $: brandColor = storefront?.brand_color || '#4f46e5';

	let orderData: any = null;
	let isLoading = false;
	let error = '';
	let success = '';
    let step = 1; 

	let shippingAddress = '';
	let billingAddress = '';
	let sameAsShipping = true;

	$: if (sameAsShipping) {
		billingAddress = shippingAddress;
	}

	$: branch = storefront?.branches?.[0];
	$: deliveryEnabled = branch?.delivery_enabled ?? true;
	
	let fulfillmentType = 'delivery';
	
	$: if (!deliveryEnabled && fulfillmentType === 'delivery') {
		fulfillmentType = 'pickup';
	}

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

	async function initiatePayment() {
		if (!orderData || !$currentUser) return;
		
		isLoading = true;
		error = '';

		try {
			const reference = `ORD-${Date.now()}-${Math.floor(Math.random() * 1000)}`;
			
			await MonnifyService.pay({
				email: ($currentUser.email || '').trim(),
				name: ($currentUser.user_metadata?.full_name || 'Customer').trim(),
				amount: orderData.total,
				ref: reference,
				description: `Order ${reference} for ${storefront.name}`,
				metadata: {
					tenant_id: storefront.id,
					customer_id: $currentUser.id,
					order_type: 'marketplace'
				},
				onSuccess: async (response) => {
					console.log('Payment successful:', response);
					// Monnify returns transactionReference or similar
					await completeOrder(response.transactionReference || response.paymentReference || reference);
				},
				onClose: () => {
					isLoading = false;
					console.log('Payment closed');
				}
			});
		} catch (err: any) {
			console.error('Payment initialization failed:', err);
			error = 'Could not initialize payment gateway. Please try again.';
			isLoading = false;
		}
	}

	async function completeOrder(paymentReference: string) {
		isLoading = true;
		error = '';

		try {
			// Format items as required by the RPC
			const formattedItems = orderData.items.map((i: any) => ({
				product_id: i.product_id || i.id,
				product_name: i.product_name || i.name,
				quantity: i.quantity,
				unit_price: i.unit_price || i.price,
				subtotal: (i.unit_price || i.price) * i.quantity
			}));

			const { data: orderId, error: rpcError } = await supabase.rpc('checkout_storefront_order', {
				p_tenant_id: storefront.id,
				p_branch_id: orderData.branch_id || storefront.branches?.[0]?.id, 
				p_customer_id: $currentUser?.id,
				p_order_type: 'marketplace',
				p_fulfillment_type: fulfillmentType,
				p_subtotal: orderData.subtotal,
				p_delivery_fee: fulfillmentType === 'delivery' ? (orderData.delivery_fee || 0) : 0,
				p_tax_amount: orderData.tax || 0,
				p_total_amount: fulfillmentType === 'delivery' ? orderData.total : (orderData.total - (orderData.delivery_fee || 0)),
				p_delivery_address_id: orderData.delivery_address_id || null,
				p_special_instructions: orderData.special_instructions || null,
				p_items: formattedItems,
				p_service_charge: orderData.service_charge || 0,
				p_payment_reference: paymentReference,
				p_billing_address: billingAddress,
				p_shipping_address: shippingAddress
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
			console.error("Order Completion Error:", err);
			error = err.message || 'Payment was successful but we failed to record your order. Please contact support with reference: ' + paymentReference;
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
							onclick={() => goto('/profile')}
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
						</section>

						<!-- Fulfillment Selection -->
						{#if deliveryEnabled}
							<section class="form-section">
								<h3 class="section-label">Fulfillment Choice</h3>
								<div class="flex gap-4">
									<button 
										class="flex-1 p-6 rounded-3xl border-2 transition-all flex flex-col items-center gap-3 {fulfillmentType === 'delivery' ? 'border-gray-900 bg-gray-50' : 'border-gray-100 hover:border-gray-200'}"
										onclick={() => fulfillmentType = 'delivery'}
									>
										<Truck class="w-8 h-8 {fulfillmentType === 'delivery' ? 'text-gray-900' : 'text-gray-400'}" />
										<div class="text-center">
											<p class="text-[10px] font-black uppercase tracking-widest {fulfillmentType === 'delivery' ? 'text-gray-900' : 'text-gray-500'}">Home Delivery</p>
											<p class="text-[8px] font-bold text-gray-400 uppercase mt-1">To your doorstep</p>
										</div>
									</button>
									<button 
										class="flex-1 p-6 rounded-3xl border-2 transition-all flex flex-col items-center gap-3 {fulfillmentType === 'pickup' ? 'border-gray-900 bg-gray-50' : 'border-gray-100 hover:border-gray-200'}"
										onclick={() => fulfillmentType = 'pickup'}
									>
										<ShoppingBag class="w-8 h-8 {fulfillmentType === 'pickup' ? 'text-gray-900' : 'text-gray-400'}" />
										<div class="text-center">
											<p class="text-[10px] font-black uppercase tracking-widest {fulfillmentType === 'pickup' ? 'text-gray-900' : 'text-gray-500'}">Self Pickup</p>
											<p class="text-[8px] font-bold text-gray-400 uppercase mt-1">Collect from branch</p>
										</div>
									</button>
								</div>
							</section>
						{/if}
						
						<!-- Address Section -->
						<section class="form-section">
							<h3 class="section-label">Logistics & Billing</h3>
							<div class="address-grid">
								{#if fulfillmentType === 'delivery'}
									<div class="address-field">
										<label for="shipping_address" class="field-label">Shipping Address</label>
										<textarea 
											id="shipping_address" 
											bind:value={shippingAddress} 
											placeholder="Enter full delivery address"
											class="address-textarea"
										></textarea>
									</div>
								{/if}
								
								<div class="address-field {fulfillmentType === 'delivery' ? 'mt-6' : ''}">
									<div class="flex items-center justify-between mb-2">
										<label for="billing_address" class="field-label">Billing Address</label>
										{#if fulfillmentType === 'delivery'}
											<label class="flex items-center gap-2 text-xs font-bold text-gray-500 cursor-pointer hover:text-gray-900 transition-colors">
												<input type="checkbox" bind:checked={sameAsShipping} class="rounded border-gray-300 text-blue-600 focus:ring-blue-500" />
												Same as shipping
											</label>
										{/if}
									</div>
									{#if !sameAsShipping || fulfillmentType === 'pickup'}
										<textarea 
											id="billing_address" 
											bind:value={billingAddress} 
											placeholder="Enter billing address"
											class="address-textarea"
										></textarea>
									{/if}
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
										<p class="item-val">Monnify Integrated</p>
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
								<span>Subtotal</span>
								<span>₦{orderData.subtotal.toLocaleString()}</span>
							</div>
							{#if orderData.tax > 0}
								<div class="summary-row">
									<span>Estimated Tax</span>
									<span>₦{orderData.tax.toLocaleString(undefined, { maximumFractionDigits: 0 })}</span>
								</div>
							{/if}
							<div class="summary-row">
								<span>Service Charge</span>
								<span>₦{(orderData.service_charge || 0).toLocaleString()}</span>
							</div>
							{#if fulfillmentType === 'delivery' && orderData.delivery_fee > 0}
								<div class="summary-row">
									<span>Logistics</span>
									<span>₦{orderData.delivery_fee.toLocaleString()}</span>
								</div>
							{/if}
						</div>

						<div class="summary-total-row">
							<p class="total-label">Estimated Total</p>
							<p class="total-val" style="color: {brandColor};">
								₦{(fulfillmentType === 'delivery' ? orderData.total : (orderData.total - (orderData.delivery_fee || 0))).toLocaleString(undefined, { maximumFractionDigits: 0 })}
							</p>
						</div>

						<button
							onclick={initiatePayment}
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
		--font-display: 'Inter', -apple-system, sans-serif;
		--font-body: 'Inter', -apple-system, sans-serif;
		--surface: #f3f4f6;
		--on-surface: #111827;
		--on-surface-muted: #6b7280;
		--border: #e5e7eb;
		--radius: 14px;
	}

	.checkout-page {
		background: var(--surface);
		color: var(--on-surface);
		font-family: var(--font-body);
		min-height: 100vh;
		padding: 2rem 0 4rem;
	}

	.max-w-7xl {
		max-width: 1100px;
	}

	/* ─── LAYOUT ─── */
	.checkout-layout {
		display: grid;
		grid-template-columns: 1fr;
		gap: 1.5rem;
		align-items: flex-start;
	}
	@media (min-width: 1024px) {
		.checkout-layout { grid-template-columns: 1fr 360px; }
	}

	.checkout-main { display: flex; flex-direction: column; }

	/* ─── SUCCESS SCREEN ─── */
	.success-screen { 
		text-align: center; padding: 5rem 2rem; background: #fff; 
		border-radius: var(--radius); border: 1px solid var(--border);
		box-shadow: 0 1px 4px rgba(0,0,0,0.04);
		animation: fadeIn 0.6s ease;
	}
	@keyframes fadeIn { from { opacity: 0; transform: translateY(10px); } to { opacity: 1; transform: translateY(0); } }
	
	.success-icon { width: 72px; height: 72px; background: #f0fdf4; color: #059669; border-radius: 50%; display: flex; align-items: center; justify-content: center; margin: 0 auto 1.5rem; }
	.success-title { font-size: 1.75rem; font-weight: 800; margin-bottom: 0.5rem; letter-spacing: -0.02em; }
	.success-sub { font-size: 0.875rem; color: var(--on-surface-muted); max-width: 400px; margin: 0 auto 2rem; line-height: 1.6; }
	
	.success-steps { display: flex; flex-direction: column; gap: 0.75rem; max-width: 300px; margin: 0 auto 2rem; text-align: left; }
	.step-item { display: flex; align-items: center; gap: 10px; font-size: 0.75rem; font-weight: 600; color: var(--on-surface-muted); }
	.step-icon { width: 14px; height: 14px; color: var(--on-surface); }
	.success-btn { display: inline-flex; width: auto; padding-left: 2rem; padding-right: 2rem; border-radius: 10px; }

	/* ─── HEADER ─── */
	.process-header { margin-bottom: 2rem; }
	.process-steps { display: flex; align-items: center; gap: 1rem; margin-bottom: 1rem; }
	.step { font-size: 0.75rem; font-weight: 700; text-transform: uppercase; letter-spacing: 0.05em; color: var(--on-surface-muted); }
	.step.active { color: var(--on-surface); border-bottom: 2px solid var(--on-surface); padding-bottom: 2px; }
	.step-sep { width: 20px; height: 1px; background: var(--border); }
	.page-title { font-size: 1.75rem; font-weight: 800; line-height: 1.2; letter-spacing: -0.02em; }

	.alert { margin-bottom: 1.5rem; padding: 1rem; border-radius: 10px; font-size: 0.8125rem; display: flex; align-items: center; gap: 10px; }
	.alert-error { background: #fef2f2; border: 1px solid #fee2e2; color: #b91c1c; }

	/* ─── FORM ─── */
	.form-sections { display: flex; flex-direction: column; gap: 1.5rem; }
	.section-label { font-size: 0.875rem; font-weight: 700; color: var(--on-surface); margin-bottom: 1rem; }
	
	.info-card { display: flex; flex-direction: column; gap: 1.25rem; padding: 1.75rem; background: #fff; border: 1px solid var(--border); border-radius: var(--radius); box-shadow: 0 1px 4px rgba(0,0,0,0.04); }
	.info-item { display: flex; align-items: center; gap: 1rem; }
	.item-icon-box { width: 40px; height: 40px; background: #f9fafb; border-radius: 8px; display: flex; align-items: center; justify-content: center; color: var(--on-surface-muted); }
	.item-label { font-size: 0.7rem; font-weight: 700; text-transform: uppercase; color: var(--on-surface-muted); margin-bottom: 2px; }
	.item-val { font-size: 0.875rem; font-weight: 600; color: var(--on-surface); }
	.item-sub { font-size: 0.75rem; color: var(--on-surface-muted); }

	.payment-card { display: flex; justify-content: space-between; align-items: center; padding: 1.25rem; background: #fff; border: 1px solid var(--border); border-radius: var(--radius); cursor: pointer; transition: all 0.2s; box-shadow: 0 1px 4px rgba(0,0,0,0.04); }
	.payment-card.active { border-color: var(--on-surface); background: rgba(0,0,0,0.01); }
	.payment-info { display: flex; align-items: center; gap: 1rem; }
	.payment-check { color: #059669; }

	.quality-box { display: flex; align-items: center; gap: 1rem; padding: 1.25rem; background: #111827; color: #fff; border-radius: var(--radius); }
	.quality-icon { width: 20px; height: 20px; color: #fff; opacity: 0.6; }
	.quality-title { font-size: 0.75rem; font-weight: 700; text-transform: uppercase; letter-spacing: 0.05em; margin-bottom: 2px; }
	.quality-sub { font-size: 0.75rem; color: rgba(255,255,255,0.6); line-height: 1.5; }

	/* ─── SUMMARY ─── */
	.checkout-summary { position: sticky; top: 5rem; }
	.summary-box { background: #fff; border: 1px solid var(--border); border-radius: var(--radius); padding: 1.75rem; box-shadow: 0 1px 4px rgba(0,0,0,0.04); }
	.summary-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 1.5rem; }
	.summary-title { font-size: 1rem; font-weight: 700; }
	.summary-icon { width: 14px; height: 14px; color: #d1d5db; }

	.summary-items { display: flex; flex-direction: column; gap: 1.25rem; padding-bottom: 1.25rem; border-bottom: 1px solid #f3f4f6; margin-bottom: 1.25rem; max-height: 250px; overflow-y: auto; }
	.summary-item { display: grid; grid-template-columns: 48px 1fr 60px; gap: 1rem; align-items: center; }
	.item-img-wrap { width: 48px; height: 56px; border-radius: 6px; border: 1px solid #e5e7eb; background: #f9fafb; overflow: hidden; flex-shrink: 0; }
	.item-img { width: 100%; height: 100%; object-fit: cover; }
	.item-name { font-size: 0.8125rem; font-weight: 600; line-height: 1.3; }
	.item-qty { font-size: 0.75rem; color: var(--on-surface-muted); }
	.item-total { font-size: 0.8125rem; font-weight: 700; text-align: right; }

	.summary-rows { display: flex; flex-direction: column; gap: 0.75rem; padding-bottom: 1.25rem; border-bottom: 1px solid #f3f4f6; margin-bottom: 1.25rem; }
	.summary-row { display: flex; justify-content: space-between; font-size: 0.8125rem; color: var(--on-surface-muted); font-weight: 500; }

	.summary-total-row { display: flex; justify-content: space-between; align-items: center; margin-bottom: 1.5rem; }
	.total-label { font-size: 1rem; font-weight: 800; color: #111827; }
	.total-val { font-size: 1rem; font-weight: 800; }

	.btn-primary {
		width: 100%; padding: 1rem; border-radius: 10px;
		background: var(--on-surface); color: #fff;
		font-size: 0.9375rem; font-weight: 700; border: none;
		display: flex; align-items: center; justify-content: center; gap: 0.5rem;
		cursor: pointer; transition: opacity 0.15s, transform 0.15s;
	}
	.btn-primary:hover { opacity: 0.9; transform: translateY(-1px); }
	.btn-primary:disabled { opacity: 0.6; cursor: not-allowed; transform: none; }
	.btn-back { display: block; text-align: center; margin-top: 1.25rem; font-size: 0.8125rem; font-weight: 600; color: var(--on-surface-muted); text-decoration: none; }
    .btn-back:hover { color: var(--on-surface); }

	.loader-dot { width: 12px; height: 12px; border: 2px solid rgba(255,255,255,0.3); border-top-color: #fff; border-radius: 50%; animation: spin 0.8s linear infinite; }
	@keyframes spin { to { transform: rotate(360deg); } }

	.field-label { display: block; font-size: 0.75rem; font-weight: 700; text-transform: uppercase; color: var(--on-surface-muted); margin-bottom: 0.5rem; }
	.address-textarea { 
		width: 100%; min-height: 80px; padding: 1rem; background: #fff; 
		border: 1px solid var(--border); border-radius: 12px; 
		font-size: 0.875rem; color: var(--on-surface); line-height: 1.5;
		resize: vertical; transition: border-color 0.2s;
	}
	.address-textarea:focus { outline: none; border-color: var(--on-surface); }
	.mt-6 { margin-top: 1.5rem; }
</style>
