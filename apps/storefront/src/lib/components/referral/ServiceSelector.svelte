<script lang="ts">
	import { onMount } from 'svelte';
	import { page } from '$app/stores';
	import { ServiceRouter, type ServiceType, type RoutingResult } from '$lib/services/serviceRouter';
	import AutoRouteNotification from './AutoRouteNotification.svelte';
	import { goto } from '$app/navigation';

	/**
	 * ServiceSelector Component
	 * Feature: 004-tenant-referral-commissions
	 *
	 * Implements automatic service routing:
	 * - If referring tenant offers service → auto-route (no directory shown)
	 * - If referring tenant doesn't offer service → show external directory
	 *
	 * Usage:
	 * <ServiceSelector
	 *   serviceType="diagnostic"
	 *   referringTenantId={$page.data.referringTenantId}
	 *   on:autoRoute={(e) => handleAutoRoute(e.detail)}
	 *   on:showDirectory={(e) => handleShowDirectory(e.detail)}
	 * />
	 */

	export let serviceType: ServiceType;
	export let referringTenantId: string | null = null;
	export let autoNavigate = true; // Automatically navigate on auto-route
	export let showNotification = true; // Show notification when auto-routing

	let routing: RoutingResult | null = null;
	let loading = true;
	let error: string | null = null;

	onMount(async () => {
		await determineRouting();
	});

	async function determineRouting() {
		loading = true;
		error = null;

		try {
			routing = await ServiceRouter.getServiceProvider(referringTenantId, serviceType);

			if (routing.shouldAutoRoute) {
				// Dispatch auto-route event
				const event = new CustomEvent('autoRoute', {
					detail: {
						serviceType,
						providerId: routing.providerTenantId,
						providerName: routing.providerName
					}
				});
				document.dispatchEvent(event);

				// Auto-navigate if enabled
				if (autoNavigate && routing.providerTenantId) {
					await handleAutoRoute(routing);
				}
			} else {
				// Dispatch show-directory event
				const event = new CustomEvent('showDirectory', {
					detail: { serviceType }
				});
				document.dispatchEvent(event);
			}
		} catch (err) {
			error = err instanceof Error ? err.message : 'Failed to determine routing';
			console.error('Service routing error:', err);
		} finally {
			loading = false;
		}
	}

	async function handleAutoRoute(routing: RoutingResult) {
		// Navigate to the service page for the auto-routed provider
		const routes: Record<ServiceType, string> = {
			pharmacy: '/products',
			diagnostic: '/diagnostics',
			consultation: '/consultations'
		};

		const targetRoute = routes[serviceType];
		if (targetRoute) {
			await goto(targetRoute);
		}
	}
</script>

{#if loading}
	<div class="service-selector-loading">
		<div class="spinner"></div>
		<p>Determining service availability...</p>
	</div>
{:else if error}
	<div class="service-selector-error">
		<p>Error: {error}</p>
		<button on:click={determineRouting}>Retry</button>
	</div>
{:else if routing}
	{#if routing.shouldAutoRoute}
		{#if showNotification}
			<AutoRouteNotification
				serviceType={serviceType}
				providerName={routing.providerName || 'Provider'}
			/>
		{/if}
	{:else}
		<!-- Directory will be shown by parent component -->
		<slot name="directory">
			<div class="service-directory-placeholder">
				<p>Showing directory for {serviceType} services...</p>
			</div>
		</slot>
	{/if}
{/if}

<style>
	.service-selector-loading {
		display: flex;
		flex-direction: column;
		align-items: center;
		justify-content: center;
		padding: 2rem;
		gap: 1rem;
	}

	.spinner {
		width: 40px;
		height: 40px;
		border: 4px solid #f3f3f3;
		border-top: 4px solid #3498db;
		border-radius: 50%;
		animation: spin 1s linear infinite;
	}

	@keyframes spin {
		0% {
			transform: rotate(0deg);
		}
		100% {
			transform: rotate(360deg);
		}
	}

	.service-selector-error {
		padding: 1rem;
		background-color: #fee;
		border: 1px solid #fcc;
		border-radius: 4px;
		color: #c33;
	}

	.service-selector-error button {
		margin-top: 0.5rem;
		padding: 0.5rem 1rem;
		background-color: #3498db;
		color: white;
		border: none;
		border-radius: 4px;
		cursor: pointer;
	}

	.service-directory-placeholder {
		padding: 2rem;
		text-align: center;
		background-color: #f9f9f9;
		border-radius: 8px;
	}
</style>
