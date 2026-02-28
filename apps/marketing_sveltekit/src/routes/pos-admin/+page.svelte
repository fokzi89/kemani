<script>
	import { onMount } from 'svelte';
	import { browser } from '$app/environment';

	onMount(() => {
		if (browser) {
			// Redirect to the static Flutter app
			window.location.replace('/pos-admin/index.html');
		}
	});
</script>

<svelte:head>
	<title>Kemani POS - Loading...</title>
	<meta name="description" content="Kemani POS Admin - Sign up or sign in" />
</svelte:head>

<div class="flex items-center justify-center min-h-screen bg-white">
	<div class="text-center">
		<div class="inline-block animate-spin rounded-full h-12 w-12 border-b-2 border-emerald-600 mb-4"></div>
		<p class="text-gray-600">Loading Kemani POS...</p>
	</div>
</div>

<style>
	@keyframes spin {
		to {
			transform: rotate(360deg);
		}
	}

	.animate-spin {
		animation: spin 1s linear infinite;
	}
</style>
