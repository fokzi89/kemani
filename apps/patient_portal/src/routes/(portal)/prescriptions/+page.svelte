<script lang="ts">
  import { 
    Pill,
    Calendar,
    User,
    Clock,
    Download,
    Eye,
    ChevronDown,
    ChevronUp,
    FileText,
    History,
    Search,
    Filter,
    ArrowRight
  } from 'lucide-svelte';
  import { fade, slide } from 'svelte/transition';
  import { flip } from 'svelte/animate';

  export let data;
  $: prescriptions = data.prescriptions || [];
  $: provider = data.provider;
  $: brandColor = provider?.brand_color || '#003f87';

  let searchQuery = '';
  let expandedId: string | null = null;

  $: filtered = prescriptions.filter(p => {
    const matchesSearch = !searchQuery || 
      p.healthcare_providers?.full_name?.toLowerCase().includes(searchQuery.toLowerCase()) || 
      p.prescription_code?.toLowerCase().includes(searchQuery.toLowerCase());
    return matchesSearch;
  });

  function toggleExpand(id: string) {
    if (expandedId === id) expandedId = null;
    else expandedId = id;
  }
</script>

<svelte:head>
  <title>Your Prescriptions — {provider?.name}</title>
</svelte:head>

<div class="prescriptions-page" style="--brand: {brandColor};">
  <div class="layout-container">
    <header class="page-header">
      <div class="headline">
        <h1 class="page-title">Prescription History</h1>
        <p class="page-desc">View and download your medication history issued by {provider?.name}.</p>
      </div>

       <div class="stats-overview">
        <div class="stat-card">
          <span class="stat-val">{prescriptions.length}</span>
          <span class="stat-label">Total Prescriptions</span>
        </div>
      </div>
    </header>

    <div class="search-filters">
       <div class="search-wrapper">
          <Search class="w-4 h-4 text-outline" />
          <input type="text" bind:value={searchQuery} placeholder="Search by code or doctor..." />
       </div>
    </div>

    <div class="history-list">
      {#if filtered.length === 0}
        <div class="empty-state" in:fade>
           <div class="empty-icon-box">
              <Pill class="w-10 h-10" />
           </div>
           <h3>No prescriptions yet</h3>
           <p>Any medications prescribed by your provider will appear here.</p>
        </div>
      {:else}
        <div class="list-grid">
          {#each filtered as presc (presc.id)}
            <div 
              class="presc-card" 
              class:is-expanded={expandedId === presc.id}
              animate:flip={{ duration: 300 }}
              in:slide={{ duration: 400 }}
            >
              <div class="presc-header" on:click={() => toggleExpand(presc.id)}>
                <div class="presc-info">
                   <div class="p-icon" style="background: {brandColor}10; color: {brandColor};">
                      <FileText class="w-5 h-5" />
                   </div>
                   <div class="p-meta">
                      <h3>{presc.prescription_code || 'Prescription #' + presc.id.slice(0, 8)}</h3>
                      <div class="meta-row">
                         <span class="m-item"><User class="w-3.5 h-3.5" /> {presc.healthcare_providers?.full_name || 'Dr. Unknown'}</span>
                         <span class="m-item"><Calendar class="w-3.5 h-3.5" /> {new Date(presc.created_at).toLocaleDateString()}</span>
                      </div>
                   </div>
                </div>
                <div class="presc-actions">
                   <span class="drug-count">{presc.prescribed_drugs?.length || 0} Medications</span>
                   {#if expandedId === presc.id}
                      <ChevronUp class="w-5 h-5" />
                   {:else}
                      <ChevronDown class="w-5 h-5" />
                   {/if}
                </div>
              </div>

              {#if expandedId === presc.id}
                <div class="presc-details" transition:slide>
                   <div class="drugs-list">
                      {#each presc.prescribed_drugs || [] as drug}
                         <div class="drug-item">
                            <div class="d-info">
                               <span class="d-name">{drug.drug_name}</span>
                               <span class="d-dosage">{drug.dosage} - {drug.frequency} for {drug.duration}</span>
                            </div>
                            <button class="pharmacy-link" title="Source from pharmacy">
                               <ArrowRight class="w-4 h-4" />
                            </button>
                         </div>
                      {/each}
                   </div>
                   {#if presc.notes}
                      <div class="presc-notes">
                         <span class="n-label">Doctor's Instructions</span>
                         <p>{presc.notes}</p>
                      </div>
                   {/if}
                   <div class="d-footer">
                      <button class="download-btn">
                         <Download class="w-4 h-4" />
                         Download PDF
                      </button>
                   </div>
                </div>
              {/if}
            </div>
          {/each}
        </div>
      {/if}
    </div>
  </div>
</div>

<style>
  .prescriptions-page {
    min-height: calc(100vh - 64px);
    background: #f8fafc;
    padding: 3rem 0;
  }

  .page-header { display: flex; flex-direction: column; gap: 2rem; margin-bottom: 3rem; }
  @media (min-width: 768px) { .page-header { flex-direction: row; justify-content: space-between; align-items: flex-end; } }

  .page-title { font-size: 2.25rem; font-weight: 900; color: #0f172a; margin-bottom: 0.5rem; letter-spacing: -0.03em; }
  .page-desc { font-size: 1rem; color: #64748b; font-weight: 500; }

  .stats-overview { display: flex; gap: 1.5rem; }
  .stat-card { background: white; padding: 1rem 1.75rem; border-radius: 1.25rem; box-shadow: 0 4px 6px -1px rgba(0,0,0,0.05); border: 1px solid #f1f5f9; display: flex; flex-direction: column; align-items: center; min-width: 140px; }
  @media (max-width: 640px) {
     .prescriptions-page { padding: 1.5rem 0; }
     .page-header { gap: 1rem; margin-bottom: 2rem; }
     .stat-card { min-width: 100%; }
  }
  .stat-val { font-size: 1.75rem; font-weight: 800; color: #1e293b; line-height: 1; margin-bottom: 0.25rem; }
  .stat-label { font-size: 0.7rem; font-weight: 700; color: #94a3b8; text-transform: uppercase; letter-spacing: 0.05em; }

  .search-filters { margin-bottom: 2.5rem; }
  .search-wrapper { background: white; border-radius: 1rem; padding: 0 1rem; height: 48px; display: flex; align-items: center; gap: 0.75rem; border: 1.5px solid #e2e8f0; width: 100%; max-width: 360px; transition: all 0.2s; }
  .search-wrapper:focus-within { border-color: var(--brand); box-shadow: 0 0 0 4px var(--brand)10; }
  .search-wrapper input { border: none; outline: none; flex: 1; font-size: 0.9375rem; font-weight: 500; color: #1e293b; }

  .list-grid { display: flex; flex-direction: column; gap: 1rem; }

  .presc-card { background: white; border-radius: 1.25rem; border: 1.5px solid #f1f5f9; box-shadow: 0 4px 10px -2px rgba(0,0,0,0.03); transition: all 0.2s ease; overflow: hidden; }
  .presc-card.is-expanded { border-color: var(--brand); box-shadow: 0 15px 30px -10px rgba(0,0,0,0.08); }

  .presc-header { padding: 1.25rem 1.5rem; display: flex; justify-content: space-between; align-items: center; cursor: pointer; user-select: none; }
  @media (max-width: 640px) {
     .presc-header { flex-direction: column; align-items: flex-start; gap: 1rem; }
     .presc-actions { width: 100%; justify-content: space-between; padding-top: 1rem; border-top: 1px solid #f8fafc; }
     .meta-row { flex-direction: column; gap: 0.4rem; }
  }
  .presc-header:hover { background: #f8fafc; }

  .presc-info { display: flex; align-items: center; gap: 1rem; }
  .p-icon { width: 44px; height: 44px; border-radius: 12px; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
  .p-meta h3 { font-size: 1rem; font-weight: 800; color: #0f172a; margin-bottom: 0.1rem; }
  .meta-row { display: flex; gap: 1rem; }
  .m-item { font-size: 0.75rem; font-weight: 600; color: #64748b; display: flex; align-items: center; gap: 0.25rem; }

  .presc-actions { display: flex; align-items: center; gap: 1.5rem; color: #94a3b8; }
  .drug-count { font-size: 0.8125rem; font-weight: 700; color: #1e293b; background: #f1f5f9; padding: 0.25rem 0.75rem; border-radius: 99px; }

  .presc-details { padding: 0 1.5rem 1.5rem; border-top: 1px solid #f1f5f9; }
  
  .drugs-list { padding: 1.25rem 0; display: flex; flex-direction: column; gap: 0.75rem; }
  .drug-item { display: flex; justify-content: space-between; align-items: center; padding: 0.75rem 1rem; background: #f8fafc; border-radius: 0.75rem; }
  .d-name { display: block; font-size: 0.9375rem; font-weight: 800; color: #0f172a; margin-bottom: 0.1rem; }
  .d-dosage { font-size: 0.8125rem; font-weight: 600; color: #64748b; }
  .pharmacy-link { width: 32px; height: 32px; border-radius: 50%; color: var(--brand); display: flex; align-items: center; justify-content: center; border: 1px solid #e2e8f0; background: white; cursor: pointer; transition: all 0.2s; }
  .pharmacy-link:hover { background: var(--brand); color: white; border-color: var(--brand); }

  .presc-notes { padding: 1.25rem; background: #fffbeb; border: 1px solid #fef3c7; border-radius: 1rem; margin-bottom: 1.25rem; }
  .n-label { display: block; font-size: 0.65rem; font-weight: 800; color: #92400e; text-transform: uppercase; margin-bottom: 0.5rem; }
  .presc-notes p { font-size: 0.875rem; color: #b45309; font-weight: 500; line-height: 1.5; }

  .d-footer { display: flex; justify-content: flex-end; }
  .download-btn { padding: 0.625rem 1.25rem; border-radius: 0.75rem; background: #1e293b; color: white; font-size: 0.8125rem; font-weight: 700; display: flex; align-items: center; gap: 0.5rem; transition: background 0.2s; }
  .download-btn:hover { background: #0f172a; }

  .empty-state { text-align: center; padding: 6rem 2rem; background: white; border-radius: 2rem; border: 2px dashed #e2e8f0; }
  .empty-icon-box { width: 80px; height: 80px; border-radius: 1.5rem; background: #f8fafc; color: #cbd5e1; display: flex; align-items: center; justify-content: center; margin: 0 auto 1.5rem; }
  .empty-state h3 { font-size: 1.5rem; font-weight: 800; color: #0f172a; margin-bottom: 0.75rem; }
</style>
