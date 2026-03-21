<script lang="ts">
	import { supabase } from '$lib/supabase';
	import { Mail, AlertCircle, CheckCircle, ArrowLeft } from 'lucide-svelte';

	let email = $state('');
	let loading = $state(false);
	let error = $state('');
	let success = $state(false);

	async function handleReset(e: Event) {
		e.preventDefault();
		loading = true;
		error = '';
		try {
			const { error: resetError } = await supabase.auth.resetPasswordForEmail(email, {
				redirectTo: `${window.location.origin}/auth/reset-password`
			});
			if (resetError) throw resetError;
			success = true;
		} catch (err: any) {
			error = err.message || 'Failed to send reset email';
		} finally {
			loading = false;
		}
	}
</script>

<svelte:head>
	<title>Forgot Password – Kemani POS</title>
</svelte:head>

<div class="min-h-screen flex items-center justify-center bg-gradient-to-br from-indigo-50 via-white to-purple-50 p-4">
	<div class="max-w-md w-full bg-white rounded-2xl shadow-xl p-8">
		<a href="/auth/login" class="inline-flex items-center gap-1 text-sm text-gray-500 hover:text-gray-700 mb-6">
			<ArrowLeft class="h-4 w-4" /> Back to Login
		</a>

		<div class="mb-8">
			<h1 class="text-2xl font-bold text-gray-900">Forgot your password?</h1>
			<p class="text-gray-500 mt-1 text-sm">Enter your email address and we'll send you a reset link.</p>
		</div>

		{#if success}
			<div class="bg-green-50 border border-green-200 rounded-xl p-6 text-center">
				<CheckCircle class="h-12 w-12 text-green-500 mx-auto mb-3" />
				<h2 class="text-lg font-semibold text-green-900">Reset link sent!</h2>
				<p class="text-sm text-green-700 mt-1">Check your inbox at <strong>{email}</strong>. The link expires in 1 hour.</p>
				<a href="/auth/login" class="mt-4 inline-block text-sm font-medium text-green-700 underline">Back to Login</a>
			</div>
		{:else}
			{#if error}
				<div class="bg-red-50 border border-red-200 text-red-800 px-4 py-3 rounded-lg mb-5 flex items-start gap-2">
					<AlertCircle class="h-5 w-5 flex-shrink-0 mt-0.5" />
					<p class="text-sm">{error}</p>
				</div>
			{/if}

			<form onsubmit={handleReset} class="space-y-5">
				<div>
					<label for="email" class="block text-sm font-medium text-gray-700 mb-1">Email Address</label>
					<div class="relative">
						<div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
							<Mail class="h-4 w-4 text-gray-400" />
						</div>
						<input id="email" type="email" bind:value={email} required placeholder="you@example.com"
							class="w-full pl-10 pr-4 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm" />
					</div>
				</div>

				<button type="submit" disabled={loading}
					class="w-full bg-indigo-600 hover:bg-indigo-700 text-white font-semibold py-3 px-4 rounded-lg transition-colors disabled:opacity-50 disabled:cursor-not-allowed">
					{loading ? 'Sending...' : 'Send Reset Link'}
				</button>
			</form>
		{/if}
	</div>
</div>
