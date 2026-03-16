<script lang="ts">
	import { onMount } from 'svelte';
	import { page } from '$app/stores';
	import { ReferralSessionService } from '$lib/services/referralSession';
	import { referralContext } from '$lib/stores/referralContext';
	import type { ReferralSession } from '$lib/types/commission';

	/**
	 * ReferralSessionTracker Component
	 * Tracks and validates referral sessions on the client side
	 * Automatically refreshes session activity on user interaction
	 * Updates referralContext store for auth system to use
	 */

	let session: ReferralSession | null = null;
	let isActive = false;
	let referrerName: string | null = null;

	// Get session token from cookie (client-side)
	function getSessionCookie(): string | null {
		const cookies = document.cookie.split(';');
		for (const cookie of cookies) {
			const [name, value] = cookie.trim().split('=');
			if (name === 'referral_session') {
				return value;
			}
		}
		return null;
	}

	// Validate session on mount
	onMount(async () => {
		const sessionToken = getSessionCookie();

		if (sessionToken) {
			session = await ReferralSessionService.getSessionByToken(sessionToken);

			if (session) {
				isActive = true;

				// Update referral context for auth system
				referralContext.setSession(session);

				// Optionally fetch tenant name for display
				// await fetchTenantName(session.referring_tenant_id);
			} else {
				// No valid session, clear context
				referralContext.clear();
			}
		} else {
			// No session cookie, clear context
			referralContext.clear();
		}
	});

	// Refresh session on user activity
	async function refreshSessionActivity() {
		if (!isActive) return;

		const sessionToken = getSessionCookie();
		if (sessionToken) {
			await ReferralSessionService.refreshSession(sessionToken);
		}
	}

	// Refresh session when cart is updated (for multi-service checkout)
	function handleCartUpdate() {
		console.log('Cart updated - refreshing referral session');
		refreshSessionActivity();
	}

	// Set up activity listeners
	onMount(() => {
		// Refresh session on page visibility change
		const handleVisibilityChange = () => {
			if (document.visibilityState === 'visible') {
				refreshSessionActivity();
			}
		};

		// Refresh session on user interaction (debounced)
		let refreshTimeout: ReturnType<typeof setTimeout>;
		const handleUserActivity = () => {
			clearTimeout(refreshTimeout);
			refreshTimeout = setTimeout(() => {
				refreshSessionActivity();
			}, 60000); // Refresh after 1 minute of activity
		};

		// Listen for cart update events (User Story 3: Multi-service checkout)
		// Apps should dispatch 'cart:update' event when items are added
		document.addEventListener('cart:update', handleCartUpdate as EventListener);
		document.addEventListener('visibilitychange', handleVisibilityChange);
		document.addEventListener('mousemove', handleUserActivity);
		document.addEventListener('keydown', handleUserActivity);
		document.addEventListener('scroll', handleUserActivity);

		return () => {
			document.removeEventListener('cart:update', handleCartUpdate as EventListener);
			document.removeEventListener('visibilitychange', handleVisibilityChange);
			document.removeEventListener('mousemove', handleUserActivity);
			document.removeEventListener('keydown', handleUserActivity);
			document.removeEventListener('scroll', handleUserActivity);
			clearTimeout(refreshTimeout);
		};
	});
</script>

<!--
  This component runs silently in the background.
  Optionally, you can display referral info to the user:
-->

{#if isActive && session}
	<div class="referral-badge" data-testid="referral-active">
		<!-- Optional: Display referral info to user -->
		<!-- <span>Browsing via {referrerName || 'Partner'}</span> -->
	</div>
{/if}

<style>
	.referral-badge {
		/* Hidden by default - add your styles if you want to display */
		display: none;
	}
</style>
