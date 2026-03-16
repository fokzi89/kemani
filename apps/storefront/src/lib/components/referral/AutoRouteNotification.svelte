<script lang="ts">
	import { onMount } from 'svelte';
	import type { ServiceType } from '$lib/services/serviceRouter';

	/**
	 * AutoRouteNotification Component
	 * Feature: 004-tenant-referral-commissions
	 *
	 * Displays a notification when customer is auto-routed to referring tenant's service
	 *
	 * Usage:
	 * <AutoRouteNotification
	 *   serviceType="diagnostic"
	 *   providerName="Fokz Diagnostics"
	 * />
	 */

	export let serviceType: ServiceType;
	export let providerName: string;
	export let autoDismiss = true;
	export let dismissDelay = 5000; // 5 seconds

	let visible = true;

	const serviceLabels: Record<ServiceType, string> = {
		pharmacy: 'Pharmacy Services',
		diagnostic: 'Diagnostic Tests',
		consultation: 'Medical Consultations'
	};

	onMount(() => {
		if (autoDismiss) {
			setTimeout(() => {
				visible = false;
			}, dismissDelay);
		}
	});

	function dismiss() {
		visible = false;
	}
</script>

{#if visible}
	<div class="auto-route-notification" role="alert" data-testid="auto-route-notification">
		<div class="notification-icon">
			<svg
				width="24"
				height="24"
				viewBox="0 0 24 24"
				fill="none"
				stroke="currentColor"
				stroke-width="2"
			>
				<path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path>
				<polyline points="22 4 12 14.01 9 11.01"></polyline>
			</svg>
		</div>

		<div class="notification-content">
			<h4>Automatic Service Selection</h4>
			<p>
				You're browsing through <strong>{providerName}</strong>. We've automatically selected
				their {serviceLabels[serviceType]} for you.
			</p>
		</div>

		<button class="dismiss-button" on:click={dismiss} aria-label="Dismiss notification">
			<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor">
				<line x1="18" y1="6" x2="6" y2="18"></line>
				<line x1="6" y1="6" x2="18" y2="18"></line>
			</svg>
		</button>
	</div>
{/if}

<style>
	.auto-route-notification {
		display: flex;
		align-items: flex-start;
		gap: 1rem;
		padding: 1rem 1.5rem;
		background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
		color: white;
		border-radius: 8px;
		box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
		margin-bottom: 1.5rem;
		animation: slideIn 0.3s ease-out;
	}

	@keyframes slideIn {
		from {
			opacity: 0;
			transform: translateY(-10px);
		}
		to {
			opacity: 1;
			transform: translateY(0);
		}
	}

	.notification-icon {
		flex-shrink: 0;
		width: 24px;
		height: 24px;
		color: white;
	}

	.notification-content {
		flex-grow: 1;
	}

	.notification-content h4 {
		margin: 0 0 0.25rem 0;
		font-size: 1rem;
		font-weight: 600;
	}

	.notification-content p {
		margin: 0;
		font-size: 0.875rem;
		line-height: 1.4;
		opacity: 0.95;
	}

	.notification-content strong {
		font-weight: 600;
		opacity: 1;
	}

	.dismiss-button {
		flex-shrink: 0;
		background: none;
		border: none;
		color: white;
		cursor: pointer;
		padding: 0;
		width: 20px;
		height: 20px;
		opacity: 0.8;
		transition: opacity 0.2s;
	}

	.dismiss-button:hover {
		opacity: 1;
	}

	.dismiss-button:focus {
		outline: 2px solid white;
		outline-offset: 2px;
		border-radius: 2px;
	}
</style>
