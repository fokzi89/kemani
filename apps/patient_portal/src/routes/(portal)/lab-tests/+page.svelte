<script lang="ts">
  import { 
    Activity,
    Calendar,
    User,
    Clock,
    Download,
    Eye,
    ChevronDown,
    ChevronUp,
    FlaskConical,
    FileText,
    Search,
    Filter,
    ArrowRight,
    AlertCircle
  } from 'lucide-svelte';
  import { fade, slide } from 'svelte/transition';
  import { flip } from 'svelte/animate';

  export let data;
  $: labRequests = data.labRequests || [];
  $: provider = data.provider;
  $: brandColor = provider?.brand_color || '#003f87';

  let searchQuery = '';
  let expandedId: string | null = null;

  $: filtered = labRequests.filter(l => {
    const matchesSearch = !searchQuery || 
      l.test_type?.toLowerCase().includes(searchQuery.toLowerCase()) || 
      l.healthcare_providers?.full_name?.toLowerCase().includes(searchQuery.toLowerCase());
    return matchesSearch;
  });

  function toggleExpand(id: string) {
    if (expandedId === id) expandedId = null;
    else expandedId = id;
  }

  const priorityColors = {
    routine: { text: '#2563eb', bg: '#eff6ff' },
    urgent: { text: '#d97706', bg: '#fffbeb' },
    stat: { text: '#dc2626', bg: '#fef2f2' }
  };
</script>

<svelte:head>
  <title>Lab Test Requests History — {provider?.name}</title>
</svelte:head>

<div class="lab-tests-page" style="--brand: {brandColor};">
  <div class="layout-container">
    <header class="page-header">
      <div class="headline">
        <h1 class="page-title">Lab Test Requests</h1>
        <p class="page-desc">View and download laboratory orders issued by {provider?.name}.</p>
      </div>

       <div class="stats-overview">
        <div class="stat-card">
          <span class="stat-val">{labRequests.length}</span>
          <span class="stat-label">Total Requests</span>
        </div>
      </div>
    </header>

    <div class="search-filters">
       <div class="search-wrapper">
          <Search class="w-4 h-4 text-outline" />
          <input type="text" bind:value={searchQuery} placeholder="Search test type or doctor..." />
       </div>
    </div>

    <div class="history-list">
      {#if filtered.length === 0}
        <div class="empty-state" in:fade>
           <div class="empty-icon-box">
              <FlaskConical class="w-10 h-10" />
           </div>
           <h3>No laboratory requests found</h3>
           <p>Any diagnostic tests ordered for you will be listed here.</p>
        </div>
      {:else}
        <div class="list-grid">
          {#each filtered as lab (lab.id)}
            <div 
              class="lab-card" 
              class:is-expanded={expandedId === lab.id}
              animate:flip={{ duration: 300 }}
              in:slide={{ duration: 400 }}
            >
              <div class="lab-header" on:click={() => toggleExpand(lab.id)}>
                <div class="lab-info">
                   <div class="l-icon" style="background: {brandColor}10; color: {brandColor};">
                      <Activity class="w-5 h-5" />
                   </div>
                   <div class="l-meta">
                      <h3>{lab.test_type?.replace('_', ' ').toUpperCase() || 'Laboratory Request'}</h3>
                      <div class="meta-row">
                         <span class="m-item"><User class="w-3.5 h-3.5" /> {lab.healthcare_providers?.full_name}</span>
                         <span class="m-item"><Calendar class="w-3.5 h-3.5" /> {new Date(lab.created_at).toLocaleDateString()}</span>
                      </div>
                   </div>
                </div>
                <div class="lab-actions">
                   {#if lab.priority}
                      <span 
                        class="priority-tag" 
                        style="background: {priorityColors[lab.priority]?.bg}; color: {priorityColors[lab.priority]?.text};"
                      >
                         {lab.priority}
                      </span>
                   {/if}
                   {#if expandedId === lab.id}
                      <ChevronUp class="w-5 h-5 text-outline" />
                   {:else}
                      <ChevronDown class="w-5 h-5 text-outline" />
                   {/if}
                </div>
              </div>

              {#if expandedId === lab.id}
                <div class="lab-details" transition:slide>
                   <div class="tests-list">
                      <span class="sec-label">Tests Requested</span>
                      <div class="test-items">
                         {#if lab.tests && lab.tests.length > 0}
                           {#each lab.tests as test}
                             <div class="test-item">
                                <div class="ti-main">
                                   <span class="ti-name">{test.name}</span>
                                   {#if test.sample_type}
                                      <span class="ti-sample">Sample: {test.sample_type}</span>
                                   {/if}
                                </div>
                                {#if test.special_instructions}
                                   <div class="ti-notes">
                                      <AlertCircle class="w-3 h-3" />
                                      {test.special_instructions}
                                   </div>
                                {/if}
                             </div>
                           {/each}
                         {:else}
                           <p class="no-data">No specific tests listed. See clinical indication below.</p>
                         {/if}
                      </div>
                   </div>

                   {#if lab.clinical_indication}
                      <div class="clinical-info">
                         <span class="sec-label">Clinical Indication</span>
                         <p>{lab.clinical_indication}</p>
                      </div>
                   {/if}

                   {#if lab.notes}
                      <div class="additional-notes">
                         <span class="sec-label">Additional Instructions</span>
                         <p>{lab.notes}</p>
                      </div>
                   {/if}

                   <div class="d-footer">
                      <button class="download-btn">
                         <Download class="w-4 h-4" />
                         E-Request PDF
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
  .lab-tests-page {
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
     .lab-tests-page { padding: 1.5rem 0; }
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

  .lab-card { background: white; border-radius: 1.25rem; border: 1.5px solid #f1f5f9; box-shadow: 0 4px 10px -2px rgba(0,0,0,0.03); transition: all 0.2s ease; overflow: hidden; }
  .lab-card.is-expanded { border-color: var(--brand); box-shadow: 0 15px 30px -10px rgba(0,0,0,0.08); }

  .lab-header { padding: 1.25rem 1.5rem; display: flex; justify-content: space-between; align-items: center; cursor: pointer; user-select: none; }
  @media (max-width: 640px) {
     .lab-header { flex-direction: column; align-items: flex-start; gap: 1rem; }
     .lab-actions { width: 100%; justify-content: space-between; padding-top: 1rem; border-top: 1px solid #f8fafc; }
     .meta-row { flex-direction: column; gap: 0.4rem; }
  }
  .lab-header:hover { background: #f8fafc; }

  .lab-info { display: flex; align-items: center; gap: 1rem; }
  .l-icon { width: 44px; height: 44px; border-radius: 12px; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
  .l-meta h3 { font-size: 1rem; font-weight: 800; color: #0f172a; margin-bottom: 0.1rem; }
  .meta-row { display: flex; gap: 1rem; }
  .m-item { font-size: 0.75rem; font-weight: 600; color: #64748b; display: flex; align-items: center; gap: 0.25rem; }

  .lab-actions { display: flex; align-items: center; gap: 1.5rem; }
  .priority-tag { font-size: 0.65rem; font-weight: 800; text-transform: uppercase; padding: 0.25rem 0.6rem; border-radius: 99px; letter-spacing: 0.05em; }

  .lab-details { padding: 0 1.5rem 1.5rem; border-top: 1px solid #f1f5f9; }
  .sec-label { display: block; font-size: 0.6rem; font-weight: 800; color: #94a3b8; text-transform: uppercase; letter-spacing: 0.05em; margin-bottom: 0.75rem; }

  .tests-list { padding: 1.25rem 0; }
  .test-items { display: flex; flex-direction: column; gap: 0.75rem; }
  .test-item { padding: 1rem; background: #f8fafc; border-radius: 0.75rem; }
  .ti-main { display: flex; justify-content: space-between; align-items: center; margin-bottom: 0.25rem; }
  .ti-name { font-size: 0.9375rem; font-weight: 800; color: #0f172a; }
  .ti-sample { font-size: 0.75rem; font-weight: 600; color: #64748b; }
  .ti-notes { font-size: 0.75rem; font-weight: 600; color: #94a3b8; display: flex; align-items: center; gap: 0.35rem; margin-top: 0.25rem; }

  .clinical-info, .additional-notes { padding: 1.25rem; background: #f8fafc; border-radius: 1rem; margin-top: 1.25rem; }
  .clinical-info p, .additional-notes p { font-size: 0.875rem; color: #475569; font-weight: 500; line-height: 1.5; }

  .d-footer { display: flex; justify-content: flex-end; margin-top: 1.5rem; }
  .download-btn { padding: 0.625rem 1.25rem; border-radius: 0.75rem; background: #1e293b; color: white; font-size: 0.8125rem; font-weight: 700; display: flex; align-items: center; gap: 0.5rem; transition: background 0.2s; }

  .empty-state { text-align: center; padding: 6rem 2rem; background: white; border-radius: 2rem; border: 2px dashed #e2e8f0; }
  .empty-icon-box { width: 80px; height: 80px; border-radius: 1.5rem; background: #f8fafc; color: #cbd5e1; display: flex; align-items: center; justify-content: center; margin: 0 auto 1.5rem; }
  .empty-state h3 { font-size: 1.5rem; font-weight: 800; color: #0f172a; margin-bottom: 0.75rem; }
</style>
