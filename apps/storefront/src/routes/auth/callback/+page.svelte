<script lang="ts">
	import { onMount } from 'svelte';
	import { goto } from '$app/navigation';
	import { authStore } from '$lib/stores/auth';
	import { supabase } from '$lib/supabase';

	let loading = true;
	let error = '';

	onMount(async () => {
		try {
			// Get the hash fragment from URL (contains access_token)
			const hashParams = new URLSearchParams(window.location.hash.substring(1));
			const accessToken = hashParams.get('access_token');
			const refreshToken = hashParams.get('refresh_token');

			// Get redirect parameter
			const urlParams = new URLSearchParams(window.location.search);
			const redirectUrl = urlParams.get('redirect') || '/';

			if (accessToken && refreshToken) {
				// Set the session from tokens
				const { data, error: sessionError } = await supabase.auth.setSession({
					access_token: accessToken,
					refresh_token: refreshToken
				});

				if (sessionError) {
					throw sessionError;
				}

				if (data.user && data.session) {
					// Update auth store
					authStore.setAuth(data.user, data.session);

					// Create tenant-specific customer record (via server-side hook)
					// The hook will detect the current subdomain and create customer record
					// No action needed here - it happens automatically in hooks.server.ts

					// Redirect to intended destination
					await goto(redirectUrl);
					return;
				}
			}

			// If no tokens in hash, try to get session normally
			const { data: sessionData, error: getSessionError } = await supabase.auth.getSession();

			if (getSessionError) {
				throw getSessionError;
			}

			if (sessionData.session) {
				authStore.setAuth(sessionData.session.user, sessionData.session);
				await goto(redirectUrl);
				return;
			}

			// No session found
			error = 'No authentication session found. Please try logging in again.';
			loading = false;

			// Redirect to login after a delay
			setTimeout(() => {
				goto('/auth/login');
			}, 3000);
		} catch (err: any) {
			console.error('Auth callback error:', err);
			error = err.message || 'Authentication failed. Please try again.';
			loading = false;

			// Redirect to login after a delay
			setTimeout(() => {
				goto('/auth/login');
			}, 3000);
		}
	});
</script>

<svelte:head>
	<title>Authenticating...</title>
</svelte:head>

<div class="min-h-screen flex items-center justify-center bg-gray-50 dark:bg-gray-900 px-4">
	<div class="max-w-md w-full text-center">
		{#if loading}
			<div class="bg-white dark:bg-gray-800 rounded-xl shadow-lg p-12 space-y-6">
				<div class="flex justify-center">
					<svg class="animate-spin h-16 w-16 text-blue-600" viewBox="0 0 24 24">
						<circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4" fill="none"></circle>
						<path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
					</svg>
				</div>
				<h2 class="text-2xl font-bold text-gray-900 dark:text-white">
					Signing you in...
				</h2>
				<p class="text-gray-600 dark:text-gray-400">
					Please wait while we verify your account
				</p>
			</div>
		{:else if error}
			<div class="bg-white dark:bg-gray-800 rounded-xl shadow-lg p-12 space-y-6">
				<div class="flex justify-center">
					<svg class="h-16 w-16 text-red-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
						<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
					</svg>
				</div>
				<h2 class="text-2xl font-bold text-gray-900 dark:text-white">
					Authentication Error
				</h2>
				<p class="text-red-600 dark:text-red-400">
					{error}
				</p>
				<p class="text-sm text-gray-600 dark:text-gray-400">
					Redirecting to login page...
				</p>
			</div>
		{/if}
	</div>
</div>
