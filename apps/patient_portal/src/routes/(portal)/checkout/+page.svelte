
<script lang="ts">
    import { cartStore, cartTotalItems, cartTotalPrice } from '$lib/stores/cart';
    import { isAuthenticated, currentUser } from '$lib/stores/auth';
    import { supabase } from '$lib/supabase';
    import { goto } from '$app/navigation';
    import { fade, slide } from 'svelte/transition';
    import { 
        ChevronLeft, ShoppingBag, MapPin, Truck, 
        Store, CreditCard, ArrowRight, X, Trash2,
        ChevronRight, CheckCircle2, AlertCircle, Plus, Minus
    } from 'lucide-svelte';

    export let data;
    $: provider = data.provider;
    $: brandColor = provider?.brand_color || '#003f87';

    let fulfillmentType = 'pickup'; // 'pickup' or 'delivery'
    let deliveryAddress = '';
    let specialInstructions = '';
    let isPlacingOrder = false;
    let orderError = '';

    $: items = $cartStore.items;
    $: pharmacyName = $cartStore.pharmacyName;
    $: subtotal = $cartTotalPrice;
    $: tax = subtotal * 0.05; // 5% tax mockup
    $: deliveryFee = fulfillmentType === 'delivery' ? 1500 : 0;
    $: total = subtotal + tax + deliveryFee;

    async function placeOrder() {
        if (!$isAuthenticated) {
            // In a real app, we'd redirect to login and come back
            orderError = 'Please sign in to complete your order.';
            return;
        }

        if (fulfillmentType === 'delivery' && !deliveryAddress) {
            orderError = 'Please provide a delivery address.';
            return;
        }

        isPlacingOrder = true;
        orderError = '';

        try {
            const tenantId = provider.id;
            const branchId = $cartStore.branchId;
            const userId = $currentUser.id;

            // 1. Ensure customer record exists (required for FK)
            const { data: customer, error: customerErr } = await supabase
                .from('customers')
                .upsert({
                    id: userId,
                    tenant_id: tenantId,
                    email: $currentUser.email,
                    full_name: $currentUser.user_metadata?.full_name || 'Patient',
                    phone: $currentUser.phone || ''
                })
                .select()
                .single();

            if (customerErr) throw customerErr;

            // 2. Handle Delivery Address
            let deliveryAddressId = null;
            if (fulfillmentType === 'delivery') {
                const { data: address, error: addrErr } = await supabase
                    .from('customer_addresses')
                    .insert({
                        customer_id: userId,
                        address_line: deliveryAddress,
                        label: 'Default Delivery'
                    })
                    .select()
                    .single();
                
                if (addrErr) throw addrErr;
                deliveryAddressId = address.id;
            }

            // 3. Create Order
            const orderNumber = `ORD-${Math.floor(Date.now() / 1000)}`;
            const { data: order, error: orderErr } = await supabase
                .from('orders')
                .insert({
                    tenant_id: tenantId,
                    branch_id: branchId,
                    order_number: orderNumber,
                    customer_id: userId,
                    order_type: 'marketplace',
                    fulfillment_type: fulfillmentType,
                    delivery_address_id: deliveryAddressId,
                    subtotal: subtotal,
                    tax_amount: tax,
                    delivery_fee: deliveryFee,
                    total_amount: total,
                    special_instructions: specialInstructions,
                    order_status: 'pending',
                    payment_status: 'unpaid'
                })
                .select()
                .single();

            if (orderErr) throw orderErr;

            // 2. Create Order Items
            const orderItems = items.map(item => ({
                order_id: order.id,
                product_id: item.id,
                product_name: item.name,
                quantity: item.quantity,
                unit_price: item.price,
                subtotal: item.price * item.quantity
            }));

            const { error: itemsErr } = await supabase
                .from('order_items')
                .insert(orderItems);

            if (itemsErr) throw itemsErr;

            // 3. Clear cart and redirect
            cartStore.clearCart();
            goto(`/order-success/${order.id}`);

        } catch (err: any) {
            console.error('Order placement failed:', err);
            orderError = err.message || 'Failed to place order. Please try again.';
        } finally {
            isPlacingOrder = false;
        }
    }
</script>

<svelte:head>
    <title>Checkout — {provider?.name}</title>
</svelte:head>

<div class="checkout-page" style="--brand: {brandColor};">
    <div class="layout-container">
        <header class="checkout-header">
            <button class="back-btn" on:click={() => history.back()}>
                <ChevronLeft class="w-5 h-5 mr-1" /> Back
            </button>
            <h1>Secure Checkout</h1>
        </header>

        {#if $cartTotalItems === 0}
            <div class="empty-state" in:fade>
                <div class="empty-icon"><ShoppingBag class="w-16 h-16" /></div>
                <h2>Your cart is empty</h2>
                <p>Browse our pharmacies to find the medications you need.</p>
                <a href="/pharmacies" class="primary-btn mt-4">Browse Pharmacies</a>
            </div>
        {:else}
            <div class="checkout-grid">
                <!-- Main Content -->
                <div class="checkout-main">
                    <!-- Fulfillment Selection -->
                    <section class="checkout-section">
                        <div class="section-header">
                            <div class="step-num">1</div>
                            <h3>Fulfillment Method</h3>
                        </div>
                        
                        <div class="fulfillment-options">
                            <button 
                                class="option-card" 
                                class:active={fulfillmentType === 'pickup'}
                                on:click={() => fulfillmentType = 'pickup'}
                            >
                                <Store class="w-6 h-6" />
                                <div class="option-info">
                                    <span class="o-title">Pick up in store</span>
                                    <span class="o-desc">Collect from {pharmacyName} branch</span>
                                </div>
                                <div class="o-check"><CheckCircle2 /></div>
                            </button>

                            <button 
                                class="option-card" 
                                class:active={fulfillmentType === 'delivery'}
                                on:click={() => fulfillmentType = 'delivery'}
                            >
                                <Truck class="w-6 h-6" />
                                <div class="option-info">
                                    <span class="o-title">Home Delivery</span>
                                    <span class="o-desc">Standard delivery in 24-48h</span>
                                </div>
                                <div class="o-check"><CheckCircle2 /></div>
                            </button>
                        </div>

                        {#if fulfillmentType === 'delivery'}
                            <div class="delivery-form" transition:slide>
                                <label for="address">Delivery Address</label>
                                <textarea 
                                    id="address" 
                                    bind:value={deliveryAddress} 
                                    placeholder="Enter your full street address, apartment, and city..." 
                                    rows="3"
                                ></textarea>
                                <p class="helper">Ensure someone is available at this address to receive your order.</p>
                            </div>
                        {/if}
                    </section>

                    <!-- User Info & Special Instructions -->
                    <section class="checkout-section">
                        <div class="section-header">
                            <div class="step-num">2</div>
                            <h3>Order Details</h3>
                        </div>
                        
                        {#if !$isAuthenticated}
                            <div class="auth-warning">
                                <AlertCircle class="w-5 h-5" />
                                <div>
                                    <p>You must be signed in to place an order.</p>
                                    <button class="text-btn">Sign in now</button>
                                </div>
                            </div>
                        {:else}
                            <div class="user-summary">
                                <div class="u-info">
                                    <span class="label">Ordered by</span>
                                    <span class="val">{$currentUser?.user_metadata?.full_name}</span>
                                </div>
                                <div class="u-info">
                                    <span class="label">Contact Email</span>
                                    <span class="val">{$currentUser?.email}</span>
                                </div>
                            </div>
                        {/if}

                        <div class="input-group">
                            <label for="instructions">Special Instructions (Optional)</label>
                            <textarea id="instructions" bind:value={specialInstructions} placeholder="e.g. Leave at the front desk, allergic to penicillin..."></textarea>
                        </div>
                    </section>

                    <!-- Items in Cart -->
                    <section class="checkout-section">
                        <div class="section-header">
                            <div class="step-num">3</div>
                            <h3>Review Items</h3>
                        </div>
                        <p class="pharmacy-source">Fulfilling Pharmacy: <strong>{pharmacyName}</strong></p>
                        
                        <div class="order-items">
                            {#each items as item}
                                <div class="order-item">
                                    <div class="item-img">
                                        {#if item.image_url}
                                            <img src={item.image_url} alt={item.name} />
                                        {:else}
                                            <ShoppingBag class="w-5 h-5 opacity-20" />
                                        {/if}
                                    </div>
                                    <div class="item-info">
                                        <div class="item-top">
                                            <h4>{item.name}</h4>
                                            <span>₦{(item.price * item.quantity).toLocaleString()}</span>
                                        </div>
                                        <div class="item-bottom">
                                            <div class="cart-qty-selector">
                                                <button on:click={() => cartStore.updateQuantity(item.id, item.quantity - 1)}><Minus class="w-3 h-3" /></button>
                                                <span>{item.quantity}</span>
                                                <button on:click={() => cartStore.updateQuantity(item.id, item.quantity + 1)}><Plus class="w-3 h-3" /></button>
                                            </div>
                                            <button class="remove-btn" on:click={() => cartStore.removeItem(item.id)}>
                                                <Trash2 class="w-4 h-4" />
                                            </button>
                                        </div>
                                    </div>
                                </div>
                            {/each}
                        </div>
                    </section>
                </div>

                <!-- Summary Sidebar -->
                <aside class="checkout-sidebar">
                    <div class="summary-card">
                        <h3>Order Summary</h3>
                        <div class="summary-rows">
                            <div class="s-row">
                                <span>Subtotal</span>
                                <span>₦{subtotal.toLocaleString()}</span>
                            </div>
                            <div class="s-row">
                                <span>Tax (5%)</span>
                                <span>₦{tax.toLocaleString()}</span>
                            </div>
                            {#if fulfillmentType === 'delivery'}
                                <div class="s-row">
                                    <span>Delivery Fee</span>
                                    <span>₦{deliveryFee.toLocaleString()}</span>
                                </div>
                            {/if}
                            <hr />
                            <div class="s-row total">
                                <span>Total</span>
                                <span style="color: var(--brand);">₦{total.toLocaleString()}</span>
                            </div>
                        </div>

                        {#if orderError}
                            <div class="error-box" transition:fade>
                                <AlertCircle class="w-4 h-4 mr-2" />
                                {orderError}
                            </div>
                        {/if}

                        <button 
                            class="place-order-btn" 
                            disabled={isPlacingOrder || !$isAuthenticated}
                            on:click={placeOrder}
                            style="background: {brandColor};"
                        >
                            {#if isPlacingOrder}
                                <div class="btn-spinner"></div> Placing Order...
                            {:else}
                                Confirm & Place Order <ArrowRight class="ml-2 w-5 h-5" />
                            {/if}
                        </button>
                        <p class="security-note"><CreditCard class="w-3 h-3 hmr-1" /> Secure checkout powered by Kemani</p>
                    </div>
                </aside>
            </div>
        {/if}
    </div>
</div>

<style>
    .checkout-page { min-height: 100vh; background: var(--surface); padding: 2rem 0 6rem; }
    .checkout-header { display: flex; align-items: center; gap: 2rem; margin-bottom: 2.5rem; }
    .back-btn { display: flex; align-items: center; font-size: 0.8125rem; font-weight: 700; color: var(--on-surface-variant); }
    .checkout-header h1 { font-family: var(--font-headline); font-size: 2rem; font-weight: 800; color: var(--on-surface); }

    .checkout-grid { display: grid; grid-template-columns: 1fr; gap: 2rem; }
    @media (min-width: 1024px) { .checkout-grid { grid-template-columns: 1fr 380px; } }

    .checkout-section { background: white; border-radius: 1.5rem; border: 1px solid var(--outline-variant); padding: 2rem; margin-bottom: 1.5rem; }
    .section-header { display: flex; align-items: center; gap: 1rem; margin-bottom: 2rem; }
    .step-num { width: 32px; height: 32px; border-radius: 50%; background: var(--brand); color: white; display: flex; align-items: center; justify-content: center; font-size: 0.875rem; font-weight: 800; }
    .section-header h3 { font-size: 1.25rem; font-weight: 800; color: var(--on-surface); }

    .fulfillment-options { display: grid; grid-template-columns: 1fr; gap: 1rem; margin-bottom: 1.5rem; }
    @media (min-width: 640px) { .fulfillment-options { grid-template-columns: 1fr 1fr; } }
    .option-card { border: 2px solid var(--outline-variant); border-radius: 1.25rem; padding: 1.25rem; display: flex; align-items: center; gap: 1rem; text-align: left; background: white; position: relative; transition: all 0.2s; }
    .option-card.active { border-color: var(--brand); background: var(--surface-container-low); }
    .option-info { flex: 1; display: flex; flex-direction: column; gap: 0.15rem; }
    .o-title { font-weight: 800; font-size: 0.9375rem; color: var(--on-surface); }
    .o-desc { font-size: 0.75rem; color: var(--on-surface-variant); }
    .o-check { position: absolute; top: 0.75rem; right: 0.75rem; color: var(--brand); opacity: 0; transform: scale(0.5); transition: all 0.2s; }
    .option-card.active .o-check { opacity: 1; transform: scale(1); }

    .delivery-form { border-top: 1px solid var(--outline-variant); padding-top: 1.5rem; }
    label { display: block; font-size: 0.8125rem; font-weight: 700; color: var(--on-surface); margin-bottom: 0.5rem; }
    textarea { width: 100%; border: 1.5px solid var(--outline-variant); border-radius: 1rem; padding: 1rem; font-size: 0.875rem; outline: none; transition: border-color 0.2s; }
    textarea:focus { border-color: var(--brand); }
    .helper { font-size: 0.7rem; color: var(--on-surface-variant); margin-top: 0.5rem; }

    .auth-warning { background: var(--error-container); color: var(--on-error-container); padding: 1.25rem; border-radius: 1rem; display: flex; gap: 1rem; align-items: center; }
    .auth-warning p { font-size: 0.875rem; font-weight: 600; }
    .text-btn { font-size: 0.8125rem; font-weight: 800; text-decoration: underline; }

    .user-summary { display: grid; grid-template-columns: 1fr; gap: 1rem; background: var(--surface-container-lowest); padding: 1.25rem; border-radius: 1rem; margin-bottom: 2rem; }
    @media (min-width: 640px) { .user-summary { grid-template-columns: 1fr 1fr; } }
    .u-info { display: flex; flex-direction: column; }
    .label { font-size: 0.65rem; color: var(--on-surface-variant); text-transform: uppercase; font-weight: 800; margin-bottom: 0.25rem; }
    .val { font-size: 0.875rem; font-weight: 700; color: var(--on-surface); }

    .pharmacy-source { font-size: 0.8125rem; color: var(--on-surface-variant); margin-bottom: 1rem; }
    .order-items { display: flex; flex-direction: column; gap: 1rem; }
    .order-item { display: flex; align-items: center; gap: 1rem; padding: 1rem; background: var(--surface-container-lowest); border-radius: 1rem; }
    .item-img { width: 44px; height: 44px; background: white; border-radius: 0.5rem; display: flex; align-items: center; justify-content: center; border: 1px solid var(--outline-variant); }
    .item-img img { width: 100%; height: 100%; object-fit: cover; }
    .item-info { flex: 1; display: flex; flex-direction: column; }
    .item-top { display: flex; justify-content: space-between; align-items: center; }
    .item-top h4 { font-size: 0.875rem; font-weight: 700; }
    .item-top span { font-size: 0.875rem; font-weight: 800; color: var(--brand); }
    .item-bottom { display: flex; justify-content: space-between; align-items: center; margin-top: 0.5rem; }
    
    .cart-qty-selector { display: flex; align-items: center; gap: 0.75rem; background: white; padding: 0.25rem 0.5rem; border-radius: 0.5rem; border: 1px solid var(--outline-variant); }
    .cart-qty-selector button { width: 24px; height: 24px; display: flex; align-items: center; justify-content: center; color: var(--on-surface-variant); }
    .cart-qty-selector span { font-size: 0.8125rem; font-weight: 700; min-width: 15px; text-align: center; }

    .remove-btn { color: #ba1a1a; padding: 0.25rem; opacity: 0.6; transition: opacity 0.2s; }
    .remove-btn:hover { opacity: 1; }

    .checkout-sidebar { position: sticky; top: 100px; }
    .summary-card { background: white; border-radius: 1.5rem; border: 1px solid var(--outline-variant); padding: 2rem; box-shadow: 0 10px 30px -5px rgba(0,0,0,0.05); }
    .summary-card h3 { font-size: 1.25rem; font-weight: 800; margin-bottom: 1.5rem; }
    .summary-rows { display: flex; flex-direction: column; gap: 1rem; }
    .s-row { display: flex; justify-content: space-between; font-size: 0.875rem; color: var(--on-surface-variant); font-weight: 600; }
    .s-row.total { font-size: 1.25rem; font-weight: 900; color: var(--on-surface); padding-top: 0.5rem; }
    hr { border: none; border-top: 1px solid var(--outline-variant); margin: 0.5rem 0; }
    
    .place-order-btn { width: 100%; padding: 1.25rem; border-radius: 1rem; color: white; font-size: 1rem; font-weight: 800; display: flex; align-items: center; justify-content: center; margin-top: 2rem; transition: transform 0.2s; }
    .place-order-btn:hover:not(:disabled) { transform: translateY(-2px); }
    .place-order-btn:disabled { opacity: 0.5; cursor: not-allowed; }
    .security-note { font-size: 0.65rem; color: var(--on-surface-variant); text-align: center; margin-top: 1rem; display: flex; align-items: center; justify-content: center; }

    .error-box { background: #fef2f2; color: #ba1a1a; padding: 0.75rem; border-radius: 0.75rem; font-size: 0.75rem; font-weight: 700; margin-top: 1.5rem; display: flex; align-items: center; }

    .empty-state { text-align: center; padding: 5rem 1rem; background: white; border-radius: 2rem; border: 1px solid var(--outline-variant); margin-top: 2rem; }
    .empty-icon { width: 80px; height: 80px; border-radius: 50%; background: var(--surface-container-low); display: flex; align-items: center; justify-content: center; color: var(--on-surface-variant); margin: 0 auto 1.5rem; }
    .empty-state h2 { font-family: var(--font-headline); font-size: 1.5rem; font-weight: 800; margin-bottom: 0.5rem; }
    .empty-state p { font-size: 0.9375rem; color: var(--on-surface-variant); margin-bottom: 2rem; }
    .primary-btn { display: inline-block; background: var(--brand); color: white; padding: 1rem 2rem; border-radius: 1rem; font-weight: 800; text-decoration: none; }

    .btn-spinner { width: 20px; height: 20px; border: 3px solid rgba(255,255,255,0.3); border-top-color: white; border-radius: 50%; animation: spin 0.8s linear infinite; margin-right: 0.75rem; }
    @keyframes spin { to { transform: rotate(360deg); } }
</style>
