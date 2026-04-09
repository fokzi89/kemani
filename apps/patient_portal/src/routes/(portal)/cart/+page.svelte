<script lang="ts">
    import { cartStore, cartTotalItems, cartTotalPrice } from '$lib/stores/cart';
    import { fade } from 'svelte/transition';
    import { 
        ChevronLeft, ShoppingBag, Trash2,
        ArrowRight, Plus, Minus
    } from 'lucide-svelte';

    export let data;
    $: provider = data.provider;
    $: brandColor = provider?.brand_color || '#003f87';

    $: items = $cartStore.items;
    $: pharmacyName = $cartStore.pharmacyName;
    $: subtotal = $cartTotalPrice;
    $: tax = subtotal * 0.05; // 5% tax mockup (to match checkout initially)
    $: estimatedTotal = subtotal + tax; // Delivery calculated at checkout
</script>

<svelte:head>
    <title>Your Cart — {provider?.name}</title>
</svelte:head>

<div class="cart-page" style="--brand: {brandColor};">
    <div class="layout-container">
        <header class="cart-header">
            <button class="back-btn" on:click={() => history.back()}>
                <ChevronLeft class="w-5 h-5 mr-1" /> Back
            </button>
            <h1>Your Cart</h1>
        </header>

        {#if $cartTotalItems === 0}
            <div class="empty-state" in:fade>
                <div class="empty-icon"><ShoppingBag class="w-16 h-16" /></div>
                <h2>Your cart is empty</h2>
                <p>Browse our pharmacies to find the medications you need.</p>
                <a href="/pharmacies" class="primary-btn mt-4">Pharmacy Shops</a>
            </div>
        {:else}
            <div class="cart-grid">
                <!-- Main Content: Items List -->
                <div class="cart-main">
                    <section class="cart-section">
                        <div class="section-header">
                            <h3>Items</h3>
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
                                                <Trash2 class="w-4 h-4" /> Remove
                                            </button>
                                        </div>
                                    </div>
                                </div>
                            {/each}
                        </div>
                    </section>
                </div>

                <!-- Summary Sidebar -->
                <aside class="cart-sidebar">
                    <div class="summary-card">
                        <h3>Cart Summary</h3>
                        <div class="summary-rows">
                            <div class="s-row">
                                <span>Subtotal</span>
                                <span>₦{subtotal.toLocaleString()}</span>
                            </div>
                            <div class="s-row">
                                <span>Estimated Tax (5%)</span>
                                <span>₦{tax.toLocaleString()}</span>
                            </div>
                            <hr />
                            <div class="s-row total">
                                <span>Estimated Total</span>
                                <span style="color: var(--brand);">₦{estimatedTotal.toLocaleString()}</span>
                            </div>
                            <p class="helper-text">Delivery fee will be calculated at checkout.</p>
                        </div>
                        
                        <a href="/checkout" class="checkout-btn" style="background: {brandColor};">
                            Proceed to Checkout <ArrowRight class="ml-2 w-5 h-5" />
                        </a>
                    </div>
                </aside>
            </div>
        {/if}
    </div>
</div>

<style>
    .cart-page { min-height: 100vh; background: var(--surface); padding: 1.25rem 0 4rem; }
    .cart-header { display: flex; align-items: center; gap: 1.25rem; margin-bottom: 1.5rem; }
    .back-btn { display: flex; align-items: center; font-size: 0.75rem; font-weight: 700; color: var(--on-surface-variant); cursor: pointer; background: transparent; border: none; }
    .cart-header h1 { font-family: var(--font-headline); font-size: 1.5rem; font-weight: 800; color: var(--on-surface); }

    .cart-grid { display: grid; grid-template-columns: 1fr; gap: 1.25rem; }
    @media (min-width: 1024px) { .cart-grid { grid-template-columns: 1fr 320px; } }

    .cart-section { background: white; border-radius: 1rem; border: 1px solid var(--outline-variant); padding: 1.25rem; margin-bottom: 1rem; }
    .section-header { display: flex; align-items: center; gap: 0.75rem; margin-bottom: 1.25rem; border-bottom: 1px solid var(--outline-variant); padding-bottom: 0.75rem; }
    .section-header h3 { font-size: 1rem; font-weight: 800; color: var(--on-surface); }

    .pharmacy-source { font-size: 0.75rem; color: var(--on-surface-variant); margin-bottom: 0.75rem; }
    .order-items { display: flex; flex-direction: column; gap: 0.75rem; }
    .order-item { display: flex; align-items: center; gap: 0.75rem; padding: 0.75rem; background: var(--surface-container-lowest); border-radius: 0.75rem; }
    .item-img { width: 48px; height: 48px; background: white; border-radius: 0.5rem; display: flex; align-items: center; justify-content: center; border: 1px solid var(--outline-variant); flex-shrink: 0; }
    .item-img img { width: 100%; height: 100%; object-fit: cover; }
    .item-info { flex: 1; display: flex; flex-direction: column; min-width: 0; }
    .item-top { display: flex; justify-content: space-between; align-items: center; gap: 0.5rem; }
    .item-top h4 { font-size: 0.8125rem; font-weight: 700; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
    .item-top span { font-size: 0.8125rem; font-weight: 800; color: var(--brand); flex-shrink: 0; }
    .item-bottom { display: flex; justify-content: space-between; align-items: center; margin-top: 0.375rem; }
    
    .cart-qty-selector { display: flex; align-items: center; gap: 0.5rem; background: white; padding: 0.2rem 0.375rem; border-radius: 0.4rem; border: 1px solid var(--outline-variant); }
    .cart-qty-selector button { width: 24px; height: 24px; display: flex; align-items: center; justify-content: center; color: var(--on-surface-variant); cursor: pointer; background: transparent; border: none; }
    .cart-qty-selector span { font-size: 0.75rem; font-weight: 700; min-width: 14px; text-align: center; }

    .remove-btn { display: flex; align-items: center; gap: 0.25rem; color: #ba1a1a; padding: 0.2rem; font-size: 0.75rem; font-weight: 600; opacity: 0.7; transition: opacity 0.2s; cursor: pointer; background: transparent; border: none; }
    .remove-btn:hover { opacity: 1; }

    .cart-sidebar { position: sticky; top: 80px; }
    .summary-card { background: white; border-radius: 1rem; border: 1px solid var(--outline-variant); padding: 1.25rem; box-shadow: 0 6px 20px -5px rgba(0,0,0,0.06); }
    .summary-card h3 { font-size: 1rem; font-weight: 800; margin-bottom: 1rem; }
    .summary-rows { display: flex; flex-direction: column; gap: 0.75rem; }
    .s-row { display: flex; justify-content: space-between; font-size: 0.8125rem; color: var(--on-surface-variant); font-weight: 600; }
    .s-row.total { font-size: 1.0625rem; font-weight: 900; color: var(--on-surface); padding-top: 0.375rem; }
    .helper-text { font-size: 0.65rem; color: var(--on-surface-variant); text-align: center; margin-top: 0.25rem; }
    hr { border: none; border-top: 1px solid var(--outline-variant); margin: 0.25rem 0; }
    
    .checkout-btn { width: 100%; padding: 0.875rem; border-radius: 0.875rem; color: white; font-size: 0.9375rem; font-weight: 800; display: flex; align-items: center; justify-content: center; margin-top: 1.25rem; transition: transform 0.2s; text-decoration: none; }
    .checkout-btn:hover { transform: translateY(-2px); }

    .empty-state { text-align: center; padding: 3rem 1rem; background: white; border-radius: 1.25rem; border: 1px solid var(--outline-variant); margin-top: 1.5rem; }
    .empty-icon { width: 64px; height: 64px; border-radius: 50%; background: var(--surface-container-low); display: flex; align-items: center; justify-content: center; color: var(--on-surface-variant); margin: 0 auto 1rem; }
    .empty-state h2 { font-family: var(--font-headline); font-size: 1.25rem; font-weight: 800; margin-bottom: 0.375rem; }
    .empty-state p { font-size: 0.875rem; color: var(--on-surface-variant); margin-bottom: 1.5rem; }
    .primary-btn { display: inline-block; background: var(--brand); color: white; padding: 0.75rem 1.5rem; border-radius: 0.875rem; font-weight: 800; text-decoration: none; font-size: 0.875rem; }
</style>
