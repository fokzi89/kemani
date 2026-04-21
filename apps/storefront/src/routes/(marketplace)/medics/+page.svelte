<script lang="ts">
	import { Stethoscope, Star, Clock, ShieldCheck, MapPin, Tag, ArrowRight } from 'lucide-svelte';
	import { page } from '$app/stores';

	export let data;

	$: rawProviders = data.providers || [];
	$: providers = rawProviders.filter((d: any) => d !== null);
	$: storefront = data.storefront;
    
	$: brandColor = storefront?.brand_color || '#4f46e5';

	let localSearch = '';
	$: urlSearch = $page.url.searchParams.get('q') || '';
	$: searchQuery = localSearch || urlSearch;

	$: filteredProviders = providers.filter((d: any) => {
		if (!searchQuery) return true;
		const q = searchQuery.toLowerCase();
		return (
			d.full_name?.toLowerCase().includes(q) ||
			d.specialization?.toLowerCase().includes(q)
		);
	});

	let isFilterModalOpen = false;
	function toggleFilters() { isFilterModalOpen = !isFilterModalOpen; }
</script>

<svelte:head>
	<title>Medics Professionals | {storefront?.name || 'Healthcare'} </title>
	<meta name="description" content="View our network of verified healthcare professionals." />
</svelte:head>

<div class="page-wrap">
	<!-- ════════════════════════════
		 HERO / SEARCH
	════════════════════════════ -->
	<section class="hero">
		<div class="hero-inner">
			<h1 class="hero-title">Find a Medical Professional</h1>
			<p class="hero-sub">Book verified specialists — in-person or virtual.</p>

			<div class="search-bar-wrap">
				<!-- Location -->
				<div class="search-field">
					<svg class="search-icon" viewBox="0 0 24 24" fill="currentColor" style="color:{brandColor}">
						<path d="M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7zm0 9.5c-1.38 0-2.5-1.12-2.5-2.5s1.12-2.5 2.5-2.5 2.5 1.12 2.5 2.5-1.12 2.5-2.5 2.5z"/>
					</svg>
					<input type="text" value="All Locations" placeholder="City, State" class="search-input" />
				</div>
				<div class="search-divider"></div>
				<!-- Keyword -->
				<div class="search-field search-field--grow">
					<svg class="search-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
						<circle cx="11" cy="11" r="8"/><path d="m21 21-4.35-4.35"/>
					</svg>
					<input type="text" placeholder="Doctor name or specialty..." class="search-input" bind:value={localSearch} />
				</div>
				<!-- Button -->
				<button class="search-btn" style="background:{brandColor}" onclick={() => localSearch = localSearch}>Search</button>
			</div>

			<!-- Specialty pills -->
			<div class="specialty-pills">
				{#each ['All', 'General Practice', 'Cardiology', 'Dermatology', 'Pediatrics', 'Neurology'] as spec, i}
					<button
						class="pill"
						class:pill--active={i === 0}
						style={i === 0 ? `background:${brandColor};border-color:${brandColor};color:#fff` : ''}
					>
						{spec}
					</button>
				{/each}
			</div>
		</div>
	</section>

	<!-- ════════════════════════════
		 BODY: SIDEBAR + RESULTS
	════════════════════════════ -->
	<div class="body-wrap">

		<!-- ── SIDEBAR ── -->
		<aside class="sidebar">
			<div class="filter-card">
				<div class="filter-header">
					<span class="filter-title">Filters</span>
					<button class="filter-reset" style="color:{brandColor}">Clear all</button>
				</div>

				<!-- Availability -->
				<div class="filter-group">
					<p class="filter-label">Availability</p>
					{#each ['Available Today', 'Next 3 Days', 'This Week'] as lbl}
						<label class="filter-row">
							<input type="checkbox" class="filter-check" style="accent-color:{brandColor}" />
							<span class="filter-text">{lbl}</span>
						</label>
					{/each}
				</div>

				<div class="filter-sep"></div>

				<!-- Gender -->
				<div class="filter-group">
					<p class="filter-label">Gender</p>
					{#each ['Any Gender', 'Male', 'Female'] as lbl, i}
						<label class="filter-row">
							<input type="radio" name="gender" class="filter-check" checked={i===0} style="accent-color:{brandColor}" />
							<span class="filter-text">{lbl}</span>
						</label>
					{/each}
				</div>

				<div class="filter-sep"></div>

				<!-- Price -->
				<div class="filter-group">
					<p class="filter-label">Consultation Fee</p>
					{#each ['Any Price', 'Under ₦10,000', '₦10k – ₦25k', '₦25k+'] as lbl, i}
						<label class="filter-row">
							<input type="radio" name="price" class="filter-check" checked={i===0} style="accent-color:{brandColor}" />
							<span class="filter-text">{lbl}</span>
						</label>
					{/each}
				</div>
			</div>

			<!-- CTA Banner -->
			<div class="sidebar-cta" style="background:{brandColor}">
				<div class="cta-glow"></div>
				<svg class="cta-icon" viewBox="0 0 24 24" fill="white">
					<path d="M4.5 6.375a4.125 4.125 0 1 1 8.25 0 4.125 4.125 0 0 1-8.25 0ZM14.25 8.625a3.375 3.375 0 1 1 6.75 0 3.375 3.375 0 0 1-6.75 0ZM1.5 19.125a7.125 7.125 0 0 1 14.25 0v.003l-.001.119a.75.75 0 0 1-.363.63 13.067 13.067 0 0 1-6.761 1.873c-2.472 0-4.786-.684-6.76-1.873a.75.75 0 0 1-.364-.63l-.001-.122ZM17.25 19.128l-.001.144a2.25 2.25 0 0 1-.233.96 10.088 10.088 0 0 0 5.06-1.01.75.75 0 0 0 .42-.643 4.875 4.875 0 0 0-6.957-4.611 8.586 8.586 0 0 1 1.71 5.157v.003Z"/>
				</svg>
				<h4 class="cta-title">Need guidance?</h4>
				<p class="cta-text">Our care coordinators can match you with the right specialist.</p>
				<button class="cta-btn">Talk to us →</button>
			</div>
		</aside>

		<!-- ── RESULTS ── -->
		<section class="results">

			<!-- Results topbar -->
			<div class="results-topbar">
				<div>
					<h2 class="results-count">{filteredProviders.length} professional{filteredProviders.length !== 1 ? 's' : ''} found</h2>
					<p class="results-sub">in {storefront?.name || 'our network'}</p>
				</div>
				<div class="topbar-actions">
					<button class="mobile-filter-btn" onclick={toggleFilters}>
						<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" width="18" height="18">
							<path d="M3 4h18M6 10h12M9 16h6" stroke-linecap="round"/>
						</svg>
						Filters
					</button>
					<div class="sort-wrap">
						<span class="sort-label">Sort by:</span>
						<select class="sort-select">
							<option>Best Match</option>
							<option>Highest Rated</option>
							<option>Most Experienced</option>
						</select>
					</div>
				</div>
			</div>

			<!-- Mobile Filter Modal -->
			{#if isFilterModalOpen}
				<!-- svelte-ignore a11y_click_events_have_key_events -->
				<!-- svelte-ignore a11y_no_static_element_interactions -->
				<div class="filter-modal-backdrop" onclick={toggleFilters}>
					<div class="filter-modal-content" onclick={(e) => e.stopPropagation()} onkeydown={(e) => e.stopPropagation()} role="dialog" aria-modal="true" aria-labelledby="filter-modal-title" tabindex="-1">
						<div class="modal-header">
							<h3 id="filter-modal-title">Refine Search</h3>
							<button class="close-btn" onclick={toggleFilters}>✕</button>
						</div>
						<div class="modal-body">
							<div class="modal-filters">
								 <!-- Availability -->
								 <div class="filter-group">
									 <p class="filter-label">Availability</p>
									 {#each ['Available Today', 'Next 3 Days', 'This Week'] as lbl}
										 <label class="filter-row">
											 <input type="checkbox" class="filter-check" style="accent-color:{brandColor}" />
											 <span class="filter-text">{lbl}</span>
										 </label>
									 {/each}
								 </div>
								 <div class="filter-sep"></div>
								 <!-- Gender -->
								 <div class="filter-group">
									 <p class="filter-label">Gender</p>
									 {#each ['Any Gender', 'Male', 'Female'] as lbl, i}
										 <label class="filter-row">
											 <input type="radio" name="m-gender" class="filter-check" checked={i===0} style="accent-color:{brandColor}" />
											 <span class="filter-text">{lbl}</span>
										 </label>
									 {/each}
								 </div>
								 <div class="filter-sep"></div>
								 <button class="apply-btn" style="background:{brandColor}" onclick={toggleFilters}>Apply Filters</button>
							</div>
						</div>
					</div>
				</div>
			{/if}

			<!-- Provider cards grid -->
			<div class="doctor-list">
				{#each filteredProviders as medic (medic?.id)}
					{#if medic}
						<article class="doctor-card">
							<!-- Card Header: Avatar + Verified -->
							<div class="card-header">
								<div class="card-avatar-wrap">
									{#if medic.profile_photo_url}
										<img src={medic.profile_photo_url} alt={medic.full_name} class="card-avatar" />
									{:else}
										<div class="card-avatar card-avatar--placeholder">
											{(medic.full_name || 'H').charAt(0).toUpperCase()}
										</div>
									{/if}
									<span class="online-dot" title="Active"></span>
								</div>
								{#if medic.is_verified}
									<span class="verified-badge">
										<svg viewBox="0 0 20 20" fill="currentColor" width="11" height="11">
											<path fill-rule="evenodd" d="M10 18a8 8 0 1 0 0-16 8 8 0 0 0 0 16zm3.857-9.809a.75.75 0 0 0-1.214-.882l-3.483 4.79-1.88-1.88a.75.75 0 1 0-1.06 1.061l2.5 2.5a.75.75 0 0 0 1.137-.089l4-5.5z" clip-rule="evenodd"/>
										</svg>
										Verified
									</span>
								{/if}
							</div>

							<!-- Card Body -->
							<div class="card-body">
								<h3 class="card-name">{medic.full_name}</h3>
								<p class="card-specialty" style="color:{brandColor}">{medic.specialization || 'Healthcare Provider'}</p>

								<div class="card-meta">
									{#if medic.average_rating}
									<span class="meta-item">
										<svg viewBox="0 0 20 20" fill="#FBBF24" width="13" height="13">
											<path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 0 0 .95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 0 0-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 0 0-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 0 0-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 0 0 .951-.69l1.07-3.292z"/>
										</svg>
										<strong>{medic.average_rating}</strong>
										<span class="meta-light">({medic.reviews_count || 0})</span>
									</span>
									{/if}
									<span class="meta-item">
										<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" width="13" height="13">
											<path stroke-linecap="round" stroke-linejoin="round" d="M15 10.5a3 3 0 1 1-6 0 3 3 0 0 1 6 0z"/>
											<path stroke-linecap="round" stroke-linejoin="round" d="M19.5 10.5c0 7.142-7.5 11.25-7.5 11.25S4.5 17.642 4.5 10.5a7.5 7.5 0 1 1 15 0z"/>
										</svg>
										{storefront?.name || 'Medical Center'}
									</span>
									{#if medic.years_of_experience}
									<span class="meta-item">
										<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" width="13" height="13">
											<path stroke-linecap="round" stroke-linejoin="round" d="M12 6v6h4.5m4.5 0a9 9 0 1 1-18 0 9 9 0 0 1 18 0z"/>
										</svg>
										{medic.years_of_experience}+ yrs
									</span>
									{/if}
								</div>
							</div>

							<!-- Card Footer -->
							<div class="card-footer">
								<div class="avail-badge">
									<span class="avail-dot"></span>
									Available
								</div>
								<div class="btn-row">
									<a href="/medics/{medic.id}" class="btn btn--primary" style="background:{brandColor}">Book Now</a>
								</div>
							</div>
						</article>
					{/if}
				{/each}

			<!-- Empty state -->
				{#if filteredProviders.length === 0}
					<div class="empty-state">
						<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1" class="empty-icon">
							<path stroke-linecap="round" stroke-linejoin="round" d="M17 20h5v-2a3 3 0 0 0-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 0 1 5.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 0 1 9.288 0M15 7a3 3 0 1 1-6 0 3 3 0 0 1 6 0Z"/>
						</svg>
						<h3 class="empty-title">No specialists found</h3>
						<p class="empty-text">Try adjusting your filters or search terms.</p>
					</div>
				{/if}
			</div>

			<!-- Pagination -->
			{#if filteredProviders.length > 0}
				<div class="pagination">
					<button class="page-btn page-btn--nav" aria-label="Previous Page">
						<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" width="16" height="16">
							<path stroke-linecap="round" stroke-linejoin="round" d="M15 19l-7-7 7-7"/>
						</svg>
					</button>
					<button class="page-btn page-btn--active" style="background:{brandColor};border-color:{brandColor};color:#fff">1</button>
					<button class="page-btn">2</button>
					<button class="page-btn">3</button>
					<button class="page-btn page-btn--nav" aria-label="Next Page">
						<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" width="16" height="16">
							<path stroke-linecap="round" stroke-linejoin="round" d="M9 5l7 7-7 7"/>
						</svg>
					</button>
				</div>
			{/if}

		</section>
	</div>
</div>

<style>
/* ══ Page Layout ══════════════════════════════════════════ */
.page-wrap {
  background: #f3f4f6;
  min-height: 100vh;
  font-family: 'Inter', sans-serif;
}

/* ══ Hero ═════════════════════════════════════════════════ */
.hero {
  background: #fff;
  border-bottom: 1px solid #e5e7eb;
  padding: 3rem 1.5rem;
}
.hero-inner {
  max-width: 860px;
  margin: 0 auto;
  text-align: center;
}
.hero-title {
  font-family: 'Inter', sans-serif;
  font-size: 2rem;
  font-weight: 800;
  color: #111827;
  margin-bottom: 0.5rem;
  letter-spacing: -0.025em;
}
.hero-sub {
  color: #6b7280;
  font-size: 0.9375rem;
  margin-bottom: 2rem;
}

/* Search bar */
.search-bar-wrap {
  display: flex;
  align-items: center;
  background: #fff;
  border: 1.5px solid #d1d5db;
  border-radius: 14px;
  box-shadow: 0 4px 24px rgba(0,0,0,0.07);
  overflow: hidden;
  margin-bottom: 1.25rem;
}
.search-field {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0 1.25rem;
  flex: 1;
  height: 56px;
}
.search-field--grow { flex: 1.6; }
.search-icon {
  width: 18px;
  height: 18px;
  flex-shrink: 0;
}
.search-input {
  border: none;
  outline: none;
  width: 100%;
  font-size: 0.875rem;
  color: #1f2937;
  background: transparent;
  font-family: inherit;
}
.search-input::placeholder { color: #9ca3af; }
.search-divider {
  width: 1px;
  height: 28px;
  background: #e5e7eb;
  flex-shrink: 0;
}
.search-btn {
  height: 100%;
  padding: 0 2rem;
  color: #fff;
  font-size: 0.875rem;
  font-weight: 600;
  font-family: inherit;
  cursor: pointer;
  border: none;
  transition: opacity 0.15s;
  white-space: nowrap;
}
.search-btn:hover { opacity: 0.9; }

/* Specialty pills */
.specialty-pills {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
  justify-content: center;
}
.pill {
  padding: 0.375rem 0.875rem;
  border-radius: 999px;
  font-size: 0.8125rem;
  font-weight: 500;
  border: 1.5px solid #e5e7eb;
  background: #f9fafb;
  color: #374151;
  cursor: pointer;
  transition: all 0.15s;
  font-family: inherit;
}
.pill:hover { background: #f3f4f6; border-color: #d1d5db; }
.pill--active { font-weight: 700; }

/* ══ Body ═════════════════════════════════════════════════ */
.body-wrap {
  display: flex;
  gap: 2rem;
  max-width: 1280px;
  margin: 0 auto;
  padding: 2rem 1.5rem;
  align-items: flex-start;
}

/* ══ Sidebar ══════════════════════════════════════════════ */
.sidebar {
  width: 260px;
  flex-shrink: 0;
  display: flex;
  flex-direction: column;
  gap: 1.25rem;
}
.filter-card {
  background: #fff;
  border: 1px solid #e5e7eb;
  border-radius: 14px;
  padding: 1.25rem;
  box-shadow: 0 1px 4px rgba(0,0,0,0.05);
}
.filter-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 1.25rem;
}
.filter-title {
  font-weight: 700;
  font-size: 0.9375rem;
  color: #111827;
}
.filter-reset {
  font-size: 0.75rem;
  font-weight: 600;
  background: none;
  border: none;
  cursor: pointer;
  text-decoration: underline;
  font-family: inherit;
}
.filter-group { margin-bottom: 0.25rem; }
.filter-label {
  font-size: 0.6875rem;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.08em;
  color: #9ca3af;
  margin-bottom: 0.75rem;
}
.filter-row {
  display: flex;
  align-items: center;
  gap: 0.625rem;
  margin-bottom: 0.625rem;
  cursor: pointer;
}
.filter-check { cursor: pointer; }
.filter-text {
  font-size: 0.875rem;
  color: #374151;
  font-family: inherit;
}
.filter-row:hover .filter-text { color: #111827; }
.filter-sep {
  height: 1px;
  background: #f3f4f6;
  margin: 1rem 0;
}

/* Sidebar CTA */
.sidebar-cta {
  border-radius: 14px;
  padding: 1.5rem;
  color: #fff;
  position: relative;
  overflow: hidden;
}
.cta-glow {
  position: absolute;
  top: -30px;
  right: -30px;
  width: 100px;
  height: 100px;
  border-radius: 50%;
  background: rgba(255,255,255,0.15);
}
.cta-icon { width: 32px; height: 32px; margin-bottom: 0.75rem; }
.cta-title {
  font-size: 1rem;
  font-weight: 700;
  margin-bottom: 0.375rem;
  font-family: 'Inter', sans-serif;
}
.cta-text {
  font-size: 0.8125rem;
  opacity: 0.85;
  line-height: 1.5;
  margin-bottom: 1rem;
}
.cta-btn {
  width: 100%;
  padding: 0.625rem;
  background: rgba(255,255,255,0.2);
  border: none;
  border-radius: 8px;
  color: #fff;
  font-size: 0.8125rem;
  font-weight: 600;
  cursor: pointer;
  transition: background 0.15s;
  font-family: inherit;
}
.cta-btn:hover { background: rgba(255,255,255,0.3); }

/* ══ Results ══════════════════════════════════════════════ */
.results { flex: 1; min-width: 0; }
.results-topbar {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  margin-bottom: 1.25rem;
  gap: 1rem;
}
.results-count {
  font-size: 1.125rem;
  font-weight: 700;
  color: #111827;
}
.results-sub {
  font-size: 0.8125rem;
  color: #6b7280;
  margin-top: 2px;
}
.sort-wrap {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}
.sort-label {
  font-size: 0.8125rem;
  color: #6b7280;
  white-space: nowrap;
}
.sort-select {
  font-size: 0.8125rem;
  font-family: inherit;
  border: 1px solid #d1d5db;
  border-radius: 8px;
  padding: 0.375rem 0.75rem;
  background: #fff;
  color: #374151;
  cursor: pointer;
  outline: none;
}

/* ══ Doctor Grid ══════════════════════════════════════════ */
.doctor-list {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 1.25rem;
}

.doctor-card {
  background: #fff;
  border: 1px solid #e5e7eb;
  border-radius: 14px;
  display: flex;
  flex-direction: column;
  box-shadow: 0 1px 4px rgba(0,0,0,0.04);
  transition: box-shadow 0.2s, border-color 0.2s;
  overflow: hidden;
}
.doctor-card:hover {
  box-shadow: 0 6px 20px rgba(0,0,0,0.10);
  border-color: #d1d5db;
  transform: translateY(-2px);
}

/* ── Card internals (grid style) ─── */
.card-header {
  padding: 1.25rem 1.25rem 0;
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
}
.card-body {
  padding: 0.875rem 1.25rem 0;
  flex: 1;
}
.card-footer {
  padding: 1rem 1.25rem;
  border-top: 1px solid #f3f4f6;
  margin-top: 1rem;
  display: flex;
  flex-direction: column;
  gap: 0.625rem;
}

/* Avatar */
.card-avatar-wrap { position: relative; flex-shrink: 0; }
.card-avatar {
  width: 64px;
  height: 64px;
  border-radius: 12px;
  object-fit: cover;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 1.375rem;
  font-weight: 700;
  color: #9ca3af;
  background: #f3f4f6;
  border: 1.5px solid #e5e7eb;
}
.card-avatar--placeholder { background: #f3f4f6; }
.online-dot {
  position: absolute;
  bottom: -3px;
  right: -3px;
  width: 12px;
  height: 12px;
  background: #22c55e;
  border: 2.5px solid #fff;
  border-radius: 50%;
}
.card-name {
  font-size: 0.9375rem;
  font-weight: 700;
  color: #111827;
  font-family: 'Inter', sans-serif;
  line-height: 1.3;
  margin-bottom: 2px;
}
.verified-badge {
  display: inline-flex;
  align-items: center;
  gap: 3px;
  background: #ecfdf5;
  color: #065f46;
  font-size: 0.625rem;
  font-weight: 700;
  padding: 2px 7px;
  border-radius: 999px;
  border: 1px solid #a7f3d0;
  text-transform: uppercase;
  letter-spacing: 0.04em;
}
.card-specialty {
  font-size: 0.8125rem;
  font-weight: 600;
  margin-bottom: 0.625rem;
}
.card-meta {
  display: flex;
  flex-direction: column;
  gap: 0.375rem;
}
.meta-item {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  font-size: 0.8125rem;
  color: #6b7280;
}
.meta-item strong { color: #1f2937; font-weight: 700; }
.meta-light { color: #9ca3af; }
.avail-badge {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  background: #f0fdf4;
  color: #166534;
  font-size: 0.75rem;
  font-weight: 600;
  padding: 4px 10px;
  border-radius: 8px;
  border: 1px solid #bbf7d0;
  white-space: nowrap;
}
.avail-dot {
  width: 7px;
  height: 7px;
  background: #22c55e;
  border-radius: 50%;
}
.btn-row {
  display: flex;
  gap: 0.5rem;
  width: 100%;
}
.btn {
  flex: 1;
  padding: 0.5rem 0.75rem;
  border-radius: 8px;
  font-size: 0.8125rem;
  font-weight: 600;
  font-family: inherit;
  cursor: pointer;
  transition: all 0.15s;
  white-space: nowrap;
  border: none;
  text-decoration: none;
  display: inline-flex;
  align-items: center;
  justify-content: center;
}
.btn--secondary {
  background: #f9fafb;
  color: #374151;
  border: 1.5px solid #e5e7eb;
}
.btn--secondary:hover { background: #f3f4f6; }
.btn--primary { color: #fff; }
.btn--primary:hover { opacity: 0.9; }

/* ══ Empty State ══════════════════════════════════════════ */
.empty-state {
  text-align: center;
  padding: 4rem 2rem;
  background: #fff;
  border: 1px solid #e5e7eb;
  border-radius: 14px;
}
.empty-icon { width: 56px; height: 56px; color: #d1d5db; margin: 0 auto 1rem; }
.empty-title { font-size: 1.125rem; font-weight: 700; color: #374151; margin-bottom: 0.25rem; }
.empty-text { font-size: 0.875rem; color: #9ca3af; }

/* ══ Pagination ═══════════════════════════════════════════ */
.pagination {
  display: flex;
  justify-content: center;
  align-items: center;
  gap: 0.375rem;
  margin-top: 2.5rem;
  padding-bottom: 2rem;
}
.page-btn {
  width: 36px;
  height: 36px;
  border-radius: 8px;
  border: 1.5px solid #e5e7eb;
  background: #fff;
  color: #374151;
  font-size: 0.875rem;
  font-weight: 600;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.15s;
  font-family: inherit;
}
.page-btn:hover { background: #f9fafb; border-color: #d1d5db; }
.page-btn--active { font-weight: 700; }
.page-btn--nav { color: #6b7280; }

/* ══ Responsive ═══════════════════════════════════════════ */
@media (max-width: 1024px) {
  .doctor-list { grid-template-columns: repeat(2, 1fr); }
}
@media (max-width: 900px) {
  .sidebar { display: none; }
  .body-wrap { padding: 1rem; }
}
@media (max-width: 640px) {
  .hero { padding: 2rem 1rem; }
  .hero-title { font-size: 1.625rem; }
  .search-bar-wrap { flex-direction: column; border-radius: 12px; height: auto; padding: 0.5rem; gap: 0.5rem; }
  .search-field { height: 48px; border: 1.5px solid #e5e7eb; border-radius: 8px; flex: none; width: 100%; padding: 0 0.875rem; }
  .search-field--grow { border-bottom: 1.5px solid #e5e7eb; }
  .search-divider { display: none; }
  .search-btn { height: 48px; width: 100%; border-radius: 8px; }
  .doctor-list { grid-template-columns: 1fr; }
  .results-topbar { flex-direction: column; align-items: stretch; gap: 1rem; }
  .topbar-actions { display: flex; justify-content: space-between; align-items: center; gap: 0.5rem; }
  .mobile-filter-btn { display: flex; align-items: center; gap: 0.5rem; background: #fff; border: 1.5px solid #d1d5db; padding: 0.5rem 1rem; border-radius: 8px; font-size: 0.8125rem; font-weight: 700; color: #374151; }
}

/* Modal specific responsive overrides */
.filter-modal-backdrop {
  position: fixed;
  inset: 0;
  background: rgba(0,0,0,0.5);
  z-index: 50;
  display: flex;
  align-items: flex-end;
}
.filter-modal-content {
  background: white;
  width: 100%;
  border-top-left-radius: 1rem;
  border-top-right-radius: 1rem;
  max-height: 90vh;
  display: flex;
  flex-direction: column;
}
.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1rem;
  border-bottom: 1px solid #e5e7eb;
}
.modal-header h3 { font-weight: 700; font-size: 1.125rem; }
.close-btn { background: none; border: none; font-size: 1.25rem; font-weight: bold; cursor: pointer; color: #6b7280; }
.modal-body { padding: 1rem; overflow-y: auto; }
.apply-btn {
  width: 100%;
  padding: 0.875rem;
  border-radius: 8px;
  color: white;
  font-weight: 700;
  border: none;
  margin-top: 1rem;
}
</style>
