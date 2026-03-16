<script lang="ts">
	import { invalidate } from '$app/navigation';
	import { onMount } from 'svelte';
	import { authStore } from '$lib/stores/auth';
	import { supabase } from '$lib/supabase';
	import ReferralSessionTracker from '$lib/components/referral/ReferralSessionTracker.svelte';
	import '../app.css';

	export let data;

	// Update auth store when session changes
	$: if (data.session) {
		authStore.setAuth(data.session.user, data.session);
	} else {
		authStore.clearAuth();
	}

	// Initialize auth and set up realtime listener
	onMount(() => {
		authStore.initialize();

		// Listen for auth state changes
		const {
			data: { subscription }
		} = supabase.auth.onAuthStateChange((event, session) => {
			if (event === 'SIGNED_IN' || event === 'SIGNED_OUT' || event === 'TOKEN_REFRESHED') {
				invalidate('supabase:auth');
			}
		});

		return () => {
			subscription.unsubscribe();
		};
	});
</script>

<!-- Referral Session Tracker (runs on every page) -->
<ReferralSessionTracker />

<slot />
