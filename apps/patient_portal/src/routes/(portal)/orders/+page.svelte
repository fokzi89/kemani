
<script lang="ts">
  import { ShoppingBag, Calendar, MapPin, ChevronRight, Package, Truck, Clock, CheckCircle2, XCircle, Info, ChevronDown } from 'lucide-svelte';
  import { fade, slide } from 'svelte/transition';
  import { onMount } from 'svelte';

  export let data;
  $: orders = data.orders || [];
  $: provider = data.provider;
  $: brandColor = provider?.brand_color || '#003f87';

  let expandedOrderId: string | null = null;

  function toggleOrder(id: string) {
    expandedOrderId = expandedOrderId === id ? null : id;
  }

  function formatDate(dateStr: string) {
    return new Date(dateStr).toLocaleDateString('en-US', {
      month: 'short',
      day: 'numeric',
      year: 'numeric'
    });
  }

  function getStatusColor(status: string) {
    switch (status?.toLowerCase()) {
      case 'completed': return '#2e7d32';
      case 'pending': return '#ed6c02';
      case 'processing': return '#0288d1';
      case 'cancelled': return '#d32f2f';
      default: return '#757575';
    }
  }
</script>

<svelte:head>
  <title>My Orders — {provider?.name}</title>
</svelte:head>

<div class="orders-page" style="--brand: {brandColor};">
  <header class="page-header">
    <div class="layout-container">
      <div class="header-content">
        <div class="header-icon"><ShoppingBag class="w-8 h-8" /></div>
        <div class="header-text">
          <h1>Order History</h1>
          <p>Track your pharmacy purchases and medication orders.</p>
        </div>
      </div>
    </div>
  </header>

  <main class="layout-container">
    {#if orders.length === 0}
      <div class="empty-state" in:fade>
        <div class="empty-gfx">
          <Package class="w-16 h-16" />
        </div>
        <h2>No orders found</h2>
        <p>You haven't placed any pharmacy orders yet. Visit our partner shops to get started.</p>
        <a href="/pharmacies" class="cta-btn" style="background: {brandColor};">Explore Pharmacies</a>
      </div>
    {:else}
      <div class="orders-list">
        {#each orders as order (order.id)}
          <div class="order-card" class:expanded={expandedOrderId === order.id}>
            <div class="order-summary" on:click={() => toggleOrder(order.id)}>
              <div class="order-main-info">
                <div class="order-meta">
                  <span class="order-num">#{order.order_number}</span>
                  <span class="order-date">{formatDate(order.created_at)}</span>
                </div>
                <div class="order-shop">
                  <MapPin class="w-4 h-4" />
                  <span>{order.branches?.name || 'Partner Pharmacy'}</span>
                </div>
              </div>

              <div class="order-status-price">
                <div class="status-badge" style="background: {getStatusColor(order.order_status)}20; color: {getStatusColor(order.order_status)};">
                  <Clock class="w-3 h-3 mr-1" />
                  {order.order_status || 'Pending'}
                </div>
                <div class="order-total">
                  ₦{order.total_amount?.toLocaleString()}
                </div>
                <div class="expand-icon">
                  <ChevronDown class="w-5 h-5 transition-transform" />
                </div>
              </div>
            </div>

            {#if expandedOrderId === order.id}
              <div class="order-details" transition:slide>
                <div class="details-grid">
                  <section class="items-section">
                    <h4>Purchase Summary ({order.order_items?.length} items)</h4>
                    <div class="items-list">
                      {#each order.order_items as item}
                        <div class="order-item">
                          <span class="i-qty">{item.quantity}x</span>
                          <span class="i-name">{item.product_name}</span>
                          <span class="i-price">₦{item.subtotal?.toLocaleString()}</span>
                        </div>
                      {/each}
                    </div>
                    <div class="calc-table">
                        <div class="calc-row"><span>Subtotal</span><span>₦{order.subtotal?.toLocaleString()}</span></div>
                        {#if order.delivery_fee > 0}<div class="calc-row"><span>Delivery Fee</span><span>₦{order.delivery_fee?.toLocaleString()}</span></div>{/if}
                        {#if order.tax_amount > 0}<div class="calc-row"><span>Tax</span><span>₦{order.tax_amount?.toLocaleString()}</span></div>{/if}
                        <div class="calc-row total"><span>Total</span><span>₦{order.total_amount?.toLocaleString()}</span></div>
                    </div>
                  </section>

                  <section class="fulfillment-section">
                    <h4>Fulfillment Info</h4>
                    <div class="info-box">
                      <div class="info-row">
                        <span class="icon-shell">
                          {#if order.fulfillment_type === 'delivery'}<Truck />{:else}<ShoppingBag />{/if}
                        </span>
                        <div class="info-content">
                          <span class="label">Method</span>
                          <span class="val">{order.fulfillment_type === 'delivery' ? 'Home Delivery' : 'Store Pickup'}</span>
                        </div>
                      </div>
                      <div class="info-row">
                        <span class="icon-shell"><Info /></span>
                        <div class="info-content">
                          <span class="label">Location</span>
                          <span class="val">{order.branches?.name}</span>
                          <p class="sub-val">{order.branches?.address}, {order.branches?.city}</p>
                        </div>
                      </div>
                      {#if order.special_instructions}
                        <div class="instructions">
                            <span class="label">Notes</span>
                            <p>{order.special_instructions}</p>
                        </div>
                      {/if}
                    </div>
                    <button class="reorder-btn">Re-order Items</button>
                  </section>
                </div>
              </div>
            {/if}
          </div>
        {/each}
      </div>
    {/if}
  </main>
</div>

<style>
  .orders-page { min-height: 100vh; background: var(--surface); padding-bottom: 5rem; }
  
  .page-header { background: white; border-bottom: 1px solid var(--outline-variant); padding: 3rem 0; margin-bottom: 2rem; }
  .header-content { display: flex; align-items: center; gap: 1.5rem; }
  .header-icon { width: 56px; height: 56px; border-radius: 1.25rem; background: var(--surface-container-high); display: flex; align-items: center; justify-content: center; color: var(--brand); }
  .header-text h1 { font-family: var(--font-headline); font-size: 2rem; font-weight: 800; color: var(--on-surface); line-height: 1.1; margin-bottom: 0.25rem; }
  .header-text p { font-size: 0.9375rem; color: var(--on-surface-variant); font-weight: 500; }

  .orders-list { display: flex; flex-direction: column; gap: 1rem; }
  
  .order-card { background: white; border: 1px solid var(--outline-variant); border-radius: 1.25rem; overflow: hidden; transition: all 0.2s; }
  .order-card.expanded { box-shadow: 0 10px 25px -5px rgba(0,0,0,0.05); border-color: var(--brand); }
  
  .order-summary { padding: 1.5rem 2rem; display: flex; align-items: center; justify-content: space-between; cursor: pointer; }
  .order-summary:hover { background: var(--surface-container-lowest); }
  
  .order-main-info { display: flex; flex-direction: column; gap: 0.5rem; }
  .order-meta { display: flex; align-items: center; gap: 0.75rem; }
  .order-num { font-size: 0.875rem; font-weight: 800; color: var(--on-surface); }
  .order-date { font-size: 0.8125rem; color: var(--on-surface-variant); font-weight: 600; }
  .order-shop { display: flex; align-items: center; gap: 0.5rem; font-size: 0.8125rem; font-weight: 700; color: var(--brand); }

  .order-status-price { display: flex; align-items: center; gap: 2rem; }
  .status-badge { display: flex; align-items: center; padding: 0.35rem 0.75rem; border-radius: 2rem; font-size: 0.75rem; font-weight: 800; text-transform: uppercase; letter-spacing: 0.05em; }
  .order-total { font-size: 1.125rem; font-weight: 900; color: var(--on-surface); min-width: 100px; text-align: right; }
  
  .order-card.expanded .expand-icon { transform: rotate(180deg); }
  .expand-icon { color: var(--on-surface-variant); }

  .order-details { border-top: 1px solid var(--outline-variant); background: var(--surface-container-lowest); }
  .details-grid { display: grid; grid-template-columns: 1fr; gap: 2rem; padding: 2rem; }
  @media (min-width: 768px) { .details-grid { grid-template-columns: 1fr 340px; } }

  h4 { font-size: 0.7rem; font-weight: 800; text-transform: uppercase; letter-spacing: 0.1em; color: var(--on-surface-variant); margin-bottom: 1.5rem; }
  
  .items-list { display: flex; flex-direction: column; gap: 0.75rem; margin-bottom: 1.5rem; }
  .order-item { display: flex; gap: 1rem; font-size: 0.875rem; }
  .i-qty { font-weight: 800; color: var(--on-surface); }
  .i-name { flex: 1; font-weight: 500; color: var(--on-surface-variant); }
  .i-price { font-weight: 700; color: var(--on-surface); }

  .calc-table { border-top: 1.5px dashed var(--outline-variant); padding-top: 1rem; }
  .calc-row { display: flex; justify-content: space-between; font-size: 0.875rem; color: var(--on-surface-variant); margin-bottom: 0.5rem; }
  .calc-row.total { font-size: 1.125rem; font-weight: 900; color: var(--brand); border-top: 1px solid var(--outline-variant); padding-top: 0.75rem; margin-top: 0.5rem; }

  .info-box { background: white; border-radius: 1rem; border: 1px solid var(--outline-variant); padding: 1.5rem; display: flex; flex-direction: column; gap: 1.5rem; margin-bottom: 1.5rem; }
  .info-row { display: flex; gap: 1rem; align-items: flex-start; }
  .icon-shell { width: 32px; height: 32px; border-radius: 50%; background: var(--surface-container-low); color: var(--brand); display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
  .icon-shell :global(svg) { width: 16px; height: 16px; }
  .info-content { display: flex; flex-direction: column; }
  .label { font-size: 0.65rem; font-weight: 800; color: var(--on-surface-variant); text-transform: uppercase; margin-bottom: 0.15rem; }
  .val { font-size: 0.875rem; font-weight: 700; color: var(--on-surface); }
  .sub-val { font-size: 0.75rem; color: var(--on-surface-variant); }

  .instructions { padding-top: 1rem; border-top: 1px solid var(--outline-variant); }
  .instructions p { font-size: 0.8125rem; color: var(--on-surface-variant); line-height: 1.5; font-style: italic; }

  .reorder-btn { width: 100%; padding: 1rem; border-radius: 1rem; border: 1.5px solid var(--brand); color: var(--brand); font-weight: 800; font-size: 0.875rem; transition: all 0.2s; }
  .reorder-btn:hover { background: var(--brand); color: white; }

  .empty-state { text-align: center; padding: 6rem 2rem; background: white; border-radius: 2rem; border: 1px solid var(--outline-variant); }
  .empty-gfx { width: 100px; height: 100px; border-radius: 50%; background: var(--surface-container-low); display: flex; align-items: center; justify-content: center; color: var(--on-surface-variant); margin: 0 auto 1.5rem; }
  .empty-state h2 { font-family: var(--font-headline); font-size: 1.5rem; font-weight: 800; margin-bottom: 0.5rem; }
  .empty-state p { font-size: 0.9375rem; color: var(--on-surface-variant); margin-bottom: 2rem; max-width: 400px; margin-inline: auto; }
  .cta-btn { display: inline-block; padding: 1rem 2.5rem; border-radius: 1.25rem; color: white; font-weight: 800; text-decoration: none; box-shadow: 0 10px 20px -5px rgba(0,0,0,0.1); }
</style>
