<script lang="ts">
	import { page } from '$app/stores';
	import ServiceSelector from '$lib/components/referral/ServiceSelector.svelte';
	import ServiceDirectory from '$lib/components/referral/ServiceDirectory.svelte';
	import { onMount } from 'svelte';

	/**
	 * Consultations Page (Medical Consultations)
	 * Feature: 004-tenant-referral-commissions
	 *
	 * Auto-routing behavior:
	 * - If referring tenant offers 'consultation' → auto-route to their doctors
	 * - If referring tenant doesn't offer 'consultation' → show external doctors directory
	 */

	let referringTenantId: string | null = null;
	let showDirectory = false;
	let doctors: any[] = [];
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
		console.log('Auto-routed to consultation provider:', event.detail);
		showDirectory = false;
		loadDoctors(event.detail.providerId);
	}

	function handleShowDirectory(event: CustomEvent) {
		console.log('Showing doctors directory');
		showDirectory = true;
		loading = false;
	}

	function handleProviderSelected(event: CustomEvent) {
		console.log('Doctor selected:', event.detail);
		showDirectory = false;
		loadDoctors(event.detail.providerId);
	}

	async function loadDoctors(providerId: string) {
		loading = true;
		try {
			// TODO: Load doctors from Supabase
			console.log('Loading doctors for provider:', providerId);
			doctors = []; // Placeholder
		} catch (error) {
			console.error('Error loading doctors:', error);
		} finally {
			loading = false;
		}
	}
</script>

<svelte:head>
	<title>Medical Consultations</title>
</svelte:head>

<div class="consultations-page">
	<ServiceSelector
		serviceType="consultation"
		referringTenantId={referringTenantId}
		autoNavigate={false}
		showNotification={true}
	>
		<svelte:fragment slot="directory">
			{#if showDirectory}
				<ServiceDirectory
					serviceType="consultation"
					referringTenantId={referringTenantId}
					city={null}
				/>
			{/if}
		</svelte:fragment>
	</ServiceSelector>

	{#if !showDirectory}
		<div class="consultations-content">
			<header>
				<h1>Medical Consultations</h1>
				<p>Book appointments with qualified healthcare professionals</p>
			</header>

			{#if loading}
				<div class="loading">
					<p>Loading available doctors...</p>
				</div>
			{:else if doctors.length === 0}
				<div class="empty-state">
					<p>No doctors available at this time.</p>
				</div>
			{:else}
				<div class="doctors-grid">
					{#each doctors as doctor}
						<div class="doctor-card">
							<h3>{doctor.name}</h3>
							<p class="specialization">{doctor.specialization}</p>
							<p class="price">₦{doctor.consultation_fee.toLocaleString()}</p>
							<button>Book Consultation</button>
						</div>
					{/each}
				</div>
			{/if}
		</div>
	{/if}
</div>

<style>
	.consultations-page {
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

	.doctors-grid {
		display: grid;
		grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
		gap: 1.5rem;
	}

	.doctor-card {
		padding: 1.5rem;
		background: white;
		border: 1px solid #e5e5e5;
		border-radius: 8px;
	}

	.doctor-card h3 {
		margin: 0 0 0.5rem 0;
		font-size: 1.125rem;
	}

	.specialization {
		margin: 0.5rem 0;
		font-size: 0.875rem;
		color: #666;
		text-transform: capitalize;
	}

	.price {
		margin: 0.5rem 0 1rem 0;
		font-size: 1.25rem;
		font-weight: 600;
		color: #27ae60;
	}

	.doctor-card button {
		width: 100%;
		padding: 0.75rem;
		background: #27ae60;
		color: white;
		border: none;
		border-radius: 6px;
		cursor: pointer;
		font-weight: 500;
	}

	.doctor-card button:hover {
		background: #229954;
	}
</style>
