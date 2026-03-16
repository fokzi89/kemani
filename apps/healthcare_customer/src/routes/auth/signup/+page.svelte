<script lang="ts">
	import { goto } from '$app/navigation';
	import { Mail, Lock, User, Phone, Eye, EyeOff, AlertCircle, CheckCircle } from 'lucide-svelte';
	import { authStore } from '$lib/stores/auth.svelte';

	let formData = $state({
		email: '',
		password: '',
		confirmPassword: '',
		full_name: '',
		phone: ''
	});
	let showPassword = $state(false);
	let showConfirmPassword = $state(false);
	let isLoading = $state(false);
	let error = $state('');
	let success = $state(false);

	async function handleSubmit(e: Event) {
		e.preventDefault();
		error = '';
		isLoading = true;

		// Validate passwords match
		if (formData.password !== formData.confirmPassword) {
			error = 'Passwords do not match';
			isLoading = false;
			return;
		}

		// Validate password strength
		if (formData.password.length < 6) {
			error = 'Password must be at least 6 characters';
			isLoading = false;
			return;
		}

		try {
			await authStore.signUp(formData.email, formData.password, {
				full_name: formData.full_name,
				phone: formData.phone
			});

			success = true;
			setTimeout(() => {
				goto('/');
			}, 2000);
		} catch (err: any) {
			error = err.message || 'Failed to create account. Please try again.';
		} finally {
			isLoading = false;
		}
	}
</script>

<svelte:head>
	<title>Sign Up | Kemani Health</title>
</svelte:head>

<div class="min-h-screen bg-gradient-to-br from-blue-50 to-blue-100 flex items-center justify-center px-4 py-12">
	<div class="max-w-md w-full">
		<!-- Logo/Header -->
		<div class="text-center mb-8">
			<div class="inline-flex items-center justify-center w-16 h-16 bg-gradient-to-br from-blue-500 to-blue-600 rounded-2xl mb-4">
				<span class="text-2xl font-bold text-white">K</span>
			</div>
			<h1 class="text-3xl font-bold text-gray-900">Create Account</h1>
			<p class="text-gray-600 mt-2">Join Kemani Health today</p>
		</div>

		<!-- Signup Form -->
		<div class="bg-white rounded-2xl shadow-xl p-8">
			{#if success}
				<div class="text-center py-8">
					<div class="inline-flex items-center justify-center w-16 h-16 bg-green-100 rounded-full mb-4">
						<CheckCircle class="w-8 h-8 text-green-600" />
					</div>
					<h2 class="text-2xl font-bold text-gray-900 mb-2">Account Created!</h2>
					<p class="text-gray-600">Redirecting to dashboard...</p>
				</div>
			{:else}
				<form onsubmit={handleSubmit} class="space-y-5">
					<!-- Full Name -->
					<div>
						<label for="full_name" class="block text-sm font-medium text-gray-700 mb-2">
							Full Name
						</label>
						<div class="relative">
							<div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
								<User class="h-5 w-5 text-gray-400" />
							</div>
							<input
								id="full_name"
								type="text"
								bind:value={formData.full_name}
								required
								class="block w-full pl-10 pr-3 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
								placeholder="John Doe"
							/>
						</div>
					</div>

					<!-- Email -->
					<div>
						<label for="email" class="block text-sm font-medium text-gray-700 mb-2">
							Email Address
						</label>
						<div class="relative">
							<div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
								<Mail class="h-5 w-5 text-gray-400" />
							</div>
							<input
								id="email"
								type="email"
								bind:value={formData.email}
								required
								class="block w-full pl-10 pr-3 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
								placeholder="you@example.com"
							/>
						</div>
					</div>

					<!-- Phone -->
					<div>
						<label for="phone" class="block text-sm font-medium text-gray-700 mb-2">
							Phone Number
						</label>
						<div class="relative">
							<div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
								<Phone class="h-5 w-5 text-gray-400" />
							</div>
							<input
								id="phone"
								type="tel"
								bind:value={formData.phone}
								required
								class="block w-full pl-10 pr-3 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
								placeholder="+234 801 234 5678"
							/>
						</div>
					</div>

					<!-- Password -->
					<div>
						<label for="password" class="block text-sm font-medium text-gray-700 mb-2">
							Password
						</label>
						<div class="relative">
							<div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
								<Lock class="h-5 w-5 text-gray-400" />
							</div>
							<input
								id="password"
								type={showPassword ? 'text' : 'password'}
								bind:value={formData.password}
								required
								class="block w-full pl-10 pr-10 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
								placeholder="Min. 6 characters"
							/>
							<button
								type="button"
								onclick={() => showPassword = !showPassword}
								class="absolute inset-y-0 right-0 pr-3 flex items-center"
							>
								{#if showPassword}
									<EyeOff class="h-5 h-5 text-gray-400" />
								{:else}
									<Eye class="h-5 w-5 text-gray-400" />
								{/if}
							</button>
						</div>
					</div>

					<!-- Confirm Password -->
					<div>
						<label for="confirmPassword" class="block text-sm font-medium text-gray-700 mb-2">
							Confirm Password
						</label>
						<div class="relative">
							<div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
								<Lock class="h-5 w-5 text-gray-400" />
							</div>
							<input
								id="confirmPassword"
								type={showConfirmPassword ? 'text' : 'password'}
								bind:value={formData.confirmPassword}
								required
								class="block w-full pl-10 pr-10 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
								placeholder="Re-enter password"
							/>
							<button
								type="button"
								onclick={() => showConfirmPassword = !showConfirmPassword}
								class="absolute inset-y-0 right-0 pr-3 flex items-center"
							>
								{#if showConfirmPassword}
									<EyeOff class="h-5 w-5 text-gray-400" />
								{:else}
									<Eye class="h-5 w-5 text-gray-400" />
								{/if}
							</button>
						</div>
					</div>

					<!-- Error Message -->
					{#if error}
						<div class="bg-red-50 border border-red-200 rounded-lg p-4 flex items-start gap-3">
							<AlertCircle class="w-5 h-5 text-red-600 flex-shrink-0 mt-0.5" />
							<p class="text-sm text-red-700">{error}</p>
						</div>
					{/if}

					<!-- Submit Button -->
					<button
						type="submit"
						disabled={isLoading}
						class="w-full py-3 px-4 bg-blue-600 text-white rounded-lg font-semibold hover:bg-blue-700 transition disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2"
					>
						{#if isLoading}
							<span class="w-5 h-5 border-2 border-white border-t-transparent rounded-full animate-spin"></span>
							<span>Creating account...</span>
						{:else}
							<span>Create Account</span>
						{/if}
					</button>
				</form>

				<!-- Sign In Link -->
				<div class="mt-6 text-center">
					<p class="text-sm text-gray-600">
						Already have an account?
						<a href="/auth/login" class="text-blue-600 hover:underline font-medium">
							Sign in
						</a>
					</p>
				</div>
			{/if}
		</div>

		<!-- Footer -->
		<p class="text-center text-sm text-gray-600 mt-8">
			By creating an account, you agree to our
			<a href="/terms" class="text-blue-600 hover:underline">Terms of Service</a>
			and
			<a href="/privacy" class="text-blue-600 hover:underline">Privacy Policy</a>
		</p>
	</div>
</div>
