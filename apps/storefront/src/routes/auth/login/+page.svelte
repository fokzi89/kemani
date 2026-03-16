<script lang="ts">
	import { goto } from '$app/navigation';
	import { authStore } from '$lib/stores/auth';
	import { referralContext } from '$lib/stores/referralContext';
	import { supabase } from '$lib/supabase';
	import { onMount } from 'svelte';

	let loading = false;
	let error = '';
	let redirectTo = '/';

	// Auto-fill redirect from URL params
	onMount(() => {
		const params = new URLSearchParams(window.location.search);
		const redirectParam = params.get('redirect');
		if (redirectParam) {
			redirectTo = redirectParam;
		}
	});

	async function signInWithGoogle() {
		loading = true;
		error = '';

		try {
			const { error: signInError } = await supabase.auth.signInWithOAuth({
				provider: 'google',
				options: {
					redirectTo: `${window.location.origin}/auth/callback?redirect=${encodeURIComponent(redirectTo)}`
				}
			});

			if (signInError) {
				error = signInError.message || 'Failed to sign in with Google';
				loading = false;
			}
			// If successful, user will be redirected to Google
		} catch (err: any) {
			error = err.message || 'Failed to sign in with Google';
			loading = false;
		}
	}

	async function signInWithFacebook() {
		loading = true;
		error = '';

		try {
			const { error: signInError } = await supabase.auth.signInWithOAuth({
				provider: 'facebook',
				options: {
					redirectTo: `${window.location.origin}/auth/callback?redirect=${encodeURIComponent(redirectTo)}`
				}
			});

			if (signInError) {
				error = signInError.message || 'Failed to sign in with Facebook';
				loading = false;
			}
		} catch (err: any) {
			error = err.message || 'Failed to sign in with Facebook';
			loading = false;
		}
	}
</script>

<svelte:head>
	<title>Sign In - Kemani Storefront</title>
</svelte:head>

<div class="min-h-screen flex items-center justify-center bg-gradient-to-br from-blue-50 to-indigo-100 dark:from-gray-900 dark:to-gray-800 px-4 py-12">
	<div class="max-w-md w-full space-y-8">
		<!-- Header -->
		<div class="text-center">
			<div class="mb-6">
				<div class="inline-flex items-center justify-center w-16 h-16 bg-blue-600 rounded-full">
					<svg class="w-10 h-10 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
						<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
					</svg>
				</div>
			</div>
			<h2 class="text-3xl font-bold text-gray-900 dark:text-white">
				Welcome Back
			</h2>
			<p class="mt-2 text-sm text-gray-600 dark:text-gray-400">
				Sign in to access your account
			</p>
		</div>

		<!-- Error Message -->
		{#if error}
			<div class="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 text-red-600 dark:text-red-400 px-4 py-3 rounded-lg flex items-start gap-3">
				<svg class="w-5 h-5 mt-0.5 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
					<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
				</svg>
				<div>
					{error}
				</div>
			</div>
		{/if}

		<!-- Social Sign-In Card -->
		<div class="bg-white dark:bg-gray-800 rounded-2xl shadow-xl p-8 space-y-6">
			<div class="space-y-4">
				<!-- Google Sign-In -->
				<button
					on:click={signInWithGoogle}
					disabled={loading}
					class="w-full flex items-center justify-center gap-3 px-6 py-4 bg-white dark:bg-gray-700 border-2 border-gray-300 dark:border-gray-600 rounded-xl hover:border-blue-500 dark:hover:border-blue-400 hover:shadow-lg transition-all duration-200 disabled:opacity-50 disabled:cursor-not-allowed group"
				>
					{#if loading}
						<svg class="animate-spin h-5 w-5 text-gray-600 dark:text-gray-300" viewBox="0 0 24 24">
							<circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4" fill="none"></circle>
							<path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
						</svg>
						<span class="font-semibold text-gray-700 dark:text-gray-200">Signing in...</span>
					{:else}
						<svg class="w-5 h-5" viewBox="0 0 24 24">
							<path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"/>
							<path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"/>
							<path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"/>
							<path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"/>
						</svg>
						<span class="font-semibold text-gray-700 dark:text-gray-200 group-hover:text-blue-600 dark:group-hover:text-blue-400">
							Continue with Google
						</span>
					{/if}
				</button>

				<!-- Facebook Sign-In -->
				<button
					on:click={signInWithFacebook}
					disabled={loading}
					class="w-full flex items-center justify-center gap-3 px-6 py-4 bg-[#1877F2] hover:bg-[#166FE5] text-white rounded-xl hover:shadow-lg transition-all duration-200 disabled:opacity-50 disabled:cursor-not-allowed"
				>
					{#if loading}
						<svg class="animate-spin h-5 w-5 text-white" viewBox="0 0 24 24">
							<circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4" fill="none"></circle>
							<path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
						</svg>
						<span class="font-semibold">Signing in...</span>
					{:else}
						<svg class="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
							<path d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z"/>
						</svg>
						<span class="font-semibold">
							Continue with Facebook
						</span>
					{/if}
				</button>
			</div>

			<!-- Divider -->
			<div class="relative">
				<div class="absolute inset-0 flex items-center">
					<div class="w-full border-t border-gray-300 dark:border-gray-600"></div>
				</div>
				<div class="relative flex justify-center text-sm">
					<span class="px-4 bg-white dark:bg-gray-800 text-gray-500 dark:text-gray-400">
						Secure authentication powered by Supabase
					</span>
				</div>
			</div>

			<!-- Benefits -->
			<div class="space-y-3 pt-2">
				<div class="flex items-start gap-3 text-sm text-gray-600 dark:text-gray-400">
					<svg class="w-5 h-5 text-green-500 flex-shrink-0 mt-0.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
						<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
					</svg>
					<span>No password to remember</span>
				</div>
				<div class="flex items-start gap-3 text-sm text-gray-600 dark:text-gray-400">
					<svg class="w-5 h-5 text-green-500 flex-shrink-0 mt-0.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
						<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
					</svg>
					<span>Works across all our partner clinics and pharmacies</span>
				</div>
				<div class="flex items-start gap-3 text-sm text-gray-600 dark:text-gray-400">
					<svg class="w-5 h-5 text-green-500 flex-shrink-0 mt-0.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
						<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
					</svg>
					<span>Secure and trusted authentication</span>
				</div>
			</div>
		</div>

		<!-- Footer -->
		<div class="text-center">
			<a href="/" class="text-sm text-blue-600 hover:text-blue-700 dark:text-blue-400 dark:hover:text-blue-300 font-medium inline-flex items-center gap-2">
				<svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
					<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18" />
				</svg>
				Back to shopping
			</a>
		</div>

		<!-- Privacy Note -->
		<div class="text-center text-xs text-gray-500 dark:text-gray-400">
			By signing in, you agree to our Terms of Service and Privacy Policy
		</div>
	</div>
</div>
