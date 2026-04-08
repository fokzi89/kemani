<script lang="ts">
  import { 
    Calendar, 
    Clock, 
    MessageSquare, 
    Video, 
    Phone, 
    MoreVertical, 
    ArrowRight, 
    Search,
    Filter,
    ClipboardCheck,
    XCircle,
    CheckCircle2,
    CalendarCheck,
    Loader2
  } from 'lucide-svelte';
  import { fade, slide } from 'svelte/transition';
  import { flip } from 'svelte/animate';

  export let data;
  $: consultations = data.consultations || [];
  $: provider = data.provider;
  $: brandColor = provider?.brand_color || '#003f87';

  let searchQuery = '';
  let statusFilter = 'All';

  $: filtered = consultations.filter(c => {
    const matchesSearch = !searchQuery || c.provider_name?.toLowerCase().includes(searchQuery.toLowerCase());
    const matchesStatus = statusFilter === 'All' || c.status === statusFilter.toLowerCase();
    return matchesSearch && matchesStatus;
  });

  const statusMap = {
    pending: { label: 'Pending Approval', color: '#eab308' },
    accepted: { label: 'Approved', color: '#10b981' },
    in_progress: { label: 'In Consultation', color: '#6366f1' },
    completed: { label: 'Completed', color: '#64748b' },
    cancelled: { label: 'Cancelled', color: '#ef4444' }
  };

  function getIcon(type: string) {
    if (type === 'video') return Video;
    if (type === 'audio') return Phone;
    if (type === 'chat') return MessageSquare;
    return Calendar;
  }
</script>

<svelte:head>
  <title>Your Appointments — {provider?.name}</title>
</svelte:head>

<div class="appointments-page" style="--brand: {brandColor};">
  <div class="layout-container">
    <header class="page-header">
      <div class="headline">
        <h1 class="page-title">Consultation History</h1>
        <p class="page-desc">Manage and view your past and upcoming sessions with {provider?.name}.</p>
      </div>
      
      <div class="stats-overview">
        <div class="stat-card">
          <span class="stat-val">{consultations.length}</span>
          <span class="stat-label">Total bookings</span>
        </div>
        <div class="stat-card">
          <span class="stat-val text-brand">{consultations.filter(c => c.status === 'completed').length}</span>
          <span class="stat-label">Successful visits</span>
        </div>
      </div>
    </header>

    <div class="search-filters">
       <div class="search-wrapper">
          <Search class="w-4 h-4 text-outline" />
          <input type="text" bind:value={searchQuery} placeholder="Filter by provider..." />
       </div>
       <div class="filters">
          {#each ['All', 'Pending', 'Accepted', 'Completed', 'Cancelled'] as f}
             <button 
                class="filter-chip" 
                class:active={statusFilter === f}
                on:click={() => statusFilter = f}
             >
                {f}
             </button>
          {/each}
       </div>
    </div>

    <div class="appointments-list">
      {#if filtered.length === 0}
        <div class="empty-state" in:fade>
           <div class="empty-icon-box">
              <CalendarCheck class="w-10 h-10" />
           </div>
           <h3>No consultations found</h3>
           <p>Your scheduled visits will appear here once you make a booking.</p>
           <a href="/" class="book-now-btn" style="background: {brandColor};">Schedule Now</a>
        </div>
      {:else}
        <div class="list-grid">
          {#each filtered as consult (consult.id)}
            <div 
              class="consult-card" 
              animate:flip={{ duration: 300 }}
              in:slide={{ duration: 400 }}
            >
              <div class="consult-top">
                <div class="provider-info">
                   <div class="provider-avatar">
                      {#if consult.provider_photo_url}
                         <img src={consult.provider_photo_url} alt={consult.provider_name} />
                      {:else}
                         <div class="avatar-ph">{consult.provider_name?.charAt(0)}</div>
                      {/if}
                   </div>
                   <div class="provider-meta">
                      <h3>{consult.provider_name}</h3>
                      <div class="type-tag">
                         <svelte:component this={getIcon(consult.type)} class="w-3.5 h-3.5" />
                         <span class="text-capitalize">{consult.type.replace('_', ' ')}</span>
                      </div>
                   </div>
                </div>
                <div 
                  class="status-chip" 
                  style="background: {statusMap[consult.status]?.color}15; color: {statusMap[consult.status]?.color};"
                >
                   {statusMap[consult.status]?.label || consult.status}
                </div>
              </div>

              <div class="consult-body">
                 <div class="info-item">
                    <Calendar class="w-4 h-4" />
                    <span>{new Date(consult.scheduled_time).toLocaleDateString(undefined, { dateStyle: 'medium' })}</span>
                 </div>
                 <div class="info-item">
                    <Clock class="w-4 h-4" />
                    <span>{new Date(consult.scheduled_time).toLocaleTimeString(undefined, { hour: '2-digit', minute: '2-digit' })}</span>
                 </div>
              </div>

              <div class="consult-footer">
                 <div class="fee-display">
                    <span class="label">Consultation Fee</span>
                    <span class="val">₦{consult.consultation_fee?.toLocaleString()}</span>
                 </div>
                 {#if consult.status === 'pending' || consult.status === 'accepted'}
                   <a href="/waiting-area/{consult.id}" class="action-link" style="color: {brandColor};">
                      View Details
                      <ArrowRight class="w-4 h-4" />
                   </a>
                 {:else}
                   <button class="action-link" style="color: #64748b;">
                      Summary
                      <ChevronRight class="w-4 h-4" />
                   </button>
                 {/if}
              </div>
            </div>
          {/each}
        </div>
      {/if}
    </div>
  </div>
</div>

<style>
  .appointments-page {
    min-height: calc(100vh - 64px);
    background: #f8fafc;
    padding: 3rem 0;
  }

  /* Header */
  .page-header { display: flex; flex-direction: column; gap: 2rem; margin-bottom: 3rem; }
  @media (min-width: 768px) { .page-header { flex-direction: row; justify-content: space-between; align-items: flex-end; } }

  .page-title { font-size: 2.25rem; font-weight: 900; color: #0f172a; margin-bottom: 0.5rem; letter-spacing: -0.03em; }
  .page-desc { font-size: 1rem; color: #64748b; font-weight: 500; }

  .stats-overview { display: flex; gap: 1.5rem; }
  .stat-card { background: white; padding: 1rem 1.75rem; border-radius: 1.25rem; box-shadow: 0 4px 6px -1px rgba(0,0,0,0.05); border: 1px solid #f1f5f9; display: flex; flex-direction: column; align-items: center; min-width: 140px; }
  .stat-val { font-size: 1.75rem; font-weight: 800; color: #1e293b; line-height: 1; margin-bottom: 0.25rem; }
  .text-brand { color: var(--brand); }
  .stat-label { font-size: 0.7rem; font-weight: 700; color: #94a3b8; text-transform: uppercase; letter-spacing: 0.05em; }

  /* Filters */
  .search-filters { display: flex; flex-direction: column; gap: 1.5rem; margin-bottom: 2.5rem; }
  @media (min-width: 1024px) { .search-filters { flex-direction: row; justify-content: space-between; align-items: center; } }

  .search-wrapper { background: white; border-radius: 1rem; padding: 0 1rem; height: 48px; display: flex; align-items: center; gap: 0.75rem; border: 1.5px solid #e2e8f0; width: 100%; max-width: 360px; transition: all 0.2s; }
  .search-wrapper:focus-within { border-color: var(--brand); box-shadow: 0 0 0 4px var(--brand)10; }
  .search-wrapper input { border: none; outline: none; flex: 1; font-size: 0.9375rem; font-weight: 500; color: #1e293b; }

  .filters { display: flex; gap: 0.5rem; overflow-x: auto; padding-bottom: 0.5rem; -ms-overflow-style: none; scrollbar-width: none; }
  .filters::-webkit-scrollbar { display: none; }
  .filter-chip { padding: 0.625rem 1.25rem; border-radius: 99px; background: white; border: 1.5px solid #e2e8f0; font-size: 0.8125rem; font-weight: 700; color: #64748b; cursor: pointer; transition: all 0.2s; white-space: nowrap; }
  .filter-chip:hover { border-color: #cbd5e1; color: #1e293b; }
  .filter-chip.active { background: var(--brand); border-color: var(--brand); color: white; box-shadow: 0 10px 15px -3px var(--brand)30; }

  /* List */
  .list-grid { display: grid; grid-template-columns: 1fr; gap: 1.25rem; }
  @media (min-width: 1024px) { .list-grid { grid-template-columns: repeat(2, 1fr); } }

  .consult-card { background: white; border-radius: 1.5rem; padding: 1.5rem; border: 1.5px solid #f1f5f9; box-shadow: 0 4px 10px -2px rgba(0,0,0,0.03); transition: all 0.3s ease; }
  .consult-card:hover { transform: translateY(-3px); box-shadow: 0 20px 25px -5px rgba(0,0,0,0.08); border-color: #e2e8f0; }

  .consult-top { display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 1.25rem; }
  .provider-info { display: flex; gap: 1rem; }
  .provider-avatar { width: 52px; height: 52px; border-radius: 1rem; overflow: hidden; background: #f1f5f9; flex-shrink: 0; }
  .provider-avatar img { width: 100%; height: 100%; object-fit: cover; }
  .avatar-ph { width: 100%; height: 100%; display: flex; align-items: center; justify-content: center; font-size: 1.25rem; font-weight: 900; color: #64748b; }

  .provider-meta h3 { font-size: 1.125rem; font-weight: 800; color: #0f172a; margin-bottom: 0.25rem; }
  .type-tag { display: flex; align-items: center; gap: 0.35rem; font-size: 0.75rem; font-weight: 700; color: #64748b; text-transform: uppercase; }

  .status-chip { padding: 0.35rem 0.75rem; border-radius: 99px; font-size: 0.65rem; font-weight: 800; text-transform: uppercase; letter-spacing: 0.05em; }

  .consult-body { display: flex; gap: 1.5rem; margin-bottom: 1.5rem; border-top: 1px solid #f8fafc; padding-top: 1rem; }
  .info-item { display: flex; align-items: center; gap: 0.5rem; font-size: 0.875rem; font-weight: 700; color: #1e293b; }
  .info-item :global(svg) { color: #94a3b8; }

  .consult-footer { display: flex; justify-content: space-between; align-items: flex-end; padding-top: 1.25rem; border-top: 1px solid #f1f5f9; }
  .fee-display { display: flex; flex-direction: column; gap: 0.15rem; }
  .fee-display .label { font-size: 0.6rem; font-weight: 800; color: #94a3b8; text-transform: uppercase; }
  .fee-display .val { font-size: 1rem; font-weight: 800; color: #0f172a; }

  .action-link { display: flex; align-items: center; gap: 0.4rem; font-size: 0.8125rem; font-weight: 800; text-decoration: none; cursor: pointer; border: none; background: none; padding: 0.5rem 0; }
  .action-link:hover { opacity: 0.8; }

  /* Empty State */
  .empty-state { text-align: center; padding: 6rem 2rem; background: white; border-radius: 2rem; border: 2px dashed #e2e8f0; }
  .empty-icon-box { width: 80px; height: 80px; border-radius: 1.5rem; background: #f8fafc; color: #cbd5e1; display: flex; align-items: center; justify-content: center; margin: 0 auto 1.5rem; }
  .empty-state h3 { font-size: 1.5rem; font-weight: 800; color: #0f172a; margin-bottom: 0.75rem; }
  .empty-state p { font-size: 1rem; color: #64748b; margin-bottom: 2rem; }
  .book-now-btn { display: inline-flex; align-items: center; padding: 0.875rem 2rem; border-radius: 1rem; color: white; font-weight: 800; font-size: 1rem; text-decoration: none; box-shadow: 0 10px 15px -3px rgba(0,0,0,0.1); }
</style>
