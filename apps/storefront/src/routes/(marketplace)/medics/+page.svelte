<script lang="ts">
	import { Stethoscope, Star, Clock, ShieldCheck, MapPin, Tag, ArrowRight } from 'lucide-svelte';

	export let data;

	$: providers = data.providers || [];
	$: storefront = data.storefront;
</script>

<svelte:head>
	<title>Medics Professionals | {storefront?.name || 'Healthcare'} </title>
	<meta name="description" content="View our network of verified healthcare professionals." />
</svelte:head>

<div class="medics-page">
	<!-- Page Header -->
	<header class="page-header">
		<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
			<div class="header-pre">Refined Expertise</div>
			<h1 class="header-title">Medical Professionals</h1>
			<p class="header-sub">
				A curated network of certified healthcare experts, dedicated to your holistic well-being.
			</p>
		</div>
	</header>

	<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12 pb-24">
		{#if providers.length === 0}
			<div class="empty-state">
				<div class="empty-icon">
					<Stethoscope class="w-8 h-8" />
				</div>
				<h3 class="empty-title">Curating the Network</h3>
				<p class="empty-sub">We are currently verifying new professionals to join our collection. Please check back soon.</p>
			</div>
		{:else}
			<div class="medic-grid">
				{#each providers as medic}
					{@const fullName = medic.full_name || 'Healthcare Provider'}
					{@const imgUrl = medic.profile_photo_url}
					<div class="medic-card">
						<a href={`/medics/${medic.id}`} class="medic-img-wrap">
							{#if imgUrl}
								<img src={imgUrl} alt={fullName} class="medic-img" />
							{:else}
								<div class="medic-placeholder">
									<Stethoscope class="w-12 h-12" />
								</div>
							{/if}
							
							<div class="medic-badges">
								{#if medic.is_verified}
									<span class="badge badge-verified">
										<ShieldCheck class="w-3 h-3" /> Verified
									</span>
								{/if}
								{#if medic.type}
									<span class="badge badge-type">{medic.type}</span>
								{/if}
							</div>
						</a>

						<div class="medic-info">
							<div class="medic-meta">
								<h3 class="medic-name">
									<a href={`/medics/${medic.id}`}>{fullName}</a>
								</h3>
								{#if medic.average_rating}
									<div class="medic-rating">
										<Star class="star-icon" />
										<span>{medic.average_rating}</span>
									</div>
								{/if}
							</div>

							{#if medic.specialization}
								<p class="medic-specialty">{medic.specialization}</p>
							{/if}
							
							{#if medic.bio}
								<p class="medic-bio">{medic.bio}</p>
							{/if}

							<div class="medic-footer">
								<div class="medic-stats">
									{#if medic.years_of_experience}
										<div class="stat-item">
											<Clock class="stat-icon" />
											<span>{medic.years_of_experience} Years</span>
										</div>
									{/if}
									{#if medic.reviews_count > 0}
										<div class="stat-item">
											<Tag class="stat-icon" />
											<span>{medic.reviews_count} Reviews</span>
										</div>
									{/if}
								</div>
								<a href={`/medics/${medic.id}`} class="btn-more">
									View Profile <ArrowRight class="more-icon" />
								</a>
							</div>
						</div>
					</div>
				{/each}
			</div>
		{/if}
	</div>
</div>

<style>
	/* ─── TOKENS ─── */
	:root {
		--font-display: 'Playfair Display', Georgia, serif;
		--font-body: 'Inter', -apple-system, sans-serif;
		--surface: #faf9f6;
		--on-surface: #1a1c1a;
		--on-surface-muted: #6b7280;
		--border: #f0eeea;
		--accent: #785a1a;
		--radius: 8px;
	}

	.medics-page {
		background: var(--surface);
		color: var(--on-surface);
		font-family: var(--font-body);
		min-height: 100vh;
	}

	/* ─── HEADER ─── */
	.page-header { padding: 3.5rem 0 2.5rem; background: #fff; border-bottom: 1px solid var(--border); }
	.header-pre { font-size: 10px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.2em; color: var(--accent); margin-bottom: 0.75rem; }
	.header-title { font-family: var(--font-display); font-size: 2.75rem; font-weight: 500; margin-bottom: 1rem; line-height: 1.1; }
	.header-sub { font-size: 13px; color: var(--on-surface-muted); max-width: 440px; margin: 0 auto; line-height: 1.6; font-weight: 300; }

	/* ─── EMPTY STATE ─── */
	.empty-state { text-align: center; padding: 10rem 2rem; }
	.empty-icon { width: 64px; height: 64px; background: #fff; border-radius: 50%; border: 1px solid var(--border); display: flex; align-items: center; justify-content: center; margin: 0 auto 2rem; color: #d1d5db; }
	.empty-title { font-family: var(--font-display); font-size: 2rem; margin-bottom: 0.5rem; }
	.empty-sub { font-size: 13px; color: var(--on-surface-muted); max-width: 320px; margin-left: auto; margin-right: auto; line-height: 1.6; }

	/* ─── GRID ─── */
	.medic-grid {
		display: grid;
		grid-template-columns: 1fr;
		gap: 2.5rem 1.5rem;
	}
	@media (min-width: 640px) { .medic-grid { grid-template-columns: repeat(2, 1fr); } }
	@media (min-width: 768px) { .medic-grid { grid-template-columns: repeat(3, 1fr); } }
	@media (min-width: 1280px) { .medic-grid { grid-template-columns: repeat(4, 1fr); } }

	/* ─── CARD ─── */
	.medic-card { display: flex; flex-direction: column; background: transparent; }
	
	.medic-img-wrap { 
		aspect-ratio: 3/4; position: relative; border-radius: var(--radius); 
		overflow: hidden; background: #fff; border: 1px solid var(--border);
		display: block;
	}
	.medic-img { width: 100%; height: 100%; object-fit: cover; transition: transform 0.8s ease; }
	.medic-card:hover .medic-img { transform: scale(1.05); }
	.medic-placeholder { width: 100%; height: 100%; display: flex; align-items: center; justify-content: center; color: #f3f4f6; }

	.medic-badges { position: absolute; bottom: 1rem; left: 1rem; display: flex; gap: 8px; z-index: 2; }
	.badge { font-size: 9px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.1em; padding: 4px 12px; border-radius: 4px; border: 1px solid rgba(255,255,255,0.2); }
	.badge-verified { background: #fff; color: #059669; display: flex; align-items: center; gap: 4px; }
	.badge-type { background: var(--on-surface); color: #fff; }

	.medic-info { padding-top: 1.25rem; flex: 1; display: flex; flex-direction: column; }
	.medic-meta { display: flex; align-items: baseline; justify-content: space-between; gap: 0.75rem; margin-bottom: 0.25rem; }
	.medic-name { font-family: var(--font-display); font-size: 1.125rem; font-weight: 500; line-height: 1.3; }
	.medic-name a:hover { border-bottom: 1px solid var(--on-surface); }
	
	.medic-rating { display: flex; align-items: center; gap: 4px; font-size: 11px; font-weight: 700; color: #f59e0b; }
	.star-icon { width: 12px; height: 12px; fill: currentColor; }

	.medic-specialty { font-size: 10px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.15em; color: var(--accent); margin-bottom: 1rem; }
	.medic-bio { font-size: 13px; color: var(--on-surface-muted); line-height: 1.6; margin-bottom: 1.5rem; display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden; font-weight: 300; }

	.medic-footer { margin-top: auto; padding-top: 1.25rem; border-top: 1px solid var(--border); display: flex; align-items: center; justify-content: space-between; }
	.medic-stats { display: flex; gap: 1rem; }
	.stat-item { display: flex; align-items: center; gap: 6px; font-size: 10px; font-weight: 700; text-transform: uppercase; color: #d1d5db; }
	.stat-icon { width: 12px; height: 12px; }

	.btn-more { font-size: 10px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.1em; color: var(--on-surface); display: flex; align-items: center; gap: 6px; }
	.btn-more:hover { color: var(--accent); }
	.more-icon { width: 12px; height: 12px; transition: transform 0.2s; }
	.btn-more:hover .more-icon { transform: translateX(3px); }
</style>
