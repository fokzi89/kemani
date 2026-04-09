
<script lang="ts">
    import { onMount } from 'svelte';
    import { page } from '$app/stores';
    import { supabase } from '$lib/supabase';
    import { fade, scale } from 'svelte/transition';
    import { 
        CheckCircle2, ShoppingBag, ArrowLeft, 
        Package, Truck, Calendar, Home
    } from 'lucide-svelte';

    export let data;
    $: provider = data.provider;
    $: brandColor = provider?.brand_color || '#003f87';

    let order: any = null;
    let isLoading = true;
    let error = '';

    onMount(async () => {
        const orderId = $page.params.id;
        try {
            const { data: orderData, error: orderErr } = await supabase
                .from('orders')
                .select(`
                    *,
                    branches(name, address, phone),
                    order_items(*)
                `)
                .eq('id', orderId)
                .single();

            if (orderErr) throw orderErr;
            order = orderData;
        } catch (err: any) {
            console.error('Error fetching order details:', err);
            error = 'Could not load order details.';
        } finally {
            isLoading = false;
        }
    });

    function formatDate(dateStr: string) {
        return new Date(dateStr).toLocaleDateString('en-US', {
            month: 'long',
            day: 'numeric',
            year: 'numeric',
            hour: 'numeric',
            minute: '2-digit'
        });
    }
</script>

<svelte:head>
    <title>Order Confirmed — {provider?.name}</title>
</svelte:head>

<div class="success-page" style="--brand: {brandColor};">
    <div class="layout-container mini-container">
        {#if isLoading}
            <div class="loader">
                <div class="spinner"></div>
                <p>Confirming order details...</p>
            </div>
        {:else if error}
            <div class="error-state">
                <h2>Something went wrong</h2>
                <p>{error}</p>
                <a href="/" class="btn">Return Home</a>
            </div>
        {:else if order}
            <div class="success-card" in:fade>
                <div class="success-header">
                    <div class="success-icon" in:scale={{ delay: 200, duration: 400 }}>
                        <CheckCircle2 class="w-16 h-16" />
                    </div>
                    <h1>Order Confirmed!</h1>
                    <p class="order-num">Order #{order.order_number}</p>
                    <p class="order-date">{formatDate(order.created_at)}</p>
                </div>

                <div class="status-banner">
                    <Package class="w-5 h-5" />
                    <span>Your order is being processed by <strong>{order.branches.name}</strong></span>
                </div>

                <div class="summary-section">
                    <h3>Summary</h3>
                    <div class="item-list">
                        {#each order.order_items as item}
                            <div class="summary-item">
                                <span class="i-qty">{item.quantity}x</span>
                                <span class="i-name">{item.product_name}</span>
                                <span class="i-price">₦{item.subtotal.toLocaleString()}</span>
                            </div>
                        {/each}
                    </div>
                    <div class="summary-total">
                        <span>Total Paid</span>
                        <span>₦{order.total_amount.toLocaleString()}</span>
                    </div>
                </div>

                <div class="details-section">
                    <div class="detail-block">
                        <div class="d-icon"><Calendar /></div>
                        <div class="d-text">
                            <span class="label">Status</span>
                            <span class="val">{order.order_status.toUpperCase()}</span>
                        </div>
                    </div>
                    <div class="detail-block">
                        <div class="d-icon">
                            {#if order.fulfillment_type === 'delivery'}<Truck />{:else}<ShoppingBag />{/if}
                        </div>
                        <div class="d-text">
                            <span class="label">Fulfillment</span>
                            <span class="val">{order.fulfillment_type === 'delivery' ? 'Home Delivery' : 'Pickup in Store'}</span>
                        </div>
                    </div>
                    {#if order.fulfillment_type === 'pickup'}
                        <div class="detail-block full">
                            <div class="d-icon"><Home /></div>
                            <div class="d-text">
                                <span class="label">Pickup Location</span>
                                <span class="val">{order.branches.name}</span>
                                <span class="sub-val">{order.branches.address}</span>
                            </div>
                        </div>
                    {/if}
                </div>

                <div class="success-actions">
                    <a href="/pharmacies" class="btn-outline"><ArrowLeft class="mr-2" /> Back to Shopping</a>
                    <a href="/" class="btn-primary">Return to Dashboard</a>
                </div>
            </div>
        {/if}
    </div>
</div>

<style>
    .success-page { min-height: 100vh; background: var(--surface); padding: 4rem 1rem; }
    .mini-container { max-width: 600px; margin: 0 auto; }
    
    .success-card { background: white; border-radius: 2rem; border: 1px solid var(--outline-variant); padding: 3rem; box-shadow: 0 20px 40px -10px rgba(0,0,0,0.05); }
    
    .success-header { text-align: center; margin-bottom: 2.5rem; }
    .success-icon { color: #2e7d32; display: flex; align-items: center; justify-content: center; margin-bottom: 1.5rem; }
    .success-header h1 { font-family: var(--font-headline); font-size: 2rem; font-weight: 900; color: var(--on-surface); margin-bottom: 0.5rem; }
    .order-num { font-size: 0.875rem; font-weight: 700; color: var(--brand); text-transform: uppercase; letter-spacing: 0.1em; }
    .order-date { font-size: 0.8125rem; color: var(--on-surface-variant); margin-top: 0.25rem; }

    .status-banner { background: var(--surface-container-low); color: var(--on-surface); padding: 1rem; border-radius: 1rem; display: flex; align-items: center; justify-content: center; gap: 0.75rem; font-size: 0.875rem; margin-bottom: 2.5rem; }
    .status-banner strong { font-weight: 800; color: var(--brand); }

    .summary-section { margin-bottom: 2.5rem; }
    .summary-section h3 { font-size: 1rem; font-weight: 800; color: var(--on-surface); margin-bottom: 1.25rem; text-transform: uppercase; letter-spacing: 0.05em; }
    .item-list { display: flex; flex-direction: column; gap: 0.75rem; margin-bottom: 1.5rem; }
    .summary-item { display: flex; gap: 1rem; font-size: 0.875rem; color: var(--on-surface-variant); }
    .i-qty { font-weight: 800; color: var(--on-surface); }
    .i-name { flex: 1; }
    .i-price { font-weight: 700; color: var(--on-surface); }
    .summary-total { border-top: 1.5px dashed var(--outline-variant); padding-top: 1rem; display: flex; justify-content: space-between; font-size: 1.125rem; font-weight: 900; color: var(--brand); }

    .details-section { display: grid; grid-template-columns: 1fr 1fr; gap: 1rem; margin-bottom: 3rem; }
    .detail-block { background: var(--surface-container-low); padding: 1.25rem; border-radius: 1.25rem; display: flex; gap: 1rem; align-items: flex-start; }
    .detail-block.full { grid-column: span 2; }
    .d-icon { color: var(--brand); background: white; width: 36px; height: 36px; border-radius: 50%; display: flex; align-items: center; justify-content: center; flex-shrink: 0; box-shadow: 0 4px 10px rgba(0,0,0,0.05); }
    .d-icon :global(svg) { width: 18px; height: 18px; }
    .d-text { display: flex; flex-direction: column; }
    .label { font-size: 0.625rem; font-weight: 800; color: var(--on-surface-variant); text-transform: uppercase; letter-spacing: 0.05em; margin-bottom: 0.15rem; }
    .val { font-size: 0.875rem; font-weight: 700; color: var(--on-surface); }
    .sub-val { font-size: 0.75rem; color: var(--on-surface-variant); margin-top: 0.15rem; }

    .success-actions { display: flex; flex-direction: column; gap: 1rem; }
    @media (min-width: 480px) { .success-actions { flex-direction: row; } }
    .btn-outline, .btn-primary { flex: 1; display: flex; align-items: center; justify-content: center; padding: 1.125rem; border-radius: 1rem; font-weight: 800; font-size: 0.875rem; }
    .btn-primary { background: var(--brand); color: white; }
    .btn-outline { border: 1.5px solid var(--outline-variant); color: var(--on-surface); }

    .loader { text-align: center; padding: 5rem 0; }
    .spinner { width: 40px; height: 40px; border: 4px solid var(--outline-variant); border-top-color: var(--brand); border-radius: 50%; animation: spin 1s linear infinite; margin: 0 auto 1.5rem; }
    @keyframes spin { to { transform: rotate(360deg); } }
</style>
