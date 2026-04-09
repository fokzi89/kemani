<script lang="ts">
  import { MapPin, Phone, Mail, Search, Building2, ExternalLink, ChevronLeft, ShoppingBag, FlaskConical, Heart, Baby, Package, Filter, X } from 'lucide-svelte';
  import { onMount } from 'svelte';
  import { supabase } from '$lib/supabase';
  import { fade, slide } from 'svelte/transition';

  export let data;
  $: pharmacies = data.pharmacies || [];
  $: city = data.city;
  $: provider = data.provider;
  $: brandColor = provider?.brand_color || '#003f87';

  let searchQuery = '';
  let selectedPharmacy: any = null;
  
  // City Filter Logic
  $: cities = ['All', ...new Set(pharmacies.map((p: any) => p.city).filter(Boolean))];
  let selectedCity = 'All';

  onMount(() => {
    if (city && cities.includes(city)) {
      selectedCity = city;
    }
    
    // If arriving with a search query, initialize
    if (urlSearch) {
      searchQuery = urlSearch;
      handleSearchInput();
    }

    // Also click out listener for suggestions
    const handleOutsideClick = (e: MouseEvent) => {
      if (!(e.target as Element).closest('.search-container')) {
        showSuggestions = false;
      }
    };
    document.addEventListener('click', handleOutsideClick);
    return () => document.removeEventListener('click', handleOutsideClick);
  });

  // Suggestion logic
  let showSuggestions = false;
  let drugSuggestions: any[] = [];
  let pharmacySuggestions: any[] = [];
  let isSearchingDrugs = false;
  let searchTimeout: any;
  let pharmacyIdsMatchingDrug: string[] = [];

  function handleSearchInput() {
    showSuggestions = searchQuery.length > 1;
    pharmacyIdsMatchingDrug = [];

    // Local pharmacy match
    pharmacySuggestions = pharmacies.filter((p: any) => 
      p.name?.toLowerCase().includes(searchQuery.toLowerCase()) ||
      p.address?.toLowerCase().includes(searchQuery.toLowerCase())
    ).slice(0, 3);

    // Remote drug match
    clearTimeout(searchTimeout);
    if (searchQuery.length > 2) {
      isSearchingDrugs = true;
      searchTimeout = setTimeout(async () => {
        const validBranchIds = pharmacies.map((p: any) => p.branch_id).filter(Boolean);

        const { data, error } = await supabase
          .from('branch_inventory')
          .select(`
            branch_id,
            products!inner(name, generic_name, manufacturer)
          `)
          .in('branch_id', validBranchIds.length ? validBranchIds : ['00000000-0000-0000-0000-000000000000'])
          .or(`name.ilike.%${searchQuery}%,generic_name.ilike.%${searchQuery}%,manufacturer.ilike.%${searchQuery}%`, { foreignTable: 'products' })
          .eq('products.is_active', true)
          .gt('stock_quantity', 0)
          .limit(100);
        
        if (!error && data) {
           // Update matching branch IDs for filtering
           pharmacyIdsMatchingDrug = [...new Set(data.map(d => d.branch_id))];

           const grouped = new Map();
           data.forEach(d => {
             const prod = Array.isArray(d.products) ? d.products[0] : d.products;
             if (!prod) return;
             const key = (prod.generic_name || prod.name).toLowerCase();
             if (!grouped.has(key)) {
               grouped.set(key, { name: prod.generic_name || prod.name, branches: new Set([d.branch_id]) });
             } else {
               grouped.get(key).branches.add(d.branch_id);
             }
           });
           drugSuggestions = Array.from(grouped.values()).slice(0, 4);
        }
        isSearchingDrugs = false;
      }, 400);
    } else {
      drugSuggestions = [];
      pharmacyIdsMatchingDrug = [];
      isSearchingDrugs = false;
    }
  }

  function selectSuggestion(type: 'pharmacy' | 'drug', payload: any) {
    if (type === 'pharmacy') {
      searchQuery = ''; // Clear search when navigating
      viewShop(payload);
    } else if (type === 'drug') {
      searchQuery = payload.name;
      pharmacyIdsMatchingDrug = Array.from(payload.branches);
    }
    showSuggestions = false;
  }
  let products: any[] = [];
  let productCategories: string[] = [];
  let selectedProductCategory = 'All';
  let isLoadingProducts = false;
  let productSearchQuery = '';
  let currentPage = 1;
  const itemsPerPage = 12;

  $: filteredPharmacies = pharmacies.filter((p: any) => {
    const matchesCity = selectedCity === 'All' || p.city === selectedCity;
    const qMatches = !searchQuery || 
      p.name?.toLowerCase().includes(searchQuery.toLowerCase()) ||
      p.address?.toLowerCase().includes(searchQuery.toLowerCase()) ||
      p.city?.toLowerCase().includes(searchQuery.toLowerCase());
    
    return matchesCity && (qMatches || pharmacyIdsMatchingDrug.includes(p.branch_id));
  });

  $: {
    // Reset to page 1 when search query or city changes
    if (searchQuery || selectedCity) currentPage = 1;
  }

  $: totalPages = Math.ceil(filteredPharmacies.length / itemsPerPage);
  $: paginatedPharmacies = filteredPharmacies.slice((currentPage - 1) * itemsPerPage, currentPage * itemsPerPage);

  $: filteredProducts = products.filter(p => {
    const matchesSearch = !productSearchQuery || p.name?.toLowerCase().includes(productSearchQuery.toLowerCase());
    const matchesCategory = selectedProductCategory === 'All' || p.category === selectedProductCategory;
    return matchesSearch && matchesCategory;
  });

  async function viewShop(pharmacy: any) {
    selectedPharmacy = pharmacy;
    isLoadingProducts = true;
    products = [];
    selectedProductCategory = 'All';
    
    const { data: inventoryData, error } = await supabase
      .from('branch_inventory')
      .select(`
        id, 
        stock_quantity,
        reserved_quantity,
        products!inner(
          id, 
          name, 
          description, 
          category, 
          unit_price, 
          image_url,
          generic_name,
          strength,
          dosage_form,
          manufacturer,
          unit_of_measure,
          product_type
        )
      `)
      .eq('branch_id', pharmacy.branch_id)
      .eq('products.is_active', true)
      .eq('is_active', true)
      .gt('stock_quantity', 0)
      .limit(100);
    
    if (error) {
      console.error('Error fetching inventory:', error);
    } else {
      products = (inventoryData || []).map(item => ({
        ...item.products,
        inventory_id: item.id,
        stock_quantity: item.stock_quantity - (item.reserved_quantity || 0),
        raw_stock: item.stock_quantity
      }));
      // Extract unique categories
      productCategories = ['All', ...new Set(products.map(p => p.category).filter(Boolean))];
    }
    isLoadingProducts = false;
  }

  function closePortal() {
    selectedPharmacy = null;
    products = [];
  }
</script>

<svelte:head>
  <title>Pharmacy Shop — {provider?.name}</title>
</svelte:head>

<div class="page" style="--brand:{selectedPharmacy?.brand_color || brandColor};">
  {#if !selectedPharmacy}
    <!-- Pharmacy List View -->
    <div in:fade={{ duration: 200 }}>
      <header class="page-header" style="background: linear-gradient(135deg, var(--brand) 0%, rgba(0,0,0,0.8) 100%);">
        <div class="layout-container header-inner">
          <div class="header-badge">HEALTHCARE NETWORK</div>
          <h1>Visit Our Partner Pharmacies</h1>
          <p>Access high-quality medication and pharmaceutical services across our community network.</p>
        </div>
      </header>

      <div class="layout-container">
        <div class="toolbar">
          <div class="search-container">
            <div class="search-bar" class:has-suggestions={showSuggestions}>
              <Search class="w-4 h-4 text-outline" />
              <input 
                type="text" 
                bind:value={searchQuery} 
                on:input={handleSearchInput}
                on:focus={() => { if(searchQuery.length > 1) showSuggestions = true; }}
                placeholder="Search pharmacies or drugs (e.g. Paracetamol)..." 
              />
            </div>
            
            {#if showSuggestions}
              <div class="suggestions-dropdown">
                {#if pharmacySuggestions.length > 0}
                  <div class="sugg-group">
                    <h4>Pharmacies</h4>
                    {#each pharmacySuggestions as sugg}
                      <button class="sugg-item" on:click={() => selectSuggestion('pharmacy', sugg)}>
                        <Building2 class="w-4 h-4 mr-2" style="color: var(--brand);" />
                        <div class="span-text">
                          <span class="main-text">{sugg.name}</span>
                          <span class="sub-text">{sugg.address}</span>
                        </div>
                      </button>
                    {/each}
                  </div>
                {/if}

                {#if searchQuery.length > 2}
                  <div class="sugg-group">
                    <h4>Drugs & Medication</h4>
                    {#if isSearchingDrugs}
                      <div class="sugg-loading">Searching drugs...</div>
                    {:else if drugSuggestions.length > 0}
                      {#each drugSuggestions as sugg}
                        <button class="sugg-item" on:click={() => selectSuggestion('drug', sugg)}>
                          <FlaskConical class="w-4 h-4 mr-2" style="color: var(--brand);" />
                          <div class="span-text">
                            <span class="main-text">{sugg.name}</span>
                            <span class="sub-text">Available at {sugg.branches.size} partner pharmacies</span>
                          </div>
                        </button>
                      {/each}
                    {:else}
                       <div class="sugg-loading">No drug matches found.</div>
                    {/if}
                  </div>
                {/if}
              </div>
            {/if}
          </div>

          <div class="city-filter-container">
            <MapPin class="w-4 h-4 text-outline" />
            <select class="city-select" bind:value={selectedCity}>
              {#each cities as c}
                <option value={c}>{c}</option>
              {/each}
            </select>
          </div>
        </div>

        <div class="results-grid">
          {#each paginatedPharmacies as pharmacy}
            <div class="pharmacy-card">
              <div class="card-top">
                <div class="pharmacy-logo">
                  {#if pharmacy.logo_url}
                    <img src={pharmacy.logo_url} alt={pharmacy.name} />
                  {:else}
                    <div class="logo-ph">{pharmacy.name.charAt(0)}</div>
                  {/if}
                </div>
                <div class="pharmacy-main">
                  <h3>{pharmacy?.name}</h3>
                  <p class="pharmacy-type">{pharmacy?.display_type || 'Community Pharmacy'}</p>
                </div>
              </div>

              <div class="card-details">
                <div class="detail-row">
                  <MapPin class="w-4 h-4" />
                  <span>{pharmacy.address || 'Location information unavailable'}</span>
                </div>
                <div class="detail-row">
                  <Phone class="w-4 h-4" />
                  <span>{pharmacy.phone || '+1 --- --- ----'}</span>
                </div>
              </div>

              <div class="card-footer">
                <button 
                  class="visit-btn" 
                  style="background: {pharmacy.brand_color || brandColor};"
                  on:click={() => viewShop(pharmacy)}
                >
                  Visit Shop
                  <ExternalLink class="w-4 h-4 ml-2" />
                </button>
              </div>
            </div>
          {/each}
        </div>

        {#if totalPages > 1}
          <div class="pagination">
            <button 
              class="pag-btn" 
              disabled={currentPage === 1} 
              on:click={() => { currentPage--; window.scrollTo({ top: 0, behavior: 'smooth' }); }}
            >
              Previous
            </button>
            <div class="pag-info">
              Page <strong>{currentPage}</strong> of {totalPages}
            </div>
            <button 
              class="pag-btn" 
              disabled={currentPage === totalPages} 
              on:click={() => { currentPage++; window.scrollTo({ top: 0, behavior: 'smooth' }); }}
            >
              Next
            </button>
          </div>
        {/if}
      </div>
    </div>
  {:else}
    <!-- Pharmacy Storefront Portal View (Embedded) -->
    <div in:fade={{ duration: 200 }} class="portal-view">
      <header class="portal-header">
        <div class="layout-container">
          <button class="back-link" on:click={closePortal}>
            <ChevronLeft class="w-4 h-4 mr-1" /> Back to Pharmacy List
          </button>
          
          <div class="portal-brand">
            <div class="p-logo">
              {#if selectedPharmacy.logo_url}
                <img src={selectedPharmacy.logo_url} alt={selectedPharmacy.name} />
              {:else}
                <div class="p-logo-ph" style="background: {selectedPharmacy.brand_color || brandColor};">{selectedPharmacy.name.charAt(0)}</div>
              {/if}
            </div>
            <div class="p-info">
              <h2>{selectedPharmacy.name} Shop</h2>
              <p>{selectedPharmacy.address}</p>
            </div>
          </div>
        </div>
      </header>

      <div class="layout-container">
        <!-- Product Toolbar -->
        <div class="product-toolbar">
          <div class="p-search">
            <Search class="w-4 h-4" />
            <input type="text" bind:value={productSearchQuery} placeholder="Search products in this store..." />
          </div>

          <div class="p-categories">
            {#each productCategories as cat}
              <button 
                class="p-cat-btn" 
                class:active={selectedProductCategory === cat}
                on:click={() => selectedProductCategory = cat}
              >
                {cat}
              </button>
            {/each}
          </div>
        </div>

        {#if isLoadingProducts}
          <div class="loader">
            <div class="spinner"></div>
            <p>Loading catalog...</p>
          </div>
        {:else if filteredProducts.length === 0}
          <div class="empty-state">
            <Package class="w-12 h-12 text-outline mb-4" />
            <h3>No products found</h3>
            <p>Try matching your search or check other categories.</p>
          </div>
        {:else}
          <div class="product-grid">
            {#each filteredProducts as product}
              <div class="product-card">
                <div class="product-img">
                  {#if product.image_url}
                    <img src={product.image_url} alt={product.name} />
                  {:else}
                    <div class="prod-icon"><Package class="w-8 h-8" /></div>
                  {/if}
                  {#if product.stock_quantity <= 0}
                    <div class="out-of-stock">Out of Stock</div>
                  {/if}
                </div>
                <div class="product-info">
                  <p class="p-cat">{product.category}</p>
                  <h4>{product.name}</h4>
                  {#if product.generic_name || product.strength}
                    <p class="p-medical">
                      {product.generic_name || ''} 
                      {product.strength ? `• ${product.strength}` : ''}
                    </p>
                  {/if}
                  <p class="p-desc">{product.description || 'Verified pharmacy grade product.'}</p>
                  <div class="product-bottom">
                    <span class="price">₦{product.unit_price?.toLocaleString() || '0.00'}</span>
                    <button class="add-to-cart" style="background: {selectedPharmacy.brand_color || brandColor};">
                      <ShoppingBag class="w-4 h-4" />
                    </button>
                  </div>
                </div>
              </div>
            {/each}
          </div>
        {/if}
      </div>
    </div>
  {/if}
</div>

<style>
  .page { min-height: 100vh; background: var(--surface); padding-bottom: 5rem; }

  /* Pharmacy List Styles */
  .page-header { padding: 4rem 0 6rem; color: white; text-align: center; }
  .header-badge { font-size: 0.75rem; font-weight: 800; letter-spacing: 0.1em; opacity: 0.8; margin-bottom: 1rem; }
  .page-header h1 { font-family: var(--font-headline); font-size: 2.5rem; font-weight: 800; margin-bottom: 1rem; }
  .page-header p { font-size: 1.125rem; opacity: 0.9; max-width: 600px; margin: 0 auto; line-height: 1.6; }

  .toolbar { max-width: 700px; margin: -2.5rem auto 3rem; padding: 0 1.5rem; position: relative; z-index: 10; display: flex; gap: 1rem; flex-direction: column; }
  @media (min-width: 640px) { .toolbar { flex-direction: row; } }
  
  .search-container { position: relative; flex: 1; }
  .search-bar { display: flex; align-items: center; gap: 0.75rem; background: white; padding: 0 1.25rem; border-radius: 1rem; box-shadow: 0 10px 25px -5px rgba(0,0,0,0.1); width: 100%; height: 56px; border: 1px solid var(--outline-variant); transition: all 0.2s; }
  .search-bar.has-suggestions { border-bottom-left-radius: 0; border-bottom-right-radius: 0; border-bottom-color: transparent; }
  .search-bar input { border: none; outline: none; flex: 1; font-size: 0.875rem; background: transparent; }

  .suggestions-dropdown { position: absolute; top: 100%; left: 0; right: 0; background: white; border: 1px solid var(--outline-variant); border-top: none; border-bottom-left-radius: 1rem; border-bottom-right-radius: 1rem; box-shadow: 0 10px 25px -5px rgba(0,0,0,0.1); overflow: hidden; z-index: 20; max-height: 400px; overflow-y: auto; }
  .sugg-group { border-top: 1px solid var(--outline-variant); }
  .sugg-group:first-child { border-top: none; }
  .sugg-group h4 { font-size: 0.7rem; font-weight: 800; color: var(--on-surface-variant); text-transform: uppercase; letter-spacing: 0.05em; padding: 0.85rem 1.25rem 0.5rem; background: var(--surface-container-low); }
  .sugg-item { display: flex; align-items: center; padding: 0.85rem 1.25rem; width: 100%; text-align: left; background: white; border: none; cursor: pointer; transition: background 0.2s; }
  .sugg-item:hover { background: var(--surface-container-lowest); }
  .span-text { display: flex; flex-direction: column; gap: 0.15rem; }
  .main-text { font-size: 0.875rem; font-weight: 700; color: var(--on-surface); }
  .sub-text { font-size: 0.7rem; font-weight: 500; color: var(--on-surface-variant); }
  .sugg-loading { padding: 1rem 1.25rem; font-size: 0.8125rem; color: var(--on-surface-variant); font-style: italic; }

  .city-filter-container { display: flex; align-items: center; gap: 0.5rem; background: white; padding: 0 1rem; border-radius: 1rem; box-shadow: 0 10px 25px -5px rgba(0,0,0,0.1); height: 56px; border: 1px solid var(--outline-variant); min-width: 140px; flex-shrink: 0; }
  .city-select { border: none; outline: none; background: transparent; font-size: 0.875rem; font-weight: 700; color: var(--on-surface); width: 100%; cursor: pointer; }

  .results-grid { display: grid; grid-template-columns: 1fr; gap: 1.5rem; }
  @media (min-width: 640px) { .results-grid { grid-template-columns: repeat(2, 1fr); } }
  @media (min-width: 1024px) { .results-grid { grid-template-columns: repeat(3, 1fr); } }

  .pharmacy-card { background: white; border-radius: 1.25rem; border: 1px solid var(--outline-variant); padding: 1.5rem; display: flex; flex-direction: column; transition: transform 0.2s, box-shadow 0.2s; }
  .pharmacy-card:hover { transform: translateY(-4px); box-shadow: 0 20px 25px -5px rgba(0,0,0,0.05); }

  .card-top { display: flex; align-items: center; gap: 1rem; margin-bottom: 1.5rem; }
  .pharmacy-logo { width: 56px; height: 56px; border-radius: 0.75rem; overflow: hidden; background: var(--surface-container-high); flex-shrink: 0; }
  .pharmacy-logo img { width: 100%; height: 100%; object-fit: cover; }
  .logo-ph { width: 100%; height: 100%; display: flex; align-items: center; justify-content: center; font-size: 1.5rem; font-weight: 800; background: var(--secondary-container); color: var(--on-secondary-container); }
  .pharmacy-main h3 { font-size: 1.125rem; font-weight: 700; color: var(--on-surface); line-height: 1.2; }
  .pharmacy-type { font-size: 0.75rem; font-weight: 600; color: var(--brand); text-transform: uppercase; margin-top: 0.25rem; }

  .card-details { display: flex; flex-direction: column; gap: 0.75rem; flex: 1; margin-bottom: 1.5rem; }
  .detail-row { display: flex; gap: 0.75rem; font-size: 0.8125rem; color: var(--on-surface-variant); line-height: 1.4; }
  .detail-row :global(svg) { color: var(--brand); flex-shrink: 0; }

  .visit-btn { width: 100%; display: flex; align-items: center; justify-content: center; padding: 0.875rem; border-radius: 0.75rem; color: white; font-weight: 700; font-size: 0.875rem; transition: opacity 0.2s; }
  .visit-btn:hover { opacity: 0.9; }

  /* Portal View Styles */
  .portal-view { background: var(--surface); min-height: 100vh; }
  .portal-header { background: white; border-bottom: 1px solid var(--outline-variant); padding: 1.5rem 0; margin-bottom: 2rem; position: sticky; top: 64px; z-index: 50; }
  .back-link { display: flex; align-items: center; font-size: 0.8125rem; font-weight: 700; color: var(--brand); margin-bottom: 1rem; }
  .portal-brand { display: flex; align-items: center; gap: 1.25rem; }
  .p-logo { width: 48px; height: 48px; border-radius: 0.5rem; overflow: hidden; flex-shrink: 0; }
  .p-logo img { width: 100%; height: 100%; object-fit: cover; }
  .p-logo-ph { width: 100%; height: 100%; display: flex; align-items: center; justify-content: center; color: white; font-weight: 800; font-size: 1.25rem; }
  .p-info h2 { font-family: var(--font-headline); font-size: 1.25rem; font-weight: 800; }
  .p-info p { font-size: 0.8125rem; color: var(--on-surface-variant); }

  .product-toolbar { display: flex; flex-direction: column; gap: 1rem; margin-bottom: 2rem; }
  @media (min-width: 768px) { .product-toolbar { flex-direction: row; align-items: center; justify-content: space-between; } }
  .p-search { display: flex; align-items: center; gap: 0.75rem; background: white; padding: 0 1rem; border-radius: 0.75rem; border: 1px solid var(--outline-variant); flex: 1; max-width: 400px; height: 48px; }
  .p-search input { border: none; outline: none; background: transparent; font-size: 0.875rem; width: 100%; }
  
  .p-categories { display: flex; gap: 0.5rem; overflow-x: auto; scrollbar-width: none; }
  .p-cat-btn { white-space: nowrap; padding: 0.5rem 1rem; border-radius: 0.5rem; font-size: 0.8125rem; font-weight: 600; border: 1px solid var(--outline-variant); background: white; }
  .p-cat-btn.active { background: var(--brand); color: white; border-color: var(--brand); }

  .product-grid { display: grid; grid-template-columns: repeat(2, 1fr); gap: 1rem; }
  @media (max-width: 480px) { .product-grid { grid-template-columns: 1fr; } }
  @media (min-width: 768px) { .product-grid { grid-template-columns: repeat(3, 1fr); } }
  @media (min-width: 1024px) { .product-grid { grid-template-columns: repeat(4, 1fr); } }

  .product-card { background: white; border-radius: 1rem; border: 1px solid var(--outline-variant); overflow: hidden; display: flex; flex-direction: column; transition: transform 0.2s; }
  .product-card:hover { transform: translateY(-4px); }
  .product-img { position: relative; height: 160px; background: var(--surface-container-low); display: flex; align-items: center; justify-content: center; }
  .product-img img { width: 100%; height: 100%; object-fit: cover; }
  .prod-icon { color: var(--on-surface-variant); opacity: 0.3; }
  .out-of-stock { position: absolute; top: 0.75rem; right: 0.75rem; background: rgba(0,0,0,0.6); color: white; font-size: 0.625rem; font-weight: 700; padding: 0.25rem 0.5rem; border-radius: 0.25rem; }

  .product-info { padding: 1rem; display: flex; flex-direction: column; flex: 1; }
  .p-cat { font-size: 0.6875rem; font-weight: 700; color: var(--brand); text-transform: uppercase; margin-bottom: 0.25rem; }
  .p-medical { font-size: 0.75rem; font-weight: 600; color: var(--on-surface-variant); margin-bottom: 0.5rem; display: block; }
  .product-info h4 { font-size: 0.9375rem; font-weight: 700; color: var(--on-surface); margin-bottom: 0.25rem; line-height: 1.2; }
  .p-desc { font-size: 0.75rem; color: var(--on-surface-variant); line-height: 1.4; display: -webkit-box; -webkit-line-clamp: 2; line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden; margin-bottom: 1rem; }
  .product-bottom { display: flex; align-items: center; justify-content: space-between; margin-top: auto; }
  .price { font-size: 1rem; font-weight: 800; color: var(--on-surface); }
  .add-to-cart { width: 36px; height: 36px; border-radius: 0.5rem; display: flex; align-items: center; justify-content: center; color: white; }

  .pagination { display: flex; align-items: center; justify-content: center; gap: 1.5rem; margin-top: 3rem; padding-top: 2rem; border-top: 1px solid var(--outline-variant); }
  .pag-btn { padding: 0.625rem 1.25rem; border-radius: 0.75rem; border: 1.5px solid var(--outline-variant); background: white; font-weight: 700; font-size: 0.875rem; color: var(--on-surface); cursor: pointer; transition: all 0.2s; }
  .pag-btn:hover:not(:disabled) { border-color: var(--brand); color: var(--brand); transform: translateY(-1px); }
  .pag-btn:disabled { opacity: 0.4; cursor: not-allowed; }
  .pag-info { font-size: 0.875rem; color: var(--on-surface-variant); }
  .pag-info strong { color: var(--on-surface); }
</style>
