<script lang="ts">
	import { page } from '$app/stores';
	import ServiceSelector from '$lib/components/referral/ServiceSelector.svelte';
	import ServiceDirectory from '$lib/components/referral/ServiceDirectory.svelte';
	import { onMount } from 'svelte';

	/**
	 * Diagnostics Page (Lab Tests)
	 * Feature: 004-tenant-referral-commissions
	 *
	 * Auto-routing behavior:
	 * - If referring tenant offers 'diagnostic' → auto-route to their lab
	 * - If referring tenant doesn't offer 'diagnostic' → show external lab directory
	 */

	let referringTenantId: string | null = null;
	let showDirectory = false;
	let tests: any[] = [];
	let loading = true;

	$: referringTenantId = $page.data.referringTenantId || null;

	onMount(() => {
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
		console.log('Auto-routed to diagnostic provider:', event.detail);
		showDirectory = false;
		loadTests(event.detail.providerId);
	}

	function handleShowDirectory(event: CustomEvent) {
		console.log('Showing diagnostic directory');
		showDirectory = true;
		loading = false;
	}

	function handleProviderSelected(event: CustomEvent) {
		console.log('Diagnostic provider selected:', event.detail);
		showDirectory = false;
		loadTests(event.detail.providerId);
	}

	async function loadTests(providerId: string) {
		loading = true;
		try {
			// TODO: Load diagnostic tests from Supabase
			console.log('Loading tests for provider:', providerId);
			tests = []; // Placeholder
		} catch (error) {
			console.error('Error loading tests:', error);
		} finally {
			loading = false;
		}
	}
</script>

<svelte:head>
	<title>Diagnostic Tests</title>
</svelte:head>

<div class="diagnostics-page">
	<ServiceSelector
		serviceType="diagnostic"
		referringTenantId={referringTenantId}
		autoNavigate={false}
		showNotification={true}
	>
		<svelte:fragment slot="directory">
			{#if showDirectory}
				<ServiceDirectory
					serviceType="diagnostic"
					referringTenantId={referringTenantId}
					city={null}
				/>
			{/if}
		</svelte:fragment>
	</ServiceSelector>

	{#if !showDirectory}
		<div class="diagnostics-content">
			<header>
				<h1>Diagnostic Tests</h1>
				<p>Book laboratory tests and medical screenings</p>
			</header>

			{#if loading}
				<div class="loading">
					<p>Loading available tests...</p>
				</div>
			{:else if tests.length === 0}
				<div class="empty-state">
					<p>No tests available at this time.</p>
				</div>
			{:else}
				<div class="tests-grid">
					{#each tests as test}
						<div class="test-card">
							<h3>{test.name}</h3>
							<p class="description">{test.description}</p>
							<p class="price">₦{test.price.toLocaleString()}</p>
							<button>Book Test</button>
						</div>
					{/each}
				</div>
			{/if}
		</div>
	{/if}
</div>

<style>
	.diagnostics-page {
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

	.tests-grid {
		display: grid;
		grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
		gap: 1.5rem;
	}

	.test-card {
		padding: 1.5rem;
		background: white;
		border: 1px solid #e5e5e5;
		border-radius: 8px;
	}

	.test-card h3 {
		margin: 0 0 0.5rem 0;
		font-size: 1.125rem;
	}

	.description {
		margin: 0.5rem 0;
		font-size: 0.875rem;
		color: #666;
	}

	.price {
		margin: 0.5rem 0 1rem 0;
		font-size: 1.25rem;
		font-weight: 600;
		color: #e74c3c;
	}

	.test-card button {
		width: 100%;
		padding: 0.75rem;
		background: #e74c3c;
		color: white;
		border: none;
		border-radius: 6px;
		cursor: pointer;
		font-weight: 500;
	}

	.test-card button:hover {
		background: #c0392b;
	}
</style>
