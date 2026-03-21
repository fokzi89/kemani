<script lang="ts">
	import { supabase } from '$lib/supabase';
	import { goto } from '$app/navigation';
	import { Lock, AlertCircle, CheckCircle } from 'lucide-svelte';

	let password = $state('');
	let confirmPassword = $state('');
	let loading = $state(false);
	let error = $state('');
	let success = $state(false);

	async function handleReset(e: Event) {
		e.preventDefault();
		if (password !== confirmPassword) { error = 'Passwords do not match'; return; }
		if (password.length < 6) { error = 'Password must be at least 6 characters'; return; }
		loading = true; error = '';
		try {
			const { error: updateError } = await supabase.auth.updateUser({ password });
			if (updateError) throw updateError;
			success = true;
			setTimeout(() => goto('/auth/login'), 3000);
		} catch (err: any) {
			error = err.message || 'Failed to update password';
		} finally {
			loading = false;
		}
	}
</script>

<svelte:head><title>Reset Password – Kemani POS</title></svelte:head>

<div class="min-h-screen flex items-center justify-center bg-gradient-to-br from-indigo-50 via-white to-purple-50 p-4">
	<div class="max-w-md w-full bg-white rounded-2xl shadow-xl p-8">
		<h1 class="text-2xl font-bold text-gray-900 mb-2">Set new password</h1>
		<p class="text-gray-500 text-sm mb-8">Choose a strong password for your account.</p>

		{#if success}
			<div class="bg-green-50 border border-green-200 rounded-xl p-6 text-center">
				<CheckCircle class="h-12 w-12 text-green-500 mx-auto mb-3" />
				<h2 class="text-lg font-semibold text-green-900">Password updated!</h2>
				<p class="text-sm text-green-700 mt-1">Redirecting you to login...</p>
			</div>
		{:else}
			{#if error}
				<div class="bg-red-50 border border-red-200 text-red-800 px-4 py-3 rounded-lg mb-5 flex items-start gap-2">
					<AlertCircle class="h-5 w-5 flex-shrink-0 mt-0.5" /><p class="text-sm">{error}</p>
				</div>
			{/if}
			<form onsubmit={handleReset} class="space-y-4">
				<div>
					<label for="password" class="block text-sm font-medium text-gray-700 mb-1">New Password</label>
					<div class="relative">
						<div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none"><Lock class="h-4 w-4 text-gray-400" /></div>
						<input id="password" type="password" bind:value={password} required placeholder="Min. 6 characters" class="w-full pl-10 pr-4 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm" />
					</div>
				</div>
				<div>
					<label for="confirm" class="block text-sm font-medium text-gray-700 mb-1">Confirm Password</label>
					<div class="relative">
						<div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none"><Lock class="h-4 w-4 text-gray-400" /></div>
						<input id="confirm" type="password" bind:value={confirmPassword} required placeholder="Repeat password" class="w-full pl-10 pr-4 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm" />
					</div>
				</div>
				<button type="submit" disabled={loading} class="w-full bg-indigo-600 hover:bg-indigo-700 text-white font-semibold py-3 px-4 rounded-lg transition-colors disabled:opacity-50 disabled:cursor-not-allowed">
					{loading ? 'Updating...' : 'Update Password'}
				</button>
			</form>
		{/if}
	</div>
</div>
