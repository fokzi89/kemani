<script lang="ts">
  import { MapPin, Phone, Mail, Search, FlaskConical, ExternalLink, Microscope } from 'lucide-svelte';
  export let data;
  $: diagnostics = data.diagnostics || [];
  $: city = data.city;
  $: provider = data.provider;
  $: brandColor = provider?.brand_color || '#0ea5e9';

  let searchQuery = '';
  $: filtered = diagnostics.filter((d: any) =>
    !searchQuery ||
    d.name?.toLowerCase().includes(searchQuery.toLowerCase()) ||
    d.address?.toLowerCase().includes(searchQuery.toLowerCase())
  );
</script>

<svelte:head>
  <title>Diagnostic Centres{city ? ` in ${city}` : ''} — {provider?.name}</title>
  <meta name="description" content="Find verified diagnostic centres and laboratories{city ? ` in ${city}` : ''}." />
</svelte:head>

<div class="page" style="--brand:{brandColor};">

  <!-- Header -->
  <div class="page-header" style="background:linear-gradient(135deg,#0f172a 0%,#1e3a5f 100%);">
    <div class="header-inner">
      <div class="header-icon"><FlaskConical class="w-7 h-7 text-white" /></div>
      <h1 class="header-title">Diagnostic Centres</h1>
      <p class="header-sub">
        {city ? `Verified labs & imaging centres in ${city}` : 'Verified diagnostic centres near you'}
      </p>
    </div>
  </div>

  <!-- Search -->
  <div class="search-wrap">
    <div class="search-box">
      <Search class="search-icon" />
      <input
        type="search"
        bind:value={searchQuery}
        placeholder="Search by name, service, or location…"
        class="search-input"
      />
    </div>
  </div>

  <!-- Results -->
  <div class="content">
    {#if filtered.length === 0}
      <div class="empty">
        <FlaskConical class="empty-icon" />
        <h3 class="empty-title">
          {searchQuery ? 'No centres match your search' : `No diagnostic centres found${city ? ` in ${city}` : ''}`}
        </h3>
        <p class="empty-sub">
          {searchQuery ? 'Try a different search term.' : 'Diagnostic centres will be listed as they join the network.'}
        </p>
      </div>
    {:else}
      <p class="results-count">{filtered.length} centre{filtered.length === 1 ? '' : 's'} found{city ? ` in ${city}` : ''}</p>
      <div class="grid">
        {#each filtered as centre}
          <div class="card">
            <div class="card-top">
              <div class="card-header">
                {#if centre.logo_url}
                  <img src={centre.logo_url} alt={centre.name} class="card-logo" />
                {:else}
                  <div class="card-logo-placeholder" style="background:{centre.brand_color || '#0f172a'}18;color:{centre.brand_color || '#0f172a'};">
                    <FlaskConical class="w-5 h-5" />
                  </div>
                {/if}
                <div>
                  <h3 class="card-name">{centre.name}</h3>
                  {#if centre.city}
                    <p class="card-city"><MapPin class="w-3 h-3 inline mr-1" />{centre.city}</p>
                  {/if}
                </div>
              </div>

              <div class="card-body">
                {#if centre.address}
                  <p class="card-detail"><MapPin class="detail-icon" />{centre.address}</p>
                {/if}
                {#if centre.phone}
                  <p class="card-detail"><Phone class="detail-icon" />{centre.phone}</p>
                {/if}
                {#if centre.email}
                  <p class="card-detail"><Mail class="detail-icon" />{centre.email}</p>
                {/if}

                {#if centre.services_offered?.length > 0}
                  <div class="card-tags">
                    {#each centre.services_offered.slice(0, 4) as svc}
                      <span class="tag">{svc}</span>
                    {/each}
                  </div>
                {/if}
              </div>
            </div>

            {#if centre.subdomain || centre.slug}
              <a
                href="http://{centre.subdomain || centre.slug}.localhost:5143"
                target="_blank"
                rel="noopener"
                class="card-action"
              >
                Visit Portal <ExternalLink class="w-3.5 h-3.5" />
              </a>
            {/if}
          </div>
        {/each}
      </div>
    {/if}
  </div>
</div>

<style>
  .page { min-height: 80vh; font-family: 'Inter', sans-serif; }

  .page-header { padding: 3.5rem 2rem 5rem; text-align: center; }
  .header-inner { max-width: 600px; margin: 0 auto; }
  .header-icon { width: 56px; height: 56px; border-radius: 16px; background: rgba(255,255,255,0.1); display: flex; align-items: center; justify-content: center; margin: 0 auto 16px; border: 1px solid rgba(255,255,255,0.15); }
  .header-title { font-family: 'Plus Jakarta Sans', sans-serif; font-size: 2rem; font-weight: 800; color: white; margin: 0 0 8px; }
  .header-sub { font-size: 14px; color: rgba(255,255,255,0.7); margin: 0; }

  .search-wrap { max-width: 600px; margin: -28px auto 2rem; padding: 0 1.5rem; position: relative; z-index: 10; }
  .search-box { display: flex; align-items: center; gap: 10px; background: white; border: 1px solid #e2e8f0; border-radius: 14px; padding: 12px 18px; box-shadow: 0 4px 24px rgba(0,0,0,0.12); }
  .search-box :global(.search-icon) { width: 18px; height: 18px; color: #94a3b8; flex-shrink: 0; }
  .search-input { flex: 1; border: none; outline: none; font-size: 14px; color: #0f172a; background: transparent; }

  .content { max-width: 1100px; margin: 0 auto; padding: 0 1.5rem 4rem; }
  .results-count { font-size: 13px; color: #64748b; margin-bottom: 1.25rem; }

  .grid { display: grid; grid-template-columns: 1fr; gap: 1.25rem; }
  @media (min-width: 640px) { .grid { grid-template-columns: repeat(2, 1fr); } }
  @media (min-width: 1024px) { .grid { grid-template-columns: repeat(3, 1fr); } }

  .card { background: white; border: 1px solid #e2e8f0; border-radius: 16px; overflow: hidden; box-shadow: 0 2px 8px rgba(0,0,0,0.04); display: flex; flex-direction: column; transition: all 0.2s; }
  .card:hover { box-shadow: 0 8px 28px rgba(0,0,0,0.1); transform: translateY(-3px); }
  .card-top { flex: 1; }

  .card-header { display: flex; align-items: center; gap: 12px; padding: 18px 18px 12px; border-bottom: 1px solid #f1f5f9; }
  .card-logo { width: 44px; height: 44px; border-radius: 10px; object-fit: contain; border: 1px solid #f1f5f9; }
  .card-logo-placeholder { width: 44px; height: 44px; border-radius: 10px; display: flex; align-items: center; justify-content: center; }
  .card-name { font-size: 15px; font-weight: 700; color: #0f172a; margin: 0; }
  .card-city { font-size: 11px; color: #64748b; margin: 2px 0 0; }

  .card-body { padding: 14px 18px; }
  .card-detail { display: flex; align-items: flex-start; gap: 8px; font-size: 12px; color: #475569; margin-bottom: 6px; }
  .card-detail :global(.detail-icon) { width: 13px; height: 13px; color: var(--brand); flex-shrink: 0; margin-top: 1px; }
  .card-tags { display: flex; flex-wrap: wrap; gap: 6px; margin-top: 12px; }
  .tag { font-size: 10px; font-weight: 600; padding: 3px 10px; border-radius: 99px; background: #f0f9ff; color: #0284c7; border: 1px solid #bae6fd; }

  .card-action { display: flex; align-items: center; justify-content: center; gap: 6px; padding: 12px; font-size: 12px; font-weight: 700; color: white; text-decoration: none; background: #0f172a; transition: opacity 0.2s; }
  .card-action:hover { opacity: 0.85; }

  .empty { text-align: center; padding: 5rem 2rem; }
  .empty :global(.empty-icon) { width: 48px; height: 48px; color: #cbd5e1; margin: 0 auto 16px; }
  .empty-title { font-family: 'Plus Jakarta Sans', sans-serif; font-size: 1.25rem; font-weight: 700; color: #0f172a; margin: 0 0 8px; }
  .empty-sub { font-size: 13px; color: #64748b; }
</style>
