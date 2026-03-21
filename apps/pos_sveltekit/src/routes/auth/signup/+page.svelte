<script lang="ts">
	import { supabase } from '$lib/supabase';
	import { goto } from '$app/navigation';
	import { Mail, Lock, User, Store, AlertCircle, CheckCircle } from 'lucide-svelte';

	let fullName = $state('');
	let businessName = $state('');
	let email = $state('');
	let password = $state('');
	let confirmPassword = $state('');
	let loading = $state(false);
	let error = $state('');
	let success = $state(false);

	async function handleSignup(e: Event) {
		e.preventDefault();
		if (password !== confirmPassword) {
			error = 'Passwords do not match';
			return;
		}
		if (password.length < 6) {
			error = 'Password must be at least 6 characters';
			return;
		}
		loading = true;
		error = '';

		try {
			const { data, error: authError } = await supabase.auth.signUp({
				email,
				password,
				options: {
					data: { full_name: fullName, business_name: businessName }
				}
			});
			if (authError) throw authError;
			success = true;
		} catch (err: any) {
			error = err.message || 'Failed to sign up';
		} finally {
			loading = false;
		}
	}
</script>

<svelte:head>
	<title>Sign Up – Kemani POS</title>
</svelte:head>

<div class="min-h-screen flex items-center justify-center bg-gradient-to-br from-indigo-50 via-white to-purple-50 p-4">
	<div class="max-w-md w-full bg-white rounded-2xl shadow-xl p-8">
		<div class="text-center mb-8">
			<div class="inline-flex items-center justify-center w-14 h-14 bg-indigo-600 rounded-2xl mb-4">
				<Store class="h-7 w-7 text-white" />
			</div>
			<h1 class="text-2xl font-bold text-gray-900">Create your account</h1>
			<p class="text-gray-500 mt-1 text-sm">Set up your Kemani POS in minutes</p>
		</div>

		{#if success}
			<div class="bg-green-50 border border-green-200 rounded-xl p-6 text-center">
				<CheckCircle class="h-12 w-12 text-green-500 mx-auto mb-3" />
				<h2 class="text-lg font-semibold text-green-900">Check your email!</h2>
				<p class="text-sm text-green-700 mt-1">We sent a confirmation link to <strong>{email}</strong>. Click it to activate your account.</p>
				<a href="/auth/login" class="mt-4 inline-block text-sm font-medium text-green-700 underline">Back to Login</a>
			</div>
		{:else}
			{#if error}
				<div class="bg-red-50 border border-red-200 text-red-800 px-4 py-3 rounded-lg mb-5 flex items-start gap-2">
					<AlertCircle class="h-5 w-5 flex-shrink-0 mt-0.5" />
					<p class="text-sm">{error}</p>
				</div>
			{/if}

			<form onsubmit={handleSignup} class="space-y-4">
				<div>
					<label for="fullName" class="block text-sm font-medium text-gray-700 mb-1">Full Name</label>
					<div class="relative">
						<div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
							<User class="h-4 w-4 text-gray-400" />
						</div>
						<input id="fullName" type="text" bind:value={fullName} required placeholder="John Doe"
							class="w-full pl-10 pr-4 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm" />
					</div>
				</div>

				<div>
					<label for="businessName" class="block text-sm font-medium text-gray-700 mb-1">Business Name</label>
					<div class="relative">
						<div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
							<Store class="h-4 w-4 text-gray-400" />
						</div>
						<input id="businessName" type="text" bind:value={businessName} required placeholder="My Shop"
							class="w-full pl-10 pr-4 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm" />
					</div>
				</div>

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

				<div>
					<label for="password" class="block text-sm font-medium text-gray-700 mb-1">Password</label>
					<div class="relative">
						<div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
							<Lock class="h-4 w-4 text-gray-400" />
						</div>
						<input id="password" type="password" bind:value={password} required placeholder="Min. 6 characters"
							class="w-full pl-10 pr-4 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm" />
					</div>
				</div>

				<div>
					<label for="confirmPassword" class="block text-sm font-medium text-gray-700 mb-1">Confirm Password</label>
					<div class="relative">
						<div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
							<Lock class="h-4 w-4 text-gray-400" />
						</div>
						<input id="confirmPassword" type="password" bind:value={confirmPassword} required placeholder="Repeat password"
							class="w-full pl-10 pr-4 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm" />
					</div>
				</div>

				<button type="submit" disabled={loading}
					class="w-full bg-indigo-600 hover:bg-indigo-700 text-white font-semibold py-3 px-4 rounded-lg transition-colors disabled:opacity-50 disabled:cursor-not-allowed mt-2">
					{loading ? 'Creating account...' : 'Create Account'}
				</button>
			</form>

			<p class="mt-6 text-center text-sm text-gray-600">
				Already have an account?
				<a href="/auth/login" class="font-medium text-indigo-600 hover:text-indigo-700">Sign in</a>
			</p>
		{/if}
	</div>
</div>
