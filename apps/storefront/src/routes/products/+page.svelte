<script lang="ts">
	import { page } from '$app/stores';
	import ServiceSelector from '$lib/components/referral/ServiceSelector.svelte';
	import ServiceDirectory from '$lib/components/referral/ServiceDirectory.svelte';
	import { onMount } from 'svelte';

	/**
	 * Products Page (Pharmacy)
	 * Feature: 004-tenant-referral-commissions
	 *
	 * Auto-routing behavior:
	 * - If referring tenant offers 'pharmacy' → auto-route to their products
	 * - If referring tenant doesn't offer 'pharmacy' → show external pharmacy directory
	 */

	let referringTenantId: string | null = null;
	let showDirectory = false;
	let products: any[] = [];
	let loading = true;

	// Get referring tenant from server-side data
	$: referringTenantId = $page.data.referringTenantId || null;

	onMount(() => {
		// Listen for routing events
		document.addEventListener('autoRoute', handleAutoRoute as EventListener);
		document.addEventListener('showDirectory', handleShowDirectory as EventListener);
		document.addEventListener('providerSelected', handleProviderSelected as EventListener);

		return () => {
			document.removeEventListener('autoRoute', handleAutoRoute as EventListener);
			document.removeEventListener('showDirectory', handleShowDirectory as EventListener);
			document.removeEventListener('providerSelected', handleProviderSelected as EventListener);
		};
	});

	function handleAutoRoute(event: CustomEvent) {
		console.log('Auto-routed to provider:', event.detail);
		showDirectory = false;
		loadProducts(event.detail.providerId);
	}

	function handleShowDirectory(event: CustomEvent) {
		console.log('Showing directory for:', event.detail.serviceType);
		showDirectory = true;
		loading = false;
	}

	function handleProviderSelected(event: CustomEvent) {
		console.log('Provider selected:', event.detail);
		showDirectory = false;
		loadProducts(event.detail.providerId);
	}

	async function loadProducts(providerId: string) {
		loading = true;
		try {
			// TODO: Implement product loading from Supabase
			// const { data } = await supabase
			//   .from('products')
			//   .select('*')
			//   .eq('tenant_id', providerId);
			// products = data || [];

			console.log('Loading products for tenant:', providerId);
			products = []; // Placeholder
		} catch (error) {
			console.error('Error loading products:', error);
		} finally {
			loading = false;
		}
	}
</script>

<svelte:head>
	<title>Pharmacy Products</title>
</svelte:head>

<div class="products-page">
	<ServiceSelector
		serviceType="pharmacy"
		referringTenantId={referringTenantId}
		autoNavigate={false}
		showNotification={true}
	>
		<svelte:fragment slot="directory">
			{#if showDirectory}
				<ServiceDirectory
					serviceType="pharmacy"
					referringTenantId={referringTenantId}
					city={null}
				/>
			{/if}
		</svelte:fragment>
	</ServiceSelector>

	{#if !showDirectory}
		<div class="products-content">
			<header>
				<h1>Pharmacy Products</h1>
				<p>Browse medications and health products</p>
			</header>

			{#if loading}
				<div class="loading">
					<p>Loading products...</p>
				</div>
			{:else if products.length === 0}
				<div class="empty-state">
					<p>No products available at this time.</p>
				</div>
			{:else}
				<div class="products-grid">
					{#each products as product}
						<div class="product-card">
							<h3>{product.name}</h3>
							<p class="price">₦{product.price.toLocaleString()}</p>
							<button>Add to Cart</button>
						</div>
					{/each}
				</div>
			{/if}
		</div>
	{/if}
</div>

<style>
	.products-page {
		max-width: 1200px;
		margin: 0 auto;
		padding: 2rem;
	}

	header {
		margin-bottom: 2rem;
	}

	header h1 {
		margin: 0 0 0.5rem 0;
		font-size: 2rem;
		font-weight: 700;
	}

	header p {
		margin: 0;
		color: #666;
	}

	.loading,
	.empty-state {
		padding: 3rem;
		text-align: center;
		color: #666;
	}

	.products-grid {
		display: grid;
		grid-template-columns: repeat(auto-fill, minmax(250px, 1fr));
		gap: 1.5rem;
	}

	.product-card {
		padding: 1.5rem;
		background: white;
		border: 1px solid #e5e5e5;
		border-radius: 8px;
	}

	.product-card h3 {
		margin: 0 0 0.5rem 0;
		font-size: 1.125rem;
	}

	.price {
		margin: 0.5rem 0 1rem 0;
		font-size: 1.25rem;
		font-weight: 600;
		color: #3498db;
	}

	.product-card button {
		width: 100%;
		padding: 0.75rem;
		background: #3498db;
		color: white;
		border: none;
		border-radius: 6px;
		cursor: pointer;
		font-weight: 500;
	}

	.product-card button:hover {
		background: #2980b9;
	}
</style>
