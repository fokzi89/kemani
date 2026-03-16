<script lang="ts">
	import { onMount } from 'svelte';
	import type { ServiceType } from '$lib/services/serviceRouter';
	import { supabase } from '$lib/supabase';

	/**
	 * ServiceDirectory Component
	 * Feature: 004-tenant-referral-commissions
	 *
	 * Displays external service providers when referring tenant doesn't offer service
	 * Shown when auto-routing doesn't apply
	 *
	 * Usage:
	 * <ServiceDirectory
	 *   serviceType="diagnostic"
	 *   referringTenantId={referringTenantId}
	 *   city="Lagos"
	 * />
	 */

	export let serviceType: ServiceType;
	export let referringTenantId: string | null = null;
	export let city: string | null = null; // Optional city filter

	interface Provider {
		id: string;
		name: string;
		business_type: string;
		city: string | null;
		address: string | null;
		services_offered: string[];
	}

	let providers: Provider[] = [];
	let loading = true;
	let error: string | null = null;

	const serviceLabels: Record<ServiceType, string> = {
		pharmacy: 'Pharmacies',
		diagnostic: 'Diagnostic Centers',
		consultation: 'Medical Consultations'
	};

	onMount(async () => {
		await loadProviders();
	});

	async function loadProviders() {
		loading = true;
		error = null;

		try {
			let query = supabase
				.from('tenants')
				.select('id, name, business_type, city, address, services_offered')
				.contains('services_offered', [serviceType]);

			// Exclude referring tenant (they don't offer this service)
			if (referringTenantId) {
				query = query.neq('id', referringTenantId);
			}

			// Filter by city if provided
			if (city) {
				query = query.eq('city', city);
			}

			const { data, error: fetchError } = await query;

			if (fetchError) {
				throw fetchError;
			}

			providers = (data || []) as Provider[];
		} catch (err) {
			error = err instanceof Error ? err.message : 'Failed to load providers';
			console.error('Error loading service directory:', err);
		} finally {
			loading = false;
		}
	}

	function selectProvider(provider: Provider) {
		// Dispatch event for parent to handle
		const event = new CustomEvent('providerSelected', {
			detail: {
				providerId: provider.id,
				providerName: provider.name,
				serviceType
			}
		});
		document.dispatchEvent(event);
	}
</script>

<div class="service-directory">
	<header>
		<h2>Available {serviceLabels[serviceType]}</h2>
		{#if city}
			<p class="city-filter">Showing providers in {city}</p>
		{/if}
		<p class="info-text">
			Select a provider to continue. You'll earn referral benefits on this transaction.
		</p>
	</header>

	{#if loading}
		<div class="loading-state">
			<div class="spinner"></div>
			<p>Loading providers...</p>
		</div>
	{:else if error}
		<div class="error-state">
			<p>Error: {error}</p>
			<button on:click={loadProviders}>Retry</button>
		</div>
	{:else if providers.length === 0}
		<div class="empty-state">
			<svg width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="currentColor">
				<circle cx="12" cy="12" r="10"></circle>
				<line x1="12" y1="8" x2="12" y2="12"></line>
				<line x1="12" y1="16" x2="12.01" y2="16"></line>
			</svg>
			<h3>No Providers Available</h3>
			<p>
				No {serviceLabels[serviceType].toLowerCase()} found
				{city ? `in ${city}` : 'in your area'}.
			</p>
		</div>
	{:else}
		<div class="provider-grid">
			{#each providers as provider}
				<button class="provider-card" on:click={() => selectProvider(provider)}>
					<div class="provider-header">
						<h3>{provider.name}</h3>
						<span class="badge">{provider.business_type}</span>
					</div>

					{#if provider.address || provider.city}
						<p class="provider-location">
							{provider.address || ''}{provider.address && provider.city ? ', ' : ''}{provider.city ||
								''}
						</p>
					{/if}

					<div class="provider-services">
						{#each provider.services_offered as service}
							<span class="service-tag">{service}</span>
						{/each}
					</div>

					<div class="select-action">
						<span>Select Provider</span>
						<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor">
							<line x1="5" y1="12" x2="19" y2="12"></line>
							<polyline points="12 5 19 12 12 19"></polyline>
						</svg>
					</div>
				</button>
			{/each}
		</div>
	{/if}
</div>

<style>
	.service-directory {
		padding: 1.5rem;
	}

	header {
		margin-bottom: 2rem;
	}

	header h2 {
		margin: 0 0 0.5rem 0;
		font-size: 1.75rem;
		font-weight: 700;
		color: #1a1a1a;
	}

	.city-filter {
		margin: 0.25rem 0;
		font-size: 0.875rem;
		color: #666;
	}

	.info-text {
		margin: 0.5rem 0 0 0;
		font-size: 0.875rem;
		color: #555;
		background: #f0f9ff;
		padding: 0.75rem 1rem;
		border-radius: 6px;
		border-left: 3px solid #3498db;
	}

	.loading-state,
	.error-state,
	.empty-state {
		display: flex;
		flex-direction: column;
		align-items: center;
		justify-content: center;
		padding: 3rem 1rem;
		text-align: center;
	}

	.spinner {
		width: 40px;
		height: 40px;
		border: 4px solid #f3f3f3;
		border-top: 4px solid #3498db;
		border-radius: 50%;
		animation: spin 1s linear infinite;
		margin-bottom: 1rem;
	}

	@keyframes spin {
		0% {
			transform: rotate(0deg);
		}
		100% {
			transform: rotate(360deg);
		}
	}

	.empty-state svg {
		color: #999;
		margin-bottom: 1rem;
	}

	.empty-state h3 {
		margin: 0 0 0.5rem 0;
		color: #666;
	}

	.provider-grid {
		display: grid;
		grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
		gap: 1.5rem;
	}

	.provider-card {
		display: flex;
		flex-direction: column;
		padding: 1.5rem;
		background: white;
		border: 2px solid #e5e5e5;
		border-radius: 12px;
		cursor: pointer;
		transition: all 0.2s;
		text-align: left;
	}

	.provider-card:hover {
		border-color: #3498db;
		box-shadow: 0 4px 12px rgba(52, 152, 219, 0.15);
		transform: translateY(-2px);
	}

	.provider-header {
		display: flex;
		justify-content: space-between;
		align-items: flex-start;
		margin-bottom: 0.75rem;
	}

	.provider-header h3 {
		margin: 0;
		font-size: 1.125rem;
		font-weight: 600;
		color: #1a1a1a;
	}

	.badge {
		padding: 0.25rem 0.75rem;
		background: #f0f0f0;
		color: #666;
		border-radius: 12px;
		font-size: 0.75rem;
		font-weight: 500;
		text-transform: capitalize;
	}

	.provider-location {
		margin: 0 0 1rem 0;
		font-size: 0.875rem;
		color: #666;
	}

	.provider-services {
		display: flex;
		flex-wrap: wrap;
		gap: 0.5rem;
		margin-bottom: 1rem;
	}

	.service-tag {
		padding: 0.25rem 0.625rem;
		background: #e8f4f8;
		color: #3498db;
		border-radius: 6px;
		font-size: 0.75rem;
		font-weight: 500;
		text-transform: capitalize;
	}

	.select-action {
		display: flex;
		align-items: center;
		justify-content: space-between;
		padding-top: 1rem;
		border-top: 1px solid #e5e5e5;
		color: #3498db;
		font-weight: 500;
		font-size: 0.875rem;
	}

	.select-action svg {
		transition: transform 0.2s;
	}

	.provider-card:hover .select-action svg {
		transform: translateX(4px);
	}
</style>
