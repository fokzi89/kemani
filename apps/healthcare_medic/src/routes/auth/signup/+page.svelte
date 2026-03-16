<script lang="ts">
	import { supabase } from '$lib/supabase';
	import { goto } from '$app/navigation';

	let formData = $state({
		email: '',
		password: '',
		confirmPassword: ''
	});

	let loading = $state(false);
	let error = $state('');

	async function handleSignup(e: Event) {
		e.preventDefault();
		loading = true;
		error = '';

		if (formData.password !== formData.confirmPassword) {
			error = 'Passwords do not match';
			loading = false;
			return;
		}

		if (formData.password.length < 6) {
			error = 'Password must be at least 6 characters';
			loading = false;
			return;
		}

		// Create auth account
		const { data: authData, error: authError } = await supabase.auth.signUp({
			email: formData.email,
			password: formData.password
		});

		if (authError) {
			error = authError.message;
			loading = false;
			return;
		}

		if (authData.user) {
			// Create minimal provider profile
			const slug = formData.email.split('@')[0] + '-' + Math.random().toString(36).substr(2, 6);

			const { error: profileError } = await supabase
				.from('healthcare_providers')
				.insert({
					user_id: authData.user.id,
					full_name: formData.email.split('@')[0],
					slug,
					email: formData.email,
					type: 'doctor',
					specialization: 'General Practice',
					country: 'Nigeria',
					fees: {
						chat: 5000,
						video: 10000,
						audio: 8000
					},
					is_verified: false,
					is_active: true
				});

			if (profileError) {
				error = 'Failed to create provider profile: ' + profileError.message;
				loading = false;
			} else {
				goto('/');
			}
		}
	}
</script>

<div class="min-h-screen bg-gradient-to-br from-primary-50 to-primary-100 flex items-center justify-center p-4">
	<div class="bg-white rounded-lg shadow-xl p-8 w-full max-w-md">
		<div class="text-center mb-8">
			<h1 class="text-3xl font-bold text-gray-900">Create Provider Account</h1>
			<p class="text-gray-600 mt-2">Join the healthcare platform</p>
		</div>

		{#if error}
			<div class="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-md text-sm mb-6">
				{error}
			</div>
		{/if}

		<form onsubmit={handleSignup} class="space-y-6">
			<div>
				<label for="email" class="block text-sm font-medium text-gray-700 mb-2">
					Email Address
				</label>
				<input
					id="email"
					type="email"
					bind:value={formData.email}
					required
					class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-primary-500 focus:border-transparent"
					placeholder="doctor@example.com"
				/>
			</div>

			<div>
				<label for="password" class="block text-sm font-medium text-gray-700 mb-2">
					Password
				</label>
				<input
					id="password"
					type="password"
					bind:value={formData.password}
					required
					class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-primary-500 focus:border-transparent"
					placeholder="••••••••"
				/>
			</div>

			<div>
				<label for="confirmPassword" class="block text-sm font-medium text-gray-700 mb-2">
					Confirm Password
				</label>
				<input
					id="confirmPassword"
					type="password"
					bind:value={formData.confirmPassword}
					required
					class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-primary-500 focus:border-transparent"
					placeholder="••••••••"
				/>
			</div>

			<button
				type="submit"
				disabled={loading}
				class="w-full bg-primary-600 text-white py-2 px-4 rounded-md hover:bg-primary-700 focus:outline-none focus:ring-2 focus:ring-primary-500 focus:ring-offset-2 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
			>
				{loading ? 'Creating Account...' : 'Create Account'}
			</button>
		</form>

		<div class="mt-6 text-center">
			<a href="/auth/login" class="text-sm text-primary-600 hover:text-primary-700">
				Already have an account? Sign in
			</a>
		</div>
	</div>
</div>
